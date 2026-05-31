extends BossState

var target: CharacterBody2D = null

func enter(msg: Dictionary = {}) -> void:
	if msg.has("target"):
		target = msg.target
	
	if not target:
		state_machine.change_state("neutral")
		return
		
	# Pick a state systematically instead of defaulting to melee instantly
	_decide_next_action()

func _decide_next_action() -> void:
	if not target:
		state_machine.change_state("neutral")
		return
		
	# Build a collection of usable states
	var available_states: Array[String] = ["melee", "walldash", "shoot_turret"]
	
	# Only append the surveyor spawn state if it isn't waiting on its internal timer
	var spawn_state = state_machine.states.get("spawn")
	if spawn_state and spawn_state.has_method("is_on_cooldown") and not spawn_state.is_on_cooldown():
		available_states.append("spawn")
		
	var chosen_state = available_states[randi() % available_states.size()]
	state_machine.change_state(chosen_state, {"target": target})
