extends Node
class_name BossStateMachine

@export var initial_state: BossState

var current_state: BossState
var states: Dictionary = {}

func init(boss: CharacterBody2D, movement: Node, anim: AnimationPlayer) -> void:
	for child in get_children():
		if child is BossState:
			states[child.name.to_lower()] = child
			child.boss = boss
			child.movement = movement
			child.anim = anim
			child.state_machine = self
			child.setup() 
	
	if initial_state:
		change_state(initial_state.name.to_lower()) 

func process_physics(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta) 

func change_state(new_state_name: String, msg: Dictionary = {}) -> void:
	var target_state = states.get(new_state_name.to_lower()) 
	if not target_state:
		return 
		
	if current_state:
		current_state.exit() 
		
	current_state = target_state
	current_state.enter(msg)
