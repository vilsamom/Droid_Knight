extends Control

var checkpoint_manager: Node
var player: Player

@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	canvas_layer.hide() 
	self.hide()
	player = get_parent() as Player 
	checkpoint_manager = get_tree().current_scene.get_node_or_null("CheckpointManager") 

func _on_respawn_pressed() -> void:
	if checkpoint_manager and checkpoint_manager.last_location != null: 
		var stage_trigger = get_tree().current_scene.find_child("*StageClearTrigger*", true, false) as StageClearTrigger
		if stage_trigger:
			stage_trigger.reset_trigger()

		get_tree().paused = false 
		canvas_layer.hide() 
		self.hide()
		
		if is_instance_valid(player):
			player.respawn(checkpoint_manager.last_location)

func _on_restart_pressed() -> void:
	get_tree().paused = false 
	get_tree().reload_current_scene()

func _on_items_pressed() -> void:
	pass

func _on_settings_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func game_over():
	get_tree().paused = true 
	self.show()
	canvas_layer.show()
