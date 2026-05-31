extends Camera2D

## Drag and drop the Area2D boundary node here
@export var boundary_area: Area2D
## Drag and drop the target node the camera follows (e.g., your Player)
@export var target: Node2D
## How smoothly the camera follows the player (0 = instant, higher = smoother)
@export var smooth_speed: float = 5.0

var _has_bounds: bool = false
var _bounds: Rect2

func _ready() -> void:
	if boundary_area:
		_calculate_bounds()
	else:
		push_warning("Camera2D: No boundary_area assigned.")

func _calculate_bounds() -> void:
	var collision_node = boundary_area.get_child(0)
	if collision_node is CollisionShape2D and collision_node.shape is RectangleShape2D:
		var rect_shape = collision_node.shape as RectangleShape2D
		var size = rect_shape.size
		# Get the top-left corner position in global space
		var top_left = collision_node.global_position - (size / 2)
		_bounds = Rect2(top_left, size)
		_has_bounds = true
	else:
		push_error("Camera2D: Boundary area must have a RectangleShape2D child.")

func _physics_process(delta: float) -> void:
	if not target:
		return
		
	# 1. Calculate where the camera *wants* to go (smoothly interpolating to player)
	var target_pos = target.global_position
	var new_pos = global_position.lerp(target_pos, smooth_speed * delta)
	
	# 2. If a boundary exists, restrict the position before applying it
	if _has_bounds:
		# Get half the viewport size so we account for the camera's screen edges
		var half_screen = get_viewport_rect().size / 2 / zoom
		
		# Clamp the camera position so the EDGES of the screen don't cross the area bounds
		new_pos.x = clamp(new_pos.x, _bounds.position.x + half_screen.x, _bounds.end.x - half_screen.x)
		new_pos.y = clamp(new_pos.y, _bounds.position.y + half_screen.y, _bounds.end.y - half_screen.y)
		
	# 3. Apply the final, safely restricted position
	global_position = new_pos
	
