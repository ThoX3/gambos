extends Control

func _ready():
	%Replay.pressed.connect(_on_replay_pressed)
	%Quit.pressed.connect(_on_quit_pressed)
	
func _on_replay_pressed():
	get_tree().paused = false
	%LayerVictory.visible = false
	GameManager.initialize.emit()
	get_tree().reload_current_scene()
	GameManager.start_game.emit()
	

	
func _on_quit_pressed():
	get_tree().quit()
