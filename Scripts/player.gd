class_name Player extends CharacterBody2D

@export var upgrade_max_power := false
@export var upgrade_double_gain := false
@export var player: AnimatedSprite2D
@export var sword: Sword 
@export var atk_origin: Node2D
@export var input_component: InputComponent
@export var movement_component: MovementComponent
@export var health_component: HealthComponent
@export var hurtbox: Hurtbox
@export var charge_resource: PowerMeterResource

var is_dead := false
var is_paused_for_reset := false  
var last_safe_position: Vector2
var charge_time := 0.0
const CHARGE_THRESHOLD := 1.0
var is_fully_charged := false
var vibration_intensity := 0.0

@onready var game_over: Control = $GameOver
@onready var pause_menu: Control = $PauseMenu

func _ready() -> void:
	is_dead = false
	is_paused_for_reset = false
	
	if health_component:
		health_component.died.connect(_on_died)
		
	last_safe_position = global_position
	
	if charge_resource:
		charge_resource.large_capacity = upgrade_max_power
		charge_resource.double_gain = upgrade_double_gain
		charge_resource.update_initial_state()

func _physics_process(delta: float) -> void:
	if input_component.pause:
		pause_menu.paused()
	
	if is_dead or is_paused_for_reset:
		velocity = Vector2.ZERO 
		if movement_component:
			movement_component.direction = 0.0
			movement_component.tick(delta)
		return
	
	if input_component:
		input_component.update()
	
	_apply_movement_inputs(delta)
	
	if input_component and input_component.drop_through and is_on_floor():
		position.y += 3
	
	_handle_animations()
	_sword_orientation()
	_handle_combat(delta)

func _apply_movement_inputs(delta: float) -> void:
	if tyranny_check_components([input_component, movement_component, hurtbox]):
		return
		
	movement_component.direction = input_component.move_dir
	movement_component.wants_jump = input_component.jump_pressed
	movement_component.cant_jump = input_component.jump_released
	movement_component.start_dash = input_component.dash_pressed
	hurtbox.dash_invincibility = movement_component.is_dashing
	movement_component.tick(delta)

func _handle_combat(delta: float) -> void:
	if !sword or !input_component: 
		return

	if movement_component and movement_component.is_dashing:
		if charge_time > 0.0:
			_reset_charge()
		return

	# 1. Normal Attack Trigger
	if input_component.attack_pressed and !sword.atk_cooldown:
		sword.start_attack()
	
	# 2. Handle Charge Logic
	var can_charge = charge_resource and charge_resource.has_enough_charge_resource()
	if input_component.attack_held and !sword.atk_cooldown and can_charge:
		charge_time += delta
		
		if charge_time >= 0.15 and charge_time < CHARGE_THRESHOLD:
			vibration_intensity = 1.0
			sword.start_charging_visuals()
			
		if charge_time >= CHARGE_THRESHOLD and !is_fully_charged:
			is_fully_charged = true
			vibration_intensity = 3.0
			sword.fully_charged_visuals()
		
		if charge_time >= 0.15:
			sword.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * vibration_intensity
	else:
		# Reset sword offset if we aren't holding/charging anymore
		if sword.position != Vector2.ZERO:
			sword.position = Vector2.ZERO
	
	# 3. Release Charge Attack
	if input_component.attack_released:
		if is_fully_charged and !sword.atk_cooldown:
			if charge_resource and charge_resource.consume_charge_attack_cost():
				sword.start_charged_attack()
		_reset_charge()

func _reset_charge() -> void:
	charge_time = 0.0
	is_fully_charged = false
	vibration_intensity = 0.0
	
	if sword:
		sword.position = Vector2.ZERO
		sword.stop_charging_visuals()
	
	var ui_layer = get_tree().get_first_node_in_group("power_ui")
	if ui_layer and ui_layer.has_method("set_charge_vibration"):
		ui_layer.set_charge_vibration(0.0)

func _sword_orientation() -> void:
	if !player or !atk_origin or !sword: 
		return
	atk_origin.scale.x = -1 if player.flip_h else 1
	if movement_component:
		sword.visible = !movement_component.is_dashing

func _handle_animations() -> void:
	if !player or !movement_component: 
		return
		
	if movement_component.is_dashing:
		player.play("roll")
	elif movement_component.mid_air:
		player.play("jump")
	else:
		player.play("idle" if movement_component.direction == 0 else "walk")

func _on_died() -> void:
	if is_dead: 
		return
	is_dead = true
	_reset_charge()
	
	if player: 
		player.play("death")
	if sword: 
		sword.visible = false
		
	await get_tree().create_timer(3.0).timeout
	if game_over:
		game_over.game_over()

func respawn(spawn_position: Vector2) -> void:
	is_dead = false 
	is_paused_for_reset = false 
	global_position = spawn_position
	velocity = Vector2.ZERO 
	last_safe_position = spawn_position 
	
	# Finds every single HealthComponent in the scene and resets it to max health
	get_tree().call_group("health_components", "reset_health")
	
	# Added: Resets the power meter resource to 0 when respawning
	if charge_resource:
		charge_resource.reset_resource()
	
	_snap_camera_to_player() 
	_reset_charge()

func reset_to_fall_point(target_position: Vector2) -> void:
	if is_paused_for_reset or is_dead: 
		return
	
	is_paused_for_reset = true
	velocity = Vector2.ZERO
	_reset_charge()
	
	await get_tree().create_timer(0.2).timeout
	if is_dead: 
		return
	
	global_position = target_position 
	last_safe_position = target_position
	
	_snap_camera_to_player()
	
	if hurtbox:
		hurtbox.trigger_spawn_protection()
	
	is_paused_for_reset = false

func _snap_camera_to_player() -> void:
	var cam: Camera2D = null
	
	if has_node("Camera2D"):
		cam = get_node("Camera2D") as Camera2D
	else:
		cam = get_tree().get_first_node_in_group("main_camera") as Camera2D
		
	if cam and cam.has_method("snap_to_target"):
		var cam_area = cam.get_node_or_null("CameraArea")
		if cam_area:
			cam_area.set_deferred("monitoring", false)
			cam_area.set_deferred("monitorable", false)
		
		await cam.snap_to_target()
		
		if cam_area:
			cam_area.set_deferred("monitoring", true)
			cam_area.set_deferred("monitorable", true)

func tyranny_check_components(components: Array) -> bool:
	for comp in components:
		if comp == null: 
			return true
	return false
