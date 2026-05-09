extends TextureButton

func _on_toggled(toggled_on: bool) -> void:
	get_tree().call_group("batteries", "toggle_battery", toggled_on)
