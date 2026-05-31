extends Area2D

@export var atk_anim: AnimationPlayer
@export var hitbox: Hitbox
var atk_cooldown := false
var charging := false
var multiplier: int = 1

@onready var sprite: Sprite2D = $Sprite2D # 
@onready var charge_particle: CPUParticles2D = $ChargeParticle

func start_attack():
	if atk_cooldown: return # 
	
	hitbox.multiplier = 1 # 
	atk_anim.play("slash") # 
	
	charge_particle.emitting = true
	get_tree().create_timer(0.25).timeout.connect(func(): charge_particle.emitting = false)
	
	await _cooldown(1.1)


func _cooldown(seconds: float):
	atk_cooldown = true # 
	await get_tree().create_timer(seconds).timeout # 
	atk_cooldown = false # 

func stop_attack():
	atk_anim.play("RESET") #
