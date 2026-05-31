extends CharacterBody2D

@export_group("Timing Settings")
@export var fire_interval: float = 3.0  ## Total duration of one full firing cycle in seconds
@export var time_offset: float = 0.0    ## Time offset in seconds to shift this turret's firing phase

@export_group("Dependencies")
@export var animation_player: AnimationPlayer
@export var visible_enabler: VisibleOnScreenEnabler2D

var _next_fire_time: float = 0.0
var _is_first_run: bool = true

@export var flip_direction := false
@export var arrow_scene: PackedScene
@export var shake_intensity: float = 2.0

# References to your sprites
@export var turret_sprite: Sprite2D
@export var blast_sprite: Sprite2D
@export var fire_point: Node2D
@export var charge_particles: CPUParticles2D
@export var explosion: CPUParticles2D

# States
@export var charging: bool = false
@export var fire: bool = false
@export var recoil: bool = false

func _process(_delta):
	if flip_direction:
		scale.x = -1
	else:
		scale.x = 1
		
	# Handle Charging (Blast Sprite shakes in all directions)
	if charging:
		charge_particles.emitting = true
		blast_sprite.position = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		charge_particles.emitting = false
		blast_sprite.position = Vector2.ZERO

	# Handle Firing
	if fire:
		shoot_arrow()
		fire = false # Reset fire state immediately

	# Handle Recoil (Turret Sprite shakes horizontally)
	if recoil:
		explosion.emitting = true
		turret_sprite.position.x = randf_range(-shake_intensity * 2, shake_intensity * 2)
	else:
		explosion.emitting = false
		turret_sprite.position.x = 0
	
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
		
	if not visible_enabler:
		visible_enabler = get_node_or_null("VisibleOnScreenEnabler2D")

	# Establish our absolute timeline position immediately
	_recalculate_next_fire_time()

func _physics_process(_delta: float) -> void:
	var current_time = _get_global_time()
	
	# Keep catching up if the game paused or experienced severe frame drops
	if current_time >= _next_fire_time:
		_fire()
		_recalculate_next_fire_time()

func _on_screen_entered() -> void:
	# Robust wake-up check: Figure out where the global clock is right now
	var current_time = _get_global_time()
	
	# If our recorded next fire time is in the past, we missed it while off-screen.
	# Recalculate cleanly so we don't fire an accidental "double shot" or instant bullet.
	if current_time >= _next_fire_time:
		_recalculate_next_fire_time()
		
		# Optional: If you want to catch a fire animation halfway through its timeline
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

func shoot_arrow():
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		# Add arrow to the main world so it doesn't move with the turret
		get_tree().current_scene.add_child(arrow)
		
		# Set position and direction
		arrow.global_position = fire_point.global_position
		if flip_direction:
			arrow.direction = Vector2.LEFT
			arrow.scale.x = -1 # Flip the arrow sprite to face left
		else:
			arrow.direction = Vector2.RIGHT
			arrow.scale.x = 1
