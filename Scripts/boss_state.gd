extends Node
class_name BossState

var boss: CharacterBody2D
var movement: Node # Will cast to EnemyMovementComponent safely
var anim: AnimationPlayer
var state_machine: BossStateMachine

func setup() -> void:
	pass

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
