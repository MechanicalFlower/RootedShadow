class_name RootCollider

extends Area

export(NodePath) var audio_path

onready var audio_node = get_node(audio_path) as Spatial


func _ready():
	randomize()
	connect("body_entered", self, "_on_Root_body_entered")


func _on_Root_body_entered(body):
	if body.name == "Player":
		print("Player walk in root")

		# Trigger wood sound
		if audio_node.get_child_count() > 0:
			var audio = randi() % audio_node.get_child_count()
			audio_node.get_child(audio).play()

		# Find the closest Spider Tree
		var most_closest_spider_tree = null
		var most_closest_distance = -1

		for spider_tree in get_tree().get_nodes_in_group("spider_tree"):
			if most_closest_spider_tree == null:
				most_closest_spider_tree = spider_tree
				most_closest_distance = most_closest_spider_tree.global_translation.distance_to(
					global_translation
				)
			else:
				var distance = spider_tree.global_translation.distance_to(global_translation)
				if most_closest_distance > distance:
					most_closest_spider_tree = spider_tree
					most_closest_distance = distance

		assert(most_closest_spider_tree != null)

		# Change this state to chase the player
		most_closest_spider_tree.set_target_location(
			get_tree().get_nodes_in_group("player")[0].global_translation
		)
		most_closest_spider_tree.set_state(most_closest_spider_tree.States.CHASE)
