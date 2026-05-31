class_name Door extends StaticBody2D

# Export a node path to the lever so this door knows which lever to listen to
@export var target_lever: Area2D

# --- New Starting State Toggle ---
enum DoorState { CLOSED, OPEN }
@export_group("State Settings")
@export var starting_state: DoorState = DoorState.CLOSED

# Exported strings for your animation names so you can easily change them in the inspector
@export_group("Animations")
@export var open_animation: String = "open"
@export var close_animation: String = "close"

@export_group("Visual Settings")
@export var open_light_color: Color = Color("00f439")
@export var closed_light_color: Color = Color("ff0011")

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	if target_lever:
		# Connect to the lever's state_changed signal dynamically
		target_lever.state_changed.connect(_on_lever_state_changed)
		
		# Set the door's initial state based on the lever's starting position
		_match_lever_state(target_lever.current_state)
	else:
		# If no lever is attached, use the manual inspector starting_state toggle
		_match_manual_state(starting_state)


func _on_lever_state_changed(new_state: Lever.LeverState) -> void:
	_match_lever_state(new_state)


func _match_lever_state(state: Lever.LeverState) -> void:
	if state == Lever.LeverState.GREEN:
		_open_door()
	else:
		_close_door()


# New helper function to match our local starting_state enum when there is no lever
func _match_manual_state(state: DoorState) -> void:
	if state == DoorState.OPEN:
		_open_door()
	else:
		_close_door()


func _open_door() -> void:
	animation.play(open_animation) # Fixed to use the exported string variable[cite: 2]
	if light:
		light.color = open_light_color


func _close_door() -> void:
	animation.play(close_animation)
	if light:
		light.color = closed_light_color
