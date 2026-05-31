class_name StageClearTrigger extends Node

# --- References ---
@export_group("Target Connections")
@export var enemy_room: EnemyRoom
@export var target_door: Door 

@export_group("Progression Settings")
@export_enum("None", "Stage 2", "Stage 3", "Stage 4", "Stage 5", "Stage 6", "Stage 7", "Stage 8", "Stage 9") var stage_to_unlock: int = 0

@export_group("Paths")
@export var main_menu_scene_path: String = "res://Scenes/main_menu.tscn"

@export var canvas_layer: CanvasLayer
@export var color_rect: ColorRect

var sequence_started: bool = false
var clearance_timer: SceneTreeTimer = null

func _ready() -> void:
	if color_rect:
		color_rect.color = Color(0, 0, 0, 0)
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if enemy_room:
		enemy_room.state_changed.connect(_on_enemy_room_state_changed)
		_on_enemy_room_state_changed(enemy_room.current_state)
	else:
		push_warning("StageClearTrigger: No EnemyRoom assigned!")

func _on_enemy_room_state_changed(new_state: EnemyRoom.GateState) -> void:
	if sequence_started:
		return

	if new_state == EnemyRoom.GateState.GREEN:
		_start_clearance_countdown()
	elif new_state == EnemyRoom.GateState.RED:
		_abort_clearance_countdown()

func _start_clearance_countdown() -> void:
	clearance_timer = get_tree().create_timer(1.0)
	await clearance_timer.timeout
	
	if clearance_timer != null:
		_run_stage_clear_sequence()

func _abort_clearance_countdown() -> void:
	if clearance_timer != null:
		clearance_timer = null

func _run_stage_clear_sequence() -> void:
	sequence_started = true
	_set_input_disabled(true)
	
	if target_door:
		target_door._open_door()
	
	# STEP 1: Wait exactly 2 seconds before initiating the screen fade
	await get_tree().create_timer(2.0).timeout
	
	# STEP 2: Execute non-smooth retro block fade over exactly 2.0 seconds total duration
	await _fade_to_black_stepped()
	
	# STEP 3: Wait exactly 1 second while the screen is completely pitch black
	await get_tree().create_timer(1.0).timeout
	
	# STEP 4: Unlock next stage progression and swap scenes
	_unlock_next_stage()
	get_tree().change_scene_to_file(main_menu_scene_path)

func _set_input_disabled(disabled: bool) -> void:
	set_process_input(!disabled)
	set_process_unhandled_input(!disabled)
	
	var player_node = get_tree().get_first_node_in_group("Player")
	if player_node and is_instance_valid(player_node):
		player_node.set_physics_process(!disabled)
		player_node.set_process(!disabled)

## Breaks the 2-second fade duration down into 4 discrete, retro-stepping frames
func _fade_to_black_stepped() -> void:
	if not color_rect: 
		return
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Step 1: 25% Opacity (0.5 seconds elapsed)
	color_rect.color = Color(0, 0, 0, 0.25)
	await get_tree().create_timer(0.5).timeout
	
	# Step 2: 50% Opacity (1.0 second elapsed)
	color_rect.color = Color(0, 0, 0, 0.50)
	await get_tree().create_timer(0.5).timeout
	
	# Step 3: 75% Opacity (1.5 seconds elapsed)
	color_rect.color = Color(0, 0, 0, 0.75)
	await get_tree().create_timer(0.5).timeout
	
	# Step 4: 100% Solid Pitch Black (2.0 seconds total fade duration complete)
	color_rect.color = Color(0, 0, 0, 1.0)
	await get_tree().create_timer(0.5).timeout

func _unlock_next_stage() -> void:
	if stage_to_unlock == 0:
		return
		
	var stage_variable_name: String = "stage" + str(stage_to_unlock + 1) + "_open"
		
	if has_node("/root/LevelCore"):
		var level_core = get_node("/root/LevelCore")
		if stage_variable_name in level_core:
			level_core.set(stage_variable_name, true)

func reset_trigger() -> void:
	sequence_started = false
	clearance_timer = null
	
	if color_rect:
		color_rect.color = Color(0, 0, 0, 0)
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	set_process_input(true)
	set_process_unhandled_input(true)
	
	if enemy_room:
		_on_enemy_room_state_changed(enemy_room.current_state)
