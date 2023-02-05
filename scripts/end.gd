extends Node


func _on_BlueCar_interacted(player, item):
	GameManager.set_game_mode(GameManager.GameMode.END)
