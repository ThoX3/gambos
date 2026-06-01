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
	var random_cards = UpgradeManager.get_random_upgrades(3)
	display_upgrades(random_cards)
	%Card.get_node("TextureButton").grab_focus()

func display_upgrades(cards: Array[upgradeData]):
	if cards.size() >= 1:
		%Card.setup(cards[0])
	if cards.size() >= 2:
		%Card2.setup(cards[1])
	if cards.size() >= 3:
		%Card3.setup(cards[2])
	if not %Card.selected.is_connected(_on_card_selected):
		%Card.selected.connect(_on_card_selected)
	if not %Card2.selected.is_connected(_on_card_selected):
		%Card2.selected.connect(_on_card_selected)
	if not %Card3.selected.is_connected(_on_card_selected):
		%Card3.selected.connect(_on_card_selected)

func _on_card_selected(data: upgradeData):
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.apply_upgrade(data)
	%CanvasLayer.visible = false
	get_tree().paused = false
	
	# Ralenti en sortie d'amélioration
	Engine.time_scale = 0.1
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ignore_time_scale(true)
	tween.tween_property(Engine, "time_scale", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)
