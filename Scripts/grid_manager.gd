extends Node

var grid_data: Dictionary = {}
const GRID_STEP: float = 1.0


func add_component(grid_pos: Vector3i, component: Node3D) -> bool:
	if is_cell_empty(grid_pos):
		grid_data[grid_pos] = component
		return true
	else:
		return false

func remove_component(grid_pos: Vector3i) -> void:
	if not is_cell_empty(grid_pos):
		var component = grid_data[grid_pos]
		grid_data.erase(grid_pos)
		
		if is_instance_valid(component):
			component.queue_free()
		
		
func is_cell_empty(grid_pos: Vector3i) -> bool:
	return not grid_data.has(grid_pos)

func get_component(grid_pos: Vector3i) -> Node3D:
	return grid_data.get(grid_pos, null)

func world_to_grid(world_pos: Vector3) -> Vector3i:
	var snapped_pos = world_pos.snapped(Vector3(GRID_STEP, GRID_STEP, GRID_STEP))
	var grid_x = int(round(snapped_pos.x / GRID_STEP))
	var grid_y = int(round(snapped_pos.y / GRID_STEP))
	var grid_z = int(round(snapped_pos.z / GRID_STEP))
	
	return Vector3i(grid_x, grid_y, grid_z)

func grid_to_world(grid_pos: Vector3i) -> Vector3:
	var world_x = float(grid_pos.x) * GRID_STEP
	var world_y = float(grid_pos.y) * GRID_STEP
	var world_z = float(grid_pos.z) * GRID_STEP
	
	return Vector3(world_x, world_y, world_z)


func _on_start_simulation_button_up() -> void:
	var robot = RigidBody3D.new()
	robot.name = "Robot"
	robot.mass = 10.0
	
	get_tree().current_scene.add_child(robot)

	for block in grid_data.values():
		if not is_instance_valid(block):
			continue
			
		var old_global_transform = block.global_transform	
	
		block.get_parent().remove_child(block)
		robot.add_child(block)
		
		block.global_transform = old_global_transform
		
		if block.is_in_group("wheels"):
			_disable_collisions(block)
		else:
			_transfer_collisions_to_rigidbody(block, robot)
			
		_set_owner_recursive(block, robot)
	for cable in get_tree().get_nodes_in_group("cables"):
		if not is_instance_valid(cable):
			continue
			
		var old_cable_transform = cable.global_transform
		
		cable.get_parent().remove_child(cable)
		robot.add_child(cable)
		
		cable.global_transform = old_cable_transform
		
		_set_owner_recursive(cable, robot)
		
	grid_data.clear()
	
	
	
	
func _disable_collisions(node: Node) -> void:
	if node is CollisionShape3D:
		node.set_deferred("disabled", true)
		
	for child in node.get_children():
		_disable_collisions(child)
	
func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	if node != new_owner:
		node.owner = new_owner
	
	for child in node.get_children():
		_set_owner_recursive(child, new_owner)

func _transfer_collisions_to_rigidbody(node: Node, robot: RigidBody3D) -> void:
	if node is PhysicsBody3D and node != robot:
		node.collision_layer = 0
		node.collision_mask = 0
		
	if node is CollisionShape3D:
		var dup_shape = node.duplicate()
		robot.add_child(dup_shape)
		dup_shape.global_transform = node.global_transform
		
		node.set_deferred("disabled", true)
		
	for child in node.get_children():
		_transfer_collisions_to_rigidbody(child, robot)
