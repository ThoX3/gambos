extends Control

@export var Stats = Resource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.xp_changed.connect(_update_progres_bar)
	GameManager.level_up.connect(_update_level)
	_update_progres_bar()
	_update_level()
	show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _update_progres_bar():
	$TextureProgressBar.max_value = Stats.requiredXp
	$TextureProgressBar.value = Stats.currentXp
	
	
func _update_level():
	$Level.text = str(Stats.level)
