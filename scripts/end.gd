extends Node


func _on_BlueCar_interacted(_player, _item):
	GameManager.set_game_mode(GameManager.GameMode.END)
