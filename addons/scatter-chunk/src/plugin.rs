use gdnative::api::{EditorPlugin, Script, Texture};
use gdnative::prelude::*;

#[derive(gdnative::derive::NativeClass)]
#[inherit(EditorPlugin)]
pub struct ScatterChunkPlugin;

#[methods]
impl ScatterChunkPlugin {
    fn new(_owner: TRef<EditorPlugin>) -> Self {
        ScatterChunkPlugin
    }

    #[method]
    fn _enter_tree(&self, #[base] owner: TRef<EditorPlugin>) {
        let script = load::<Script>("res://native/SplitMultimeshContainer.gdns").unwrap();
        let texture = load::<Texture>("res://assets/icon.png").unwrap();
        owner.add_custom_type("SplitMultimeshContainer", "Spatial", script, texture);
    }

    #[method]
    fn _exit_tree(&self, #[base] owner: TRef<EditorPlugin>) {
        owner.remove_custom_type("SplitMultimeshContainer");
    }
}
