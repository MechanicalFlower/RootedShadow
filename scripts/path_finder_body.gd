class_name PathFinderBody
extends KinematicBody

var direction := Vector3.ZERO
var velocity := Vector3.ZERO

onready var nav_agent = get_node("%NavigationAgent") as NavigationAgent


func _ready():
#	nav_agent.set_target_location(get_tree().get_nodes_in_group("player")[0].global_translation)
	nav_agent.connect("velocity_computed", self, "_on_NavAgent_velocity_computed")


func pathfinding():
	if nav_agent.is_navigation_finished():
		return
	var target = nav_agent.get_next_location()
	direction = global_translation.direction_to(target)
	velocity = direction * nav_agent.max_speed
	nav_agent.set_velocity(velocity)


func _on_NavAgent_velocity_computed(safe_velocity: Vector3):
	move_and_slide(safe_velocity, Vector3.UP)


func set_target_location(position: Vector3):
	nav_agent.set_target_location(position)
