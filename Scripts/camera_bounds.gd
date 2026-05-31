extends Area2D

var zone_bounds: Rect2
var colliding_camera_area: Area2D = null

func _ready() -> void:
	_calculate_zone_bounds()
	
	# Godot 4 built-in signals for area/shape overlaps
	area_shape_entered.connect(_on_area_shape_entered)
	area_shape_exited.connect(_on_area_shape_exited)

func _calculate_zone_bounds() -> void:
	var collision_node = get_child(0)
	if collision_node is CollisionShape2D and collision_node.shape is RectangleShape2D:
		var rect_shape = collision_node.shape as RectangleShape2D
		var size = rect_shape.size
		var top_left = collision_node.global_position - (size / 2)
		zone_bounds = Rect2(top_left, size)
	else:
		push_error("CameraBoundArea: Must have a CollisionShape2D with a RectangleShape2D.")

func _physics_process(_delta: float) -> void:
	# If a camera area is actively colliding with us, keep pushing it back
	if colliding_camera_area and is_instance_valid(colliding_camera_area):
		_prevent_overlap(colliding_camera_area)

func _prevent_overlap(camera_area: Area2D) -> void:
	var camera = camera_area.get_parent() as Camera2D
	if not camera:
		return

	# Get the size of the camera's detector shape
	var cam_collision = camera_area.get_child(0) as CollisionShape2D
	var cam_half_size := Vector2.ZERO
	
	if cam_collision and cam_collision.shape is RectangleShape2D:
		cam_half_size = (cam_collision.shape as RectangleShape2D).size / 2
	elif cam_collision and cam_collision.shape is CircleShape2D:
		var radius = (cam_collision.shape as CircleShape2D).radius
		cam_half_size = Vector2(radius, radius)

	var current_pos = camera_area.global_position

	# Determine which edge of this boundary box the camera is touching
	var dist_to_left = abs(current_pos.x - zone_bounds.position.x)
	var dist_to_right = abs(current_pos.x - zone_bounds.end.x)
	var dist_to_top = abs(current_pos.y - zone_bounds.position.y)
	var dist_to_bottom = abs(current_pos.y - zone_bounds.end.y)

	var min_dist = min(min(dist_to_left, dist_to_right), min(dist_to_top, dist_to_bottom))

	# Instantly snap the camera back outside the border
	if min_dist == dist_to_left:
		camera.global_position.x = zone_bounds.position.x - cam_half_size.x
	elif min_dist == dist_to_right:
		camera.global_position.x = zone_bounds.end.x + cam_half_size.x
	elif min_dist == dist_to_top:
		camera.global_position.y = zone_bounds.position.y - cam_half_size.y
	elif min_dist == dist_to_bottom:
		camera.global_position.y = zone_bounds.end.y + cam_half_size.y

# Triggers when the camera first makes contact
func _on_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	colliding_camera_area = area

# Triggers when the camera completely leaves the boundary
func _on_area_shape_exited(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if colliding_camera_area == area:
		colliding_camera_area = null
