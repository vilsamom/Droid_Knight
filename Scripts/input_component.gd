class_name InputComponent extends Node

var move_dir: float
var jump_pressed := false
var jump_released := false
var dash_pressed := false
var attack_pressed := false
var attack_held := false
var attack_released := false
var drop_through := false
var pause := false

func update() -> void:
	move_dir = Input.get_axis("left", "right")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	dash_pressed = Input.is_action_just_pressed("dash")
	attack_pressed = Input.is_action_just_pressed("attack")
	attack_held = Input. is_action_pressed("attack")
	attack_released = Input.is_action_just_released("attack")
	drop_through = Input.is_action_just_pressed("down")
	pause = Input.is_action_just_pressed("pause")
