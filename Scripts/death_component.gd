class_name DeathComponent extends Node

@export_group("Dependencies")
@export var health_component: HealthComponent
@export var character_body: CharacterBody2D
@export var animated_sprite: AnimatedSprite2D

@export_group("Settings")
@export var death_animation_name: String = "death"
@export var explosion_scene: PackedScene 
@export var linger_time: float = 2.0

var is_dead: bool = false # Guard flag to prevent double-triggering

signal dead

func _ready() -> void:
	if health_component:
		health_component.died.connect(_on_death)

func _on_death() -> void:
	if is_dead: return
	is_dead = true
	dead.emit()
	_disable_character()
	
	var can_animate = animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(death_animation_name)
	
	if can_animate:
		_play_death_sequence()
		if not animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.connect(_on_death_animation_finished)
	else:
		if animated_sprite:
			animated_sprite.visible = false
		_explode()

# Callback triggered once the death animation completes
func _on_death_animation_finished() -> void:
	if animated_sprite.animation == death_animation_name:
		if animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_death_animation_finished)
		
		# Wait 1 second after the animation ends before exploding
		get_tree().create_timer(1.0).timeout.connect(_explode)

func instant_kill() -> void:
	if is_dead: return
	is_dead = true
	
	_disable_character()
	if animated_sprite:
		animated_sprite.visible = false
	_explode()

func _disable_character() -> void:
	character_body.set_physics_process(false)
	character_body.set_process(false)
	
	# Loop through all children to find collision bodies, shapes, and hurtboxes
	for child in character_body.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
			
		# Check if the child is your Hurtbox (Area2D) and shut it down completely
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
			# Also disable any internal collision shapes inside the Area2D container
			for sub_child in child.get_children():
				if sub_child is CollisionShape2D or sub_child is CollisionPolygon2D:
					sub_child.set_deferred("disabled", true)
		
		# Safer check: only disable nodes that actually process
		if child.has_method("set_process") and child != animated_sprite:
			child.set_process(false)
			child.set_physics_process(false)

func _play_death_sequence() -> void:
	animated_sprite.play(death_animation_name)

func _explode() -> void:
	if not explosion_scene:
		character_body.queue_free()
		return
	
	var explosion = explosion_scene.instantiate()
	# Add to the level, not the character, so it stays when the character is freed
	character_body.get_parent().add_child(explosion)
	explosion.global_position = character_body.global_position
	
	# --- Particle Setup logic ---
	_apply_explosion_visuals(explosion)
	
	# MOBILE CLEANUP: Ensure the explosion removes itself
	if explosion is CPUParticles2D or explosion is GPUParticles2D:
		explosion.one_shot = true
		explosion.emitting = true
		# Automatically free the particles after their lifetime is over
		get_tree().create_timer(explosion.lifetime).timeout.connect(explosion.queue_free)
	
	character_body.queue_free()

# Helper to keep _explode clean
func _apply_explosion_visuals(explosion: Node) -> void:
	var fire_gradient = Gradient.new()
	fire_gradient.set_color(0, Color(2.0, 2.0, 2.0, 1.0)) 
	fire_gradient.add_point(0.1, Color(1, 0.9, 0.2, 1)) 
	fire_gradient.add_point(0.3, Color(0.9, 0.35, 0.05, 1)) 
	fire_gradient.add_point(0.6, Color(0.5, 0.0, 0.0, 0.8)) 
	fire_gradient.set_color(1, Color(0.1, 0.1, 0.1, 0.0)) 

	if explosion is CPUParticles2D:
		explosion.color_ramp = fire_gradient
	elif explosion is GPUParticles2D:
		var gradient_tex = GradientTexture1D.new()
		gradient_tex.gradient = fire_gradient
		if explosion.process_material is ParticleProcessMaterial:
			explosion.process_material.color_ramp = gradient_tex
	else:
		explosion.modulate = Color(1.5, 0.6, 0.2, 1.0)
