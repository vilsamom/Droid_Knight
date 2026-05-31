extends BossState

@export var bullet_scene: PackedScene
@export var laser_color: Color = Color(1.5, 0.0, 0.0, 2.0)
@export var laser_thickness: float = 2.0

var laser_line: Line2D
var muzzle: Marker2D

func setup() -> void:
	if boss.gun:
		muzzle = boss.gun.get_node_or_null("Muzzle")

func enter(_msg: Dictionary = {}) -> void:
	boss.velocity = Vector2.ZERO
	_execute_sequence()

func _execute_sequence() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player or not muzzle:
		state_machine.change_state("stand")
		return

	# Draw telegraphing laser sight
	laser_line = Line2D.new()
	laser_line.width = laser_thickness
	laser_line.default_color = laser_color
	get_tree().current_scene.add_child(laser_line)

	var time_passed = 0.0
	while time_passed < 1.0:
		if is_instance_valid(player) and is_instance_valid(laser_line):
			boss.aim_gun_at(player.global_position)
			laser_line.points = [muzzle.global_position, player.global_position]
		await get_tree().create_timer(0.01).timeout
		time_passed += 0.01

	if is_instance_valid(laser_line):
		laser_line.queue_free()

	# Unload 5 consecutive rounds at 0.2s steps
	for i in range(5):
		_fire_projectile()
		await get_tree().create_timer(0.2).timeout

	state_machine.change_state("stand")

func _fire_projectile() -> void:
	if bullet_scene and boss.gun and muzzle:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = muzzle.global_position
		bullet.global_rotation = boss.gun.global_rotation
