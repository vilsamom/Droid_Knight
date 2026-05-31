class_name BossSequence extends Area2D

@export_group("Target Connections")
@export var player: CharacterBody2D
@export var boss: CharacterBody2D
@export var stage_clear_node: StageClearTrigger

@export_group("Cutscene Settings")
@export var boss_walk_speed: float = 100.0
@export var stop_distance: float = 80.0

var sequence_triggered: bool = false
var boss_walking: bool = false

func _ready() -> void:
	# Ensure the boss and stage clear triggers are completely disabled at startup
	if boss:
		boss.set_physics_process(false)
		boss.set_process(false)
	
	if stage_clear_node:
		stage_clear_node.set_process(false)
		# Defer disabling if it relies on other processing loops
		stage_clear_node.set_physics_process(false)

	# Connect the area trigger to detect the player
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body == player:
		_try_trigger_sequence()


func _on_area_entered(area: Area2D) -> void:
	# Fallback in case your player detection is area-based rather than body-based
	var parent = area.get_parent()
	if parent == player:
		_try_trigger_sequence()


func _try_trigger_sequence() -> void:
	if sequence_triggered:
		return
		
	# Check if the player is currently grounded on the floor
	if player and player.is_on_floor():
		sequence_triggered = true
		_start_sequence()


func _start_sequence() -> void:
	# 1. Freeze the player completely
	player.set_physics_process(false)
	player.set_process(false)
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	
	# If your player has an animation helper, reset it to idle here
	# e.g., player.get_node("AnimationPlayer").play("idle")

	# 2. Start the boss approach sequence
	boss_walking = true


func _physics_process(delta: float) -> void:
	if not boss_walking or not boss or not player:
		return

	# Calculate horizontal/2D distance between boss and player
	var direction = (player.global_position - boss.global_position).normalized()
	var current_distance = boss.global_position.distance_to(player.global_position)

	# Keep moving the boss until it reaches the 80px stop boundary
	if current_distance > stop_distance:
		# Simple direct movement for the cutscene override
		boss.global_position += direction * boss_walk_speed * delta
		
		# Optional: If your boss uses standard move_and_slide, uncomment below instead:
		# boss.velocity = direction * boss_walk_speed
		# boss.move_and_slide()
	else:
		# Reached the destination! Stop walking and wait 1 second
		boss_walking = false
		if "velocity" in boss:
			boss.velocity = Vector2.ZERO
			
		_finish_sequence_after_delay()


func _finish_sequence_after_delay() -> void:
	# Wait for 1 second after the walk sequence completes
	await get_tree().create_timer(1.0).timeout
	
	# 3. Reactivate the Boss AI and logic
	if boss:
		boss.set_physics_process(true)
		boss.set_process(true)
		
	# 4. Reactivate the Stage Clear Trigger node tracking
	if stage_clear_node:
		stage_clear_node.set_process(true)
		stage_clear_node.set_physics_process(true)
		# Manually force it to re-evaluate the room state immediately upon opening
		if stage_clear_node.has_method("reset_trigger"):
			stage_clear_node.reset_trigger()

	# 5. Give control back to the player
	if player:
		player.set_physics_process(true)
		player.set_process(true)
		
	print("Boss fight initiated!")
	# Disable this sequence area entirely now that it is finished
	queue_free()
