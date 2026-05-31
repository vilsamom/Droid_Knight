extends TextureProgressBar

@export var health_component: HealthComponent
@export var tween_duration: float = 0.2
@export var shake_amount: float = 4.0

var _prev_health: float
# Store the true, absolute starting position of the health bar
var _base_position: Vector2 
var _shake_tween: Tween

func _ready() -> void:
	# Capture the correct default position before any shaking happens
	_base_position = position 
	
	if health_component:
		health_component.health_changed.connect(update_bar)
		_prev_health = health_component.current_health
		value = (_prev_health / health_component.max_health) * max_value

func update_bar(current: float, max_health: float) -> void:
	if max_health <= 0: return
	
	var target_value = (current / max_health) * max_value
	
	var health_tween = create_tween()
	health_tween.tween_property(self, "value", target_value, tween_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	if current < _prev_health:
		_shake_effect()
		
	_prev_health = current

func _shake_effect() -> void:
	# If a shake is already running, kill it so it doesn't fight the new one
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	
	# Always force the position back to base before starting a new shake sequence
	position = _base_position 
	
	_shake_tween = create_tween()
	
	for i in range(5):
		var rand_offset = Vector2(
			randf_range(-shake_amount, shake_amount), 
			randf_range(-shake_amount, shake_amount)
		)
		# Calculate offset relative to the immutable base position, not the current position
		_shake_tween.tween_property(self, "position", _base_position + rand_offset, 0.03)
	
	# Guarantee it snaps perfectly back to the default layout spot at the end
	_shake_tween.tween_property(self, "position", _base_position, 0.03)
