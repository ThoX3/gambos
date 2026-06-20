extends BaseMap


func _ready() -> void:
	super._ready()
	AudioManager.play_music("map2")

func _physics_process(_delta: float) -> void:
	super._physics_process(_delta)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
