extends Control

signal buy_requested(node: Control)

@export var upgrade_id: String = "health"
@export var max_level: int = 3
@export var base_cost: int = 1
@export var parent_node: Control 

var current_level: int = 0
var current_cost: int = 0
var is_unlocked: bool = false

@onready var buy_button = $TextureButton
@onready var level_label = $VBoxContainer/Level
@onready var price_label = $VBoxContainer/HBoxContainer/Price
func _ready():
	buy_button.pressed.connect(func(): buy_requested.emit(self))

func update_node(save_data: SaveData) -> void:
	# 1. Get current level from save data
	current_level = save_data.get("upgrade_" + upgrade_id + "_level")
	if current_level == null: current_level = 0 # Fallback
	
	current_cost = base_cost + (current_level * 1) # Adjust your math here!
	level_label.text = str(current_level) + "/" + str(max_level)
	
	# 2. Check Unlock Condition (Parent must be at least level 1)
	if parent_node == null:
		is_unlocked = true # Root nodes are always unlocked
	else:
		# Check the parent's level dynamically
		var parent_level = save_data.get("upgrade_" + parent_node.upgrade_id + "_level")
		is_unlocked = (parent_level != null and parent_level > 0)
		
	# 3. Visual Updates
	if not is_unlocked:
		modulate = Color(0.2, 0.2, 0.2, 1.0) # Dark and locked
		buy_button.disabled = true
	elif current_level >= max_level:
		modulate = Color(1.0, 0.84, 0.0, 1.0) # Gold/Maxed out
		buy_button.disabled = true
		level_label.text = "MAX"
	else:
		modulate = Color.WHITE # Available to buy
		buy_button.disabled = (save_data.pearls < current_cost)
