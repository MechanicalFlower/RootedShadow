class_name Interactable
extends StaticBody

signal interacted(player, item)

export var prompt_message := "Interact"
export var prompt_action := "interact"


func get_prompt():
	var key_name = ""
	for action in InputMap.get_action_list(prompt_action):
		if action is InputEventKey:
			key_name = OS.get_scancode_string(action.physical_scancode)
	return tr(prompt_message) + "\n[" + key_name + "]"


func interact(player):
	emit_signal("interacted", player, self)
