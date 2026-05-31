extends BossState

@export var state_cooldown_duration: float = 2.0
var cooldown_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	anim.play("idle")
	boss.velocity = Vector2.ZERO
	cooldown_timer = state_cooldown_duration

func physics_update(delta: float) -> void:
	boss.move_and_slide()
	
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	# Gun aims continuously during standby frames
	boss.aim_gun_at(player.global_position)
	
	# Countdown 2-second delay window
	if cooldown_timer > 0:
		cooldown_timer -= delta
		return 

	# --- COOLDOWN HAS FINISHED: EVALUATE TARGET DISTRIBUTION ZONE ---
	
	# Condition A: Player is inside the close range melee area -> Strike!
	if boss.atk_a_aggro.has_overlapping_bodies():
		for body in boss.atk_a_aggro.get_overlapping_bodies():
			if body.is_in_group("Player"):
				state_machine.change_state("melee_attack")
				return

	# Condition B: Outside melee range, select randomly among the 3 remaining profiles
	var active_choices = ["dash_attack", "shoot_turret", "spawn_surveyor"]
	var chosen_state = active_choices[randi() % active_choices.size()]
	
	state_machine.change_state(chosen_state)
