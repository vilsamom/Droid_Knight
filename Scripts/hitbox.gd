class_name Hitbox extends Area2D

# Emitted whenever this hitbox successfully damages a hurtbox
signal hit_registered(hurtbox: Hurtbox)

@export var damage: int = 1
var multiplier: int = 1

# Tracks hurtboxes that have already taken damage during this specific overlap window
var _hit_targets: Array[Hurtbox] = []

func _ready() -> void:
	# Automatically clean up targets when they exit the hitbox area
	area_exited.connect(_on_area_exited)

func _physics_process(_delta: float):
	var overlapping_areas = get_overlapping_areas() 
	
	# If the hitbox gets turned off/disabled by an animation, clear history instantly
	if overlapping_areas.is_empty() and not _hit_targets.is_empty():
		_hit_targets.clear()
		
	for area in overlapping_areas: 
		if area is Hurtbox and not _hit_targets.has(area): 
			_signal_damage(area)

func _signal_damage(hurtbox: Hurtbox):
	# Double check that the target hurtbox is active and valid
	if hurtbox.monitoring and not hurtbox.is_invincible and not hurtbox.dash_invincibility:
		_hit_targets.append(hurtbox)
		hit_registered.emit(hurtbox)
		hurtbox.deal_damage(damage * multiplier, global_position)

func _on_area_exited(area: Area2D) -> void:
	if area is Hurtbox and _hit_targets.has(area):
		_hit_targets.erase(area)

## Resets tracking manually (Can be called at the start of sword swings)
func reset_hit_history() -> void:
	_hit_targets.clear()
