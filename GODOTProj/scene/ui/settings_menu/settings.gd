extends Control

signal back_pressed

@onready var music_slider: HSlider = $VBoxContainer/SettingsList/MusicControl/HSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SettingsList/SFXControl/HSlider
@onready var damage_numbers_checkbox: CheckBox = $VBoxContainer/SettingsList/DamageNumberControl/CheckBox
@onready var haptic_slider: HSlider = $VBoxContainer/SettingsList/HapticControl/HSlider
@onready var font_checkbox: CheckBox = $VBoxContainer/SettingsList/FontControl/CheckBox
@onready var back_button: Button = $VBoxContainer/Button

var music_bus_index: int
var sfx_bus_index: int
func _ready() -> void:
	# 1. Find the audio buses
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# 2. Synchronize sliders and UI with current save / system state
	if SaveManager.current_save:
		music_slider.value = SaveManager.current_save.setting_music_volume
		sfx_slider.value = SaveManager.current_save.setting_sfx_volume
		damage_numbers_checkbox.button_pressed = SaveManager.current_save.setting_show_damage_numbers
		haptic_slider.value = SaveManager.current_save.setting_haptic_strength
		font_checkbox.button_pressed = SaveManager.current_save.setting_use_pixel_font
	else:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))
		damage_numbers_checkbox.button_pressed = true
	
	# 3. Connect UI signals
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	damage_numbers_checkbox.toggled.connect(_on_damage_numbers_toggled)
	haptic_slider.value_changed.connect(_on_haptic_changed)
	font_checkbox.toggled.connect(_on_font_toggled)
	back_button.pressed.connect(_on_back_pressed)


func _on_music_volume_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(music_bus_index, db_value)
	AudioServer.set_bus_mute(music_bus_index, value <= 0.0)
	if SaveManager.current_save:
		SaveManager.current_save.setting_music_volume = value

func _on_sfx_volume_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(sfx_bus_index, db_value)
	AudioServer.set_bus_mute(sfx_bus_index, value <= 0.0)
	if SaveManager.current_save:
		SaveManager.current_save.setting_sfx_volume = value
		
	# Play a test sound to hear the new volume
	if is_node_ready():
		AudioManager.play_sound("projectile_pop")

func _on_damage_numbers_toggled(toggled_on: bool) -> void:
	if SaveManager.current_save:
		SaveManager.current_save.setting_show_damage_numbers = toggled_on

func _on_haptic_changed(value: float) -> void:
	if SaveManager.current_save:
		SaveManager.current_save.setting_haptic_strength = value
		
	# Quick test vibration to demonstrate the new strength
	GameManager.joy_vibration(0, 0.5, 0.5, 0.1)
		
func _on_font_toggled(toggled_on: bool) -> void:
	if SaveManager.current_save:
		SaveManager.current_save.setting_use_pixel_font = toggled_on
		if FontManager:
			FontManager.set_modern_font(not toggled_on)

func _on_back_pressed() -> void:
	# Save changes to disk
	SaveManager.save_game()
	# Emit a signal so your Main node knows to close this menu
	back_pressed.emit()
