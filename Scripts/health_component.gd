class_name HealthComponent extends Node

signal health_changed(current: float, max: float)
signal died

@export var character_body: CharacterBody2D
@export var max_health := 100.0
var current_health: float
var dead := false

func _ready() -> void:
	current_health = max_health
	_emit()
	# ADDED: Register every instance of a HealthComponent to a global group
	add_to_group("health_components")

func damage(amount: float) -> void:
	# Prevent taking damage if already dead
	if dead:
		return
		
	current_health = clamp(current_health - amount, 0.0, max_health)
	_emit()
		
	if current_health <= 0.0:
		dead = true
		died.emit()

func heal(amount: float) -> void:
	# Prevent healing if dead unless explicitly revived via reset_health()
	if dead:
		return
		
	current_health = clamp(current_health + amount, 0.0, max_health)
	_emit()

func _emit() -> void:
	health_changed.emit(current_health, max_health)

func set_all_sprites_flash(should_flash: bool) -> void:
	if not character_body:
		return
	_apply_flash_recursive(character_body, should_flash)

func _apply_flash_recursive(node: Node, should_flash: bool) -> void:
	if node is CanvasItem and node.material is ShaderMaterial:
		node.set_instance_shader_parameter("flash_white", should_flash)
	
	for child in node.get_children():
		_apply_flash_recursive(child, should_flash)

func reset_health() -> void:
	dead = false
	current_health = max_health
	_emit()
