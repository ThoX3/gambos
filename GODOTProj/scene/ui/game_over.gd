extends Control

signal quit_button_pressed

func _ready():
	%Replay.pressed.connect(_on_replay_pressed)
	%Quit.pressed.connect(_on_quit_pressed)
	
func _on_replay_pressed():
	get_tree().paused = false
	%LayerGameOver.visible = false
	GameManager.skip_menu = true
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	%LayerGameOver.visible = false
	quit_button_pressed.emit()
