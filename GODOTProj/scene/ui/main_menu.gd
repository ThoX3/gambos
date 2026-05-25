extends Control

signal pearl_shop_button_pressed

@onready var play_button = $VBoxContainer/PlayButton
@onready var pearl_shop_button = $VBoxContainer/PearlShopButton
@onready var quit_button = $VBoxContainer/QuitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_button.pressed.connect(play)
	pearl_shop_button.pressed.connect(open_pearl_shop)
	quit_button.pressed.connect(get_tree().quit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play():
	self.visible = false
	GameManager.start_game.emit()
	
func open_pearl_shop():
	pearl_shop_button_pressed.emit()
	
