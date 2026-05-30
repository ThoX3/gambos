extends Control

func _ready() -> void:
	hide()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	%LayerPause.visible = new_pause_state
	if new_pause_state:
		%Resume.grab_focus()
