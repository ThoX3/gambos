extends PanelContainer

signal buy_requested(upgrade_id: String, cost: int)

# --- INSPECTOR SETTINGS ---
@export var upgrade_id: String = "health" 
@export var title_text: String = "Vie"
@export var base_cost: int = 100
@export var cost_multiplier: float = 0.5

# --- NODE REFERENCES ---
@onready var title_label = $MarginContainer/HBoxContainer/Title
@onready var level_label = $MarginContainer/HBoxContainer/CurrentValue
@onready var buy_button = $MarginContainer/HBoxContainer/Button

var current_cost: int = 0

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	title_label.text = title_text

func update_card(current_level: int, player_pearls: int) -> void:
	current_cost = base_cost + int(base_cost * current_level * cost_multiplier)
	
	level_label.text = "Niveau : " + str(current_level)
	buy_button.text = "Acheter (" + str(current_cost) + " perles)"
	
	buy_button.disabled = player_pearls < current_cost

func _on_buy_pressed() -> void:
	buy_requested.emit(upgrade_id, current_cost)
