extends Camera2D

## Drag and drop your Player node here
@export var target: Node2D
## How smoothly the camera follows the player (higher = faster)
@export var smooth_speed: float = 5.0

@onready var camera_area: Area2D = $CameraArea

func _physics_process(delta: float) -> void:
	if not target:
		return
		
	# 1. Calculate where the camera wants to go smoothly
	var target_pos = target.global_position
	var next_pos = global_position.lerp(target_pos, smooth_speed * delta)
	
	# 2. Check if our detector is overlapping with any boundary areas
	var overlapping_areas = camera_area.get_overlapping_areas()
	
	for area in overlapping_areas:
		var collision_shape = area.get_child(0)
		if collision_shape is CollisionShape2D and collision_shape.shape is RectangleShape2D:
			var rect_shape = collision_shape.shape as RectangleShape2D
			var size = rect_shape.size
			var top_left = collision_shape.global_position - (size / 2)
			var zone_bounds = Rect2(top_left, size)
			
			var cam_collision = camera_area.get_child(0) as CollisionShape2D
			var cam_half_size := Vector2.ZERO
			if cam_collision and cam_collision.shape is RectangleShape2D:
				cam_half_size = (cam_collision.shape as RectangleShape2D).size / 2
				
			next_pos = _clamp_pos_outside_box(next_pos, zone_bounds, cam_half_size)

	# 3. Apply the position
	global_position = next_pos

## CALL THIS FUNCTION WHEN RESETTING THE PLAYER TO PREVENT JOLTING
func snap_to_target() -> void:
	if target:
		# Wait exactly 1 physics frame for collision matrices to clear
		await get_tree().physics_frame
		
		# Set position immediately
		global_position = target.global_position
		# Force Godot's rendering server to override any lerp smoothing variables instantly
		force_update_scroll()

func _clamp_pos_outside_box(current_pos: Vector2, box: Rect2, half_size: Vector2) -> Vector2:
	var dist_to_left = abs(current_pos.x - box.position.x)
	var dist_to_right = abs(current_pos.x - box.end.x)
	var dist_to_top = abs(current_pos.y - box.position.y)
	var dist_to_bottom = abs(current_pos.y - box.end.y)

	var min_dist = min(min(dist_to_left, dist_to_right), min(dist_to_top, dist_to_bottom))

	if min_dist == dist_to_left:
		current_pos.x = box.position.x - half_size.x
	elif min_dist == dist_to_right:
		current_pos.x = box.end.x + half_size.x
	elif min_dist == dist_to_top:
		current_pos.y = box.position.y - half_size.y
	elif min_dist == dist_to_bottom:
		current_pos.y = box.end.y + half_size.y
		
	return current_pos
