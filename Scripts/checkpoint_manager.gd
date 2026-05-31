class_name CheckpointManager extends Node 

var last_location: Vector2 
var player: Player 
var active_checkpoint: Area2D = null

func _ready() -> void:
	# 1. Scan child checkpoints to find the designated starting one
	for child in get_children(): 
		if child is Area2D and child.has_node("RespawnPoint"): 
			if child.active and active_checkpoint == null:
				active_checkpoint = child
			elif child.active and active_checkpoint != null:
				child.active = false
				child.get_node("AnimationPlayer").play("deactivated")

	if active_checkpoint == null:
		for child in get_children():
			if child is Area2D and child.has_node("RespawnPoint"):
				active_checkpoint = child
				active_checkpoint.active = true
				active_checkpoint.get_node("AnimationPlayer").play("activated")
				break

	# 2. Grab the pre-existing Player node present in the scene tree
	player = get_parent().get_node_or_null("Player") as Player
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Player

	# 3. Determine starting location based on checkpoint or player's current position
	if active_checkpoint: 
		var respawn_marker = active_checkpoint.get_node("RespawnPoint") as Marker2D 
		last_location = respawn_marker.global_position 
	else: 
		if player:
			last_location = player.global_position 
		else:
			last_location = Vector2.ZERO 

	# 4. Position and initialize the existing player
	_setup_existing_player()

# Configures the active scene player to sync up with tracking data
func _setup_existing_player() -> void:
	if player == null: 
		push_error("CheckpointManager Error: No Player instance found in the active scene!")
		return
		
	# Move the pre-existing player to the proper start/checkpoint location
	player.global_position = last_location 
	player.last_safe_position = last_location 
	
	# CHANGED: Replaced player-only health setup with scene-wide health initialization
	_initialize_all_scene_health.call_deferred()

# Called by individual checkpoints when crossed by the player
func set_active_checkpoint(new_checkpoint: Area2D) -> void:
	if active_checkpoint and active_checkpoint != new_checkpoint:
		active_checkpoint.deactivate_checkpoint()
	
	active_checkpoint = new_checkpoint
	active_checkpoint.activate_checkpoint()
	
	var respawn_marker = active_checkpoint.get_node("RespawnPoint") as Marker2D
	last_location = respawn_marker.global_position

# CHANGED: Replaced _initialize_player_health with a clean, scene-wide reset function
func _initialize_all_scene_health() -> void:
	get_tree().call_group("health_components", "reset_health")
