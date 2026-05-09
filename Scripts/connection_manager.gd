extends Node

var pending_port: ConnectionPort = null

var active_cables: Dictionary = {}

func _get_connection_id(port_a: Node, port_b: Node) -> String:
	var id_a = port_a.get_instance_id()
	var id_b = port_b.get_instance_id()
	
	if id_a < id_b:
		return str(id_a) + "_" + str(id_b)
	else:
		return str(id_b) + "_" + str(id_a)

func select_port(port: ConnectionPort) -> void:
	if pending_port == null:
		pending_port = port
			
	elif pending_port == port:
		pending_port = null
		
	else:
		if pending_port.connected_port == port:
			pending_port.disconnect_from(port)
			var id = _get_connection_id(pending_port, port)
			if active_cables.has(id):
				active_cables[id].queue_free()
				active_cables.erase(id)
			
		elif pending_port.can_connect_to(port):
			pending_port.connect_with(port)
			var id = _get_connection_id(pending_port, port)
			if not active_cables.has(id):
				active_cables[id] = _draw_cable(pending_port.global_position, port.global_position)
				
		pending_port = null

func _draw_cable(pos_a: Vector3, pos_b: Vector3) -> MeshInstance3D:
	var cable = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	
	box_mesh.size = Vector3(0.01, 1.0, 0.01) 
	cable.mesh = box_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.0, 0.0) 
	
	mat.emission_enabled = true
	mat.emission = Color.RED
	mat.emission_energy_multiplier = 0.0
	
	cable.material_override = mat
	
	get_tree().current_scene.add_child(cable)
	var midpoint = (pos_a + pos_b) / 2.0
	cable.global_position = midpoint
	var direction = (pos_b - pos_a).normalized()
	var safe_up = Vector3.UP
	
	if direction.abs().is_equal_approx(Vector3.UP):
		safe_up = Vector3.RIGHT
		
	cable.look_at(pos_b, safe_up)
	
	cable.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	
	var distance = pos_a.distance_to(pos_b)
	cable.scale.y = distance
	
	return cable

func set_cable_power_state(port_a: ConnectionPort, port_b: ConnectionPort, has_voltage: bool) -> void:
	var id = _get_connection_id(port_a, port_b)
	
	if active_cables.has(id):
		var cable = active_cables[id]
		var mat = cable.material_override as StandardMaterial3D
		
		if has_voltage:
			mat.emission_energy_multiplier = 3.0
			mat.albedo_color = Color.RED
		else:
			mat.emission_energy_multiplier = 0.0
			mat.albedo_color = Color(0.3, 0.0, 0.0)
