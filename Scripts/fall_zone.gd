class_name FallZone extends Area2D

@export var spike_damage: int = 10

func _ready() -> void:
	add_to_group("killzone")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# 1. Damage player instantly upon impact
		if body.hurtbox:
			body.hurtbox.deal_instant_damage(spike_damage)
		
		# 2. Grab the currently active reset node from group architecture
		var reset_nodes = get_tree().get_nodes_in_group("active_reset_point")
		
		if reset_nodes.size() > 0 and reset_nodes[0].has_method("get_respawn_position"):
			var target_point = reset_nodes[0]
			body.reset_to_fall_point(target_point.get_respawn_position())
		else:
			# Fallback to the player's room initialization point if no ResetPoint was hit yet
			body.reset_to_fall_point(body.last_safe_position)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox: 
		var enemy = area.get_parent() 
		var death_comp = enemy.get_node_or_null("DeathComponent") 
		if death_comp and death_comp.has_method("instant_kill"): 
			death_comp.instant_kill()
