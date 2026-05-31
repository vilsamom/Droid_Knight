extends Area2D

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var charge_particle: CPUParticles2D = $ChargeParticle

func _ready() -> void:
	# Ensure particles start turned off
	charge_particle.emitting = false

## Plays charging animation with particles, then triggers the strike
func normal_attack() -> void:
	charge_particle.emitting = true
	animation_player.play("charging")
	
	# Wait for the charging animation to fully finish
	await animation_player.animation_finished
	
	charge_particle.emitting = false
	animation_player.play("attack")

## Skips charging entirely and immediately strikes
func quick_attack() -> void:
	charge_particle.emitting = false
	animation_player.play("attack")
