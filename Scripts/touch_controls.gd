extends Control

# The default layout positions (relative to screen/canvas size)
# You will want to populate these Vector2 values with your game's default coordinates.
const DEFAULT_LAYOUT: Dictionary = {
	"left": Vector2(12, 142),
	"right": Vector2(50, 142),
	"down": Vector2(31, 108),
	"jump": Vector2(272, 142),
	"attack": Vector2(254, 108),
	"dash": Vector2(235, 108),
	"pause": Vector2(148, 4),
	"health": Vector2(223, 5),
	"power": Vector2(252, 5),
	"shield": Vector2(281, 5)
}

const SAVE_PATH = "user://touch_layout_save.cfg"

@export var customize_layout: bool = false:
	set(value):
		customize_layout = value
		_toggle_customization_mode()

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var down: TouchScreenButton = %down
@onready var left: TouchScreenButton = %left
@onready var right: TouchScreenButton = %right
@onready var attack: TouchScreenButton = %attack
@onready var dash: TouchScreenButton = %dash
@onready var jump: TouchScreenButton = %jump
@onready var pause: TouchScreenButton = %pause
@onready var health: TouchScreenButton = %health
@onready var power: TouchScreenButton = %power
@onready var shield: TouchScreenButton = %shield

# Helper array to loop through buttons easily
@onready var buttons: Array[TouchScreenButton] = [
	left, right, down, jump, attack, dash, pause, health, power, shield
]

# Track which button is currently being dragged
var _dragging_button: TouchScreenButton = null
var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Attempt to load saved layout; if it doesn't exist, load defaults
	if not load_layout():
		load_default_layout()

func _input(event: InputEvent) -> void:
	if not customize_layout:
		return

	# Handle dragging logic when customization is active
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.is_pressed():
			# Check if we clicked/touched inside any button
			for btn in buttons:
				# We use global_position to accurately detect touches across containers
				var btn_rect = Rect2(btn.global_position, btn.texture_normal.get_size() if btn.texture_normal else Vector2(64, 64))
				if btn_rect.has_point(event.position):
					_dragging_button = btn
					_drag_offset = event.position - btn.global_position
					get_viewport().set_input_as_handled()
					break
		else:
			# Released touch/click
			_dragging_button = null

	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging_button:
			# Update position based on touch movement
			_dragging_button.global_position = event.position - _drag_offset
			get_viewport().set_input_as_handled()

### Layout Management Functions ###

# Disables button functions and prepares containers for free movement
func _toggle_customization_mode() -> void:
	for btn in buttons:
		if customize_layout:
			# Disable standard action triggering
			btn.action = "" 
			# Bypass MarginContainer restrictions by switching layout modes if necessary
			btn.layout_mode = 0 # Sets it to position-based rather than container-anchored
		else:
			# Restore original action mapping names here if needed 
			# (e.g., btn.action = btn.name)
			pass
			
	if not customize_layout:
		_dragging_button = null
		save_layout() # Automatically save when toggling customization off

# Resets buttons to the hardcoded default layout
func load_default_layout() -> void:
	for btn in buttons:
		var btn_name = btn.name.to_lower()
		if DEFAULT_LAYOUT.has(btn_name):
			btn.layout_mode = 0
			btn.global_position = DEFAULT_LAYOUT[btn_name]

# Saves the current positions to the user's device storage
func save_layout() -> void:
	var config = ConfigFile.new()
	for btn in buttons:
		config.set_value("Layout", btn.name.to_lower(), btn.global_position)
	
	var err = config.save(SAVE_PATH)
	if err != OK:
		print("Failed to save layout configuration. Error code: ", err)
	else:
		print("Layout saved successfully!")

# Loads the saved positions from device storage
func load_layout() -> bool:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false # No save file found
		
	for btn in buttons:
		var btn_name = btn.name.to_lower()
		if config.has_section_key("Layout", btn_name):
			btn.layout_mode = 0
			btn.global_position = config.get_value("Layout", btn_name)
	
	print("Layout loaded successfully!")
	return true
