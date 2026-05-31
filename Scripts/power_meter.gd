class_name PowerMeterUI extends MarginContainer

@export var resource_component: PowerMeterResource
@export var bar_15_cap: TextureProgressBar
@export var bar_30_cap: TextureProgressBar

var active_bar: TextureProgressBar
var meter_tween: Tween

# --- Container-safe Vibration Variables ---
var _bar_15_base_pos: Vector2
var _bar_30_base_pos: Vector2

var _vibration_intensity: float = 0.0
var _depletion_shake: float = 0.0

func _ready() -> void:
	# Save structural layout locations safely
	_bar_15_base_pos = bar_15_cap.position
	_bar_30_base_pos = bar_30_cap.position
	
	if not resource_component:
		push_warning("PowerMeterUI: Missing resource component reference!")
		return
		
	resource_component.resource_changed.connect(_on_resource_changed)
	
	# Wait until the current frame's initialization pass finishes to draw the layout,
	# ensuring the Player script has had time to update values.
	_setup_meter_ui.call_deferred()

func _process(delta: float) -> void:
	if _depletion_shake > 0:
		_depletion_shake = move_toward(_depletion_shake, 0.0, delta * 15.0)
		
	var total_shake = _vibration_intensity + _depletion_shake
	
	if active_bar and total_shake > 0.1:
		var base_pos = _bar_30_base_pos if active_bar == bar_30_cap else _bar_15_base_pos
		active_bar.position = base_pos + Vector2(
			randf_range(-1.0, 1.0) * total_shake,
			randf_range(-1.0, 1.0) * total_shake
		)
	else:
		bar_15_cap.position = _bar_15_base_pos
		bar_30_cap.position = _bar_30_base_pos

func _setup_meter_ui() -> void:
	# Query the configuration straight from the live component state
	var is_upgraded = resource_component.large_capacity
	
	bar_15_cap.visible = not is_upgraded
	bar_30_cap.visible = is_upgraded
	
	if is_upgraded:
		active_bar = bar_30_cap
	else:
		active_bar = bar_15_cap
		
	bar_15_cap.max_value = 15
	bar_30_cap.max_value = 30
	
	_update_bar_value(resource_component.current_resource, true)

func _on_resource_changed(current_value: int, max_value: int) -> void:
	# This ensures if the player updates the max capacity at startup, the UI swaps instantly
	if (max_value == 30 and active_bar != bar_30_cap) or (max_value == 15 and active_bar != bar_15_cap):
		_setup_meter_ui()
		
	if active_bar and current_value < active_bar.value:
		_depletion_shake = 4.0
		
	var snap_instantly = (current_value == 0)
	_update_bar_value(current_value, snap_instantly)

func _update_bar_value(value: int, snap: bool) -> void:
	if not active_bar:
		return

	if meter_tween and meter_tween.is_valid():
		meter_tween.kill()

	if snap:
		active_bar.value = value
	else:
		meter_tween = create_tween()
		meter_tween.tween_property(active_bar, "value", value, 0.25)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)

func set_charge_vibration(intensity: float) -> void:
	_vibration_intensity = intensity
