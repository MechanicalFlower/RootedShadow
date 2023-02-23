use gdnative::api::{ProjectSettings, RandomNumberGenerator, Spatial};
use gdnative::prelude::*;

#[derive(NativeClass)]
#[inherit(Spatial)]
#[register_with(Self::register_properties)]
pub struct NativeLODSpatial {
    pub enable_lod: bool,
    pub lod_0_max_distance: f32,
    pub lod_1_max_distance: f32,
    pub lod_2_max_distance: f32,
    refresh_rate: f64,
    lod_bias: f32,
    timer: f64,
}

#[methods]
impl NativeLODSpatial {
    fn register_properties(builder: &ClassBuilder<NativeLODSpatial>) {
        use gdnative::export::hint::*;

        builder
            .property::<bool>("enable_lod")
            .with_getter(move |my_node: &NativeLODSpatial, _base: TRef<Spatial>| my_node.enable_lod)
            .with_setter(
                move |my_node: &mut NativeLODSpatial, _base: TRef<Spatial>, new_value| {
                    my_node.enable_lod = new_value
                },
            )
            .with_default(true)
            .done();

        builder
            .property::<f32>("lod_0_max_distance")
            .with_getter(move |my_node: &NativeLODSpatial, _base: TRef<Spatial>| {
                my_node.lod_0_max_distance
            })
            .with_setter(
                move |my_node: &mut NativeLODSpatial, _base: TRef<Spatial>, new_value| {
                    my_node.lod_0_max_distance = new_value
                },
            )
            .with_default(10.0)
            .with_hint(FloatHint::Range(RangeHint::new(0.0, 1000.0).with_step(0.1)))
            .done();

        builder
            .property::<f32>("lod_1_max_distance")
            .with_getter(move |my_node: &NativeLODSpatial, _base: TRef<Spatial>| {
                my_node.lod_1_max_distance
            })
            .with_setter(
                move |my_node: &mut NativeLODSpatial, _base: TRef<Spatial>, new_value| {
                    my_node.lod_1_max_distance = new_value
                },
            )
            .with_default(25.0)
            .with_hint(FloatHint::Range(RangeHint::new(0.0, 1000.0).with_step(0.1)))
            .done();

        builder
            .property::<f32>("lod_2_max_distance")
            .with_getter(move |my_node: &NativeLODSpatial, _base: TRef<Spatial>| {
                my_node.lod_2_max_distance
            })
            .with_setter(
                move |my_node: &mut NativeLODSpatial, _base: TRef<Spatial>, new_value| {
                    my_node.lod_2_max_distance = new_value
                },
            )
            .with_default(100.0)
            .with_hint(FloatHint::Range(RangeHint::new(0.0, 1000.0).with_step(0.1)))
            .done();
    }

    fn new(_owner: TRef<Spatial>) -> Self {
        NativeLODSpatial {
            enable_lod: true,
            lod_0_max_distance: 10.0,
            lod_1_max_distance: 25.0,
            lod_2_max_distance: 100.0,
            refresh_rate: 0.25,
            lod_bias: 0.0,
            timer: 0.0,
        }
    }

    #[method]
    fn _ready(&mut self, #[base] _owner: TRef<Spatial>) {
        if ProjectSettings::godot_singleton().has_setting("lod/spatial_bias") {
            self.lod_bias = ProjectSettings::godot_singleton()
                .get_setting("lod/spatial_bias")
                .try_to::<f32>()
                .unwrap();
        }
        if ProjectSettings::godot_singleton().has_setting("lod/refresh_rate") {
            self.refresh_rate = ProjectSettings::godot_singleton()
                .get_setting("lod/refresh_rate")
                .try_to::<f64>()
                .unwrap();
        }

        let rng = RandomNumberGenerator::new();
        rng.randomize();
        self.timer += rng.randf_range(0.0, self.refresh_rate);
    }

    #[method]
    fn _physics_process(&mut self, #[base] owner: TRef<Spatial>, delta: f64) {
        if !self.enable_lod {
            return;
        }

        let tree = owner.get_tree().unwrap();
        let tree = unsafe { tree.assume_safe() };
        let players = tree.get_nodes_in_group("player");

        if !players.is_empty() {
            let player = players.get(0);

            if let Some(player) = player.to_object::<Spatial>() {
                let camera = unsafe { player.assume_safe() };

                if self.timer <= self.refresh_rate {
                    self.timer += delta;
                    return;
                }

                self.timer = 0.0;

                let distance = camera
                    .global_transform()
                    .origin
                    .distance_to(owner.global_transform().origin)
                    + self.lod_bias;

                let lod: u8;
                if distance < self.lod_0_max_distance {
                    lod = 0;
                } else if distance < self.lod_1_max_distance {
                    lod = 1;
                } else if distance < self.lod_2_max_distance {
                    lod = 2;
                } else {
                    lod = 3;
                }

                for child in &owner.get_children() {
                    if let Some(child) = child.to_object::<Spatial>() {
                        let child = unsafe { child.assume_safe() };

                        if child.name().ends_with(&GodotString::from_str("-lod0")) {
                            child.set_visible(lod == 0);
                        }
                        if child.name().ends_with(&GodotString::from_str("-lod1")) {
                            child.set_visible(lod == 1);
                        }
                        if child.name().ends_with(&GodotString::from_str("-lod2")) {
                            child.set_visible(lod == 2);
                        }
                    }
                }
            }
        }
    }
}
