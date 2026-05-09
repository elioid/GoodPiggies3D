extends Node3D

@export var power_output_port: ConnectionPort
var has_voltage: bool = false

func _ready() -> void:
	add_to_group("batteries")
	if power_output_port:
		power_output_port.port_connected.connect(_on_port_connected)

func toggle_battery(is_on: bool) -> void:
	has_voltage = is_on
	
	if power_output_port and power_output_port.connected_port:
		ConnectionManager.set_cable_power_state(power_output_port, power_output_port.connected_port, has_voltage)
		var downstream_device = power_output_port.connected_port.parent_device
		if downstream_device.has_method("set_voltage"):
			downstream_device.set_voltage(has_voltage)

func _on_port_connected(other_port: ConnectionPort) -> void:
	if has_voltage:
		await get_tree().process_frame 
		ConnectionManager.set_cable_power_state(power_output_port, other_port, true)
			
		var downstream_device = other_port.parent_device
		if downstream_device and downstream_device.has_method("set_voltage"):
			downstream_device.set_voltage(true)
