class_name PowerMeterResource extends Node

signal resource_changed(current_value: int, max_value: int)

var large_capacity: bool = false
var double_gain: bool = false

var current_resource: int = 0

func _ready() -> void:
	# Keep this clean so it doesn't try to auto-read before player assigns variables
	current_resource = 0

# Called by the player script immediately after setting upgrade properties
func update_initial_state() -> void:
	resource_changed.emit(current_resource, get_max_resource())

func get_max_resource() -> int:
	return 30 if large_capacity else 15

func get_gain_amount() -> int:
	return 2 if double_gain else 1

func gain_resource() -> void:
	var previous = current_resource
	current_resource = min(current_resource + get_gain_amount(), get_max_resource())
	
	if previous != current_resource:
		resource_changed.emit(current_resource, get_max_resource())

## Deducts 5 points from the meter. Returns true if successful.
func consume_charge_attack_cost() -> bool:
	if current_resource >= 5:
		current_resource -= 5
		resource_changed.emit(current_resource, get_max_resource())
		return true
	return false

## Checks if the player has enough power points to initiate a charge (minimum 5)
func has_enough_charge_resource() -> bool:
	return current_resource >= 5

func reset_resource() -> void:
	current_resource = 0
	resource_changed.emit(current_resource, get_max_resource())
