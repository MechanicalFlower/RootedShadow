extends MeshInstance


onready var controller := get_parent() as SpiderTree

var initial_tranform := Transform.IDENTITY

func _ready():
	initial_tranform = transform


func _process(_delta):
	if controller.direction != Vector3.ZERO:
		transform = initial_tranform
		rotate_object_local(controller.direction, 0.1)
