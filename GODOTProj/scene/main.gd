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

var center: Vector2 = Vector2(1312.0, 736.0)

func _ready() -> void:
	if not (starting_map and player_scene):
		push_error("Main: Missing Player or Starting Map in the Inspector!")
		
	GameManager.start_game.connect(_on_start)
	
	$UI/MainMenu.pearl_shop_button_pressed.connect(open_pearl_shop)
	$UI/MainMenu.bestiary_button_pressed.connect(open_bestiary)
	$UI/PearlShop.menu_button_pressed.connect(open_main_menu)
	$UI/Bestiary.back_button_pressed.connect(open_main_menu)
	%GameOver.quit_button_pressed.connect(game_over)
	
	if GameManager.skip_menu:
		GameManager.skip_menu = false
		_on_start()
	else:
		if GameManager.gotoshop:
			GameManager.gotoshop = false
			open_pearl_shop(true)
		else:
			open_main_menu()

func start_game(map_to_load: PackedScene) -> void:
	_clear_world()
	
	current_player = player_scene.instantiate()
	game_world.add_child(current_player)
	current_player.transform = Transform2D(Vector2(1,0), Vector2(0,1), center)
	
	if SaveManager.current_save:
		current_player.apply_pearl_upgrades(SaveManager.current_save)
	
	if current_player.has_signal("health_depleted"):
		current_player.health_depleted.connect(_on_player_health_depleted)
	
	current_map = map_to_load.instantiate()
	game_world.add_child(current_map)
	
	# Hide any left menu
	for child in ui_layer.get_children():
		if child is Control:
			child.visible = false 
			
	# Refresh HUD
	$UI/Hud._on_start()
	$UI/Hud.visible = true
	
	# Start WaveManager + connect vague_terminee pour la sauvegarde
	var wm: Node = $World/WaveManager
	wm.start_waves()
	if not wm.vague_terminee.is_connected(_on_vague_terminee):
		wm.vague_terminee.connect(_on_vague_terminee)

func _on_vague_terminee(numero: int) -> void:
	# Met à jour la vague max si on bat le record
	if SaveManager.current_save and numero > SaveManager.current_save.max_wave_reached:
		SaveManager.current_save.max_wave_reached = numero
		SaveManager.save_game()
		print("Nouveau record de vague : ", numero)

func change_level(new_map_scene: PackedScene) -> void:
	if current_map:
		current_map.queue_free()
	if new_map_scene:
		current_map = new_map_scene.instantiate()
		game_world.add_child(current_map)

func _clear_world() -> void:
	if current_player:
		current_player.queue_free()
	if current_map:
		current_map.queue_free()
		
func _on_player_health_depleted():
	SaveManager.current_save.pearls += current_player.Stats.collected_pearls
	SaveManager.save_game()
	GameManager.gotoshop = true
	get_tree().reload_current_scene()
	
func _on_start():
	start_game(starting_map)

func show_menu(menu_to_show: Control) -> void:
	for child in ui_layer.get_children():
		if child is Control:
			child.visible = false 
	menu_to_show.visible = true

func open_pearl_shop(is_from_game_over : bool) -> void:
	AudioManager.play_music("shop")
	show_menu($UI/PearlShop)
	$UI/PearlShop.was_opened_from_game_over(is_from_game_over)
	$UI/PearlShop.refresh_shop()

func open_main_menu() -> void:
	show_menu($UI/MainMenu)

func open_bestiary() -> void:
	show_menu($UI/Bestiary)
	$UI/Bestiary.setup(SaveManager.current_save.max_wave_reached)
	
func game_over():
	SaveManager.save_game()
	get_tree().paused = false
	get_tree().reload_current_scene()
