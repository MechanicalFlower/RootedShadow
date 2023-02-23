use gdnative::prelude::*;

mod ik;
mod lod;
mod plugin;
mod scatter;

fn init(handle: InitHandle) {
    handle.add_tool_class::<plugin::NativeImplPlugin>();
    handle.add_tool_class::<lod::NativeLODSpatial>();
    handle.add_tool_class::<ik::NativeIKSolver>();
    handle.add_class::<scatter::NativeSplitMultimeshContainer>();
}

godot_init!(init);
