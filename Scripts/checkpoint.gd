extends Area2D

@export var active := false

var manager: Node

@onready var respawn_point: Marker2D = $RespawnPoint 
@onready var animation: AnimationPlayer = $AnimationPlayer 
@onready var collision: CollisionShape2D = $CollisionShape2D 

func _ready() -> void:
	body_entered.connect(_on_body_entered) 
	
	# Safely look upward in the tree for the manager node 
	var current_node = get_parent() 
	while current_node != null: 
		if current_node.name == "CheckpointManager": 
			manager = current_node 
			break 
		current_node = current_node.get_parent() 
	
	# Set initial visual state frame without transitions at the start of the game
	if active: 
		animation.play("activated") 
	else: 
		animation.play("deactivated") 

func _on_body_entered(body: Node) -> void:
	# Only proceed if it's the player, the manager exists, and this checkpoint isn't already active
	if body is Player and manager != null and not active: 
		manager.set_active_checkpoint(self) 

# Called by the CheckpointManager to turn this checkpoint on with transition animations
func activate_checkpoint() -> void:
	active = true 
	animation.play("activating") 
	# Once the transition finishes, queue the static active frame state
	if not animation.animation_finished.is_connected(_on_animation_finished): 
		animation.animation_finished.connect(_on_animation_finished) 

# Called by the CheckpointManager to turn this checkpoint off with transition animations
func deactivate_checkpoint() -> void:
	active = false 
	animation.play("deactivating") 
	if not animation.animation_finished.is_connected(_on_animation_finished): 
		animation.animation_finished.connect(_on_animation_finished) 

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "activating": 
		animation.play("activated") # Fixed to match standard "activated" track name
	elif anim_name == "deactivating": 
		animation.play("deactivated") # Fixed to match standard "deactivated" track name
	
	# Disconnect to avoid stacking connections dynamically
	if animation.animation_finished.is_connected(_on_animation_finished): 
		animation.animation_finished.disconnect(_on_animation_finished)
