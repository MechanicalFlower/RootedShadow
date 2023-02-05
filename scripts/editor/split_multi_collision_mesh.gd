extends Node

export var scene: PackedScene 
export var split_multimesh_path: NodePath 

onready var split_multimesh_node = get_node(split_multimesh_path) as Spatial

func _ready():
	for child in split_multimesh_node.get_children():
		if not child is MultiMeshInstance:
			continue
		for index in child.multimesh.instance_count:
			var trans := child.multimesh.get_instance_transform(index) as  Transform 
			var scene_node := scene.instance() as Spatial
			scene_node.transform = trans
			child.add_child(scene_node)
