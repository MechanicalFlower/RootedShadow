extends CenterContainer


func _ready():
	GameManager.connect("game_mode_changed", self, "_on_game_mode_changed")


func _on_game_mode_changed(new_game_mode):
	if new_game_mode == GameManager.GameMode.GAME_OVER:
		for viewport in get_tree().get_nodes_in_group("viewports"):
			viewport.gui_disable_input = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_node("%GameOver").show()
	elif new_game_mode == GameManager.GameMode.END:
		for viewport in get_tree().get_nodes_in_group("viewports"):
			viewport.gui_disable_input = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_node("%End").show()


func _process(_delta):
	if (
		GameManager.game_mode == GameManager.GameMode.GAME_OVER
		or GameManager.game_mode == GameManager.GameMode.END
	):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_Exit_pressed():
	get_tree().quit()


func _on_Retry_pressed():
	get_tree().reload_current_scene()
