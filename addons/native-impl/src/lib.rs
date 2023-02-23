use gdnative::prelude::*;

mod ik;
mod scatter;
mod lod;
mod plugin;


fn init(handle: InitHandle) {
    handle.add_tool_class::<plugin::NativeImplPlugin>();
    handle.add_tool_class::<lod::NativeLODSpatial>();
    handle.add_tool_class::<ik::NativeIKSolver>();
    handle.add_class::<scatter::NativeSplitMultimeshContainer>();
}

godot_init!(init);
