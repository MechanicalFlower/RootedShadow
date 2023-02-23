use gdnative::prelude::*;
use gdnative::api::MultiMeshInstance;

#[derive(NativeClass)]
#[inherit(Spatial)]
pub struct NativeSplitMultimeshContainer {
    // These variables need to be exported to be able to save them to the scene
    // Do not modify them directly, modify the options in the scatter instance
    #[property(default = 0.0)]
    pub visible_range_begin: f32,
    #[property(default = 0.1)]
    pub visible_range_begin_hysteresis: f32,
    #[property(default = 0.0)]
    pub visible_range_end: f32,
    #[property(default = 0.1)]
    pub visible_range_end_hysteresis: f32,

    #[property(default = true)]
    pub is_split_multimesh_container: bool,
}


#[methods]
impl NativeSplitMultimeshContainer {
    fn new(_owner: TRef<Spatial>) -> Self {
        NativeSplitMultimeshContainer {
            visible_range_begin: 0.0,
            visible_range_begin_hysteresis: 0.1,
            visible_range_end: 0.0,
            visible_range_end_hysteresis: 0.1,
            is_split_multimesh_container: true,
        }
    }

    #[method]
    fn _process(&self, #[base] owner: TRef<Spatial>, _delta: f32) {
    
        if self.visible_range_end == 0.0 && self.visible_range_end == 0.0 {
            return;
        }
        
        let tree = owner.get_tree().unwrap();
        let tree = unsafe { tree.assume_safe() };
        let players = tree.get_nodes_in_group("player");
        
        if players.len() > 0 {
            let player = players.get(0);

            if let Some(player) = player.to_object::<Spatial>() {
                let player = unsafe { player.assume_safe() };
                
                for child in &owner.get_children() {

                    if let Some(child) = child.to_object::<MultiMeshInstance>() {
                        let child = unsafe { child.assume_safe() };
                        
                        let mmi_aabb: Aabb = child.get_aabb();
                        let mmi_aabb_center = mmi_aabb.position + mmi_aabb.size / Vector3::new(2.0, 2.0, 2.0);
                        let center: Vector3 = child.global_transform().xform(mmi_aabb_center);
                        let mut d: f32 = player.global_translation().distance_to(center);
                        // subtract the half size of the aabb to get the distance to the edge of the mmi
                        d -= mmi_aabb.size.length() / 2.0;
                        // if inside sphere make distance 0
                        if d < 0.0 {
                            d = 0.0
                        } 

                        let mut hide = false;
                        let mut show = true;

                        if self.visible_range_begin != 0.0 {
                            if d <= self.visible_range_begin - self.visible_range_begin_hysteresis {
                                // Too close, hide
                                hide = true;
                            }
                            // if inside hysteresis band do not change visibility
                            if (d - self.visible_range_begin).abs() < self.visible_range_begin_hysteresis {
                                show = false;
                            }
                        }

                        if self.visible_range_end != 0.0 {
                            if d >= self.visible_range_end + self.visible_range_end_hysteresis {
                                // Too far, hide
                                hide = true;
                            }
                            // if inside hysteresis band do not change visiblity
                            if (d - self.visible_range_end).abs() < self.visible_range_end_hysteresis {
                                show = false;
                            }
                        }

                        if hide {
                            child.set_visible(false);
                        } else if show {
                            child.set_visible(true);
                        }
                    }
                }
            }
        }
    }
}