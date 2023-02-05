extends Node

signal game_mode_changed(new_game_mode)

enum GameMode {
	NONE,
	EXPLORING,
	INTERACTION,
	SETTINGS,
	GAME_OVER,
	END,
}

export(GameMode) var game_mode = GameMode.EXPLORING setget set_game_mode


func set_game_mode(new_game_mode):
	# Usually game mode change is a result of user input (e.g. pressing Tab),
	# and that input shouldn't cause further game mode changes
	get_tree().set_input_as_handled()
	game_mode = new_game_mode
	emit_signal("game_mode_changed", game_mode)
