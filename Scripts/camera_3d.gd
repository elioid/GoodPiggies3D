extends Camera3D

enum PlayerMode { INTERACT, BUILDING }
var current_mode: PlayerMode = PlayerMode.BUILDING

var move_speed: float = 2.5
var look_sensitivity: float = 0.2

@export var grid_manager: Node

@export var current_component_scene: PackedScene:
	set(value):
		current_component_scene = value
		if is_inside_tree():
			update_preview_mesh()
		 
var preview_mesh: MeshInstance3D = null

func _ready() -> void:
	if current_component_scene:
		update_preview_mesh()
		if preview_mesh:
			preview_mesh.visible = false



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= deg_to_rad(event.relative.x * look_sensitivity)
		rotation.x -= deg_to_rad(event.relative.y * look_sensitivity)
		rotation.x = clamp(rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

func _process(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	var input_dir = Vector3.ZERO
	
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.z -= 1
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.z += 1
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1
		
	if Input.is_physical_key_pressed(KEY_E):
		input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_Q):
		input_dir.y -= 1

	input_dir = input_dir.normalized()


	var movement = transform.basis * input_dir
	position += movement * move_speed * delta

func _physics_process(_delta: float) -> void:
	if current_mode != PlayerMode.BUILDING or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if preview_mesh and preview_mesh.visible:
			preview_mesh.visible = false
		return

	_handle_building_logic()
	
func _handle_building_logic() -> void:
	
	if get_viewport().gui_get_hovered_control():
		if preview_mesh: 
			preview_mesh.visible = false
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var space_state = get_world_3d().direct_space_state
	
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_dir = project_ray_normal(mouse_pos)
	var ray_end = ray_origin + ray_dir * 100.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result:
		var offset_pos = result.position + (result.normal * (grid_manager.GRID_STEP * 0.5))
		var target_grid_pos = grid_manager.world_to_grid(offset_pos)
		
		var deletion_offset = result.position - (result.normal * (grid_manager.GRID_STEP * 0.5))
		var occupied_grid_pos = grid_manager.world_to_grid(deletion_offset)
		
		preview_mesh.global_position = grid_manager.grid_to_world(target_grid_pos)
		preview_mesh.global_basis = get_rotation_y_axis()
		preview_mesh.visible = true
		
		
		if Input.is_action_just_pressed("left_click"):
			if current_component_scene and grid_manager.is_cell_empty(target_grid_pos):
				_place_component(target_grid_pos, get_rotation_y_axis())
				
		if Input.is_action_just_pressed("erase_component"):
			grid_manager.remove_component(occupied_grid_pos)
			
	else:
		var floor_plane = Plane(Vector3.UP, 0)
		var floor_intersect = floor_plane.intersects_ray(ray_origin, ray_dir)
		
		if floor_intersect != null:

			var target_grid_pos = grid_manager.world_to_grid(floor_intersect)
			target_grid_pos.y = 0
		
			preview_mesh.global_position = grid_manager.grid_to_world(target_grid_pos)
			preview_mesh.global_basis = get_rotation_y_axis()
			preview_mesh.visible = true
			
			if Input.is_action_just_pressed("left_click"):
				if current_component_scene and grid_manager.is_cell_empty(target_grid_pos):
					_place_component(target_grid_pos, get_rotation_y_axis())
		else:
			if preview_mesh:
				preview_mesh.visible = false
		
func _place_component(grid_pos: Vector3i, target_rotation: Basis) -> void:
	var new_comp = current_component_scene.instantiate()
	get_tree().current_scene.add_child(new_comp)
	new_comp.global_position = grid_manager.grid_to_world(grid_pos)
	new_comp.global_basis = target_rotation
	grid_manager.add_component(grid_pos, new_comp)

func update_preview_mesh() -> void:
	if not current_component_scene: return
	
	if preview_mesh:
		preview_mesh.queue_free()
	
	preview_mesh = MeshInstance3D.new() 
	get_tree().root.add_child.call_deferred(preview_mesh)
	
	var temp_instance = current_component_scene.instantiate()
	var all_meshes = temp_instance.find_children("*", "MeshInstance3D", true)
	
	for m in all_meshes:
		var ghost_part = m.duplicate()
		
		ghost_part.transform = m.transform
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.8, 0.2, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost_part.material_override = mat
		
		preview_mesh.add_child(ghost_part)
	
	temp_instance.queue_free()

func get_rotation_y_axis() -> Basis:
	var cam_y_rot = global_rotation.y
	var snapped_rotation = round(cam_y_rot / (PI / 2.0)) * (PI / 2.0)
	return Basis(Vector3.UP, snapped_rotation)


func _on_camera_mode_switch_toggled(toggled_on: bool) -> void:
	if toggled_on:
		current_mode = PlayerMode.BUILDING
	else:
		current_mode = PlayerMode.INTERACT
		preview_mesh.visible = false
