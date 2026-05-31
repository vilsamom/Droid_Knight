extends CharacterBody2D

var target_detected := false
var current_target: Node2D = null

# New tracking variable for chasing movement
var movement_target: Node2D = null

@export var movement_component: EnemyMovementComponent

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var axe: Area2D = $axe
@onready var death_component: DeathComponent = $DeathComponent
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta: float) -> void:
	movement_component.process_knockback(delta) 
	
	if movement_component.is_grounded(): 
		movement_component.vertical_velocity = 0 
		
		# Priority 1: Inside Attack Range -> Stop and Attack
		if target_detected and current_target: 
			_handle_targeting() 
		# Priority 2: Inside General Aggro Range -> Walk normal but face player
		elif is_instance_valid(movement_target):
			_handle_chase(delta)
		# Priority 3: No targets -> Normal Patrol
		else:
			_handle_patrol(delta) 
	else:
		# Process gravity while falling
		if is_instance_valid(movement_target) and not target_detected:
			movement_component.face_target(movement_target.global_position)
		
		movement_component.handle_fall(delta) 
		sprite.play("idle") 

func _handle_targeting() -> void:
	if not axe.atk_cooldown: 
		movement_component.face_target(current_target.global_position) 
	
	sprite.play("idle") 
	if not axe.atk_cooldown: 
		axe.start_attack() 

func _handle_chase(delta: float) -> void:
	if not axe.atk_cooldown:
		sprite.play("walk")
		
		# Track direction before movement constraints process
		var old_dir = movement_component.direction
		
		# Walk like normal (uses default speed and obeys edge/wall turning)
		movement_component.handle_patrol(delta)
		
		# --- FIX: Only track the player if we didn't just hit a cliff edge or wall ---
		if old_dir == movement_component.direction:
			movement_component.face_target(movement_target.global_position)
	else:
		sprite.play("idle")

func _handle_patrol(delta: float) -> void:
	if not axe.atk_cooldown: 
		sprite.play("walk") 
		movement_component.handle_patrol(delta) 
	else:
		sprite.play("idle") 

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area is FallZone or area.is_in_group("killzone"): 
		if death_component: 
			death_component.instant_kill() 

func _on_hurtbox_received_damage(_amount: int, source_pos: Vector2) -> void:
	movement_component.apply_knockback(source_pos) 

func _on_death_component_dead() -> void:
	axe.visible = false 
	axe.stop_attack() 

# --- Attack Aggro Signals ---
func _on_atk_a_aggro_target_spotted(body: Variant) -> void:
	target_detected = true 
	current_target = body 

func _on_atk_a_aggro_target_lost() -> void:
	target_detected = false 
	current_target = null 

# --- Movement Aggro Signals ---
func _on_aggro_area_target_spotted(body: Variant) -> void:
	if body is CharacterBody2D:
		movement_target = body

func _on_aggro_area_target_lost() -> void:
	movement_target = null
