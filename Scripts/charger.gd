extends CharacterBody2D 

@export var charge_speed: float = 220.0 
@export var charge_duration: float = 0.4 
@export var cooldown_duration: float = 0.5 

var target_detected := false 
var current_target: Node2D = null 

var atk_cooldown = false 
var is_preparing := false 
var is_charging := false 
var is_stunned := false          # <--- Added: Tracks if the charger is hit-wall stunned
var charge_timer: float = 0.0 
var cooldown_timer: float = 0.0 
var is_on_screen: bool = true 

@export var movement_component: EnemyMovementComponent 
	
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D 
@onready var ray_cast_side: RayCast2D = $RayCastSide 
@onready var death_component: DeathComponent = $DeathComponent 
@onready var hurtbox: Area2D = $Hurtbox 
@onready var exhaust: CPUParticles2D = $CPUParticles2D 
@onready var hitbox: Hitbox = $Hitbox 
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D 

func _ready() -> void:
	exhaust.emitting = false 
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered) 
	if animated_sprite_2d:
		animated_sprite_2d.animation_finished.connect(_on_animation_finished) 

	if visible_on_screen_notifier_2d:
		visible_on_screen_notifier_2d.screen_entered.connect(_on_screen_entered) 
		visible_on_screen_notifier_2d.screen_exited.connect(_on_screen_exited) 
		is_on_screen = visible_on_screen_notifier_2d.is_on_screen() 

func _physics_process(delta: float) -> void:
	movement_component.process_knockback(delta) 
	
	if atk_cooldown and not is_stunned:
		cooldown_timer -= delta 
		if cooldown_timer <= 0: 
			atk_cooldown = false 
	
	if is_charging:
		charge_timer -= delta 
		if charge_timer <= 0: 
			_end_charge() 
	
	if movement_component.is_grounded(): 
		movement_component.vertical_velocity = 0 
		
		if is_stunned:
			_handle_stunned_state(delta)
		elif is_charging: 
			_handle_charge(delta) 
		elif is_preparing: 
			_handle_ready_state(delta) 
		elif target_detected and current_target and not atk_cooldown: 
			_start_charge_sequence() 
		else: 
			movement_component.handle_patrol(delta) 
			if is_on_screen: animated_sprite_2d.play("walk") 
	else:
		_handle_fall(delta) 

func _start_charge_sequence() -> void:
	is_preparing = true 
	if current_target:
		movement_component.face_target(current_target.global_position) 
	if is_on_screen:
		animated_sprite_2d.play("ready") 

func _handle_ready_state(delta: float) -> void:
	position.x += movement_component.knockback_velocity_x * delta 

func _handle_stunned_state(delta: float) -> void:
	# Keep slide/knockback velocity moving during stun, but do not move forward
	position.x += movement_component.knockback_velocity_x * delta

func _handle_charge(delta: float) -> void:
	if ray_cast_side.is_colliding():
		_trigger_stun()  # <--- Changed: Call stun function instead of clean exit
		return 
		
	position.x += (movement_component.direction * charge_speed + movement_component.knockback_velocity_x) * delta 
	if is_on_screen:
		exhaust.emitting = true 
	
	hitbox.multiplier = 2 

func _trigger_stun() -> void:
	is_charging = false
	is_stunned = true
	atk_cooldown = true
	exhaust.emitting = false 
	hitbox.multiplier = 1 
	
	if is_on_screen:
		animated_sprite_2d.play("stunned") # Ensure you have a "stunned" animation configuration

func _end_charge() -> void:
	is_charging = false 
	atk_cooldown = true 
	cooldown_timer = cooldown_duration 
	exhaust.emitting = false 
	
	hitbox.multiplier = 1 
	
	var ray_cast_down = movement_component.ray_cast_down 
	if ray_cast_side.is_colliding() or not ray_cast_down.is_colliding(): 
		movement_component.turn_around() 

func _handle_fall(delta: float) -> void:
	var forward_fall_speed = 0.0 
	if is_charging: 
		if ray_cast_side.is_colliding(): 
			_trigger_stun()  # <--- Changed: Triggers stun if it charges off an edge into a wall
		else:
			forward_fall_speed = movement_component.direction * charge_speed 
			
	movement_component.handle_fall(delta, forward_fall_speed) 

func _on_animation_finished() -> void:
	if is_preparing and animated_sprite_2d.animation == "ready": 
		is_preparing = false 
		is_charging = true 
		charge_timer = charge_duration 
		if is_on_screen:
			animated_sprite_2d.play("charge") 
			
	elif is_stunned and animated_sprite_2d.animation == "stunned":
		# <--- Added: Recovery sequence once the stun animation finishes playing
		is_stunned = false
		cooldown_timer = cooldown_duration # Post-stun cooldown buffer window starts now
		movement_component.turn_around() # Safe turnaround after hitting a wall

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area is FallZone or area.is_in_group("killzone"): 
		if death_component: 
			death_component.instant_kill() 

func _on_hurtbox_received_damage(_amount: int, source_pos: Vector2) -> void:
	movement_component.apply_knockback(source_pos) 

func _on_death_component_dead() -> void:
	exhaust.emitting = false 

func _on_aggro_area_target_spotted(body: Node2D) -> void:
	target_detected = true 
	current_target = body 

func _on_aggro_area_target_lost() -> void:
	target_detected = false 
	current_target = null 

func _on_screen_entered() -> void:
	is_on_screen = true 
	if is_stunned: animated_sprite_2d.play("stunned")
	elif is_charging: animated_sprite_2d.play("charge") 
	elif is_preparing: animated_sprite_2d.play("ready") 
	else: animated_sprite_2d.play("walk") 

func _on_screen_exited() -> void:
	is_on_screen = false 
	animated_sprite_2d.stop() 
	exhaust.emitting = false
