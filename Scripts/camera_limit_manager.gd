class_name CameraLimitManager extends Node2D

@export var limit_transition_speed: float = 3.0

@onready var camera: Camera2D = get_parent()

const MAX_LIMIT = 100000

var limit_left_target: float = -MAX_LIMIT
var limit_right_target: float = MAX_LIMIT
var limit_top_target: float = -MAX_LIMIT
var limit_bottom_target: float = MAX_LIMIT

func _ready() -> void:
	# Cleaned up window bounding parameters that caused the lockup
	pass

func _physics_process(delta: float) -> void:
	camera.limit_left = calc_limit(camera.limit_left, limit_left_target)
	camera.limit_right = calc_limit(camera.limit_right, limit_right_target)
	camera.limit_top = calc_limit(camera.limit_top, limit_top_target)
	camera.limit_bottom = calc_limit(camera.limit_bottom, limit_bottom_target)

func calc_limit(current_limit: float, target_limit: float) -> float:
	if current_limit == target_limit:
		return current_limit
	return _move_limit_toward(current_limit, target_limit)

func _move_limit_toward(current: float, target: float) -> float:
	# Only snap instantly if the target itself is unassigned/infinite
	if abs(target) >= MAX_LIMIT:
		return target
		
	if current != target:
		var speed = limit_transition_speed if limit_transition_speed != null else 3.0
		# Increase the delta multiplier; move_toward needs a delta-scaled value 
		# otherwise it moves at a static 3 pixels per frame.
		return move_toward(current, target, limit_transition_speed) 
	return target

func set_limiter(limiter: CameraLimiter, instant: bool = false) -> void:
	limit_left_target = limiter.get_limit_left()
	limit_right_target = limiter.get_limit_right()
	limit_top_target = limiter.get_limit_top()
	limit_bottom_target = limiter.get_limit_bottom()
	
	if instant:
		camera.limit_left = limit_left_target
		camera.limit_right = limit_right_target
		camera.limit_top = limit_top_target
		camera.limit_bottom = limit_bottom_target
