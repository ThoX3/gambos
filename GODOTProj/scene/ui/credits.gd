extends Control

signal back_pressed

@onready var back_button: Button = $VBoxContainer/Button

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus.call_deferred()
	
func _on_back_pressed() -> void:
	back_pressed.emit()
	AudioManager.play_sound_2d("menu_press", Vector2.ZERO)
