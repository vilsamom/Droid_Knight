extends Area2D

@export var explosion: CPUParticles2D
@export var speed: float = 300.0

var direction: Vector2 = Vector2.RIGHT

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if sprite:
		sprite.play("default")
	if explosion:
		explosion.modulate = Color(0.847, 1.713, 1.664)
	
	# Compute a precise 2D direction vector based directly on the spawn point's rotation
	direction = Vector2.RIGHT.rotated(rotation)

func _physics_process(delta: float) -> void:
	# Translate across both axes simultaneously over time
	position += direction * speed * delta
	
	# Check for overlapping static terrain elements (Terrain, TileMaps, StaticBodies)
	var bodies = get_overlapping_bodies()
	if bodies.size() > 0:
		explode()
		return
	
	# Check for overlapping hitboxes/hurtboxes
	var areas = get_overlapping_areas()
	for area in areas:
		# 1. Check if we hit the player's attacking weapon (Hitbox / Sword)
		if area.name.to_lower().contains("sword") or area.get_class() == "Hitbox" or area is Hitbox:
			# If it's a player strike, let the weapon attack destroy the projectile!
			explode()
			return
			
		# Ignore other bullet projectiles
		if area.name.to_lower().contains("bullet"):
			continue
			
		# 2. Only explode on characters if we hit a genuine damage receiver (a Hurtbox)
		if area.get_class() == "Hurtbox" or area.name.to_lower().contains("hurtbox"):
			explode()
			return

func explode() -> void:
	if explosion:
		# Reparent to the main scene so it stays alive after the bullet is freed
		var main_scene = get_tree().current_scene
		explosion.reparent(main_scene)
		
		# Start the particles
		explosion.emitting = true
		
		# Auto-delete the particles after they finish
		var duration = explosion.lifetime + explosion.explosiveness
		get_tree().create_timer(duration).timeout.connect(explosion.queue_free)
	
	# Delete the bullet immediately
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	await get_tree().create_timer(1.0).timeout
	queue_free()
