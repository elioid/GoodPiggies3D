extends Node3D

@export var power_input_port: ConnectionPort
var has_voltage: bool = false
var is_spinning: bool = false
var wheel_speed: float = 10
var is_inverted: bool = false

func _ready() -> void:
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

func _on_flip_direction_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_inverted = !is_inverted
