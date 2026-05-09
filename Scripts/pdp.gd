extends Node3D

@export var power_input_port: ConnectionPort 
@export var power_output_ports: Array[ConnectionPort]

var has_voltage: bool = false

func _ready() -> void:
	if power_input_port:
		power_input_port.port_connected.connect(_on_power_in_connected)
		power_input_port.port_disconnected.connect(_on_power_in_disconnected)

	
	for port in power_output_ports:
		if port:
			port.port_connected.connect(_on_power_out_connected.bind(port))

func set_voltage(new_state: bool) -> void:
	has_voltage = new_state
	
	for i in range(power_output_ports.size()):
		var port = power_output_ports[i]
		
		if port == null:
			continue 
			
		if port.connected_port:
			ConnectionManager.set_cable_power_state(port, port.connected_port, has_voltage)
			var downstream_device = port.connected_port.parent_device
			
			if downstream_device:
				
				if downstream_device.has_method("set_voltage"):
					downstream_device.set_voltage(has_voltage)

func _on_power_in_connected(other_port: ConnectionPort) -> void:
	var parent = other_port.parent_device
	if "has_voltage" in parent:
		set_voltage.call_deferred(parent.has_voltage)

func _on_power_in_disconnected(_other_port: ConnectionPort) -> void:
	set_voltage(false)
	
func _on_power_out_connected(other_port: ConnectionPort, my_port: ConnectionPort) -> void:
	if has_voltage:
		ConnectionManager.set_cable_power_state.call_deferred(my_port, other_port, true)
