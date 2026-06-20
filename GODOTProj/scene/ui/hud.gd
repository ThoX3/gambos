extends Control

@export var Stats = Resource

@export_group("Boss Healthbar Sprites")
@export var UnderCrab = CompressedTexture2D
@export var ProgressCrab = CompressedTexture2D
@export var UnderPuffer = CompressedTexture2D
@export var ProgressPuffer = CompressedTexture2D

@onready var pearl_box = $Pearls
@onready var pearl_label = $Pearls/MarginContainer/Count
@onready var wave_label = $Wave/Count
@onready var bossBar_progressBar = $HP_BossBar

var pearl_tween: Tween

func _ready() -> void:
	GameManager.xp_changed.connect(_update_progres_bar)
	GameManager.level_up.connect(_update_level)
	GameManager.health_changed.connect(_update_health_bar)
	GameManager.start_game.connect(_on_start)
	GameManager.pearls_changed.connect(_on_pearls_changed)
	GameManager.boss_health_changed.connect(_on_boss_health_changed)
	GameManager.boss_araignee_vaincu.connect(_on_boss_death)
	_update_progres_bar()
	%HP_Bar.max_value = Stats.max_health
	_update_health_bar()
	_update_level()
	pearl_box.modulate.a = 0
	pearl_box.visible = false
	
	if FontManager:
		if not FontManager.font_mode_changed.is_connected(_on_font_mode_changed):
			FontManager.font_mode_changed.connect(_on_font_mode_changed)
		_on_font_mode_changed(FontManager.is_modern_active)

func _on_start():
	_time_scale_index = 0
	Engine.time_scale = 1.0
	_update_health_bar()
	_update_progres_bar()
	_update_level()
	_set_wave_text(1)
	bossBar_progressBar.hide()
	
	# Connecte le signal du WaveManager
	var wm = get_tree().get_first_node_in_group("wave_manager")
	if wm and not wm.vague_demarree.is_connected(_on_vague_demarree):
		wm.vague_demarree.connect(_on_vague_demarree)
	
	_init_time_scales()

func _on_vague_demarree(numero: int) -> void:
	_set_wave_text(numero)
	if numero == 20:
		show_bossBar("Crab")
	if numero == 40:
		show_bossBar("Puffer")
	
func _set_wave_text(numero: int) -> void:
	var base_text = "Vague " + str(numero)
	var max_wave = SaveManager.current_save.max_wave_reached
	var sweep_rect = wave_label.get_node("SweepRect")
	
	if numero >= max_wave and max_wave > 0:
		wave_label.text = "[wave amp=20.0 freq=2.0 connected=0]" + base_text + "[/wave]"
		if sweep_rect.material:
			sweep_rect.material.set_shader_parameter("active", true)
	else:
		wave_label.text = base_text
		if sweep_rect.material:
			sweep_rect.material.set_shader_parameter("active", false)
	
func show_bossBar(Name: String):
	if Name == "Crab":
		bossBar_progressBar.texture_under = UnderCrab
		bossBar_progressBar.texture_progress = ProgressCrab
		bossBar_progressBar.texture_progress_offset = Vector2(41, 26)
	elif Name == "Puffer":
		bossBar_progressBar.texture_under = UnderPuffer
		bossBar_progressBar.texture_progress = ProgressPuffer
		bossBar_progressBar.texture_progress_offset = Vector2(39, 26)
	
	bossBar_progressBar.show()
	_on_boss_health_changed(100, 100)

func _on_boss_death():
	bossBar_progressBar.hide()

func _update_progres_bar():
	%XP_Bar.max_value = Stats.requiredXp
	%XP_Bar.value = Stats.currentXp

func _on_boss_health_changed(maxHp : int, hp):
	bossBar_progressBar.max_value = maxHp
	bossBar_progressBar.value = hp

func _update_health_bar():
	%HP_Bar.max_value = Stats.max_health
	%HP_Bar.value = Stats.current_health
	%HP.text = str(max(int(ceil(Stats.current_health)), 0)) + " / " + str(int(Stats.max_health))
	
func _update_level():
	%Level.text = str(Stats.level)	

func _on_pearls_changed():
	pearl_label.text = str(SaveManager.current_save.pearls + Stats.collected_pearls)
	
	if pearl_tween and pearl_tween.is_valid():
		pearl_tween.kill()
		
	pearl_tween = create_tween()
	
	pearl_box.visible = true
	pearl_box.scale = Vector2(1.2, 1.2) 
		
	pearl_tween.set_parallel(true)
	pearl_tween.tween_property(pearl_box, "modulate:a", 1.0, 0.1)
	pearl_tween.tween_property(pearl_box, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE)
	pearl_tween.set_parallel(false) 
	
	pearl_tween.tween_interval(2.0)
	
	pearl_tween.tween_property(pearl_box, "modulate:a", 0.0, 0.5)
	
	pearl_tween.tween_callback(func(): pearl_box.visible = false)

# --- Time scale ---
var time_scales: Array[float] = [1.0]
var _time_scale_index: int = 0

func _init_time_scales() -> void:
	var speed_lvl = SaveManager.current_save.upgrade_ingame_speed_level
	time_scales = [1.0]
	if speed_lvl >= 1:
		time_scales.append(1.5)
	if speed_lvl >= 2:
		time_scales.append(2.0)
	if speed_lvl >= 3:
		time_scales.append(3.0)
	if speed_lvl >= 4:
		time_scales.append(4.0)
	if speed_lvl >= 5:
		time_scales.append(5.0)
	
	if time_scales.size() <= 1:
		%SpeedLabel.hide()
	else:
		%SpeedLabel.show()
		%SpeedLabel.text = "x1"

func _input(event: InputEvent) -> void:
	if not GameManager.in_game:
		return
	if time_scales.size() <= 1:
		return
	
	if event.is_action_pressed("speed_up", false):
		_time_scale_index = min(_time_scale_index + 1, time_scales.size() - 1)
		_apply_time_scale()
	elif event.is_action_pressed("slow_down", false):
		_time_scale_index = max(_time_scale_index - 1, 0)
		_apply_time_scale()

func _apply_time_scale() -> void:
	Engine.time_scale = time_scales[_time_scale_index]
	%SpeedLabel.text = "x" + str(time_scales[_time_scale_index]).replace(".0", "")

func _on_font_mode_changed(is_modern: bool) -> void:
	var margins = ["margin_left", "margin_top", "margin_right", "margin_bottom"]
	_apply_margin_overrides(self, margins, is_modern)

var _original_margins = {}

func _apply_margin_overrides(node: Node, margins: Array, is_modern: bool) -> void:
	if node is MarginContainer:
		var node_id = node.get_instance_id()
		if not _original_margins.has(node_id):
			_original_margins[node_id] = {}
			for m in margins:
				_original_margins[node_id][m] = node.get_theme_constant(m)
				
		for m in margins:
			if is_modern:
				node.add_theme_constant_override(m, 0)
			else:
				node.add_theme_constant_override(m, _original_margins[node_id][m])
				
	for child in node.get_children():
		_apply_margin_overrides(child, margins, is_modern)
