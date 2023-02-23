use gdnative::prelude::*;
use gdnative::api::{OS, Spatial, Position3D, BoneAttachment};
use gdnative::globalscope::lerp;


fn lerp_vec3(a: &Vector3, b: &Vector3, scalar: &f32) -> Vector3 {
    let pt = interpolation::lerp(&[a.x, a.y, a.z], &[b.x, b.y, b.z], &scalar);
    return Vector3::new(pt[0], pt[1], pt[2]);
}

const ESPILON: f32 = 0.01;

macro_rules! to_bone {
    ($joint:expr) => {
        {
            let bone_attachement = $joint.to_object::<BoneAttachment>().unwrap();
            unsafe { bone_attachement.assume_safe() }
        }
    };
}

// Always present sub-nodes
#[derive(Debug, Clone)]
struct SubNodes {
    rest_position: Ref<Position3D>,
    ray_cast_position: Ref<Position3D>,
    pole_position: Ref<Position3D>,
    pole_rotation: Ref<Position3D>,
}

#[derive(NativeClass)]
#[inherit(Spatial)]
pub struct NativeIKSolver {
    #[property]
    pub step_interval_ms: f32,
    #[property]
    pub step_clock_offset_ms: f32,
    #[property]
    pub step_duration_ms: f32,
    #[property]
    pub step_height: f32,
    #[property]
    pub step_prediction_ratio: f32,
    #[property]
    pub step_min_distance: f32,
    step_min_distance_squared: f32,
    previous_step_time: f32,
    next_position: Vector3,
    previous_position: Vector3,
    previous_tick: f32,
    
    iteration_count: u32,
    target_position: Vector3,
    pole_position: Vector3,
    pole_rotation: Vector3,
    joints: VariantArray<Unique>,
    joint_lengths: PoolArray<f32>,
    positions: PoolArray<Vector3>,
    max_length: f32,

    sub_nodes: Option<SubNodes>,
}


#[methods]
impl NativeIKSolver {
    fn new(_owner: TRef<Spatial>) -> Self {
        NativeIKSolver {
            step_interval_ms: 400.0,
            step_clock_offset_ms: 200.0,
            step_duration_ms: 100.0,
            step_height: 0.5,
            step_prediction_ratio: 1.0,
            step_min_distance: 0.3,
            step_min_distance_squared: 0.0,
            previous_step_time: 0.0,
            next_position: Vector3::ZERO,
            previous_position: Vector3::ZERO,
            previous_tick: 0.0,

            iteration_count: 10,
            target_position: Vector3::ZERO,
            pole_position: Vector3::ZERO,
            pole_rotation: Vector3::ZERO,
            joints: VariantArray::<Unique>::new(),
            joint_lengths: PoolArray::<f32>::new(),
            positions: PoolArray::<Vector3>::new(),
            max_length: 0.0,

            sub_nodes: None,
        }
    }

    #[method]
    fn _ready(&mut self, #[base] owner: TRef<Spatial>) {
        self.sub_nodes = Some(unsafe {
            SubNodes {
                rest_position: owner.get_node_as::<Position3D>("rest_position").unwrap().claim(),
                ray_cast_position: owner.get_node_as::<Position3D>("ray_cast_position").unwrap().claim(),
                pole_position: owner.get_node_as::<Position3D>("pole_position").unwrap().claim(),
                pole_rotation: owner.get_node_as::<Position3D>("pole_rotation").unwrap().claim(),
            }
        });

        self.step_min_distance_squared = self.step_min_distance * self.step_min_distance;
	    self._set_joints(owner);
    }

    #[method]
    fn _process(&mut self, #[base] owner: TRef<Spatial>, _delta: f64) {
        if let Some(sub_nodes) = self.sub_nodes.as_ref() {
            let rest_position = unsafe { sub_nodes.rest_position.assume_safe() }.global_translation();
            let ray_cast_position = unsafe { sub_nodes.ray_cast_position.assume_safe() }.global_translation();

            let current_time = OS::godot_singleton().get_ticks_msec() as f32;
            let tick = ((current_time + self.step_clock_offset_ms) / self.step_interval_ms).floor();

            if tick - self.previous_tick > 0.0 {
                self.previous_step_time = current_time;
                self.previous_tick = tick;

                let cast_start = ray_cast_position;
                let mut cast_end = rest_position;

                let last_step_delta = rest_position - self.previous_position;
                cast_end += self.step_prediction_ratio * last_step_delta;
                cast_end += Vector3::DOWN * 2.0;

                let world = owner.get_world().unwrap();
                let world = unsafe { world.assume_safe() };
                
                let physics = world.direct_space_state().unwrap();
                let physics = unsafe { physics.assume_safe() };

                let cast_result = physics.intersect_ray(cast_start, cast_end, VariantArray::new_shared(), 2147483647, true, false);

                self.previous_position = self.next_position;
                self.next_position = cast_result.get_or("position", rest_position).to::<Vector3>().unwrap();
            }

            if self.previous_position.distance_squared_to(self.next_position) > self.step_min_distance_squared {
                let transition_ratio = f32::min(1.0, (current_time - self.previous_step_time) / self.step_duration_ms);

                self.target_position = lerp_vec3(&self.previous_position, &self.next_position, &transition_ratio);
                self.target_position.y += self.step_height - lerp(-self.step_height..=self.step_height, transition_ratio).abs();
            }

            self.iteration_count = 1;
            self.pole_position = unsafe { sub_nodes.pole_position.assume_safe() }.global_translation();
            self.pole_rotation = unsafe { sub_nodes.pole_rotation.assume_safe() }.global_translation();
            self._update_joint_transforms();
        }
    }

