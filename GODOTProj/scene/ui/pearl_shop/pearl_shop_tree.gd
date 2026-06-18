extends Control

signal menu_button_pressed

@onready var pearl_count_label: Label = %PearlsCount
@onready var tree: HBoxContainer = %Tree
@onready var tree_mask: TextureRect = %TreeMask
@onready var menu_button: Button = $MarginContainer/VBoxContainer/NavigationButtons/MenuButton
@onready var play_button: Button = $MarginContainer/VBoxContainer/NavigationButtons/PlayButton
@onready var reset_button: Button = $ResetPurchasesButton
@onready var first_node = $MarginContainer/VBoxContainer/HBoxContainer/TreeMask/MarginContainer/TreeScroll/Tree/VBoxContainer/SpeedNode
@onready var node_infos_window = $NodeInfos

@onready var list_button: Array[Variant] = [menu_button, play_button, reset_button]

@export var max_items_per_group: int = 5
const DIALOGUE_SCENE = preload("res://scene/tutorial/tutorial_dialogue.tscn")
@onready var fade_rect: ColorRect = $FadeRect

var currently_focused_node: Control = null

func _ready() -> void:
	menu_button.pressed.connect(open_menu)
	play_button.pressed.connect(play)
	reset_button.pressed.connect(reset_save)
	reset_button.gui_input.connect(_on_reset_button_gui_input)
	
	menu_button.focus_entered.connect(_on_non_node_focus_entered)
	play_button.focus_entered.connect(_on_non_node_focus_entered)
	reset_button.focus_entered.connect(_on_non_node_focus_entered)
	
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
		
func _process(delta: float) -> void:
	if currently_focused_node and node_infos_window.visible:
		var pos := currently_focused_node.global_position
		var node_size := currently_focused_node.size
		var target_pos: Vector2
		
		if pos.y <= 390:
			target_pos = pos + Vector2(node_size.x / 2.0 - node_infos_window.size.x / 2.0, node_size.y + 16)
		else:
			target_pos = pos + Vector2(node_size.x / 2.0 - node_infos_window.size.x / 2.0, -218)
			
		node_infos_window.global_position = node_infos_window.global_position.lerp(target_pos, 15.0 * delta)

func _on_visibility_changed() -> void:
	if visible:
		first_node.get_node("TextureButton").grab_focus.call_deferred()
	else:
		if node_infos_window:
			node_infos_window.visible = false

func _on_non_node_focus_entered() -> void:
	if currently_focused_node:
		currently_focused_node.get_node("TextureButton").self_modulate = Color(1.0, 1.0, 1.0)
		currently_focused_node = null
	node_infos_window.visible = false

