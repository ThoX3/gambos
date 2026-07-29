extends Control

signal back_pressed

@onready var back_button: Button = $VBoxContainer/Button

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	if GameManager.game_played_with_controller:
		back_button.grab_focus.call_deferred()
	
	# Toggle l'icon du bouton de retour selon le mode d'input
	if GameManager.game_played_with_controller and back_button.has_meta("icon"):
		back_button.icon = back_button.get_meta("icon")
	else:
		back_button.set_meta("icon", back_button.icon)
		back_button.icon = null
	
func _on_back_pressed() -> void:
	back_pressed.emit()
	AudioManager.play_sound_2d("menu_press", Vector2.ZERO)
