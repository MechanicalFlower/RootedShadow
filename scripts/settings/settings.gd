extends CenterContainer


func _ready():
	GameManager.connect("game_mode_changed", self, "_on_game_mode_changed")
	hide()


func _on_game_mode_changed(new_game_mode):
	if new_game_mode == GameManager.GameMode.SETTINGS:
		for viewport in get_tree().get_nodes_in_group("viewports"):
			viewport.gui_disable_input = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		show()
	else:
		for viewport in get_tree().get_nodes_in_group("viewports"):
			viewport.gui_disable_input = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.game_mode == GameManager.GameMode.EXPLORING:
			GameManager.set_game_mode(GameManager.GameMode.SETTINGS)

		elif GameManager.game_mode == GameManager.GameMode.SETTINGS:
			GameManager.set_game_mode(GameManager.GameMode.EXPLORING)


func _on_Exit_pressed():
	get_tree().quit()


func _on_Resume_pressed():
	GameManager.set_game_mode(GameManager.GameMode.EXPLORING)
