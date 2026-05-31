extends Area2D

@export var explosion: CPUParticles2D
@export var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	sprite.play("default")
	if explosion:
		explosion.modulate = Color(0.847, 1.713, 1.664)

func _physics_process(delta: float):
	position += direction * speed * delta
	
	# Check for overlapping physics bodies (Terrain, TileMaps, StaticBodies)
	var bodies = get_overlapping_bodies()
	if bodies.size() > 0:
		explode()
	
	# Also check for overlapping areas (other hitboxes) if needed
	var areas = get_overlapping_areas()
	if areas.size() > 0:
		explode()

func explode():
	if explosion:
		# Reparent to the main scene so it stays alive after the arrow is freed
		var main_scene = get_tree().current_scene
		explosion.reparent(main_scene)
		
		# Start the particles
		explosion.emitting = true
		
		# Optional: Auto-delete the particles after they finish
		var duration = explosion.lifetime + explosion.explosiveness
		get_tree().create_timer(duration).timeout.connect(explosion.queue_free)
	
	# Delete the arrow immediately
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	await get_tree().create_timer(1.0).timeout
	queue_free()
