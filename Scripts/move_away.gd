extends BossState

@export var speed: float = 90.0

func enter(_msg: Dictionary = {}) -> void:
	anim.play("walk")

func physics_update(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		state_machine.change_state("stand")
		return

	# Determine where player is, then look at the boss's retreat direction (opposite)
	var player_direction = sign(player.global_position.x - boss.global_position.x)
	var retreat_direction = -player_direction
	
	if retreat_direction == 0:
		retreat_direction = -1

	# Keep boss facing towards the player visually even while backing away
	if player_direction > 0:
		boss.scale.x = abs(boss.scale.x)
	else:
		boss.scale.x = -abs(boss.scale.x)

	# Since boss faces player, the RayCast is pointing AT the player. 
	# To check the wall BEHIND the boss, we check if the wall is opposite of where the raycast points.
	# We temporarily check collision manually by manually flipping raycast query parameters:
	var original_target = boss.ray_cast_side.target_position
	if retreat_direction * boss.scale.x < 0:
		boss.ray_cast_side.target_position.x = -abs(original_target.x)
	else:
		boss.ray_cast_side.target_position.x = abs(original_target.x)
		
	boss.ray_cast_side.force_raycast_update()

	if boss.ray_cast_side.is_colliding():
		# Reset target position before moving to next state
		boss.ray_cast_side.target_position = original_target
		state_machine.change_state("dash_attack")
		return

	# Reset original raycast targets
	boss.ray_cast_side.target_position = original_target

	boss.velocity.x = retreat_direction * speed
	boss.move_and_slide()
