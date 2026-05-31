extends Path2D

# --- Platform Physics Settings ---
@export_group("Platform Physics")
@export var speed: float = 100.0
@export var loop: bool = false
@export var station_wait_time: float = 1.0

# --- Lever Connection ---
@export_group("Lever Connection")
@export var target_lever: Area2D
enum PlatformState { RED, GREEN }
@export var starting_state: PlatformState = PlatformState.GREEN

# --- Internal State Tracking ---
var is_moving := true
var is_waiting := false
var forward_direction := 1
var total_length := 0.0

# --- Nodes ---
@onready var path: PathFollow2D = $PathFollow2D

func _ready() -> void:
	if curve:
		total_length = curve.get_baked_length()
	else:
		total_length = 1.0
	
	if path:
		path.loop = loop
	
	if target_lever:
		target_lever.state_changed.connect(_on_lever_state_changed)
		_match_lever_state(target_lever.current_state)
	else:
		_match_manual_state(starting_state)


func _process(delta: float) -> void:
	# Do not move if deactivated by a lever OR currently paused at a station
	if !is_moving or is_waiting:
		return

	# 1. Apply movement along the path at a strict constant speed
	var movement_step = speed * delta * forward_direction
	path.progress += movement_step

	# 2. Check boundaries to trigger the station stop
	var current_ratio = path.progress / total_length
	
	if forward_direction == 1 and current_ratio >= 0.999:
		_trigger_station_stop()
	elif forward_direction == -1 and current_ratio <= 0.001:
		_trigger_station_stop()


func _trigger_station_stop() -> void:
	# Set waiting state to pause _process movement
	is_waiting = true
	
	# Snap exactly to the boundary edge to clean up sub-pixel frame float rounding
	if forward_direction == 1:
		path.progress = total_length
	else:
		path.progress = 0.0

	# Create a scene tree timer on the fly for the pause duration
	await get_tree().create_timer(station_wait_time).timeout
	
	# After the timer finishes, handle switching and resume
	_swap_direction()
	is_waiting = false


func _swap_direction() -> void:
	if loop:
		if forward_direction == 1:
			path.progress = 0.0
		else:
			path.progress = total_length
	else:
		# Flip the direction vector cleanly
		if forward_direction == 1:
			forward_direction = -1
		else:
			forward_direction = 1


# --- State Control Functions ---

func _on_lever_state_changed(new_state) -> void:
	_match_lever_state(new_state)


func _match_lever_state(state) -> void:
	if state == 1:
		_activate_green()
	else:
		_activate_red()


func _match_manual_state(state: PlatformState) -> void:
	if state == PlatformState.GREEN:
		_activate_green()
	else:
		_activate_red()


func _activate_green() -> void:
	is_moving = true


func _activate_red() -> void:
	is_moving = false
