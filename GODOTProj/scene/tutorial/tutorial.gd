extends Node2D

enum State { INIT, INIT_WALK, PHASE1, HEAVEN1, PHASE2, HEAVEN2, END }
var current_state: State = State.INIT

@export var tuto_map_scene: PackedScene = preload("res://scene/tutorial/TutoMap.tscn")
@export var heaven_scene: PackedScene = preload("res://scene/tutorial/ShrimpHeaven.tscn")
@export var player_scene: PackedScene = preload("res://scene/player/player.tscn")
@export var dialogue_scene: PackedScene = preload("res://scene/tutorial/tutorial_dialogue.tscn")
@export var enemy_scene: PackedScene = preload("res://scene/enemy/enemy.tscn")
@export var enemy_stats: Resource = preload("res://ressources/enemy/Crab.tres")
@export var hud_scene: PackedScene = preload("res://scene/tutorial/hud.tscn")

var current_map: Node = null
var current_player: Node2D = null
var current_hud: Control = null
var spawned_enemies: Array = []

var init_walk_dialog: CanvasLayer = null
var init_walk_overlay: CanvasLayer = null
var init_walk_start_pos: Vector2 = Vector2.ZERO
var init_walk_ready: bool = false
var is_healing: bool = false

func _ready() -> void:
	call_deferred("start_init_walk")

func clear_scene() -> void:
	if current_map:
		if current_map.get_parent() is CanvasLayer:
			current_map.get_parent().queue_free()
		else:
			current_map.queue_free()
		current_map = null
	if current_player:
		if current_player.has_node("Camera"):
			current_player.get_node("Camera").enabled = false
		current_player.queue_free()
		current_player = null
	if current_hud:
		current_hud.queue_free()
		current_hud = null
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()
	for pearl in get_tree().get_nodes_in_group("Collectible"):
		pearl.queue_free()

func spawn_hud() -> void:
	current_hud = hud_scene.instantiate()
	var canvas = CanvasLayer.new()
	canvas.add_child(current_hud)
	add_child(canvas)
	
	current_hud.Stats = current_player.Stats
	current_hud._update_health_bar()

func start_init_walk() -> void:
	current_state = State.INIT_WALK
	clear_scene()
	
	if tuto_map_scene:
		current_map = tuto_map_scene.instantiate()
		add_child(current_map)
	
	current_player = player_scene.instantiate()
	current_map.add_child(current_player)
	current_player.can_shoot = false
	current_player.global_position = Vector2(1050, 575) # Porte de lka maison
	current_player.y_sort_enabled = true
	init_walk_ready = false
	
	var collect_shape = current_player.get_node_or_null("Area2D/PlayerCollectRadius")
	if collect_shape and collect_shape.shape is CircleShape2D:
		var new_shape = collect_shape.shape.duplicate()
		new_shape.radius = 10000.0
		collect_shape.shape = new_shape
	
	spawn_hud()
	
	GameManager.GameOver.connect(_on_player_died_phase1)
	
	AudioManager.play_sound_2d("door_close", Vector2.ZERO)
	
	var fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 120
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_canvas.add_child(fade_rect)
	add_child(fade_canvas)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.5)
	tween.tween_callback(fade_canvas.queue_free)
	
	var walk_dest = Vector2(1000, 600)
	var walk_tween = create_tween()
	walk_tween.tween_property(current_player, "global_position", walk_dest, 1.5)
	walk_tween.tween_callback(func():
		init_walk_start_pos = current_player.global_position
		init_walk_ready = true
	)
	
	init_walk_dialog = dialogue_scene.instantiate()
	add_child(init_walk_dialog)
	var text_array: Array[String] = ["Quelle belle journée ! Ça nous ferait pas de mal de marcher un peu."]
	init_walk_dialog.start_dialogue(text_array, false, true)
	
	init_walk_overlay = CanvasLayer.new()
	var textures = [
		load("res://assets/sprites/tutorial/xbox_left_up.png"),
		load("res://assets/sprites/tutorial/xbox_left_right.png"),
		load("res://assets/sprites/tutorial/xbox_left_down.png"),
		load("res://assets/sprites/tutorial/xbox_left_left.png")
	]
	var overlay_rect = TextureRect.new()
	overlay_rect.name = "OverlayRect"
	overlay_rect.texture = textures[0]
	overlay_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay_rect.custom_minimum_size = Vector2(64, 64)
	overlay_rect.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	overlay_rect.offset_left = -32
	overlay_rect.offset_right = 32
	overlay_rect.offset_bottom = -228
	overlay_rect.offset_top = -325
	overlay_rect.modulate.a = 0.0 # start hidden
	init_walk_overlay.add_child(overlay_rect)
	
	var overlay_timer = Timer.new()
	overlay_timer.wait_time = 1.0
	overlay_timer.autostart = true
	var idx_ref = [0]
	overlay_timer.timeout.connect(func():
		if is_instance_valid(overlay_rect):
			idx_ref[0] = (idx_ref[0] + 1) % 4
			overlay_rect.texture = textures[idx_ref[0]]
	)
	init_walk_overlay.add_child(overlay_timer)
	add_child(init_walk_overlay)
	
	var overlay_fade_tween = create_tween()
	overlay_fade_tween.tween_interval(3.5) 
	overlay_fade_tween.tween_property(overlay_rect, "modulate:a", 1.0, 0.5)
	
	set_process(true)

