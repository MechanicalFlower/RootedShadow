tool
extends Node

const MultimeshHelper = preload("res://scripts/editor/multimesh_helper.gd")

export var scene: PackedScene 
export var multimesh_path: NodePath 

onready var multimesh_node = get_node(multimesh_path) as Spatial

func _ready():
	MultimeshHelper.add_scene_to_mesh_by_multimesh(multimesh_node, scene)
