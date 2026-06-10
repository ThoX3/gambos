extends Control

signal menu_button_pressed
signal bestiary_button_pressed
signal settings_button_pressed

@export var STATS_FONT: FontFile

## Empêche le toggle pause quand le bestiaire est ouvert par-dessus
var _bestiary_open: bool = false

func _ready() -> void:
	hide()
	%Resume.pressed.connect(_on_resume_pressed)
	%Quit.pressed.connect(_on_quit_pressed)
	%BestiaryButton.pressed.connect(_on_bestiary_pressed) 
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%Quit.focus_entered.connect(_display_quit_info)
	%Quit.focus_exited.connect(_hide_quit_info)

func _input(event: InputEvent) -> void:
	if _bestiary_open:
		return  # Le bestiaire gère lui-même ui_cancel
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if GameManager.in_game == true:
		var new_pause_state = !get_tree().paused
		get_tree().paused = new_pause_state
		%LayerPause.visible = new_pause_state
		if new_pause_state:
			update_stats_display()
			%Resume.grab_focus()

func update_stats_display():
	for child in %PlayerStats.get_children():
		child.queue_free()
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("get_player_stats"):
		var stats = player.get_player_stats()
		for category in stats:
			var label = Label.new()
			label.text = category + str(stats[category])
			label.add_theme_font_override("font", STATS_FONT)
			%PlayerStats.add_child(label)

func _on_resume_pressed():
	toggle_pause()

func _on_quit_pressed() -> void:
	AudioManager.play_music("main_menu")
	%LayerPause.visible = false
	menu_button_pressed.emit()

func _on_bestiary_pressed() -> void:
	_bestiary_open = true
	%LayerPause.visible = false  # Cache le menu pause visuellement
	bestiary_button_pressed.emit()
	
func _on_settings_pressed():
	%LayerPause.visible = false
	settings_button_pressed.emit()

func notify_settings_closed() -> void:
	%LayerPause.visible = true
	%Resume.grab_focus()

func notify_bestiary_closed() -> void:
	GameManager.in_game = true
	_bestiary_open = false
	%LayerPause.visible = true   # Réaffiche le menu pause
	%Resume.grab_focus()
	
func _display_quit_info() -> void:
	%QuitDescription.text = "Retourne au menu principal tout en gardant les perles accumulées pendant la partie."
	%QuitDescription.show()
	
func _hide_quit_info() -> void:
	%QuitDescription.text = ""
	%QuitDescription.show()
