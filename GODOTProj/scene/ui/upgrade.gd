extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	GameManager.level_up.connect(_on_level_update)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_level_update():
	get_tree().paused = true
	%CanvasLayer.visible = true
	var random_cards = UpgradeManager.get_random_upgrades(1)
	display_upgrades(random_cards)

func display_upgrades(cards: Array[upgradeData]):
	if cards.size() >= 1:
		%Card.setup(cards[0])
	if cards.size() >= 2:
		%Card2.setup(cards[1])
	if cards.size() >= 3:
		%Card3.setup(cards[2])

func _on_button_pressed() -> void:
	hide()
	get_tree().paused = false
