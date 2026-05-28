extends Control

signal back_button_pressed

@onready var pearl_count_label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/PearlsCount
@onready var item_list = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ShopItems
@onready var back_button = $MarginContainer/VBoxContainer/BackButton
@onready var reset_button = $ResetPurchasesButton

func _ready() -> void:
	back_button.pressed.connect(hide_shop)
	reset_button.pressed.connect(reset_save)
	
	for card in item_list.get_children():
		if card.has_signal("buy_requested"):
			card.buy_requested.connect(_on_card_buy_requested)
			
func refresh_shop() -> void:
	var current_pearls = SaveManager.current_save.pearls
	pearl_count_label.text = str(current_pearls)
	
	for card in item_list.get_children():
		if card.has_method("update_card"):
			var level = 0
			
			match card.upgrade_id:
				"health": level = SaveManager.current_save.upgrade_health_level
				"damage": level = SaveManager.current_save.upgrade_damage_level
				"speed":  level = SaveManager.current_save.upgrade_speed_level
				"speed-damage": level = SaveManager.current_save.upgrade_speed_damage_level
				"projectile-number": level = SaveManager.current_save.upgrade_projectile_level
				
			card.update_card(level, current_pearls)

func _on_card_buy_requested(id: String, cost: int) -> void:
	if SaveManager.current_save.pearls >= cost:
		SaveManager.current_save.pearls -= cost
		
		match id:
			"health": SaveManager.current_save.upgrade_health_level += 1
			"damage": SaveManager.current_save.upgrade_damage_level += 1
			"speed":  SaveManager.current_save.upgrade_speed_level += 1
			"speed-damage": SaveManager.current_save.upgrade_speed_damage_level += 1
			"projectile-number": SaveManager.current_save.upgrade_projectile_level += 1
			
		SaveManager.save_game()		
		refresh_shop()
		
func hide_shop() -> void:
	self.visible = false
	back_button_pressed.emit()
	
func reset_save():
	SaveManager.current_save = SaveData.new()
	SaveManager.save_game()
	refresh_shop()
