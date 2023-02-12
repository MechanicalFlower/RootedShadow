extends Node

const MultimeshHelper = preload("res://scripts/editor/multimesh_helper.gd")

export var scene: PackedScene 
export var split_multimesh_path: NodePath 

onready var split_multimesh_node = get_node(split_multimesh_path) as Spatial

func _ready():
	for child in split_multimesh_node.get_children():
		if not child is MultiMeshInstance:
			continue
		MultimeshHelper.add_scene_to_mesh_by_multimesh(child, scene)
