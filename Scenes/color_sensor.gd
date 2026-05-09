extends Node3D

@onready var ray_cast: RayCast3D = $SensorModel/RayCast3D
@onready var color_indicator: MeshInstance3D = $SensorModel/ColorIndicator

func _physics_process(delta: float) -> void:
	if ray_cast.is_colliding():
		var object = ray_cast.get_collider()
		if object is MeshInstance3D:
			var material = object.get_active_material(0)
			if material is StandardMaterial3D:
				var color = material.albedo_color
				print("color detected:", color)
				update_indicator(color)
	else:
		update_indicator(Color.BLACK)

func update_indicator(color: Color) -> void:
	color_indicator.get_active_material(0).albedo_color = color
	
