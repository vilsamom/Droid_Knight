extends StaticBody2D

@export_group("Timing Settings")
@export var always_on: bool = false   ## If true, the furnace fires continuously and ignores interval math
@export var fire_interval: float = 3.0 ## Total duration of one full firing cycle in seconds
@export var time_offset: float = 0.0    ## Time offset in seconds to shift this turret's firing phase

@export_group("Dependencies")
@export var animation_player: AnimationPlayer
@export var visible_enabler: VisibleOnScreenEnabler2D

var _next_fire_time: float = 0.0
var _is_first_run: bool = true

func _ready() -> void:
	visible_enabler.screen_entered.connect(_on_screen_entered)

	# Setup initial state
	if always_on:
		if animation_player and animation_player.has_animation("always_on"):
			animation_player.play("always_on")
	else:
		animation_player.play("RESET")
		_recalculate_next_fire_time()

func _physics_process(_delta: float) -> void:
	# If always_on is true, we don't want to run ANY interval math. 
	# The "always_on" animation loop handles itself, so we just exit early.
	if always_on:
		return 
	
	var current_time = _get_global_time()
	
	# Keep catching up if the game paused or experienced severe frame drops
	if current_time >= _next_fire_time:
		_fire()
		_recalculate_next_fire_time()

func _on_screen_entered() -> void:
	# If it's always on, letting the animation component loop naturally is enough.
	# We don't want to force-call _fire() here and break the "always_on" animation state.
	if always_on:
		if animation_player and not animation_player.is_playing():
			animation_player.play("always_on")
		return
		
	# Robust wake-up check for normal interval mode:
	var current_time = _get_global_time()
	
	if current_time >= _next_fire_time:
		_recalculate_next_fire_time()
		_sync_missed_animation(current_time)

func _recalculate_next_fire_time() -> void:
	var current_time = _get_global_time()
	
	# Math safely accounts for the offset shifting the time tracking backwards/forwards
	var adjusted_time = current_time - time_offset
	var current_cycle = floori(adjusted_time / fire_interval)
	
	# The absolute next timestamp this turret is allowed to fire
	_next_fire_time = ((current_cycle + 1) * fire_interval) + time_offset
	
	# If a massive lag spike occurred and the calculated time is still behind, skip to the absolute next valid cycle
	if _next_fire_time <= current_time:
		_next_fire_time += fire_interval

func _sync_missed_animation(current_time: float) -> void:
	if not animation_player or not animation_player.has_animation("fire"):
		return
		
	# Calculate how long ago the turret *should* have fired in this active cycle
	var last_fire_expected = _next_fire_time - fire_interval
	var time_elapsed_since_fire = current_time - last_fire_expected
	var anim_length = animation_player.get_animation("fire").length
	
	# If the fire animation would still be playing right now, skip directly into it!
	if time_elapsed_since_fire < anim_length:
		animation_player.play("fire")
		animation_player.seek(time_elapsed_since_fire, true)

func _get_global_time() -> float:
	# Using high-precision msec tracking converted to a float timestamp
	return Time.get_ticks_msec() / 1000.0

func _fire() -> void:
	if animation_player and animation_player.has_animation("fire"):
		animation_player.play("fire")
