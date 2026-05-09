extends Node3D

@export var power_input_port: ConnectionPort

@export var suspension_rest_dist: float = 2.0
@export var spring_strength: float = 250.0
@export var spring_damping: float = 25.0
@export var drive_force: float = -20.0

@onready var raycast: RayCast3D = $RayCast3D

var has_voltage: bool = false
var is_spinning: bool = false
var wheel_speed: float = 10
var is_inverted: bool = false
var robot_body: RigidBody3D = null

func _ready() -> void:
	add_to_group("wheels")
	
	if power_input_port:
		power_input_port.port_connected.connect(_on_connected)
		power_input_port.port_disconnected.connect(_on_disconnected)

func set_voltage(new_state: bool) -> void:
	has_voltage = new_state
	if has_voltage:
		is_spinning = true
	else:
		is_spinning = false

func _on_connected(other_port: ConnectionPort) -> void:
	var parent = other_port.parent_device
	if "has_voltage" in parent:
		set_voltage(parent.has_voltage)

func _on_disconnected(_other_port: ConnectionPort) -> void:
	set_voltage(false)

func _process(delta: float) -> void:
	if is_spinning:
		var direction_multiplier = -1.0 if is_inverted else 1.0
		$WheelMesh.rotate_z(wheel_speed * delta * direction_multiplier) 

func _physics_process(_delta: float) -> void:
	if robot_body == null:
		var parent = get_parent()
		if parent is RigidBody3D:
			robot_body = parent
		return

	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()
		var distance = global_position.distance_to(hit_point)
		
		var force_offset = global_position - robot_body.global_position
		
		var compression = suspension_rest_dist - distance
		var up_direction = global_basis.y 
		
		var velocity_at_point = robot_body.linear_velocity + robot_body.angular_velocity.cross(force_offset)		
		var vertical_velocity = velocity_at_point.dot(up_direction)
		
		var suspension_force = (compression * spring_strength) - (vertical_velocity * spring_damping)
		
		robot_body.apply_force(up_direction * max(0.0, suspension_force), force_offset)
		
		if is_spinning:
			var direction_multiplier = -1.0 if is_inverted else 1.0
			
			var forward_direction = hit_normal.cross(global_basis.z).normalized()
			
			var propulsion = forward_direction * drive_force * direction_multiplier
			robot_body.apply_force(propulsion, force_offset)

func _on_flip_direction_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_inverted = !is_inverted
