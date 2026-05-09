extends RayCast3D # (or RayCast2D)

var offset: Vector3
var rayPos : Vector3

func _ready() -> void:
	offset = transform.basis.x * 100.0
	rayPos = transform.origin + offset


func _physics_process(delta):
	if is_colliding():
		var origin = global_transform.origin
		var collision_point = get_collision_point()
		var distance = origin.distance_to(collision_point)
		print("Distance to object: ", distance)
