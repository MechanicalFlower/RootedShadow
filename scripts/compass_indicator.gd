extends MeshInstance

onready var parent := get_parent().get_parent().get_parent() as Spatial


func _process(delta: float):
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

	if most_closest_spider_tree != null and most_closest_distance > 20:
		var origin := parent.translation
		origin.y = 0

		var target := parent.to_local(most_closest_spider_tree.global_translation)
		target.y = 0

		var direction := origin.direction_to(target)
		var angle = direction.angle_to(Vector3.BACK)

#		if direction.length_squared() < 0.001:
#			angle = 0

		if direction.x < 0:
			angle = -angle

		rotation.y = my_lerp_angle(rotation.y, angle + PI, delta)
	else:
		rotate_object_local(Vector3.UP, 1)
		if most_closest_distance != -1 and most_closest_distance < 5:
			GameManager.set_game_mode(GameManager.GameMode.GAME_OVER)


# https://stackoverflow.com/a/68876704/9741124
func short_angle_dist(from, to):
	return wrapf(to - from, -PI, PI)


func my_lerp_angle(from, to, weight):
	return from + short_angle_dist(from, to) * weight
