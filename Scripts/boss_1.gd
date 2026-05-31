extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D 
@onready var axe: Area2D = $Axe 
@onready var animation_player: AnimationPlayer = $AnimationPlayer 
@onready var ray_cast_side: RayCast2D = $RayCastSide 
@onready var surveyer_spawn: Marker2D = $SurveyerSpawn 
@onready var gun: Sprite2D = $gun
@onready var atk_a_aggro: Area2D = $AtkAAggro 
@onready var aggro_area: Area2D = $AggroArea 
@onready var boss_state_machine: BossStateMachine = $BossStateMachine 

## Flag allowing specific states (like the charge dash) to temporarily lock orientation
var is_facing_locked: bool = false

func _ready() -> void:
	boss_state_machine.init(self, null, animation_player) 

func _physics_process(delta: float) -> void:
	if not is_facing_locked:
		_face_player_global()
		
	boss_state_machine.process_physics(delta)

## Tracks and mirrors the boss to face the player globally
func _face_player_global() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
		
	if player.global_position.x > global_position.x:
		scale.x = abs(scale.x)
	else:
		scale.x = -abs(scale.x)

## Rotates the weapon assembly correctly regardless of current parent mirror flip configurations
func aim_gun_at(target_position: Vector2) -> void:
	if not gun: return
	if scale.x < 0:
		var target_dir = (target_position - gun.global_position).normalized()
		gun.global_rotation = atan2(-target_dir.y, -target_dir.x)
	else:
		gun.look_at(target_position)
