extends BaseMap


func _ready() -> void:
	super._ready()
	AudioManager.play_music("map1")
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm:
		wm.vague_demarree.connect(AudioManager._on_vague_change)

func _physics_process(_delta: float) -> void:
	super._physics_process(_delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
