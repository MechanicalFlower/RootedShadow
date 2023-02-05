extends PathFollow

export var speed: int = 20


func _process(delta):
	set_offset(get_offset() + delta * speed)
