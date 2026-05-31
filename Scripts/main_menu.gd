extends Control

@onready var stage_select: Control = $StageSelect


func _on_start_pressed() -> void:
	stage_select.select_stage()


func _on_items_pressed() -> void:
	pass # Replace with function body.


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