func start_phase1() -> void:
	current_state = State.PHASE1
	AudioManager.play_music("map1")
	
	spawn_enemies(5)
	
	var dialog = dialogue_scene.instantiate()
	add_child(dialog)
	var text_array: Array[String] = [
		"Oh non ! Le gang des crabes nous attaque, fuyons !"
	]
	dialog.start_dialogue(text_array, true)

func spawn_enemies(count: int) -> void:
	for i in range(count):
		var enemy = enemy_scene.instantiate()
		var custom_stats = enemy_stats.duplicate()
		custom_stats.attack_damage = 2
		custom_stats.max_hp = 1
		enemy.stats = custom_stats
		enemy.tutorial_mode = true
		enemy.z_index = 1
		current_map.add_child(enemy)
		var spawn_pos = Vector2.ZERO
		var valid = false
		for attempt in range(100):
			spawn_pos = Vector2(
				randf_range(50, 1792 - 50),
				randf_range(50, 1024 - 50)
			)
			var dx = abs(spawn_pos.x - current_player.global_position.x)
			var dy = abs(spawn_pos.y - current_player.global_position.y)
			if dx > 680 or dy > 400:
				valid = true
				break
		
		if not valid:
			spawn_pos = Vector2(100, 100)
			
		enemy.global_position = spawn_pos
		spawned_enemies.append(enemy)

func _on_player_died_phase1() -> void:
	GameManager.GameOver.disconnect(_on_player_died_phase1)
	_transition_to_heaven1()

func _transition_to_heaven1() -> void:
	var fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 120
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_canvas.add_child(fade_rect)
	add_child(fade_canvas)
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# 2 seconds fade to black
	tween.tween_property(fade_rect, "color:a", 1.0, 2.0)
	
	# shrimp_heaven music starts
	tween.tween_callback(func(): AudioManager.play_music("shrimp_heaven"))
	
	# 0.5 second fade from black to white
	tween.tween_property(fade_rect, "color", Color(1, 1, 1, 1), 0.5)
	
	# Load heaven scene
	tween.tween_callback(func(): start_heaven1())
	
	# 3 seconds fade from white to transparent
	tween.tween_property(fade_rect, "color:a", 0.0, 3.0)
	tween.tween_callback(fade_canvas.queue_free)

func start_heaven1() -> void:
	current_state = State.HEAVEN1
	clear_scene()
	
	if heaven_scene:
		current_map = heaven_scene.instantiate()
		var canvas = CanvasLayer.new()
		canvas.add_child(current_map)
		add_child(canvas)
	
	var dialog = dialogue_scene.instantiate()
	add_child(dialog)
	var text_array: Array[String] = [
		"Mon cher Gambos, tu as péri.",
		"Pas d'inquiétude ! Je suis Naïades, ta déesse, et tu es au paradis, en sécurité.",
		"Tu ne resteras pas ici longtemps cependant. Un destin héroïque t'attend sur Terre.",
		"Gambos, tu es l'élu du peuple des crevettes. Tu vas montrer au monde entier que notre espèce n'a rien d'inférieur.",
		"Je vais t'aider dans ta quête. Je serai constamment à tes côtés pendant que tu combats pour la dignité de notre peuple.",
		"Je te confie l'attaque bulle [img=24]res://assets/sprites/projectile/bubble_icon.png[/img]. Elle te permettra de prendre ta revanche face à ces vilains crabes. Dorénavant, tu peux aussi nager plus vite.",
		"Je te renvoie sur Terre, pour que tu essayes tes nouvelles capacités !"
	]
	dialog.start_dialogue(text_array)
	dialog.dialogue_finished.connect(_transition_to_phase2, CONNECT_ONE_SHOT)

func _transition_to_phase2() -> void:
	var fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 120
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_canvas.add_child(fade_rect)
	add_child(fade_canvas)
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	tween.tween_callback(func():
		AudioManager.play_music("map1")
		start_phase2()
	)
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)
	tween.tween_callback(fade_canvas.queue_free)

