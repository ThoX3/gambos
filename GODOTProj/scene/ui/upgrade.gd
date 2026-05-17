extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	GameManager.level_up.connect(_on_level_update)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_level_update():
	get_tree().paused = true
	show()


func _on_button_pressed() -> void:
	hide()
	get_tree().paused = false
