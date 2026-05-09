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
