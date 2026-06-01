extends Control

class_name PearlTreeNode

signal buy_requested(id: String, cost: int)

@export var upgrade_id: String = "health"
@export var upgrade_name: String = "Vie"
@export var upgrade_description: String = ""
@export var icon_texture: Texture2D = preload("res://assets/sprites/pearl_shop/icons/damage.png")
@export var max_level: int = 3
@export var parent_node: Control
@export var parent_node_unlock_level: int = 1

var current_level = 0
var current_cost: int = 0
var is_unlocked: bool = false
var was_unlocked_preview: bool = false

@onready var buy_button = $TextureButton
@onready var level_label = $VBoxContainer/Level
@onready var price_label = $VBoxContainer/HBoxContainer/Price
@onready var title_label = $VBoxContainer/Title
@onready var lock_overlay = $LockOverlay
@onready var icon: TextureRect = $IconContainer/Icon

const TEX_NORMAL = preload("res://assets/sprites/pearl_shop/normal.png")
const TEX_NORMAL_HOVERED = preload("res://assets/sprites/pearl_shop/normal_hovered.png")
const TEX_NORMAL_FOCUSED = preload("res://assets/sprites/pearl_shop/normal_focused.png")
const TEX_LOCKED = preload("res://assets/sprites/pearl_shop/locked.png")
const TEX_LOCKED_HOVERED = preload("res://assets/sprites/pearl_shop/locked_hovered.png")
const TEX_LOCKED_FOCUSED = preload("res://assets/sprites/pearl_shop/locked_focused.png")
const TEX_TOO_EXPENSIVE = preload("res://assets/sprites/pearl_shop/too_expensive.png")
const TEX_TOO_EXPENSIVE_HOVERED = preload("res://assets/sprites/pearl_shop/too_expensive_hovered.png")
const TEX_TOO_EXPENSIVE_FOCUSED = preload("res://assets/sprites/pearl_shop/locked_focused.png")
const TEX_MAXED = preload("res://assets/sprites/pearl_shop/maxed.png")
const TEX_MAXED_HOVERED = preload("res://assets/sprites/pearl_shop/maxed_hovered.png")
const TEX_MAXED_FOCUSED = preload("res://assets/sprites/pearl_shop/maxed_focused.png")

func _ready():
	buy_button.pressed.connect(_on_buy_button_pressed)
	title_label.text = upgrade_name
	icon.texture = icon_texture

func _on_buy_button_pressed():
	if not is_unlocked or current_level >= max_level or SaveManager.current_save.pearls < current_cost:
		AudioManager.play_sound_2d("menu_press", Vector2.ZERO)
		return
	buy_requested.emit(upgrade_id, current_cost)

func play_unlock_anim(delay: float) -> void:
	AudioManager.play_sound_2d("pearl_shop_unlock", Vector2.ZERO)

	if not lock_overlay.visible:
		return
		
	var tween = create_tween()
	# Optional small delay
	if delay > 0:
		tween.tween_interval(delay)
		
	# Drop and fade out parallel
	tween.tween_property(lock_overlay, "modulate", Color(1, 1, 1, 0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(lock_overlay, "position:y", lock_overlay.position.y + 20, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(func(): lock_overlay.visible = false)

func update_node(anim_delay: float = 0.0, is_initial_load: bool = false) -> void:
	# 1. Get current level from save data
	current_level = SaveManager.current_save.get("upgrade_" + upgrade_id + "_level")
	if current_level == null: 
		push_error("Pearl shop: Can't find " + upgrade_id + " in save")
		current_level = 0 
	
	if UpgradeManager.has_method("get_cost_" + upgrade_id):
		current_cost = UpgradeManager.call("get_cost_" + upgrade_id, current_level)
	else:
		current_cost = UpgradeManager.get_default_cost(current_level)
		
	level_label.text = str(current_level) + "/" + str(max_level)
	if price_label:
		price_label.text = str(current_cost)
	
	# 2. Check Unlock Condition 
	if parent_node == null:
		is_unlocked = true # Root nodes are always unlocked
	else:
		var parent_level = SaveManager.current_save.get("upgrade_" + parent_node.upgrade_id + "_level")
		is_unlocked = (parent_level != null and parent_level >= parent_node_unlock_level)
		
	# Check for new unlock BEFORE setting UI
	var is_newly_unlocked = false
	if is_unlocked and not was_unlocked_preview and not is_initial_load:
		is_newly_unlocked = true
	
	# Store the current unlock state for the next check
	was_unlocked_preview = is_unlocked
		
	# 3. Visual Updates
	modulate = Color.WHITE 
	
	buy_button.disabled = false
	
	if not is_unlocked:
		lock_overlay.visible = true
		price_label.visible = false
		lock_overlay.modulate = Color.WHITE
		lock_overlay.position.y = 0
		icon.modulate = Color(1, 1, 1, 0.1)
		_set_button_textures(TEX_LOCKED, TEX_LOCKED_HOVERED, TEX_LOCKED_FOCUSED)
		_set_labels_color(Color(0.5, 0.5, 0.5, 1.0))
	else:
		price_label.visible = true
		if is_newly_unlocked and lock_overlay.visible:
			play_unlock_anim(anim_delay)
		else:
			lock_overlay.visible = false
			lock_overlay.modulate = Color(1, 1, 1, 1)
			lock_overlay.position.y = 0
		
		if current_level >= max_level:
			level_label.text = "MAX"
			_set_button_textures(TEX_MAXED, TEX_MAXED_HOVERED, TEX_MAXED_FOCUSED)
			_set_labels_color(Color.WHITE)
			price_label.visible = false
			icon.modulate = Color(1, 1, 1, 0.3)
		elif SaveManager.current_save.pearls < current_cost:
			_set_button_textures(TEX_TOO_EXPENSIVE, TEX_TOO_EXPENSIVE_HOVERED, TEX_TOO_EXPENSIVE_FOCUSED)
			_set_labels_color(Color(0.75, 0.75, 0.75, 1.0))
			icon.modulate = Color(1, 1, 1, 0.2)
		else:
			_set_button_textures(TEX_NORMAL, TEX_NORMAL_HOVERED, TEX_NORMAL_FOCUSED)
			_set_labels_color(Color.WHITE)
			icon.modulate = Color(1, 1, 1, 0.3)

func _set_button_textures(base: Texture2D, hover: Texture2D, focused: Texture2D) -> void:
	buy_button.texture_normal = base
	buy_button.texture_pressed = base
	buy_button.texture_hover = hover
	buy_button.texture_disabled = base
	buy_button.texture_focused = focused

func _set_labels_color(color: Color) -> void:
	title_label.modulate = color
	level_label.modulate = color
	price_label.modulate = color
