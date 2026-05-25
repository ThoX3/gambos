extends Control

func _ready():
	%Replay.pressed.connect(_on_replay_pressed)
	%Quit.pressed.connect(_on_quit_pressed)
	
func _on_replay_pressed():
	get_tree().paused = false
	%LayerVictory.visible = false
	GameManager.skip_menu = true
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	get_tree().quit()
