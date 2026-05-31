class_name EnemyFlyingComponent
extends Node

@export_group("Flight Settings")
@export var max_speed: float = 100.0 
@export var acceleration: float = 150.0
@export var friction: float = 0.85 

@export_group("Sweet Spot Range")
@export var min_distance: float = 50.0 
@export var max_distance: float = 100.0 

@export_group("Idle Wander Settings")
@export var idle_wander_radius: float = 40.0 
@export var idle_wait_time: float = 2.0 

@export_group("Avoidance Settings")
@export var avoidance_force: float = 300.0 
@export var wall_bounce_back: float = 4.0 

@export_group("Knockback Settings")
@export var knockback_decay: float = 1000.0 

@export_group("RayCast Assignments")
@export var ray_left: RayCast2D
@export_group("RayCast Assignments")
@export var ray_right: RayCast2D
@export_group("RayCast Assignments")
@export var ray_up: RayCast2D
@export_group("RayCast Assignments")
@export var ray_down: RayCast2D

@export_group("Juice & Wobble")
@export var wave_frequency: float = 3.0
@export var wave_amplitude: float = 5.0 

@export_group("Required Node Assignments")
@export var parent_body: CharacterBody2D
@export_group("Required Node Assignments")
@export var sprite: AnimatedSprite2D

var current_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO

# Tracking for confined wandering
var spawn_anchor_position: Vector2 = Vector2.ZERO
var last_wander_offset: Vector2 = Vector2.ZERO

var target_idle_position: Vector2 = Vector2.ZERO
var _idle_timer: float = 0.0
var _time_passed: float = 0.0

func _ready() -> void:
	if parent_body:
		spawn_anchor_position = parent_body.global_position
		target_idle_position = spawn_anchor_position

func tick(delta: float, target_player: CharacterBody2D = null) -> void:
	_time_passed += delta
	
	# --- 1. DECAY KNOCKBACK ---
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		knockback_velocity = Vector2.ZERO
		
	var target_dir = Vector2.ZERO
	
	# --- 2. MOVEMENT VECTOR CALCULATION ---
	if is_instance_valid(target_player):
		var distance_to_player = parent_body.global_position.distance_to(target_player.global_position)
		var base_dir = parent_body.global_position.direction_to(target_player.global_position)
		
		if distance_to_player > max_distance:
			target_dir = base_dir
		elif distance_to_player < min_distance:
			target_dir = -base_dir
		else:
			# Subtly strafe within sweet spot range
			target_dir = Vector2(-base_dir.y, base_dir.x) * 0.3
			
		# Stay above player if below
		if parent_body.global_position.y > target_player.global_position.y:
			target_dir.y = -1.0
			
		if sprite:
			sprite.flip_h = (target_player.global_position.x < parent_body.global_position.x)
	else:
		# Idle Roaming behavior
		_idle_timer -= delta
		if parent_body.global_position.distance_to(target_idle_position) < 10.0 or _idle_timer <= 0:
			_generate_new_idle_spot()
		target_dir = parent_body.global_position.direction_to(target_idle_position)
	
	# --- 3. APPLY ACCELERATION & FRICTION RE-ENABLED ---
	current_velocity += target_dir * acceleration * delta
	current_velocity = current_velocity.limit_length(max_speed)
	current_velocity *= (1.0 - (friction * delta))
	
	# Hard Pseudo-Collision Wall Repel Logic
	if ray_left and ray_left.is_colliding():
		if current_velocity.x < 0: current_velocity.x = 0 
		current_velocity.x += avoidance_force * wall_bounce_back * delta 
		
	if ray_right and ray_right.is_colliding():
		if current_velocity.x > 0: current_velocity.x = 0 
		current_velocity.x -= avoidance_force * wall_bounce_back * delta 
		
	if ray_up and ray_up.is_colliding():
		if current_velocity.y < 0: current_velocity.y = 0 
		current_velocity.y += avoidance_force * wall_bounce_back * delta 
		
	if ray_down and ray_down.is_colliding():
		if current_velocity.y > 0: current_velocity.y = 0 
		current_velocity.y -= avoidance_force * wall_bounce_back * delta 

	# --- 4. PROCEDURAL FLOATING SINE BOBBING ---
	var dynamic_bobbing = Vector2(
		cos(_time_passed * wave_frequency) * wave_amplitude * 0.5,
		sin(_time_passed * wave_frequency) * wave_amplitude
	)
	
	# Combine movement forces
	var raw_final_velocity = current_velocity + knockback_velocity + (dynamic_bobbing * 60.0 * delta)
	
	# HARD CAP UPGRADE: Enforce max_speed limit on total velocity to completely prevent speed bursts
	parent_body.velocity = raw_final_velocity.limit_length(max_speed)
	parent_body.move_and_slide()

func apply_knockback(source_pos: Vector2, force: float = 240.0) -> void:
	if parent_body:
		var knock_dir = source_pos.direction_to(parent_body.global_position).normalized()
		knockback_velocity = knock_dir * force

func _generate_new_idle_spot() -> void:
	_idle_timer = idle_wait_time
	
	var next_offset = Vector2.ZERO
	
	if last_wander_offset == Vector2.ZERO:
		next_offset = Vector2(
			randf_range(-idle_wander_radius, idle_wander_radius),
			randf_range(-idle_wander_radius, idle_wander_radius)
		)
	else:
		var inverse_dir = -last_wander_offset.normalized()
		inverse_dir = inverse_dir.rotated(randf_range(-0.45, 0.45))
		
		var last_length = last_wander_offset.length()
		var inverse_length = idle_wander_radius - last_length
		inverse_length = max(inverse_length, idle_wander_radius * 0.25)
		
		next_offset = inverse_dir * inverse_length

	last_wander_offset = next_offset
	target_idle_position = spawn_anchor_position + next_offset
