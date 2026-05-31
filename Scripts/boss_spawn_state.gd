extends BossState

@export var surveyor_scene: PackedScene

func enter(_msg: Dictionary = {}) -> void:
	boss.velocity = Vector2.ZERO
	anim.play("spawn")
	
	if surveyor_scene and boss.surveyer_spawn:
		var surveyor = surveyor_scene.instantiate()
		get_tree().current_scene.add_child(surveyor)
		surveyor.global_position = boss.surveyer_spawn.global_position
		
		# Upward physics propulsion pop
		if surveyor is CharacterBody2D:
			surveyor.velocity = Vector2(0, -400)
			
	await get_tree().create_timer(0.6).timeout
	state_machine.change_state("stand")
