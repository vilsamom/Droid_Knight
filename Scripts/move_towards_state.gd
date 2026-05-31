extends BossState

@export var speed: float = 100.0

func enter(_msg: Dictionary = {}) -> void:
	anim.play("walk")

func physics_update(_delta: float) -> void:
	# Fixed case consistency: looking for lowercase "player" group
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		state_machine.change_state("stand")
		return

	# Calculate horizontal direction tracking in global coordinate space
	var tracking_direction = sign(player.global_position.x - boss.global_position.x)
	
	if tracking_direction == 0:
		tracking_direction = 1 # Default forward fallback
		
	# Flip the boss visual scale safely based on real global direction layout
	if tracking_direction > 0:
		boss.scale.x = abs(boss.scale.x)
	else:
		boss.scale.x = -abs(boss.scale.x)

	# Raycast checks wall directly ahead. With scale.x inverted, the raycast automatically points the right way.
	if boss.ray_cast_side.is_colliding():
		state_machine.change_state("stand")
		return

	# Apply direct horizontal velocity matching the tracking direction
	boss.velocity.x = tracking_direction * speed
	boss.move_and_slide()

	# Melee range aggression safety check
	if boss.atk_a_aggro.has_overlapping_bodies():
		for body in boss.atk_a_aggro.get_overlapping_bodies():
			if body.is_in_group("Player"):
				state_machine.change_state("melee_attack")
				return
