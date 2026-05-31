extends BossState

func enter(_msg: Dictionary = {}) -> void:
	if anim and anim.has_animation("RESET"):
		anim.play("RESET")
	if boss:
		boss.velocity = Vector2.ZERO

func physics_update(_delta: float) -> void:
	# While neutral during cutscenes, don't execute movement code
	pass