func start_phase2() -> void:
	current_state = State.PHASE2
	clear_scene()
	
	if tuto_map_scene:
		current_map = tuto_map_scene.instantiate()
		add_child(current_map)
	
	current_player = player_scene.instantiate()
	current_map.add_child(current_player)
	current_player.can_shoot = false # Disabled while falling
	current_player.prevent_death = true
	
	var target_pos = Vector2(1159 - 200, 480)
	current_player.global_position = target_pos - Vector2(0, 200)
	
	# Pause player physics while falling
	current_player.set_physics_process(false)
	current_player.set_process(false)
	
	var sprite = current_player.get_node("AnimatedSprite2D")
	sprite.modulate.a = 0.0
	sprite.play_backwards("death")
	
	var spawn_tween = create_tween().set_parallel(true)
	spawn_tween.tween_property(current_player, "global_position:y", target_pos.y, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	spawn_tween.tween_property(sprite, "modulate:a", 1.0, 2.0)\
		.set_ease(Tween.EASE_OUT)
	
	spawn_tween.chain().tween_callback(func():
		if is_instance_valid(current_player):
			current_player.set_physics_process(true)
			current_player.set_process(true)
			current_player.can_shoot = true
			current_player.get_node("AnimatedSprite2D").play("walk")
			GameManager.joy_vibration(0, 0.5, 0.5, 0.3)
	)
	
	current_player.Stats.current_health = current_player.Stats.max_health
	current_player.Stats.speed = 150
	
	var collect_shape = current_player.get_node_or_null("Area2D/PlayerCollectRadius")
	if collect_shape and collect_shape.shape is CircleShape2D:
		var new_shape = collect_shape.shape.duplicate()
		new_shape.radius = 10000.0
		collect_shape.shape = new_shape
	
	spawn_hud()
	
	spawn_enemies(5)
	set_process(true)

func _process(delta: float) -> void:
	if current_hud:
		current_hud._update_health_bar()
	
	if current_state == State.INIT_WALK and init_walk_ready:
		if is_instance_valid(current_player) and current_player.global_position.distance_to(init_walk_start_pos) > 100.0:
			if is_instance_valid(init_walk_dialog):
				init_walk_dialog._finish()
				init_walk_dialog = null
			if is_instance_valid(init_walk_overlay):
				var overlay_rect = init_walk_overlay.get_node_or_null("OverlayRect")
				if overlay_rect:
					var overlay_tween = create_tween()
					overlay_tween.tween_property(overlay_rect, "modulate:a", 0.0, 0.3)
					# Keep the reference alive long enough to finish the tween
					var temp_overlay = init_walk_overlay
					overlay_tween.tween_callback(temp_overlay.queue_free)
				else:
					init_walk_overlay.queue_free()
				init_walk_overlay = null
			start_phase1()
	
	if current_state == State.PHASE2:
		if is_instance_valid(current_player) and current_player.Stats.current_health <= 2.0:
			if not is_healing:
				is_healing = true
				current_player.Stats.current_health = current_player.Stats.max_health
				current_player.start_invincibility()
				AudioManager.play_sound_2d("health_refill", current_player.global_position)
				var tween = create_tween()
				tween.tween_property(current_player.get_node("AnimatedSprite2D"), "modulate", Color(0.5, 1.0, 0.5), 0.2)
				tween.tween_property(current_player.get_node("AnimatedSprite2D"), "modulate", Color.WHITE, 0.2)
				tween.tween_callback(func(): is_healing = false)
		
		var enemies_alive = false
		for enemy in spawned_enemies:
			if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
				enemies_alive = true
				break
		
		if not enemies_alive and spawned_enemies.size() > 0:
			set_process(false)
			await get_tree().create_timer(3.0).timeout
			_transition_to_heaven2()

func _transition_to_heaven2() -> void:
	var fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 120
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(1, 1, 1, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_canvas.add_child(fade_rect)
	add_child(fade_canvas)
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	tween.tween_callback(func():
		AudioManager.play_music("shrimp_heaven_full")
		start_heaven2()
	)
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)
	tween.tween_callback(fade_canvas.queue_free)

func start_heaven2() -> void:
	current_state = State.HEAVEN2
	clear_scene()
	
	if heaven_scene:
		current_map = heaven_scene.instantiate()
		var canvas = CanvasLayer.new()
		canvas.add_child(current_map)
		add_child(canvas)
	
	var dialog = dialogue_scene.instantiate()
	add_child(dialog)
	var text_array: Array[String] = [
		"Félicitations, Gambos ! Tu as été extraordinaire. Je pense que tu es prêt pour ton aventure héroïque.",
		"Ces perles [img=24]res://assets/sprites/collectibles/pearl_icon.png[/img] que tu as pu ramasser sont très précieuses. Tu pourras m'en confier pour que je t'aide à devenir plus puissant.",
		"Attends-toi à revenir me voir fréquemment ! La tâche ne sera pas simple. Je serai toujours là pour t'aider à être encore meilleur.",
		"Durant ta quête, tu pourras aussi récolter des algues [img=24]res://assets/sprites/collectibles/SeaweedXP_Idle1.png[/img]. Elles te permettront de devenir de plus en plus fort, mais leurs effets ne restent pas entre tes multiples vies.",
		"Maintenant, assez discuté ! Viens au temple pour me confier des perles et gagner en force."
	]
	dialog.start_dialogue(text_array)
	dialog.dialogue_finished.connect(end_tutorial, CONNECT_ONE_SHOT)

func end_tutorial() -> void:
	current_state = State.END
	SaveManager.current_save.tutorial_completed = true
	SaveManager.current_save.pearls += 5 # Force 5 pearls
	SaveManager.save_game()
	
	GameManager.gotoshop = true
	GameManager.gotoshop_from_tutorial = true
	get_tree().change_scene_to_file("res://scene/main.tscn")
