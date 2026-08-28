extends Node

signal xp_changed()
signal health_changed()
signal pearls_changed()
signal initialize()
signal start_game()
signal resume_game()
signal level_up()

signal GameOver()
signal Retry()

# Boss signal
signal boss_health_changed(maxHp : int, currentHp : int)
signal boss_araignee_vaincu()
signal boss_poisson_vaincu()
signal gambos_devenu_roi()

signal kill_registered(enemy_path: String)

var skip_menu: bool = false
var gotoshop: bool = false
var gotoshop_from_tutorial: bool = false
var in_game: bool = false
var game_played_with_controller: bool = true
var auto_hide_cursor: bool = false

var _mouse_idle_timer: float = 0.0
const MOUSE_HIDE_DELAY: float = 3.0
var _last_mouse_pos: Vector2 = Vector2.ZERO
var menu_cursor: Texture2D = load("res://assets/sprites/cursor/cursor.png")
var in_game_cursor: Texture2D = load("res://assets/sprites/cursor/in_game_sable.png")

func _ready() -> void:
	set_process(true)
	
	# Check for controllers
	game_played_with_controller = Input.get_connected_joypads().size() >= 1
	Input.joy_connection_changed.connect(manage_controller_connection)
	
func _process(delta: float) -> void:
	if game_played_with_controller or auto_hide_cursor:
		# Hide mouse cursor after MOUSE_HIDE_DELAY seconds of inactivity
		var current_mouse_pos: Vector2 = get_viewport().get_mouse_position()
		
		if current_mouse_pos != _last_mouse_pos:
			_last_mouse_pos = current_mouse_pos
			_mouse_idle_timer = MOUSE_HIDE_DELAY
			if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				
		if _mouse_idle_timer > 0.0:
			_mouse_idle_timer -= delta
			if _mouse_idle_timer <= 0.0:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func joy_vibration(device: int, weak_magnitude: float, strong_magnitude: float, duration: float = 0.0) -> void:
	var strength = SaveManager.current_save.setting_haptic_strength
	if strength > 0.0:
		Input.start_joy_vibration(device, weak_magnitude * strength, strong_magnitude * strength, duration)
		
func manage_controller_connection():
	game_played_with_controller = Input.get_connected_joypads().size() >= 1

func enable_menu_cursor():
	auto_hide_cursor = false
	if SaveManager.current_save.use_custom_cursors:
		Input.set_custom_mouse_cursor(menu_cursor)
	else:
		Input.set_custom_mouse_cursor(null)
		
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func enable_in_game_cursor():
	if SaveManager.current_save.use_custom_cursors:
		if SaveManager.current_save.mondes_completes_total >= 1:
			auto_hide_cursor = false
			Input.set_custom_mouse_cursor(in_game_cursor)
		else:
			auto_hide_cursor = true
			Input.set_custom_mouse_cursor(menu_cursor)
	else:
		auto_hide_cursor = true
		Input.set_custom_mouse_cursor(null)
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

var run_enemy_kill_counts: Dictionary = {}   # remis à zéro à chaque run

func register_enemy_kill(data: EnemyData) -> void:
	if data == null:
		return
	var key := data.resource_path
	run_enemy_kill_counts[key] = run_enemy_kill_counts.get(key, 0) + 1
	kill_registered.emit(key)

func reset_run_kill_counts() -> void:
	run_enemy_kill_counts.clear()

func get_total_kill_count(data: EnemyData) -> int:
	if data == null:
		return 0
	var key := data.resource_path
	var saved: int = SaveManager.current_save.enemy_kill_counts.get(key, 0)
	var run: int = run_enemy_kill_counts.get(key, 0)
	return saved + run

## Fusionne les kills de la run en cours dans la save (à appeler à la fin d'une partie)
func flush_kill_counts_to_save() -> void:
	for key in run_enemy_kill_counts:
		var prev: int = SaveManager.current_save.enemy_kill_counts.get(key, 0)
		SaveManager.current_save.enemy_kill_counts[key] = prev + run_enemy_kill_counts[key]
	run_enemy_kill_counts.clear()
