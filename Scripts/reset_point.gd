class_name ResetPoint extends Area2D

@export var active := false

@onready var respawn_point: Marker2D = $RespawnPoint

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if active:
		_set_active_state(true)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not active:
		# Enforce a true single-active point paradigm by updating active collections
		var old_points = get_tree().get_nodes_in_group("active_reset_point")
		for point in old_points:
			if point != self and point.has_method("_set_active_state"):
				point._set_active_state(false)
		
		_set_active_state(true)

func _set_active_state(is_active: bool) -> void:
	active = is_active
	if active:
		add_to_group("active_reset_point")
	else:
		if is_in_group("active_reset_point"):
			remove_from_group("active_reset_point")

func get_respawn_position() -> Vector2:
	if respawn_point:
		return respawn_point.global_position
	return global_position
