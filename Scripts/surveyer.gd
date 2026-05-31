extends CharacterBody2D

@export_group("Weapons & Telegraphing")
@export var bullet_scene: PackedScene 
@export var laser_charge_time: float = 0.5
@export var fire_cooldown_time: float = 1.5
@export var laser_color: Color = Color(1.5, 0.0, 0.0, 2.0) # Boosted RGB values above 1.0 for HDR glow!
@export var laser_thickness: float = 2.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var flying_component: EnemyFlyingComponent = $EnemyFlyingComponent
@onready var detection_zone: Area2D = $DetectionZone
@onready var gun: Sprite2D = $gun

var player_node: Node2D = null

# Firing Loop variables
var is_firing_sequence: bool = false
var fire_cooldown_timer: float = 0.0
var laser_line: Line2D = null

# Idle Gun Rotation variables
var idle_gun_target_angle: float = 0.5 * PI 
var idle_gun_timer: float = 0.0

func _ready() -> void:
	idle_gun_target_angle = randf_range(0.0, PI)

func _physics_process(delta: float) -> void:
	# CHANGED: Use the correct flying component tracking method
	if flying_component:
		flying_component.tick(delta, player_node as CharacterBody2D) 
	
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer -= delta
		
	if is_instance_valid(player_node):
		var target_offset_pos = player_node.global_position + Vector2(0, -8)
		var angle_to_player = gun.global_position.direction_to(target_offset_pos).angle()
		gun.global_rotation = rotate_toward(gun.global_rotation, angle_to_player, 6.0 * delta)
		
		if fire_cooldown_timer <= 0.0 and not is_firing_sequence:
			_start_laser_targeting_sequence()
	else:
		_handle_idle_gun_rotation(delta)
		
	if is_firing_sequence:
		_update_laser_beam()

func _handle_idle_gun_rotation(delta: float) -> void:
	idle_gun_timer -= delta
	if idle_gun_timer <= 0.0:
		idle_gun_timer = randf_range(1.5, 3.0)
		# CHANGED: Godot 4 uses 'TAU' instead of 'TWO_PI'
		idle_gun_target_angle = randf_range(0.0, TAU)
		
	gun.global_rotation = rotate_toward(gun.global_rotation, idle_gun_target_angle, 2.0 * delta)

func _start_laser_targeting_sequence() -> void:
	is_firing_sequence = true
	laser_line = Line2D.new()
	laser_line.width = laser_thickness
	laser_line.default_color = laser_color
	laser_line.z_index = 1
	get_tree().current_scene.add_child(laser_line)
	get_tree().create_timer(laser_charge_time).timeout.connect(_on_laser_charge_complete)

func _update_laser_beam() -> void:
	if not is_instance_valid(laser_line) or player_node == null or not is_instance_valid(player_node):
		_cleanup_laser()
		return
		
	var offset_target_pos = player_node.global_position + Vector2(0, -8)
	laser_line.points = [gun.global_position, offset_target_pos]

func _on_laser_charge_complete() -> void:
	if not is_firing_sequence:
		_cleanup_laser()
		return
		
	_cleanup_laser()
	_fire_bullet()
	
	fire_cooldown_timer = fire_cooldown_time
	is_firing_sequence = false

func _fire_bullet() -> void:
	if not bullet_scene:
		return
		
	var bullet_instance = bullet_scene.instantiate()
	bullet_instance.global_position = gun.global_position
	bullet_instance.rotation = gun.global_rotation
	get_tree().current_scene.add_child(bullet_instance)

func _cleanup_laser() -> void:
	if is_instance_valid(laser_line):
		laser_line.queue_free()
	laser_line = null

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body is Player:
		player_node = body

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body == player_node:
		player_node = null
		_cleanup_laser()
		is_firing_sequence = false
