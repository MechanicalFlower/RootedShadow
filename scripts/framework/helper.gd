extends Spatial

export var fast_close := true

var _last_esc_time = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameManager.set_game_mode(GameManager.GameMode.EXPLORING)

	if !OS.is_debug_build():
		fast_close = false

	if fast_close:
		print("** Fast Close enabled in the 'main.gd' script **")
		print("** 'Esc' to close 'Shift + F1' to release mouse **")

	set_process_input(fast_close)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_ESCAPE:
				var now = OS.get_ticks_msec()
				if now - _last_esc_time < 200:
					get_tree().quit()  # Quits the game
				else:
					_last_esc_time = now

	if event.is_action_pressed("change_mouse_input"):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Capture mouse if clicked on the game, needed for HTML5
# Called when an InputEvent hasn't been consumed by _input() or any GUI item
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
