extends Control

signal back_pressed

@onready var volume_slider: HSlider = $VBoxContainer/SettingsList/SoundControl/HSlider
@onready var haptic_slider: HSlider = $VBoxContainer/SettingsList/HapticControl/HSlider
@onready var font_checkbox: CheckBox = $VBoxContainer/SettingsList/FontControl/CheckBox
@onready var back_button: Button = $VBoxContainer/Button

var master_bus_index: int

func _ready() -> void:
	# 1. Find the Master audio bus
	master_bus_index = AudioServer.get_bus_index("Master")
	
	# 2. Synchronize sliders and UI with current save / system state
	if SaveManager.current_save:
		volume_slider.value = SaveManager.current_save.setting_master_volume
		haptic_slider.value = SaveManager.current_save.setting_haptic_strength
		font_checkbox.button_pressed = SaveManager.current_save.setting_use_pixel_font
	else:
		var current_db = AudioServer.get_bus_volume_db(master_bus_index)
		volume_slider.value = db_to_linear(current_db)
	
	# 3. Connect UI signals
	volume_slider.value_changed.connect(_on_volume_value_changed)
	haptic_slider.value_changed.connect(_on_haptic_changed)
	font_checkbox.toggled.connect(_on_font_toggled)
	back_button.pressed.connect(_on_back_pressed)


func _on_volume_value_changed(value: float) -> void:
	# Convert the 0.0 -> 1.0 slider value to decibels (-80dB to 0dB)
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(master_bus_index, db_value)
	AudioServer.set_bus_mute(master_bus_index, value <= 0.0)
	
	if SaveManager.current_save:
		SaveManager.current_save.setting_master_volume = value

func _on_haptic_changed(value: float) -> void:
	if SaveManager.current_save:
		SaveManager.current_save.setting_haptic_strength = value
		
	# Quick test vibration to demonstrate the new strength
	GameManager.joy_vibration(0, 0.5, 0.5, 0.1)
		
func _on_font_toggled(toggled_on: bool) -> void:
	if SaveManager.current_save:
		SaveManager.current_save.setting_use_pixel_font = toggled_on

func _on_back_pressed() -> void:
	# Save changes to disk
	SaveManager.save_game()
	# Emit a signal so your Main node knows to close this menu
	back_pressed.emit()
