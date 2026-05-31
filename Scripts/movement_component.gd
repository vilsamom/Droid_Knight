class_name MovementComponent extends Node

@export var body:CharacterBody2D
@export var sprite: AnimatedSprite2D
@export var coyote_timer: Timer
@export var jump_buffer_timer: Timer
@export var dash_timer: Timer
@export var dash_cooldown: Timer
@export var speed := 150.0
@export var accel = 800.0
@export var friction = 1000.0
@export var jump_velocity:= -400.0
@export var dash_speed := 300.0

var direction: float
var wants_jump := false
var cant_jump := false
var mid_air := false
var start_dash := false
var coyote_time_activated := false
var jump_buffered := false
var is_dashing := false
var dash_direction: float

func tick(delta: float) -> void:
	if body == null:
		return
	
	#MOVEMENT
	if is_dashing:
		body.velocity.x = dash_direction * dash_speed
	else:
		if direction:
			body.velocity.x = move_toward(body.velocity.x, direction * speed, accel * delta)
		else:
			body.velocity.x = move_toward(body.velocity.x, 0, friction * delta)
	
	#GRAVITY 
	if !body.is_on_floor(): 
		body.velocity += body.get_gravity() * delta
		mid_air = true
		if !coyote_time_activated:
			coyote_timer.start()
			coyote_time_activated = true
	else:
		mid_air = false
		if coyote_time_activated:
			coyote_time_activated = false
			coyote_timer.stop()
	
	#JUMP
	if wants_jump:
		if !coyote_timer.is_stopped() or body.is_on_floor():
			body.velocity.y = jump_velocity
			coyote_timer.stop()
			jump_buffered = false
		else:
			jump_buffered = true
			jump_buffer_timer.start()
	
	if jump_buffered and body.is_on_floor():
		body.velocity.y = jump_velocity
		jump_buffered = false
		jump_buffer_timer.stop()

	if cant_jump and body.velocity.y < jump_velocity / 3:
		body.velocity.y = jump_velocity / 3
	
	wants_jump = false
	cant_jump = false
	
	#DASH
	if start_dash and dash_cooldown.is_stopped() and !is_dashing:
		is_dashing = true
		if direction != 0:
			dash_direction = direction
		else:
			dash_direction = -1.0 if sprite.flip_h else 1.0
		
		dash_timer.start()
		dash_cooldown.start()
		
	body.move_and_slide()
	
	#FACE MOVEMENT DIRECTION
	if sprite and direction > 0:
		sprite.flip_h = false
	elif sprite and direction < 0:
		sprite.flip_h = true

func _on_jump_buffer_timer_timeout() -> void:
	jump_buffered = false

func _on_dash_timer_timeout() -> void:
	is_dashing = false
