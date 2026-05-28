extends Control

signal back_button_pressed

@onready var pearl_count_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/PearlsCount
@onready var tree: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TreeScroll/HBoxContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var reset_button: Button = $ResetPurchasesButton

func _ready() -> void:
	back_button.pressed.connect(hide_shop)
	reset_button.pressed.connect(reset_save)
	
	tree.draw.connect(_on_tree_draw)
	tree.sort_children.connect(tree.queue_redraw)
	
	for box in tree.get_children():
		for node in box.get_children():
			if node.has_signal("buy_requested"):
				node.buy_requested.connect(_on_node_buy_requested)
	
	visibility_changed.connect(_on_visibility_changed)	
	refresh_shop()
			
func refresh_shop() -> void:
	var current_pearls = SaveManager.current_save.pearls
	pearl_count_label.text = str(current_pearls)
	
	for box in tree.get_children():
		for node in box.get_children():
			if node.has_method("update_node"):
				node.update_node()

	_request_redraw()

func _on_visibility_changed() -> void:
	if visible:
		_request_redraw()

func _request_redraw() -> void:
	if is_inside_tree():
		await get_tree().process_frame
		tree.queue_redraw()

func _on_tree_draw() -> void:
	for box in tree.get_children():
		for node in box.get_children():
			if node.has_method("update_node") and "parent_node" in node and node.parent_node != null:
				var start_pos = (node.global_position + node.size / 2.0) - tree.global_position
				var end_pos = (node.parent_node.global_position + node.parent_node.size / 2.0) - tree.global_position
				
				var color = Color(0.9, 0.75, 0.1, 1.0) if node.is_unlocked else Color(0.25, 0.25, 0.25, 0.6)
				var width = 6.0 if node.is_unlocked else 4.0
				
				tree.draw_line(end_pos, start_pos, color, width, true)


func _on_node_buy_requested(id: String, cost: int) -> void:
	if SaveManager.current_save.pearls >= cost:
		SaveManager.current_save.pearls -= cost
		
		match id:
			"health": SaveManager.current_save.upgrade_health_level += 1
			"damage": SaveManager.current_save.upgrade_damage_level += 1
			"speed":  SaveManager.current_save.upgrade_speed_level += 1
			"speed_damage": SaveManager.current_save.upgrade_speed_damage_level += 1
			"xp_gain": SaveManager.current_save.upgrade_xp_gain_level += 1
			"luck": SaveManager.current_save.upgrade_luck_level += 1
			"regen": SaveManager.current_save.upgrade_regen_level += 1
			
		SaveManager.save_game()		
		refresh_shop()
		
func hide_shop() -> void:
	self.visible = false
	back_button_pressed.emit()
	
func reset_save():
	SaveManager.current_save = SaveData.new()
	SaveManager.save_game()
	refresh_shop()
