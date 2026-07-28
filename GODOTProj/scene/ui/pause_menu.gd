extends Control

signal menu_button_pressed
signal bestiary_button_pressed
signal settings_button_pressed

@export var STATS_FONT: Font = preload("res://assets/fonts/dynamic/DePixelKlein.tres")

## Empêche le toggle pause quand le bestiaire est ouvert par-dessus
var _bestiary_open: bool = false
var _disable_pause: bool = false

func _ready() -> void:
	hide()
	if not %Resume.pressed.is_connected(_on_resume_pressed):
		%Resume.pressed.connect(_on_resume_pressed)
	if not %Quit.pressed.is_connected(_on_quit_pressed):
		%Quit.pressed.connect(_on_quit_pressed)
	if not %BestiaryButton.pressed.is_connected(_on_bestiary_pressed):
		%BestiaryButton.pressed.connect(_on_bestiary_pressed) 
	if not %SettingsButton.pressed.is_connected(_on_settings_pressed):
		%SettingsButton.pressed.connect(_on_settings_pressed)
	%Quit.focus_entered.connect(_display_quit_info)
	%Quit.focus_exited.connect(_hide_quit_info)

func _input(event: InputEvent) -> void:
	if _bestiary_open:
		return  # Le bestiaire gère lui-même ui_cancel
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	var level_up = get_node_or_null("../LevelUp")
	var is_upgrade_open = false
	if level_up and level_up.visible:
		is_upgrade_open = true

	if GameManager.in_game == true or is_upgrade_open:
		var is_pause_visible = visible
		
		if is_pause_visible:
			visible = false
			if is_upgrade_open:
				get_tree().paused = true
				if level_up.has_method("_focus_card"):
					level_up._focus_card(level_up._focused_card_index)
			else:
				get_tree().paused = false
		elif not _disable_pause:
			visible = true
			get_tree().paused = true
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
	visible = false
	menu_button_pressed.emit()

func _on_bestiary_pressed() -> void:
	_bestiary_open = true
	visible = false  
	bestiary_button_pressed.emit()
	
func _on_settings_pressed():
	visible = false
	settings_button_pressed.emit()

func notify_settings_closed() -> void:
	visible = true
	%Resume.grab_focus()

func notify_bestiary_closed() -> void:
	var level_up = get_node_or_null("../LevelUp")
	var is_upgrade_open = false
	if level_up and level_up.visible:
		is_upgrade_open = true

	if not is_upgrade_open:
		GameManager.in_game = true
	_bestiary_open = false
	visible = true   # Réaffiche le menu pause
	%Resume.grab_focus()
	
func _display_quit_info() -> void:
	%QuitDescription.text = "Retourne au menu principal tout en gardant les perles accumulées pendant la partie."
	%QuitDescription.show()
	
func _hide_quit_info() -> void:
	%QuitDescription.text = ""
	%QuitDescription.show()
