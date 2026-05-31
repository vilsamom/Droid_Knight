extends CharacterBody2D

@export var movement_component: EnemyMovementComponent

@onready var death_component: DeathComponent = %DeathComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var aggro_area: Area2D = $AggroArea

var current_target: CharacterBody2D = null

func _ready() -> void:
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta: float) -> void:
	movement_component.process_knockback(delta) 
	
	if movement_component.is_grounded(): 
		movement_component.vertical_velocity = 0 
		
		# Track the direction before patrolled constraints execute
		var old_dir = movement_component.direction
		
		# Move at normal speed and obey ledge/wall detection constraints
		movement_component.handle_patrol(delta) 
		
		# If handle_patrol changed the direction, it means we hit a wall or ledge.
		# ONLY face the target if we didn't just turn around due to a cliff edge.
		if old_dir == movement_component.direction:
			if is_instance_valid(current_target): 
				movement_component.face_target(current_target.global_position) 
	else:
		# Keep falling naturally if it happens to be airborne
		if is_instance_valid(current_target): 
			movement_component.face_target(current_target.global_position) 
		movement_component.handle_fall(delta) 

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area is FallZone or area.is_in_group("killzone"): 
		if death_component: 
			death_component.instant_kill() 

func _on_hurtbox_received_damage(_amount: int, source_pos: Vector2) -> void:
	movement_component.apply_knockback(source_pos) 

func _on_aggro_area_target_spotted(body: Variant) -> void:
	if body is CharacterBody2D: 
		current_target = body 

func _on_aggro_area_target_lost() -> void:
	current_target = null
