extends Node

export var sprint_speed := 16
export var fov_multiplier := 1.05

onready var controller := get_parent() as MovementController
onready var camera := get_parent().get_node("Head").cam as Camera

onready var normal_speed: int = controller.speed
onready var normal_fov: float = camera.fov


func _physics_process(delta: float) -> void:
	if can_sprint():
		controller.speed = sprint_speed
		camera.set_fov(lerp(camera.fov, normal_fov * fov_multiplier, delta * 8))
	else:
		controller.speed = normal_speed
		camera.set_fov(lerp(camera.fov, normal_fov, delta * 8))


func can_sprint() -> bool:
	return (
		controller.is_on_floor()
		and Input.is_action_pressed("sprint")
		and controller.input_axis.x >= 0.5
	)
