class_name Projectile extends Area2D

@onready var atk_anim: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var linger_time: Timer = $LingerTime

var dir: float

func _ready() -> void:
	atk_anim.play("blast")
	linger_time.start()


func _on_linger_time_timeout() -> void:
	queue_free()
