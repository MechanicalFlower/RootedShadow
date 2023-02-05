extends Node

export var scene: PackedScene 
export var multimesh_path: NodePath 

onready var multimesh_node = get_node(multimesh_path) as Spatial

func _ready():
	for index in multimesh_node.multimesh.instance_count:
		var trans := multimesh_node.multimesh.get_instance_transform(index) as  Transform 
		var scene_node := scene.instance() as Spatial
		scene_node.transform = trans
		multimesh_node.add_child(scene_node)
