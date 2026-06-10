extends Control

signal back_pressed

@onready var volume_slider: HSlider = $VBoxContainer/SoundControl/HSlider
@onready var back_button: Button = $VBoxContainer/Button

var master_bus_index: int

func _ready() -> void:
	# 1. Find the Master audio bus
	master_bus_index = AudioServer.get_bus_index("Master")
	
	# 2. Synchronize slider position with current system volume on launch
	var current_db = AudioServer.get_bus_volume_db(master_bus_index)
	volume_slider.value = db_to_linear(current_db)
	
	# 3. Connect UI signals
	volume_slider.value_changed.connect(_on_volume_value_changed)
	back_button.pressed.connect(_on_back_pressed)


func _on_volume_value_changed(value: float) -> void:
	# Convert the 0.0 -> 1.0 slider value to decibels (-80dB to 0dB)
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(master_bus_index, db_value)
	
	# Completely mute the bus if slider is dragged to absolute 0 
	# (Prevents tiny, mathematical ghost noises)
	AudioServer.set_bus_mute(master_bus_index, value <= 0.0)


func _on_back_pressed() -> void:
	# Emit a signal so your Main node knows to close this menu
	back_pressed.emit()
