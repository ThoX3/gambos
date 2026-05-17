extends Control

@export var Stats = Resource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.xp_changed.connect(_update_progres_bar)
	GameManager.level_up.connect(_update_level)
	GameManager.health_changed.connect(_update_health_bar)
	GameManager.start_game.connect(_on_start)
	_update_progres_bar()
	%HP_Bar.max_value = Stats.max_health
	_update_health_bar()
	_update_level()
	show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _update_progres_bar():
	%XP_Bar.max_value = Stats.requiredXp
	%XP_Bar.value = Stats.currentXp

func _update_health_bar():
	# %HP_Bar.max_value = Stats.max_health
	%HP_Bar.value = Stats.current_health
	
func _update_level():
	$Level.text = str(Stats.level)

func _on_start():
	_update_health_bar()
	_update_progres_bar()
	_update_level()
