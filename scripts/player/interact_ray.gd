extends RayCast

onready var prompt = $Prompt as Label


func _ready():
	GameManager.connect("game_mode_changed", self, "_on_game_mode_changed")
	add_exception(owner)
	prompt.set_text("")


func _physics_process(_delta):
	if is_colliding():
		var detected = get_collider()

		if detected is Interactable:
			prompt.set_text(detected.get_prompt())

			if Input.is_action_just_pressed(detected.prompt_action):
#				get_tree().set_input_as_handled()
				detected.interact(owner)
	else:
		prompt.set_text("")


func _on_game_mode_changed(new_game_mode):
	var is_exploring = new_game_mode == GameManager.GameMode.EXPLORING
	set_physics_process(is_exploring)
	if not is_exploring:
		prompt.set_text("")
