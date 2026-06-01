extends Control

signal menu_button_pressed

@onready var pearl_count_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/PearlsCount
@onready var tree: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/FadeMask/MarginContainer/TreeScroll/HBoxContainer
@onready var tree_mask: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/FadeMask
@onready var menu_button: Button = $MarginContainer/VBoxContainer/NavigationButtons/MenuButton
@onready var play_button: Button = $MarginContainer/VBoxContainer/NavigationButtons/PlayButton
@onready var reset_button: Button = $ResetPurchasesButton
@onready var first_node = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/FadeMask/MarginContainer/TreeScroll/HBoxContainer/VBoxContainer/SpeedNode
@onready var node_infos_window = $NodeInfos

@onready var list_button = [menu_button, play_button, reset_button]

@onready var fade_rect: ColorRect = $FadeRect

var hover_timer: Timer
var currently_focused_node: Control = null

func _ready() -> void:
	menu_button.pressed.connect(open_menu)
	play_button.pressed.connect(play)
	reset_button.pressed.connect(reset_save)
	
	menu_button.focus_entered.connect(_on_non_node_focus_entered)
	play_button.focus_entered.connect(_on_non_node_focus_entered)
	reset_button.focus_entered.connect(_on_non_node_focus_entered)
	
	hover_timer = Timer.new()
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_show_node_infos_window)
	add_child(hover_timer)
	
	tree_mask.clip_children = CLIP_CHILDREN_ONLY
	tree.draw.connect(_on_tree_draw)
	tree.sort_children.connect(tree.queue_redraw)
	
	for node in tree.find_children("*", "PearlTreeNode", true):
		if node.has_signal("buy_requested"):
			node.buy_requested.connect(_on_node_buy_requested)
		if node.has_node("TextureButton"):
			node.get_node("TextureButton").focus_entered.connect(_on_node_focus_entered.bind(node))
	
	visibility_changed.connect(_on_visibility_changed)

	node_infos_window.visible = false

	refresh_shop(true)
	
	if visible:
		first_node.get_node("TextureButton").grab_focus.call_deferred()
		
	# ── Musique et son ─────────────────────────
	for button in list_button:
		button.focus_entered.connect(_on_navigation_menu)
		button.mouse_entered.connect(_on_navigation_menu)
		button.pressed.connect(_on_validation_menu)
		
func _on_visibility_changed() -> void:
	if visible:
		first_node.get_node("TextureButton").grab_focus.call_deferred()
	else:
		hover_timer.stop()
		if node_infos_window:
			node_infos_window.visible = false

func _on_non_node_focus_entered() -> void:
	currently_focused_node = null
	hover_timer.stop()
	node_infos_window.visible = false

