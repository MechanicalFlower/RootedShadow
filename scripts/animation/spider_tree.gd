class_name SpiderTree
extends PathFinderBody

enum States { PATROL, CHASE }

export(NodePath) var patrol_path

var state = States.PATROL

var player_node

# For path following.
var patrol_index = 0

onready var patrol_node := get_node(patrol_path) as Path
onready var patrol_points := patrol_node.curve.get_baked_points() as PoolVector3Array
# TODO : avoid this
onready var parent := get_parent() as Spatial


func _ready():
	player_node = get_tree().get_nodes_in_group("player")[0]
	patrol_index = 0
	set_target_location(parent.to_global(patrol_points[patrol_index]))


func set_state(new_state):
	state = new_state


func pathfollow():
	if nav_agent.is_navigation_finished():
		patrol_index = wrapi(patrol_index + 1, 0, patrol_points.size())
		set_target_location(parent.to_global(patrol_points[patrol_index]))
	var target = nav_agent.get_next_location()
	direction = global_translation.direction_to(target)
	velocity = direction * nav_agent.max_speed
	nav_agent.set_velocity(velocity)


func _physics_process(_delta):
	if global_translation.distance_to(player_node.global_translation) > 50:
		return

	# Depending on the current state, choose a movement target.
	match state:
		# Move along assigned path.
		States.PATROL:
			pathfollow()

		# Move towards player.
		States.CHASE:
			pathfinding()

			if nav_agent.is_navigation_finished():
				# If the player is in the close area, continue to chase
				if global_translation.distance_to(player_node.global_translation) < 30:
					set_target_location(player_node.global_translation)
				else:
					# Return to patrol otherwise
					set_state(States.PATROL)


# To handle correctly footsteep
func get_accel() -> float:
	return 2.0
