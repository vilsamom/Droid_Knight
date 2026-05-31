class_name Lever extends Hurtbox

enum LeverState { RED, GREEN }

@export_group("Lever Settings")
@export var initial_state: LeverState = LeverState.RED
@export var is_one_time_use: bool = true

@export_group("Visual Settings")
@export var red_light_color: Color = Color("ff0011")
@export var green_light_color: Color = Color("00f439")

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var light: PointLight2D = $PointLight2D

var cooldown_time: float = 0.3
var current_state: LeverState
var is_used: bool = false
var is_on_cooldown: bool = false

signal state_changed(new_state: LeverState)
signal lever_activated()

func _ready() -> void:
	current_state = initial_state
	_update_visuals()


func deal_damage(amount: int, hit_position: Vector2) -> void:
	# Ignore hits if it's single-use and already done, or if it's cooling down
	if (is_one_time_use and is_used) or is_on_cooldown:
		return
		
	_toggle_state()


func _toggle_state() -> void:
	if current_state == LeverState.RED:
		current_state = LeverState.GREEN
	else:
		current_state = LeverState.RED
	
	if is_one_time_use:
		is_used = true
	else:
		# Start the cooldown if it's a multi-use lever
		_start_cooldown()
	
	state_changed.emit(current_state)
	lever_activated.emit()
	
	_update_visuals()


func _start_cooldown() -> void:
	is_on_cooldown = true
	await get_tree().create_timer(cooldown_time).timeout
	is_on_cooldown = false


func _update_visuals() -> void:
	if current_state == LeverState.RED:
		animation.play("red")
		if light:
			light.color = red_light_color
	else:
		animation.play("green")
		if light:
			light.color = green_light_color
