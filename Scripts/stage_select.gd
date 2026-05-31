extends Control

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var stage_name: Label = %StageName

# Keep track of the currently active button so we can revert it later
var active_button: TouchScreenButton = null
var current_stage: String

# Store references to your buttons
var stage_buttons: Array[TouchScreenButton] = []

# A dictionary to remember the original normal X and Y coordinates for each button
var original_regions: Dictionary = {}

# How far down the pressed state lives from the normal state
const PRESSED_OFFSET_Y: int = 96

func _ready() -> void:
	canvas_layer.hide()
	self.hide()
	
	# Grouping buttons into an array to stop copying/pasting code [cite: 2]
	stage_buttons = [
		%Stage0, %Stage1, %Stage2, %Stage3, %Stage4, 
		%Stage5, %Stage6, %Stage7, %Stage8, %Stage9
	]
	
	# An array tracking whether each stage is open from LevelCore [cite: 2]
	var stages_open = [
		LevelCore.stage0_open, LevelCore.stage1_open, LevelCore.stage2_open,
		LevelCore.stage3_open, LevelCore.stage4_open, LevelCore.stage5_open,
		LevelCore.stage6_open, LevelCore.stage7_open, LevelCore.stage8_open,
		LevelCore.stage9_open
	]
	
	# Cache the original AtlasTexture coordinates before we start modifying them
	for button in stage_buttons:
		if button and button.texture_normal is AtlasTexture:
			# Store the unique Rect2 region setup in the Godot Inspector for this button
			original_regions[button] = button.texture_normal.region

	# Set up initial visibility
	for i in range(stage_buttons.size()):
		var button = stage_buttons[i]
		if stages_open[i]:
			button.show()
		else:
			button.hide()
			
	# --- DEFAULT SELECTION ---
	# Automatically select Stage 0 by default at the start if it is open
	if LevelCore.stage0_open:
		_on_stage_0_pressed()

func _on_select_pressed() -> void:
	if current_stage != "":
		get_tree().change_scene_to_file(current_stage)

func _on_back_pressed() -> void:
	canvas_layer.hide()
	self.hide()

# --- CENTRALIZED SELECTION LOGIC ---
func _select_button_visuals(clicked_button: TouchScreenButton) -> void:
	if clicked_button == active_button:
		return # Already selected, do nothing [cite: 3]
		
	# 1. Revert the old active button back to its original normal texture coordinates
	if active_button != null and original_regions.has(active_button):
		var old_atlas = active_button.texture_normal as AtlasTexture
		if old_atlas:
			old_atlas.region = original_regions[active_button]
		
	# 2. Change the newly clicked button's texture to its normal coordinates + 96 Y
	if original_regions.has(clicked_button):
		var new_atlas = clicked_button.texture_normal as AtlasTexture
		if new_atlas:
			var base_region = original_regions[clicked_button]
			# Shift the Y position down by 96 pixels relative to its own baseline
			new_atlas.region = Rect2(base_region.position.x, base_region.position.y + PRESSED_OFFSET_Y, base_region.size.x, base_region.size.y)
	
	# 3. Save this button as our current active choice [cite: 3]
	active_button = clicked_button

# --- BUTTON SIGNALS ---

func _on_stage_0_pressed() -> void:
	_select_button_visuals(%Stage0)
	stage_name.text = "Training Lab"
	current_stage = "res://Scenes/stage_0.tscn"

func _on_stage_1_pressed() -> void:
	_select_button_visuals(%Stage1)
	stage_name.text = "Cyber City"
	current_stage = "res://Scenes/stage_1.tscn"

func _on_stage_2_pressed() -> void:
	_select_button_visuals(%Stage2)
	stage_name.text = "Stage 2 Name"

func _on_stage_3_pressed() -> void:
	_select_button_visuals(%Stage3)
	stage_name.text = "Stage 3 Name"

func _on_stage_4_pressed() -> void:
	_select_button_visuals(%Stage4)
	stage_name.text = "Stage 4 Name"

func _on_stage_5_pressed() -> void:
	_select_button_visuals(%Stage5)
	stage_name.text = "Stage 5 Name"

func _on_stage_6_pressed() -> void:
	_select_button_visuals(%Stage6)
	stage_name.text = "Stage 6 Name"

func _on_stage_7_pressed() -> void:
	_select_button_visuals(%Stage7)
	stage_name.text = "Stage 7 Name"

func _on_stage_8_pressed() -> void:
	_select_button_visuals(%Stage8)
	stage_name.text = "Stage 8 Name"

func _on_stage_9_pressed() -> void:
	_select_button_visuals(%Stage9)
	stage_name.text = "Stage 9 Name"


func select_stage():
	self.show()
	canvas_layer.show()
