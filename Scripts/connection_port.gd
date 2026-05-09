class_name ConnectionPort
extends Area3D

signal port_connected(other_port: ConnectionPort)

signal port_disconnected(other_port: ConnectionPort)

@export var port_type: String 
@export var parent_device: Node3D 

var connected_port: ConnectionPort = null

func _ready() -> void:
	input_event.connect(_on_input_event)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		ConnectionManager.select_port(self)

func can_connect_to(other_port: ConnectionPort) -> bool:
	if connected_port != null or other_port.connected_port != null:
		return false 
	if self.parent_device == other_port.parent_device:
		return false 
	return true

func connect_with(other_port: ConnectionPort) -> void:
	self.connected_port = other_port
	other_port.connected_port = self
	
	port_connected.emit(other_port)
	other_port.port_connected.emit(self)

func disconnect_from(other_port: ConnectionPort) -> void:
	self.connected_port = null
	other_port.connected_port = null
	
	port_disconnected.emit(other_port)
	other_port.port_disconnected.emit(self)