func _on_node_focus_entered(node: Control) -> void:
	AudioManager.play_sound_2d("menu_selection", Vector2.ZERO)
	
	node.get_node("TextureButton").self_modulate = Color(1.0, 0.9372549, 0.70980394)
	
	if currently_focused_node:
		currently_focused_node.get_node("TextureButton").self_modulate = Color(1.0, 1.0, 1.0)  # restore previous node
	
	currently_focused_node = node
	_update_node_infos_window()
	
	var scroll: ScrollContainer = tree.get_parent()
	var node_center_in_tree_x := node.global_position.x + (node.size.x / 2.0) - tree.global_position.x
	var target_x := node_center_in_tree_x - (scroll.size.x / 2.0)
	
	var node_center_in_tree_y := node.global_position.y + (node.size.y / 2.0) - tree.global_position.y
	var target_y := node_center_in_tree_y - (scroll.size.y / 2.0)
	
	var tween := create_tween()
	tween.tween_property(scroll, "scroll_horizontal", int(target_x), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(scroll, "scroll_vertical", int(target_y), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _update_node_infos_window() -> void:
	if currently_focused_node == null or not is_visible_in_tree():
		return
	
	var title: String = currently_focused_node.upgrade_name
	var description: String = currently_focused_node.upgrade_description
	
	if not currently_focused_node.is_unlocked:
		if currently_focused_node.locked_by_monde:
			description = "[font_size=14][u]Verrouillé[/u]\n" + description
		elif currently_focused_node.parent_node != null:
			var parent_name = currently_focused_node.parent_node.upgrade_name
			var required_level = currently_focused_node.parent_node_unlock_level
			description = "[font_size=14][u]Débloqué quand " + parent_name + " sera au niveau " + str(required_level) + ".[/u]\n" + description
	
	node_infos_window.set_infos(title, description)
	
	var was_visible = node_infos_window.visible
	node_infos_window.visible = true
	
	if not was_visible:
		var pos := currently_focused_node.global_position
		var node_size := currently_focused_node.size
		var target_pos: Vector2
		if pos.y <= 390:
			target_pos = pos + Vector2(node_size.x / 2.0 - node_infos_window.size.x / 2.0, node_size.y + 16)
		else:
			target_pos = pos + Vector2(node_size.x / 2.0 - node_infos_window.size.x / 2.0, -218)
		node_infos_window.global_position = target_pos

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
				anim_delay += 0.4 
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
		
		var prop_name := "upgrade_" + id + "_level"
		if prop_name in SaveManager.current_save:
			SaveManager.current_save.set(prop_name, SaveManager.current_save.get(prop_name) + 1)
		else:
			push_warning("Unhandled upgrade id: ", id)
		
		SaveManager.current_save.total_purchases += 1
		
		SaveManager.save_game()
		AudioManager.play_sound_2d("pearl_shop_buy", Vector2.ZERO)
		refresh_shop()
		
func open_menu() -> void:
	AudioManager.play_music("main_menu")
	self.visible = false
	menu_button_pressed.emit()
	
func play() -> void:
	if GameManager.gotoshop_from_tutorial:
		%GodessRect.z_index = 100
		var tween := create_tween()
		tween.tween_property(fade_rect, "color:a", 0.75, 1)
		var dialog = DIALOGUE_SCENE.instantiate()
		add_child(dialog)
		var dialog_lines: Array[String] = ["Bon courage pour ta quête, Gambos !"]
		dialog.start_dialogue(dialog_lines, true)
		dialog.dialogue_finished.connect(func():
			%GodessRect.z_index = 0
			get_tree().paused = false
			GameManager.skip_menu = true
			GameManager.gotoshop_from_tutorial = false
			get_tree().reload_current_scene()
			GameManager.Retry.emit()
		)
		return
		
	get_tree().paused = false
	GameManager.skip_menu = true
	GameManager.gotoshop_from_tutorial = false
	get_tree().reload_current_scene()
	
	GameManager.Retry.emit()
	
func reset_save():
	SaveManager.current_save = SaveData.new()
	SaveManager.save_game()
	refresh_shop()

func _on_reset_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		SaveManager.current_save.pearls += 1000
		SaveManager.current_save.upgrade_ingame_speed_level = 5
		SaveManager.current_save.tutorial_completed = true
		SaveManager.save_game()
		refresh_shop()

func was_opened_from_game_over(param: bool):
	if param:
		# Fondu noir vers transparent
		fade_rect.color   = Color(0, 0, 0, 1)  # repart toujours de transparent
		fade_rect.visible = true
		var tween := create_tween()
		tween.tween_property(fade_rect, "color:a", 0, 1.5)
		
		play_button.visible = true
		if GameManager.gotoshop_from_tutorial:
			menu_button.visible = false
			play_button.text = " Commencer la conquête des océans !"
		else:
			menu_button.visible = true
			menu_button.text = " Menu principal"
			play_button.text = " Rejouer\n"
	else:
		play_button.visible = false
		menu_button.text = " Retour"
		menu_button.visible = true
		play_button.text = " Rejouer\n"

func _on_navigation_menu() -> void:
	AudioManager.play_sound_2d("menu_selection", Vector2.ZERO)

func _on_validation_menu() -> void:
	AudioManager.play_sound_2d("menu_press", Vector2.ZERO)
