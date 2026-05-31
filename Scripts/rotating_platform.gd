extends StaticBody2D

# Export variables
@export var enable_vibration: bool = false
@export var disable_player_detection: bool = false

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $Sprite2D/AnimatableBody2D/DetectionArea

func _process(_delta: float) -> void:
	if enable_vibration:
		_apply_vibration()

func _on_player_entered(body: Node2D) -> void:
	# If detection is disabled, do nothing
	if disable_player_detection:
		return
		
	# Check if the body entering is the player (adjust "Player" to your character's class or name)
	if body.is_in_group("Player") or body.name == "Player":
		# Optional: Check if the player is actually landing from above
		if body.has_method("is_on_floor") and body.is_on_floor():
			animation_player.play("rotate")


func _apply_vibration() -> void:
	# Simple cosmetic vibration code (modulating sprite slightly)
	# You can replace this with your actual vibration logic
	sprite_2d.position.x = randf_range(-1.0, 1.0)


func _on_detection_area_body_entered(body: Node2D) -> void:
	_on_player_entered(body)
