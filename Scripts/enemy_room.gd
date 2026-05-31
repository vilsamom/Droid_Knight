class_name EnemyRoom extends Area2D

enum GateState { RED, GREEN }

@export_group("Gate Settings")
@export var initial_state: GateState = GateState.RED 

var current_state: GateState
var _frames_skipped: int = 0

# Track actual living enemy count explicitly
var total_enemies_inside: int = 0
# Prevent tracking duplicate connections to the same enemy
var registered_hurtboxes: Array[Area2D] = []

signal state_changed(new_state: GateState)

func _ready() -> void:
	current_state = initial_state 
	area_entered.connect(_on_area_entered) 


func _physics_process(_delta: float) -> void:
	if _frames_skipped < 3:
		_frames_skipped += 1 
		return 
		
	_evaluate_state() 


func _on_area_entered(area: Area2D) -> void:
	# Verify it's an enemy hurtbox and not a map element like a lever
	if area is Hurtbox and not area is Lever: 
		if not registered_hurtboxes.has(area):
			registered_hurtboxes.append(area)
			total_enemies_inside += 1
			
			# Listen to when this specific enemy is deleted/freed
			var enemy_body = area.get_parent()
			if enemy_body:
				enemy_body.tree_exiting.connect(func():
					total_enemies_inside = max(0, total_enemies_inside - 1)
					if registered_hurtboxes.has(area):
						registered_hurtboxes.erase(area)
				)


func _evaluate_state() -> void:
	var old_state = current_state 
	
	# If our explicit tracker counts more than 0, keep it locked
	if total_enemies_inside > 0: 
		current_state = GateState.RED 
	else:
		current_state = GateState.GREEN 
		
	if old_state != current_state: 
		state_changed.emit(current_state) 
		_update_visuals() 


func _update_visuals() -> void:
	var animation_player = get_node_or_null("AnimationPlayer")
	var light_node = get_node_or_null("PointLight2D")
	
	if current_state == GateState.RED:
		if animation_player and animation_player.has_animation("red"):
			animation_player.play("red")
		if light_node:
			light_node.color = Color("ff0011")
	else:
		if animation_player and animation_player.has_animation("green"):
			animation_player.play("green")
		if light_node:
			light_node.color = Color("00f439")
