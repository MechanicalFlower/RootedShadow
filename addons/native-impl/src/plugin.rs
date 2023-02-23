use gdnative::api::{EditorPlugin, Script, Texture};
use gdnative::prelude::*;

#[derive(gdnative::derive::NativeClass)]
#[inherit(EditorPlugin)]
pub struct NativeImplPlugin;

#[methods]
impl NativeImplPlugin {
    fn new(_owner: TRef<EditorPlugin>) -> Self {
        NativeImplPlugin
    }

    #[method]
    fn _enter_tree(&self, #[base] owner: TRef<EditorPlugin>) {
        let script = load::<Script>("res://addons/native-impl/native/NativeSplitMultimeshContainer.gdns").unwrap();
        let texture = load::<Texture>("res://addons/native-impl/icons/divide.svg").unwrap();
        owner.add_custom_type("NativeSplitMultimeshContainer", "Spatial", script, texture);

        let script = load::<Script>("res://addons/native-impl/native/NativeLODSpatial.gdns").unwrap();
        let texture = load::<Texture>("res://addons/lod/lod_spatial.svg").unwrap();
        owner.add_custom_type("NativeLODSpatial", "Spatial", script, texture);

        let script = load::<Script>("res://addons/native-impl/native/NativeIKSolver.gdns").unwrap();
        let texture = load::<Texture>("res://addons/native-impl/icons/bone.svg").unwrap();
        owner.add_custom_type("NativeIKSolver", "Skeleton", script, texture);
    }

    #[method]
    fn _exit_tree(&self, #[base] owner: TRef<EditorPlugin>) {
        owner.remove_custom_type("NativeSplitMultimeshContainer");
        owner.remove_custom_type("NativeLODSpatial");
        owner.remove_custom_type("NativeIKSolver");
    }
}
