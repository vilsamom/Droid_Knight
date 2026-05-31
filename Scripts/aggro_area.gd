extends Area2D

signal target_spotted(body)
signal target_lost

func _ready() -> void:
	# Connect internal signals to our custom logic
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# Ensure we only care about PhysicsBodies (like the Player)
	if body is CharacterBody2D:
		target_spotted.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		target_lost.emit()
