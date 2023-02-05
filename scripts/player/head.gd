class_name PlayerHead

extends Spatial

export(NodePath) var cam_path := NodePath("Camera")

export var y_limit := 90.0

var mouse_axis := Vector2.ZERO
var rot := Vector3.ZERO

onready var cam: Camera = get_node(cam_path)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	y_limit = deg2rad(y_limit)


# Called when there is an input event
func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_axis = event.relative
		camera_rotation()


# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	var joystick_axis := Input.get_vector("lookleft", "lookright", "lookdown", "lookup")
	if joystick_axis != Vector2.ZERO:
		mouse_axis = joystick_axis * 1000.0 * delta
		camera_rotation()


func camera_rotation() -> void:
	var mouse_sensitivity = SettingsManager.get_value("controls", "mouse_sensitivity")

	# Horizontal mouse look.
	rot.y -= mouse_axis.x * (mouse_sensitivity / 100)
	rot.y = fmod(rot.y, deg2rad(360))

	# Vertical mouse look.
	rot.x = clamp(rot.x - mouse_axis.y * (mouse_sensitivity / 100), -y_limit, y_limit)

	get_owner().rotation.y = rot.y

	rotation.x = rot.x


func set_rot(new_rot: Vector3):
	rot = new_rot
	get_owner().rotation.y = rot.y
	rotation.x = rot.x
