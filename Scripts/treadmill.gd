extends StaticBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


@export var belt_speed: float = 100.0
@export var moving_right: bool = true:
	set(value):
		moving_right = value
		_update_belt()

func _ready() -> void:
	_update_belt()
	if !moving_right:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func _update_belt() -> void:
	var direction = 1.0 if moving_right else -1.0
	constant_linear_velocity = Vector2(belt_speed * direction, 0)