func _on_node_focus_entered(node: Control) -> void:
	AudioManager.play_sound_2d("menu_selection", Vector2.ZERO)
	currently_focused_node = node
	node_infos_window.visible = false
	hover_timer.start(1.0)
	
	var scroll: ScrollContainer = tree.get_parent()
	var node_center_in_tree_x := node.global_position.x + (node.size.x / 2.0) - tree.global_position.x
	var target_x := node_center_in_tree_x - (scroll.size.x / 2.0)
	
	var node_center_in_tree_y := node.global_position.y + (node.size.y / 2.0) - tree.global_position.y
	var target_y := node_center_in_tree_y - (scroll.size.y / 2.0)
	
	var tween := create_tween()
	tween.tween_property(scroll, "scroll_horizontal", int(target_x), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(scroll, "scroll_vertical", int(target_y), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _show_node_infos_window() -> void:
	if currently_focused_node == null or not is_visible_in_tree():
		return
	
	var description := ""
	var title := ""
	
	if currently_focused_node.is_unlocked:
		title = currently_focused_node.upgrade_name
		description = currently_focused_node.upgrade_description
	else:
		title = "???"
		if currently_focused_node.parent_node != null and currently_focused_node.parent_node.is_unlocked:
			var parent_name = currently_focused_node.parent_node.upgrade_name
			var required_level = currently_focused_node.parent_node_unlock_level
			description = "[color=#a0a0a0]Débloqué quand " + parent_name + " sera au niveau " + str(required_level) + "[/color]"
		else:
			description = "[color=#a0a0a0]???[/color]"
	
	node_infos_window.set_infos(title, description)
	node_infos_window.visible = true
	
	var pos := currently_focused_node.global_position
	var node_size := currently_focused_node.size
	
	if pos.y <= 390:
		node_infos_window.global_position = pos + Vector2(node_size.x / 2.0 - node_infos_window.size.x / 2.0, node_size.y + 16)
	else:
		node_infos_window.global_position = pos + Vector2(node_size.x / 2.0 - node_infos_window.size.x / 2.0, -218)

func refresh_shop(is_initial_load: bool = false) -> void:
	var current_pearls = SaveManager.current_save.pearls
	pearl_count_label.text = str(current_pearls)
	
	var anim_delay = 0.0
	
	for node in tree.find_children("*", "PearlTreeNode", true):
		if node.has_method("update_node"):
			# Determine if this node is about to be unlocked
			var was_locked = not node.is_unlocked
			var will_be_unlocked = false
			
			if node.parent_node == null:
				will_be_unlocked = true
			else:
				var parent_level = SaveManager.current_save.get("upgrade_" + node.parent_node.upgrade_id + "_level")
				will_be_unlocked = (parent_level != null and parent_level >= node.parent_node_unlock_level)
				
			if not is_initial_load and was_locked and will_be_unlocked:
				node.update_node(anim_delay, false)
				anim_delay += 0.15 # Add slight delay for the next node that might unlock
			else:
				node.update_node(0.0, is_initial_load)

	_request_redraw()

func _request_redraw() -> void:
	if is_inside_tree():
		await get_tree().process_frame
		tree.queue_redraw()

func _on_tree_draw() -> void:
	for node in tree.find_children("*", "PearlTreeNode", true):
		if node.has_method("update_node") and "parent_node" in node and node.parent_node != null:
			var start_pos = (node.global_position + node.size / 2.0) - tree.global_position
			var end_pos = (node.parent_node.global_position + node.parent_node.size / 2.0) - tree.global_position
			
			var color = Color(0.8156863, 0.73333335, 0.36862746) if node.is_unlocked else Color(0.25, 0.25, 0.25, 0.6)
			var width = 6.0 if node.is_unlocked else 4.0
			
			tree.draw_line(end_pos, start_pos, color, width, true)


func _on_node_buy_requested(id: String, cost: int) -> void:
	if SaveManager.current_save.pearls >= cost:
		SaveManager.current_save.pearls -= cost
		
		match id:
			"health": SaveManager.current_save.upgrade_health_level += 1
			"damage": SaveManager.current_save.upgrade_damage_level += 1
			"speed":  SaveManager.current_save.upgrade_speed_level += 1
			"attack_speed": SaveManager.current_save.upgrade_attack_speed_level += 1
			"xp_gain": SaveManager.current_save.upgrade_xp_gain_level += 1
			"luck": SaveManager.current_save.upgrade_luck_level += 1
			"regen": SaveManager.current_save.upgrade_regen_level += 1
			"skip_map": SaveManager.current_save.upgrade_skip_map_level += 1
			"thorns": SaveManager.current_save.upgrade_thorns_level += 1
			"reroll": SaveManager.current_save.upgrade_reroll_level += 1
			"collection_radius": SaveManager.current_save.upgrade_collection_radius_level += 1
			"bubble_division": SaveManager.current_save.upgrade_bubble_division_level += 1
			_: push_warning("Unhandled upgrade id: ", id)
			
		SaveManager.save_game()
		AudioManager.play_sound_2d("pearl_shop_buy", Vector2.ZERO)
		refresh_shop()
		
func open_menu() -> void:
	AudioManager.play_music("main_menu")
	self.visible = false
	menu_button_pressed.emit()
	
func play() -> void:
	get_tree().paused = false
	GameManager.skip_menu = true
	get_tree().reload_current_scene()
	
	GameManager.Retry.emit()
	
func reset_save():
	SaveManager.current_save = SaveData.new()
	SaveManager.save_game()
	refresh_shop()

func was_opened_from_game_over(param: bool):
	if param:
		# Fondu noir vers transparent
		fade_rect.color   = Color(0, 0, 0, 1)  # repart toujours de transparent
		fade_rect.visible = true
		var tween := create_tween()
		tween.tween_property(fade_rect, "color:a", 0, 1.5)
		fade_rect.queue_free()
		
		play_button.visible = true
		menu_button.text = "Menu principal"
	else:
		fade_rect.queue_free()
		play_button.visible = false
		menu_button.text = "Retour"

func _on_navigation_menu() -> void:
	AudioManager.play_sound_2d("menu_selection", Vector2.ZERO)

func _on_validation_menu() -> void:
	AudioManager.play_sound_2d("menu_press", Vector2.ZERO)
