extends Control

signal pearl_shop_button_pressed
signal bestiary_button_pressed

@onready var play_button = $VBoxContainer/PlayButton
@onready var pearl_shop_button = $VBoxContainer/PearlShopButton
@onready var bestiary_button = $VBoxContainer/BestiaryButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready() -> void:
	play_button.pressed.connect(play)
	pearl_shop_button.pressed.connect(open_pearl_shop)
	bestiary_button.pressed.connect(open_bestiary)
	quit_button.pressed.connect(get_tree().quit)
	play_button.grab_focus.call_deferred()

func _process(delta: float) -> void:
	pass

func play():
	self.visible = false
	GameManager.start_game.emit()
	
func open_pearl_shop():
	pearl_shop_button_pressed.emit()

func open_bestiary():
	bestiary_button_pressed.emit()
