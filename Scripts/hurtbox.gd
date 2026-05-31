class_name Hurtbox extends Area2D 

signal received_damage(damage: int, source_pos: Vector2) 

@export var health: HealthComponent 
@export var iframe_duration: float = 0.2 
@export var knockback_force_x := 200.0 
@export var knockback_force_y := -100.0 
@export var spawn_protection_duration: float = 0.3 

var is_invincible := false 
var dash_invincibility := false 
var flicker_interval: int = 6 
var frame_count: int = 0 
var is_flashing_white := false 

func _ready() -> void:
	trigger_spawn_protection()

func _physics_process(_delta: float):
	if is_invincible and health and !health.dead: 
		frame_count += 1 
		if frame_count % flicker_interval == 0: 
			is_flashing_white = !is_flashing_white 
			_apply_sprite_flash(is_flashing_white)
	elif health:
		_reset_flash()
		frame_count = 0 

func trigger_spawn_protection() -> void:
	dash_invincibility = true
	get_tree().create_timer(spawn_protection_duration).timeout.connect(
		func(): 
			dash_invincibility = false
	)

func deal_damage(amount: int, source_pos: Vector2):
	if is_invincible or dash_invincibility or !health: 
		return 
	
	_start_iframes() 
	health.damage(amount) 
	received_damage.emit(amount, source_pos) 
	
	if health.character_body:
		_apply_knockback(source_pos)

func deal_instant_damage(amount: int): 
	if !health: return 
	
	health.damage(amount) 
	received_damage.emit(amount, global_position) 
	
	_start_iframes() 

func _start_iframes(): 
	is_invincible = true 
	get_tree().create_timer(iframe_duration).timeout.connect(_on_iframe_timeout) 

func _on_iframe_timeout(): 
	is_invincible = false 
	_reset_flash() 

# Iterates through the sprites via your health component structure and forces over-saturated white
func _apply_sprite_flash(flash_on: bool):
	if not health:
		return
		
	# Over-saturating the RGB values forces the texture to render solid white on mobile
	var flash_color = Color(10.0, 10.0, 10.0, 1.0) if flash_on else Color(1.0, 1.0, 1.0, 1.0)
	
	# Assuming your HealthComponent holds a reference to the main sprite(s)
	if health.character_body:
		for child in health.character_body.get_children():
			if child is Sprite2D or child is AnimatedSprite2D:
				child.modulate = flash_color

func _reset_flash():
	_apply_sprite_flash(false)
	is_flashing_white = false 

func _apply_knockback(source_pos: Vector2):
	var body = health.character_body
	if not body:
		return

	# 1. Check if it's the Flying Surveyor Enemy
	if body.has_node("EnemyFlyingComponent"):
		var flying_comp = body.get_node("EnemyFlyingComponent")
		flying_comp.apply_knockback(source_pos)
		return 

	# 2. Check if it's the Ground Walker Enemy
	if body.has_node("EnemyMovementComponent"):
		return 

	# 3. Fallback: Apply default knockback rules ONLY if it's the Player
	var x_direction := 1.0 if body.global_position.x > source_pos.x else -1.0 
	var final_knockback = Vector2(x_direction * knockback_force_x, knockback_force_y) 
	body.velocity = final_knockback
