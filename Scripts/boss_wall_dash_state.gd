extends BossState

@export var dash_speed: float = 380.0
var dash_direction: float = 1.0
var keep_looping_attacks: bool = false

func enter(_msg: Dictionary = {}) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		dash_direction = sign(player.global_position.x - boss.global_position.x)
	else:
		dash_direction = 1.0 if boss.scale.x > 0 else -1.0

	if dash_direction == 0: 
		dash_direction = 1.0

	# 1. Force the boss to visually look in the direction of the dash right away
	if dash_direction > 0:
		boss.scale.x = abs(boss.scale.x)
	else:
		boss.scale.x = -abs(boss.scale.x)

	# 2. Activate the global lock so face tracking cannot change it mid-charge
	boss.is_facing_locked = true

	keep_looping_attacks = true
	_run_quick_attack_loop()

func physics_update(_delta: float) -> void:
	boss.velocity.x = dash_direction * dash_speed
	boss.move_and_slide()

	# Stop dashing and return to stand if the side raycast strikes a physical wall boundary
	boss.ray_cast_side.force_raycast_update()
	if boss.ray_cast_side.is_colliding():
		state_machine.change_state("stand")

## Chchains consecutive quick sweeps smoothly together without clipping parent speed properties
func _run_quick_attack_loop() -> void:
	while keep_looping_attacks and state_machine.current_state == self:
		if boss.axe and boss.axe.has_method("quick_attack"):
			boss.axe.quick_attack()
		
		await get_tree().create_timer(0.3).timeout

func exit() -> void:
	keep_looping_attacks = false
	# 3. Release the lock so the boss can freely look at the player again
	boss.is_facing_locked = false
