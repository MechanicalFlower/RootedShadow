class_name MovementController

extends KinematicBody

export var gravity_multiplier := 3.0
export var speed := 10
export var acceleration := 8
export var deceleration := 10
export(float, 0.0, 1.0, 0.05) var air_control := 0.3
export var jump_height := 10

var direction := Vector3.ZERO
var input_axis := Vector2.ZERO
var velocity := Vector3.ZERO
var snap := Vector3.ZERO

onready var floor_max_angle: float = deg2rad(45.0)

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier


func _ready():
	GameManager.connect("game_mode_changed", self, "_on_game_mode_changed")


# Called every physics tick. 'delta' is constant
func _physics_process(delta) -> void:
	input_axis = Input.get_vector("move_back", "move_forward", "move_left", "move_right")

	direction_input()

	if is_on_floor():
		snap = -get_floor_normal() - get_floor_velocity() * delta

		# Workaround for sliding down after jump on slope
		if velocity.y < 0:
			velocity.y = 0

		if Input.is_action_just_pressed("jump"):
			snap = Vector3.ZERO
			velocity.y = jump_height
	else:
		# Workaround for 'vertical bump' when going off platform
		if snap != Vector3.ZERO && velocity.y != 0:
			velocity.y = 0

		snap = Vector3.ZERO

		velocity.y -= gravity * delta

	accelerate(delta)

	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, floor_max_angle)


func direction_input() -> void:
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if input_axis.x >= 0.5:
		direction -= aim.z
	if input_axis.x <= -0.5:
		direction += aim.z
	if input_axis.y <= -0.5:
		direction -= aim.x
	if input_axis.y >= 0.5:
		direction += aim.x
	direction.y = 0
	direction = direction.normalized()


func get_accel() -> float:
	var temp_vel := velocity
	temp_vel.y = 0

	var temp_accel: float
	if direction.dot(temp_vel) > 0:
		temp_accel = acceleration
	else:
		temp_accel = deceleration

	if not is_on_floor():
		temp_accel *= air_control

	return temp_accel


func accelerate(delta: float) -> void:
	# Using only the horizontal velocity, interpolate towards the input.
	var temp_vel := velocity
	temp_vel.y = 0

	var temp_accel := get_accel()
	var target: Vector3 = direction * speed

	temp_vel = temp_vel.linear_interpolate(target, temp_accel * delta)

	velocity.x = temp_vel.x
	velocity.z = temp_vel.z


func _on_game_mode_changed(new_game_mode):
	var is_exploring = new_game_mode == GameManager.GameMode.EXPLORING
	set_physics_process(is_exploring)
