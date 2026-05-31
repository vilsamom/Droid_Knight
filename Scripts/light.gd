extends PointLight2D

@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	# Connect signals safely
	screen_notifier.screen_entered.connect(_on_screen_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)
	
	# Check initial state so off-screen instances start disabled
	enabled = screen_notifier.is_on_screen()

func _on_screen_entered() -> void:
	enabled = true

func _on_screen_exited() -> void:
	enabled = false