    fn _extract_joints(&mut self, owner: TRef<Spatial>) {
        let mut current_node = None;
        self.joints.clear();

        for child in &owner.get_children() {
            if let Some(child) = child.to_object::<BoneAttachment>() {
                let child = unsafe { child.assume_safe() };
                current_node = Some(child);
                self.joints.push(child);
            }
        }

        while current_node.is_some() {
            let prev_node = current_node.unwrap();
            current_node = None;

            for child in &prev_node.get_children() {
                if let Some(child) = child.to_object::<BoneAttachment>() {
                    let child = unsafe { child.assume_safe() };
                    current_node = Some(child);
                    self.joints.push(child);
                }
            }
        }
    }

    fn _set_joints(&mut self, owner: TRef<Spatial>) {
        self._extract_joints(owner);
        self.joint_lengths = PoolArray::<f32>::new();
        self.max_length = 0.0;

        for i in 1..self.joints.len() {
            let bone_attachement = to_bone!(self.joints.get(i));
            let prev_bone_attachement = to_bone!(self.joints.get(i - 1));

            self.joint_lengths.push((bone_attachement.global_translation() - prev_bone_attachement.global_translation()).length());
            self.max_length += self.joint_lengths.get(self.joint_lengths.len() - 1);
        }

        self.positions = PoolArray::<Vector3>::new();
        for joint in self.joints.iter() {
            let bone_attachement = to_bone!(joint);
            self.positions.push(bone_attachement.global_translation());
        }
    }

    fn _update_joint_transforms(&mut self) {
        if self.joints.len() == 0 {
            return;
        }

        for i in 0..self.joints.len() {
            let bone_attachement = to_bone!(self.joints.get(i));
            self.positions.set(i, bone_attachement.global_translation());
        }
        
        let first_bone_attachement = to_bone!(self.joints.get(0));
        if first_bone_attachement.global_translation().distance_squared_to(self.target_position) >= self.max_length * self.max_length {
            let direction = (self.target_position - self.positions.get(0)).normalized();
            for i in 1..self.positions.len() {
                self.positions.set(i, self.positions.get(i - 1) + direction * self.joint_lengths.get(i - 1));
            }
        } else {
            for _i in 0..self.iteration_count {
                if self.positions.get(self.positions.len() - 1).distance_squared_to(self.target_position) < ESPILON * ESPILON {
                    break;
                }

                for j in (1..self.positions.len()).rev() {
                    if j == self.positions.len() - 1 {
                        self.positions.set(j, self.target_position);
                    } else {
                        self.positions.set(j, self.positions.get(j + 1) + (self.positions.get(j) - self.positions.get(j + 1)).normalized() * self.joint_lengths.get(j));
                    }
                }

                for j in 1..self.positions.len() {
                    self.positions.set(j, self.positions.get(j - 1) + (self.positions.get(j) - self.positions.get(j - 1)).normalized() * self.joint_lengths.get(j - 1));
                }
            }
        }

        for i in 1..(self.positions.len() - 1) {
            let normal = (self.positions.get(i + 1) - self.positions.get(i - 1)).normalized();

            let plane = Plane::new(normal, self.positions.get(i - 1).dot(normal));
            let projected_pole = plane.project(self.pole_position);
            let projected_joint = plane.project(self.positions.get(i));

            let mut angle;
            let prev_pos = self.positions.get(i - 1);
            if projected_joint.is_equal_approx(prev_pos) || projected_pole.is_equal_approx(prev_pos) {
                angle = 0.0;
            } else {
                angle = (projected_joint - self.positions.get(i - 1)).angle_to(projected_pole - self.positions.get(i - 1));
            }
            
            if (projected_joint - self.positions.get(i - 1)).cross(projected_pole - self.positions.get(i - 1)).dot(plane.normal) < 0.0 {
                angle = -angle;
            }
            
            self.positions.set(i, Quat::from_axis_angle(normal, angle).normalized() * (self.positions.get(i) - self.positions.get(i - 1)) + self.positions.get(i - 1));
        }

        for i in 0..self.joints.len() {
            let bone_attachement = to_bone!(self.joints.get(i));
            bone_attachement.set_global_translation(self.positions.get(i));
            let next_position = {
                if i < self.joints.len() - 1 {
                    self.positions.get(i + 1)
                } else {
                    self.target_position
                }
            };
            let up = self.pole_rotation - self.positions.get(i);
            if bone_attachement.global_translation() != next_position {
                bone_attachement.look_at(next_position, up);
            }
        }
    }
}