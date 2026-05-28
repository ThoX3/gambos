extends Control

signal buy_requested(node: Control)

@export var upgrade_id: String = "health"
@export var max_level: int = 3
@export var base_cost: int = 1
@export var parent_node: Control 
@export var arc_to_parent: Control

var current_level: int = 0
var current_cost: int = 0
var is_unlocked: bool = false

@onready var buy_button = $TextureButton
@onready var level_label = $VBoxContainer/Level
@onready var price_label = $VBoxContainer/HBoxContainer/Price


func _ready():
	buy_button.pressed.connect(func(): buy_requested.emit(self))

func update_node() -> void:
	# 1. Get current level from save data
	current_level = SaveManager.current_save.get("upgrade_" + upgrade_id + "_level")
	if current_level == null: current_level = 0 # Fallback
	
	current_cost = base_cost + (current_level * 1) # Adjust your math here!
	level_label.text = str(current_level) + "/" + str(max_level)
	
	# 2. Check Unlock Condition (Parent must be at least level 1)
	if parent_node == null:
		is_unlocked = true # Root nodes are always unlocked
	else:
		# Check the parent's level dynamically
		var parent_level = SaveManager.current_save.get("upgrade_" + parent_node.upgrade_id + "_level")
		is_unlocked = (parent_level != null and parent_level > 0)
		
	# 3. Visual Updates
	if not is_unlocked:
		modulate = Color(0.2, 0.2, 0.2, 1.0) 
		buy_button.disabled = true
	elif current_level >= max_level:
		modulate = Color(1.0, 0.84, 0.0, 1.0) 
		buy_button.disabled = true
		level_label.text = "MAX"
	else:
		modulate = Color.WHITE 
		buy_button.disabled = (SaveManager.current_save.pearls < current_cost)
