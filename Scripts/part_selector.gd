extends HBoxContainer

@export var battery_scene: PackedScene
@export var pdp_scene: PackedScene
@export var box_scene: PackedScene
@export var rotational_motor_scene: PackedScene
@export var piggy_scene: PackedScene

@export var builder_camera: Camera3D

func _ready() -> void:
	$BatteryButton.pressed.connect(_on_part_selected.bind(battery_scene))
	$PDPButton.pressed.connect(_on_part_selected.bind(pdp_scene))
	$BoxButton.pressed.connect(_on_part_selected.bind(box_scene))
	$WheelButton.pressed.connect(_on_part_selected.bind(rotational_motor_scene))
	$PiggyButton.pressed.connect(_on_part_selected.bind(piggy_scene))

func _on_part_selected(selected_scene: PackedScene) -> void:
	if builder_camera:
		builder_camera.current_component_scene = selected_scene
