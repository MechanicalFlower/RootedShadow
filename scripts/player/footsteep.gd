extends Node

export(NodePath) var feet_path
export(NodePath) var audio_path
export(NodePath) var character_path

var footsteep_timer: float = 0
var footsteep_speed: float = 0.5
var footsteep_list: Dictionary = {}

var dont_repeat: int = 0

onready var feet = get_node(feet_path) as RayCast
onready var audios = get_node(audio_path) as Spatial
onready var character = get_node(character_path) as KinematicBody


func _ready() -> void:
	randomize()

	for audio in audios.get_children():
		footsteep_list[audio.name] = audio


func _process(_delta) -> void:
	if footsteep_timer <= 0:
		if character.direction:
			if feet.is_colliding():
				var collider = feet.get_collider()
				var groups = collider.get_groups()

				for g in groups:
					if footsteep_list.has(g):
						var footsteep_node = footsteep_list[g]

						if footsteep_node.get_child_count() > 0:
							var audio = randi() % footsteep_node.get_child_count()

							footsteep_node.get_child(audio).play()

							var temp_accel: float = character.get_accel()
							footsteep_timer = 1 - (0.06 * temp_accel)
							break
	else:
		footsteep_timer -= _delta
