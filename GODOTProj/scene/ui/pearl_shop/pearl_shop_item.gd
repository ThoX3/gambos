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
@onready var rich_text = $MarginContainer/HBoxContainer/Button/RichTextLabel

var current_cost: int = 0

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	title_label.text = title_text
	rich_text.scroll_active = false

func update_card(current_level: int, player_pearls: int) -> void:
	current_cost = base_cost + int(base_cost * current_level * cost_multiplier)
	
	level_label.text = "Niveau : " + str(current_level)
	var bbcode_string = "[center]Acheter pour " + str(current_cost) + " [img=32]res://assets/sprites/collectibles/pearl_icon.png[/img][/center]"	
	rich_text.text = bbcode_string
	buy_button.disabled = player_pearls < current_cost
	if buy_button.disabled:
		rich_text.modulate.a = 0.5
	else:
		rich_text.modulate.a = 1.0

func _on_buy_pressed() -> void:
	buy_requested.emit(upgrade_id, current_cost)
