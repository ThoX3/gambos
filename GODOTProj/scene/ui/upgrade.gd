extends Control

var _focused_card_index: int = 0
var _cards: Array = []
var lvl_reroll: int = 0
var nb_reroll: int = 1
var base_price_reroll: int
var price_reroll: int
var player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	GameManager.level_up.connect(_on_level_update)

func _input(event: InputEvent) -> void:
	if not %CanvasLayer.visible:
		return
	if event.is_action_pressed("select_right"):
		_focused_card_index = (_focused_card_index + 1) % _cards.size()
		_focus_card(_focused_card_index)
	elif event.is_action_pressed("select_left"):
		_focused_card_index = (_focused_card_index - 1 + _cards.size()) % _cards.size()
		_focus_card(_focused_card_index)

func _focus_card(index: int) -> void:
	if index < _cards.size():
		_cards[index].get_node("TextureButton").grab_focus()

func _on_level_update():
	GameManager.in_game = false
	get_tree().paused = true
	%CanvasLayer.visible = true
	_focused_card_index = 0
	var random_cards = UpgradeManager.get_random_upgrades(3)
	display_upgrades(random_cards)
	%Card.get_node("TextureButton").grab_focus()
	

func display_upgrades(cards: Array[upgradeData]):
	if !player:
		player = get_tree().get_first_node_in_group("Player")
	_cards = []
	if cards.size() >= 1:
		%Card.setup(cards[0])
		_cards.append(%Card)
	if cards.size() >= 2:
		%Card2.setup(cards[1])
		_cards.append(%Card2)
	if cards.size() >= 3:
		%Card3.setup(cards[2])
		_cards.append(%Card3)
	if not %Card.selected.is_connected(_on_card_selected):
		%Card.selected.connect(_on_card_selected)
	if not %Card2.selected.is_connected(_on_card_selected):
		%Card2.selected.connect(_on_card_selected)
	if not %Card3.selected.is_connected(_on_card_selected):
		%Card3.selected.connect(_on_card_selected)
	manage_reroll()

func _on_card_selected(data: upgradeData):
	if player:
		player.apply_upgrade(data)
	%CanvasLayer.visible = false
	get_tree().paused = false
	GameManager.in_game = true
	
	# Ralenti en sortie d'amélioration (désactivé — la vitesse du joueur est conservée)
	#Engine.time_scale = 0.1
	#var tween = create_tween()
	#tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	#tween.set_ignore_time_scale(true)
	#tween.tween_property(Engine, "time_scale", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)

func manage_reroll():
	lvl_reroll = SaveManager.current_save.upgrade_reroll_level
	if lvl_reroll > 0:
		%Reroll.visible = true
		%TotalPearl.visible = true
		base_price_reroll = 10 -  2 * (lvl_reroll - 1)
		price_reroll = int(base_price_reroll * exp(nb_reroll) / 10)
		%CostLabel.text = str(price_reroll)
		%AmountPearl.text = str(SaveManager.current_save.pearls + player.Stats.collected_pearls)
		set_reroll_disable()

func _on_reroll_pressed() -> void:
	update_pearl()
	nb_reroll += 1
	display_upgrades(UpgradeManager.get_random_upgrades(3))
	
func set_reroll_disable():
	if price_reroll <= SaveManager.current_save.pearls + player.Stats.collected_pearls:
		%Reroll.disabled = false
		%Reroll.modulate = Color.WHITE
	else :
		%Reroll.disabled = true
		%Reroll.modulate = Color(0.4, 0.4, 0.4, 1.0)

func update_pearl():
	if price_reroll <= player.Stats.collected_pearls:
		player.Stats.collected_pearls -= price_reroll
	else:
		SaveManager.current_save.pearls -= price_reroll + player.Stats.collected_pearls
		player.Stats.collected_pearls = 0
