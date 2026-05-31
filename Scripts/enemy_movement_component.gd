class_name EnemyMovementComponent
extends Node

@export_group("Movement Settings")
@export var speed: float = 60.0
@export var knockback_decay: float = 800.0
@export var gravity_force: float = 980.0

@export_group("Required Node Assignments")
@export var parent_body: CharacterBody2D
@export var ray_cast_side: RayCast2D
@export var ray_cast_down: RayCast2D
@export var ray_cast_db: RayCast2D
@export var ray_cast_df: RayCast2D

var direction: int = 1
var knockback_velocity_x: float = 0.0
var vertical_velocity: float = 0.0

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if not parent_body: warnings.append("Parent Body must be assigned.")
	if not ray_cast_side: warnings.append("RayCastSide must be assigned.")
	if not ray_cast_down: warnings.append("RayCastDown must be assigned.")
	if not ray_cast_db: warnings.append("RayCastDB must be assigned.")
	if not ray_cast_df: warnings.append("RayCastDF must be assigned.")
	return warnings

## Process knockback reduction independently
func process_knockback(delta: float) -> void:
	if abs(knockback_velocity_x) > 0.1:
		knockback_velocity_x = move_toward(knockback_velocity_x, 0, knockback_decay * delta)

## Check if enemy is safely on solid ground
func is_grounded() -> bool:
	# Force clean frame updates to bypass physics engine translation caching
	ray_cast_db.force_raycast_update()
	ray_cast_df.force_raycast_update()
	
	return ray_cast_db.is_colliding() or ray_cast_df.is_colliding()

## Handle normal pacing back and forth with wall/cliff turning mechanics
func handle_patrol(delta: float, custom_speed: float = -1.0) -> void:
	var active_speed = speed if custom_speed < 0 else custom_speed
	
	if ray_cast_side.is_colliding() or not ray_cast_down.is_colliding():
		turn_around()
		
	parent_body.position.x += (direction * active_speed + knockback_velocity_x) * delta

## Turn around, modifying local scale carefully
func turn_around() -> void:
	direction *= -1
	parent_body.scale = Vector2(direction, 1.0) 
	
	# --- FIX: Push the enemy slightly away from the edge/wall it just hit ---
	# This prevents the raycasts from getting stuck in a collision loop on tight platforms
	parent_body.position.x += direction * 2.0
	
	# Force an immediate refresh of the raycast positions after the microscopic step
	ray_cast_side.force_raycast_update()
	ray_cast_down.force_raycast_update()

func face_target(target_pos: Vector2) -> void:
	var dir_to_target = 1 if target_pos.x > parent_body.global_position.x else -1
	if dir_to_target != direction:
		# --- FIX: Only turn towards the player if there isn't a wall or ledge in that direction ---
		
		# Force a temporary update to see what is currently ahead before turning
		ray_cast_side.force_raycast_update()
		ray_cast_down.force_raycast_update()
		
		# If the walker is already at an edge or wall in its current direction, 
		# don't allow face_target to force it to turn back into danger.
		if ray_cast_side.is_colliding() or not ray_cast_down.is_colliding():
			return
			
		# If the path is clear, it's safe to face the target
		direction = dir_to_target
		parent_body.scale = Vector2(direction, 1.0)
		
		# Refresh raycasts immediately for the new direction
		ray_cast_side.force_raycast_update()
		ray_cast_down.force_raycast_update()

## Process falling gravity behavior
func handle_fall(delta: float, forward_speed: float = 0.0) -> void:
	vertical_velocity += gravity_force * delta
	parent_body.position.y += vertical_velocity * delta
	parent_body.position.x += (forward_speed + knockback_velocity_x) * delta

## Inflict damage-based knockback directionally
func apply_knockback(source_pos: Vector2, force: float = 200.0) -> void:
	var knock_dir := 1.0 if parent_body.global_position.x > source_pos.x else -1.0
	knockback_velocity_x = knock_dir * force
