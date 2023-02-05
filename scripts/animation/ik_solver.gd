tool
extends Skeleton

const ESPILON = 0.01

# Number of times the code should iterate through the joints
export var iteration_count = 10

# The target position for the end of the chain
export var target_position = Vector3.ZERO

# The position of the pole
export var pole_position = Vector3.ZERO

# The rotation of the pole
export var pole_rotation = Vector3.ZERO

# A list of joints in the Skeleton
var joints = []

# A list of lengths between each joint
var joint_lengths = 0

# A list of the positions of each joint
var positions = []

# The maximum length of the chain
var max_length = 0


# Sets the list of joints, calculates joint lengths and max length
func set_joints(new_joints):  # there is ordering to joints. joints[0] is root
	joints = new_joints
	joint_lengths = []
	max_length = 0
	# Calculate the length between each joint
	for i in range(1, joints.size()):
		joint_lengths.append(
			(joints[i].global_transform.origin - joints[i - 1].global_transform.origin).length()
		)
		# Add the joint length to the maximum length
		max_length += joint_lengths[joint_lengths.size() - 1]
	positions = []
	# Set the position of each joint
	for joint in joints:
		positions.append(joint.global_transform.origin)


# Updates the positions of each joint based on target position and pole position
func update_joint_transforms():
	# If the list of joints is empty, return immediately
	if !joints or joints.size() == 0:
		return

	# Set the position of each joint based on its global transform origin
	for i in range(0, joints.size()):
		positions[i] = joints[i].global_transform.origin

	# If the target position is farther away from the root than the max length
	if (
		joints[0].global_transform.origin.distance_squared_to(target_position)
		>= max_length * max_length
	):
		# Direct the root towards the target position
		var direction = (target_position - positions[0]).normalized()
		for i in range(1, positions.size()):
			positions[i] = positions[i - 1] + direction * joint_lengths[i - 1]

	else:
		# Repeat the calculation `iteration_count` times
		for i in range(iteration_count):
			# If the end of the chain is close enough to the target position, break the loop
			if (
				positions[positions.size() - 1].distance_squared_to(target_position)
				< ESPILON * ESPILON
			):
				break

			# Backward loop to update the position of each joint
			for j in range(positions.size() - 1, 0, -1):
				if j == positions.size() - 1:
					positions[j] = target_position
				else:
					positions[j] = (
						positions[j + 1]
						+ (positions[j] - positions[j + 1]).normalized() * joint_lengths[j]
					)

			# Forward loop to update the position of each joint
			for j in range(1, positions.size()):
				positions[j] = (
					positions[j - 1]
					+ (positions[j] - positions[j - 1]).normalized() * joint_lengths[j - 1]
				)

	# Calculate and set the rotation of the middle joints based on the pole position
	for i in range(1, positions.size() - 1):
		# Get the normal of the plane between the adjacent joints
		var normal = (positions[i + 1] - positions[i - 1]).normalized()

		# Project the pole position onto the plane
		var plane = Plane(normal, positions[i - 1].dot(normal))
		var projected_pole = plane.project(pole_position)
		var projected_joint = plane.project(positions[i])

		# Calculate the angle between the projected joint and pole
		var angle = (projected_joint - positions[i - 1]).angle_to(projected_pole - positions[i - 1])
		if (
			(projected_joint - positions[i - 1]).cross(projected_pole - positions[i - 1]).dot(
				plane.normal
			)
			< 0
		):  # need signed angle
			angle = -angle
		positions[i] = (
			Quat(normal, angle).normalized() * (positions[i] - positions[i - 1])
			+ positions[i - 1]
		)

	# Set the global transform of each joint based on the calculated positions and rotations
	for i in range(0, joints.size()):
		joints[i].global_transform.origin = positions[i]
		var next_position = positions[i + 1] if i < joints.size() - 1 else target_position
		var up = pole_rotation - positions[i]  # keep up directed at pole
		if joints[i].global_translation != next_position:
			joints[i].look_at(next_position, up)
