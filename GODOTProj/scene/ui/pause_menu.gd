extends Control

signal quit_button_pressed
signal bestiary_button_pressed

const STATS_FONT = preload("res://assets/fonts/depixel/DePixelBreit.ttf")

## Empêche le toggle pause quand le bestiaire est ouvert par-dessus
var _bestiary_open: bool = false

func _ready() -> void:
	hide()
	%Resume.pressed.connect(_on_resume_pressed)
	%Quit.pressed.connect(_on_quit_pressed)
	%BestiaryButton.pressed.connect(_on_bestiary_pressed)  # NOUVEAU

func _input(event: InputEvent) -> void:
	if _bestiary_open:
		return  # Le bestiaire gère lui-même ui_cancel
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
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
	get_tree().quit()

func _on_bestiary_pressed() -> void:
	_bestiary_open = true
	%LayerPause.visible = false  # Cache le menu pause visuellement
	bestiary_button_pressed.emit()

func notify_bestiary_closed() -> void:
	_bestiary_open = false
	%LayerPause.visible = true   # Réaffiche le menu pause
	%Resume.grab_focus()
