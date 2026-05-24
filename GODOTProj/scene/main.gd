extends Node

# --- SCENE REFERENCES ---
@export_group("Game Scenes")
@export var player_scene: PackedScene
@export var starting_map: PackedScene

# --- NODE REFERENCES ---
@onready var game_world: Node2D = $World
@onready var ui_layer: CanvasLayer = $UI

# --- STATE TRACKING ---
var current_player: CharacterBody2D = null
var current_map: Node2D = null

# --- SAVES ---
const SAVE_PATH = "user://gambos/save.tres"
var current_save: SaveData

var center: Vector2 = Vector2(1312.0, 736.0)

func _ready() -> void:
	load_game()
	
	# For now, immediately launch into the game.
	# Later, you will replace this with a function that shows the Main Menu.
	if starting_map and player_scene:
		start_game(starting_map)
	else:
		push_error("Main: Missing Player or Starting Map in the Inspector!")
		
	GameManager.start_game.connect(_on_start)

func start_game(map_to_load: PackedScene) -> void:
	_clear_world()
	
	# 1. Instantiate and add the Player
	current_player = player_scene.instantiate()
	game_world.add_child(current_player)
	current_player.transform = Transform2D(Vector2(1,0), Vector2(0,1), center)
	
	if current_player.has_signal("health_depleted"):
		current_player.health_depleted.connect(_on_player_health_depleted)
	
	# 2. Instantiate and add the Map 
	current_map = map_to_load.instantiate()
	game_world.add_child(current_map)
	
	# The GameWorld now holds both the Player and the Map side-by-side!

func change_level(new_map_scene: PackedScene) -> void:
	# 1. Remove the old map
	if current_map:
		current_map.queue_free()
		
	# 2. Load the new map
	if new_map_scene:
		current_map = new_map_scene.instantiate()
		game_world.add_child(current_map)
		
	# Note: The player is completely untouched during this transition!
	# You would likely reset their position to Vector2.ZERO here.

func _clear_world() -> void:
	# Wipes the game clean (useful for "Restarting" after a Game Over)
	if current_player:
		current_player.queue_free()
	if current_map:
		current_map.queue_free()
		
func _on_player_health_depleted():
	%GameOver/LayerGameOver.visible = true
	current_save.pearls += current_player.Stats.collected_pearls
	save_game()
	get_tree().paused = true
	
func _on_start():
	start_game(starting_map)
	
func save_game() -> void:
	var result = ResourceSaver.save(current_save, SAVE_PATH)
	
	if result == OK:
		print("Game saved successfully!")
	else:
		push_error("Failed to save game.")

func load_game() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		current_save = ResourceLoader.load(SAVE_PATH) as SaveData
		print("Save loaded! Peals: ", current_save.pearls)
	else:
		current_save = SaveData.new()
		print("No save found. Created new save profile.")
		
