extends Node

# --- SCENE REFERENCES ---
@export_group("Game Scenes")
@export var player_scene: PackedScene
@export var starting_map: PackedScene

# --- NODE REFERENCES ---
@onready var game_world: Node2D = $World
@onready var ui_layer: CanvasLayer = $UI
@onready var fade_rect: ColorRect = $UI/FadeRect

# --- STATE TRACKING ---
var current_player: CharacterBody2D = null
var current_map: Node2D = null

var center: Vector2 = Vector2(1312.0, 736.0)

func _ready() -> void:
	if not (starting_map and player_scene):
		push_error("Main: Missing Player or Starting Map in the Inspector!")
		
	GameManager.start_game.connect(_on_start)
	GameManager.resume_game.connect(_on_resume)
	
	$UI/MainMenu.pearl_shop_button_pressed.connect(open_pearl_shop)
	$UI/MainMenu.bestiary_button_pressed.connect(open_bestiary)
	$UI/PearlShop.menu_button_pressed.connect(open_main_menu)
	%pause_menu.menu_button_pressed.connect(open_main_menu_from_pause)
	$UI/pause_menu.bestiary_button_pressed.connect(open_bestiary_from_pause)
	$UI/Bestiary.back_button_pressed.connect(_on_bestiary_back)
	$UI/MenuTransition.continuer_pressed.connect(_on_continuer)
	$World/WorldManager.monde_change.connect(_on_monde_change)
	
	if GameManager.skip_menu:
		GameManager.skip_menu = false
		_on_start()
	else:
		if GameManager.gotoshop:
			GameManager.gotoshop = false
			open_pearl_shop(true)
		else:
			open_main_menu()

func setup_game_environment() -> void:
	_clear_world()
	
	current_player = player_scene.instantiate()
	game_world.add_child(current_player)
	current_player.transform = Transform2D(Vector2(1,0), Vector2(0,1), center)
	
	if not GameManager.GameOver.is_connected(_on_GameOver):
		GameManager.GameOver.connect(_on_GameOver)
	
	# Hide any left menu
	for child in ui_layer.get_children():
		if child is Control:
			child.visible = false 
			
	# Refresh HUD
	$UI/Hud._on_start()
	$UI/Hud.visible = true
	
	var wm: Node = $World/WaveManager
	if not wm.vague_terminee.is_connected(_on_vague_terminee):
		wm.vague_terminee.connect(_on_vague_terminee)
	if not wm.monde_termine.is_connected(_on_monde_termine):
		wm.monde_termine.connect(_on_monde_termine)

func start_game(map_to_load: PackedScene) -> void:
	SaveManager.current_save.run_en_cours = false
	SaveManager.current_save.run_player_stats = null
	
	setup_game_environment()
	
	current_map = map_to_load.instantiate()
	game_world.add_child(current_map)
	
	$World/WorldManager._index_monde_courant = 0
	$World/WaveManager.start_waves()

func _on_resume() -> void:
	GameManager.in_game = true
	setup_game_environment()
	$World/WorldManager.demarrer_depuis_sauvegarde()

func _on_monde_termine(_vague: int) -> void:
	var monde_suivant = $World/WorldManager.get_nom_monde_suivant()
	if monde_suivant:
		$UI/MenuTransition.afficher(monde_suivant)
	else:
		$UI/MenuTransition.afficher("Mode Infini")

func _on_vague_terminee(numero: int) -> void:
	# Met à jour la vague max si on bat le record
	if numero > SaveManager.current_save.max_wave_reached:
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
		
func _on_GameOver():
	SaveManager.current_save.run_en_cours = false
	SaveManager.current_save.run_player_stats = null
	SaveManager.current_save.pearls += current_player.Stats.collected_pearls
	SaveManager.save_game()
	GameManager.gotoshop = true
	
	fade_rect.color   = Color(0, 0, 0, 0)  # repart toujours de transparent
	fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.5)
	tween.tween_callback(reload_level)

func reload_level():
	get_tree().reload_current_scene()
	
func _on_start():
	GameManager.in_game = true
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
	# On force le moteur à oublier l'ancien focus du jeu (ex: bouton de pause ou upgrade)
	get_viewport().gui_release_focus()
	$UI/MainMenu.setup_focus()

func open_bestiary() -> void:
	GameManager.in_game = false
	show_menu($UI/Bestiary)
	$UI/Bestiary.setup(SaveManager.current_save.max_wave_reached)
	
func open_bestiary_from_pause() -> void:
	# Déplace le bestiaire en dernier dans UI pour qu'il s'affiche au-dessus du menu pause
	GameManager.in_game = false
	var bestiary = $UI/Bestiary
	$UI.move_child(bestiary, $UI.get_child_count() - 1)
	bestiary.visible = true
	
	# Prend la vague la plus élevée entre le save et la vague en cours
	var vague_en_cours : int = $World/WaveManager.get_numero_vague()
	var vague_max : int = max(SaveManager.current_save.max_wave_reached, vague_en_cours)
	bestiary.setup_from_pause(vague_max)

func _on_bestiary_back() -> void:
	if $UI/Bestiary._from_pause:
		# Fermeture depuis la pause : on cache juste le bestiaire
		$UI/Bestiary.visible = false
		$UI/pause_menu.notify_bestiary_closed()
	else:
		# Fermeture depuis le menu principal : comportement d'avant
		open_main_menu()

func _on_continuer() -> void:
	SaveManager.current_save.run_en_cours = true
	SaveManager.current_save.run_player_stats = current_player.Stats.duplicate(true)
	$World/WorldManager.passer_monde_suivant()

func _on_monde_change(config: WorldConfig) -> void:
	change_level(config.map_scene)
	$World/WaveManager.spawn_config = config.spawn_config
	if config.vagues_par_monde > 0:
		$World/WaveManager.vagues_par_monde = config.vagues_par_monde
	else:
		$World/WaveManager.vagues_par_monde = 999999  # infini
	$World/WaveManager.start_waves(true)
	AudioManager.play_music(config.musique_id)

func open_main_menu_from_pause() -> void:
	GameManager.in_game = false
	SaveManager.current_save.run_en_cours = false
	SaveManager.current_save.run_player_stats = null
	SaveManager.current_save.pearls += current_player.Stats.collected_pearls
	SaveManager.save_game()
	get_tree().paused = false
	get_tree().reload_current_scene()
