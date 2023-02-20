# Spatial script for handling character movements and IK
# By default, the script uses root joint position
# and orientation to control the character's movements.

tool
extends Spatial

# The node paths to the rest position, ray cast position,
# pole position, pole rotation, and root joint
export(NodePath) var rest_position_path
export(NodePath) var ray_cast_position_path
export(NodePath) var pole_position_path
export(NodePath) var pole_rotation_path
export(NodePath) var root_joint_path setget _set_root_joint_path

# Step interval in milliseconds, step clock offset in milliseconds,
# step duration in milliseconds, step height, and step prediction ratio
export var step_interval_ms = 400.0
export var step_clock_offset_ms = 200.0
export var step_duration_ms = 100.0
export var step_height = 0.5
export var step_prediction_ratio = 1.0
export var step_min_distance = 0.3

# Squared value of step minimum distance to avoid root calculations
var step_min_distance_squared = step_min_distance * step_min_distance
var previous_step_time = 0
var target_position = Vector3.ZERO
var next_position = Vector3.ZERO
var previous_position = Vector3.ZERO
var previous_tick = 0

# The inverse kinematic solver instance
onready var inverse_kinematic_solver = get_node("%inverse_kinematic_solver")

# Setter function for root_joint_path
func _set_root_joint_path(node_path):
	root_joint_path = node_path
	if node_path and previous_step_time != 0:
		var joints = _extract_joints(get_node(root_joint_path))
		inverse_kinematic_solver.set_joints(joints)


# Function called when the script is ready
func _ready():
	var joints = _extract_joints(get_node(root_joint_path))
	inverse_kinematic_solver.set_joints(joints)


# Extracts the joints from the root joint node
func _extract_joints(root_joint_node):
	# The current node being processed
	var current_node = root_joint_node

	# List to store all the new joints found
	var new_joints = []

	# Continue processing until all nodes have been processed
	while current_node != null:
		# Store the previous node before processing the children
		var prev_node = current_node

		# Reset the current node
		current_node = null

		# Loop through all the children of the previous node
		for child in prev_node.get_children():
			# If the child is a BoneAttachment
			if child is BoneAttachment:
				# Set the current node to the child node
				current_node = child

				# Add the child node to the list of new joints
				new_joints.append(child)

	# Print the number of joints found
#	print("found ", new_joints.size(), " joints")

	# Return the list of new joints
	return new_joints


func _process(_delta):
	# Get the rest position and ray cast position from the node paths
	var rest_position = get_node(rest_position_path).global_transform.origin
	var ray_cast_position = get_node(ray_cast_position_path).global_transform.origin

	# Get the current time
	var current_time = OS.get_ticks_msec()

	# Calculate the current tick based on the step interval and the current time
	# Adding an offset helps this instance to get its next tick earlier than instances without offset
	var tick = floor((current_time + step_clock_offset_ms) / step_interval_ms)

	# Check if the current tick is greater than the previous tick
	if tick - previous_tick > 0:
		# Update the previous step time
		previous_step_time = current_time

		# Update the previous tick
		previous_tick = tick

		# Set the cast start position to the ray cast position
		var cast_start = ray_cast_position

		# Set the cast end position to the rest position
		var cast_end = rest_position

		# Use the delta from the rest position instead of
		# the previous end position to improve prediction accuracy
		var last_step_delta = rest_position - previous_position
		cast_end += step_prediction_ratio * last_step_delta

		# Ensure the cast end position is under the surface,
		# but not too deep to affect the movement prediction
		cast_end += Vector3.DOWN * 2

		# Get the result of the ray cast from the start position to the end position
		var cast_result = get_world().direct_space_state.intersect_ray(cast_start, cast_end)

		# Update the previous position
		previous_position = next_position

		# Update the next position with the cast result position or the rest position if no result
		next_position = cast_result.position if cast_result else rest_position

	# Calculate the transition ratio
	if previous_position.distance_squared_to(next_position) > step_min_distance_squared:
		var transition_ratio = min(1, (current_time - previous_step_time) / step_duration_ms)

		# Interpolate the target to the new position
		target_position = lerp(previous_position, next_position, transition_ratio)
		target_position.y += step_height - abs(lerp(-step_height, step_height, transition_ratio))

	# Solve the inverse kinematic position to the target
	inverse_kinematic_solver.iteration_count = 1
	inverse_kinematic_solver.target_position = target_position
	inverse_kinematic_solver.pole_position = get_node(pole_position_path).global_transform.origin
	inverse_kinematic_solver.pole_rotation = get_node(pole_rotation_path).global_transform.origin
	inverse_kinematic_solver.update_joint_transforms()
