extends Control

signal pearl_shop_button_pressed
signal bestiary_button_pressed
signal settings_button_pressed

@onready var play_button = $VBoxContainer/PlayButton
@onready var resume_button = $VBoxContainer/ResumeSaveButton
@onready var pearl_shop_button = $VBoxContainer/PearlShopButton
@onready var bestiary_button = $VBoxContainer/BestiaryButton
@onready var quit_button = $VBoxContainer/HBoxContainer/QuitButton
@onready var settings_button = $VBoxContainer/HBoxContainer/SettingsButton
@onready var list_button = [play_button, resume_button, pearl_shop_button, 
							bestiary_button, quit_button, settings_button]

var is_save_available: bool = false

func _ready() -> void:
	play_button.pressed.connect(play)
	pearl_shop_button.pressed.connect(open_pearl_shop)
	bestiary_button.pressed.connect(open_bestiary)
	quit_button.pressed.connect(get_tree().quit)
	settings_button.pressed.connect(open_settings) 
	
	play_button.grab_focus.call_deferred()
	
	# ── Musique et son ─────────────────────────
	AudioManager.play_music("main_menu")
	
	for button in list_button:
		button.focus_entered.connect(_on_navigation_menu)
		button.mouse_entered.connect(_on_navigation_menu)
		
		button.pressed.connect(_on_validation_menu)
	
	check_for_save()

func _process(delta: float) -> void:
	pass

func play():
	if is_save_available:
		pass # pop up avertissement
	
	self.visible = false
	GameManager.start_game.emit()
	
func open_pearl_shop():
	AudioManager.play_music("shop")
	pearl_shop_button_pressed.emit()

func open_bestiary():
	bestiary_button_pressed.emit()
	
func open_settings():
	settings_button_pressed.emit()
	
func check_for_save():
	# Todo
	# Si on trouve une sauvegarde, on met à jour les infos du bouton,
	# on le laisse visible et on active le warning sur le bouton play
	resume_button.visible = false
	is_save_available = false

func _on_navigation_menu() -> void:
	AudioManager.play_sound_2d("menu_selection", Vector2.ZERO)

func _on_validation_menu() -> void:
	AudioManager.play_sound_2d("menu_press", Vector2.ZERO)
