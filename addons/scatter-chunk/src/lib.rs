use gdnative::prelude::*;

mod chunk;
mod plugin;

fn init(handle: InitHandle) {
    handle.add_tool_class::<plugin::ScatterChunkPlugin>();
    handle.add_class::<chunk::SplitMultimeshContainer>();
}

godot_init!(init);
