extends BossState

func enter(_msg: Dictionary = {}) -> void:
	boss.velocity = Vector2.ZERO
	
	if boss.axe and boss.axe.has_method("normal_attack"):
		await boss.axe.normal_attack() 
	
	state_machine.change_state("stand")
