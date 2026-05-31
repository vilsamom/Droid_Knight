class_name Sword extends Area2D

@export var atk_anim: AnimationPlayer 
@export var hitbox: Hitbox 
@export var particles: CPUParticles2D 
@export var wave_origin: Node2D 
@export var charge_res_component: PowerMeterResource

var atk_cooldown := false 
var multiplier: int = 1 

const WAVE_SCENE = preload("res://Scenes/wave.tscn") 

func _ready() -> void:
	if hitbox:
		hitbox.hit_registered.connect(_on_hitbox_registered)

func _on_hitbox_registered(hurtbox: Hurtbox) -> void:
	# 1. Verify we have our resource component component active
	if not charge_res_component:
		return
		
	# 2. Check if the hurtbox or its owner belongs to the "enemy" group
	if hurtbox.is_in_group("enemy") or (hurtbox.get_parent() and hurtbox.get_parent().is_in_group("enemy")):
		charge_res_component.gain_resource()

func start_attack() -> void:
	if hitbox:
		hitbox.reset_hit_history()
		hitbox.multiplier = 1
		
	if particles:
		particles.emitting = false 
		
	if atk_anim:
		atk_anim.play("slash")
		
	await _cooldown(0.25)

func start_charging_visuals() -> void:
	if !particles: 
		return
	particles.modulate = Color(0.504, 1.196, 1.755)
	particles.radial_accel_min = -200.0
	particles.radial_accel_max = -100.0
	particles.emitting = true

func fully_charged_visuals() -> void:
	if atk_anim:
		atk_anim.play("charging")
	if particles:
		particles.modulate = Color(1.713, 0.623, 0.602)
		particles.radial_accel_min = 100.0
		particles.radial_accel_max = 200.0
		particles.emitting = true

func start_charged_attack() -> void:
	if hitbox:
		hitbox.reset_hit_history()
		hitbox.multiplier = 0
		
	if particles:
		particles.emitting = false
		
	if atk_anim:
		atk_anim.play("charged_slash")
		
	shoot_wave()
	await _cooldown(0.5)
	
	if hitbox:
		hitbox.multiplier = 1

func stop_charging_visuals() -> void:
	if particles:
		particles.emitting = false
	if atk_anim && atk_anim.current_animation == "charging":
		atk_anim.play("RESET")

func shoot_wave() -> void:
	if !wave_origin or !WAVE_SCENE: 
		return
		
	var wave = WAVE_SCENE.instantiate()
	var parent_node = get_parent()
	var is_flipped = parent_node.scale.x < 0 if parent_node else false
	
	var shoot_dir = Vector2.LEFT if is_flipped else Vector2.RIGHT
	wave.direction = shoot_dir
	wave.global_position = wave_origin.global_position
	wave.scale.x = -1 if is_flipped else 1
	
	get_tree().current_scene.add_child(wave)

func _cooldown(seconds: float) -> void:
	atk_cooldown = true
	await get_tree().create_timer(seconds).timeout
	atk_cooldown = false

func stop_attack() -> void:
	if atk_anim:
		atk_anim.play("RESET")
	if particles:
		particles.emitting = false
