extends Control

@onready var pearl_count_label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/PearlsCount
@onready var item_list = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer

var main_manager = get_tree().get_first_node_in_group("main")

func _ready() -> void:
	# back_button.pressed.connect(hide_shop)
	
	for card in item_list.get_children():
		if card.has_signal("buy_requested"):
			card.buy_requested.connect(_on_card_buy_requested)
			
	refresh_shop()

func refresh_shop() -> void:
	var current_pearls = main_manager.current_save.pearls
	pearl_count_label.text = "Perles : " + str(current_pearls)
	
	for card in item_list.get_children():
		if card.has_method("update_card"):
			var level = 0
			
			match card.upgrade_id:
				"health": level = main_manager.current_save.upgrade_health_level
				"damage": level = main_manager.current_save.upgrade_damage_level
				"speed":  level = main_manager.current_save.upgrade_speed_level
				
			card.update_card(level, current_pearls)

func _on_card_buy_requested(id: String, cost: int) -> void:
	if main_manager.current_save.total_gold >= cost:
		main_manager.current_save.total_gold -= cost
		
		match id:
			"health": main_manager.current_save.upgrade_health_level += 1
			"damage": main_manager.current_save.upgrade_damage_level += 1
			"speed":  main_manager.current_save.upgrade_speed_level += 1
			
		main_manager.save_game()		
		refresh_shop()
