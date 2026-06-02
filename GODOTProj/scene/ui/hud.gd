extends Control

@export var Stats = Resource

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

func _on_start():
	_update_health_bar()
	_update_progres_bar()
	_update_level()
	wave_label.text = "1"
	bossBar_progressBar.hide()
	
	# Connecte le signal du WaveManager
	var wm = get_tree().get_first_node_in_group("wave_manager")
	if wm and not wm.vague_demarree.is_connected(_on_vague_demarree):
		wm.vague_demarree.connect(_on_vague_demarree)

func _on_vague_demarree(numero: int) -> void:
	wave_label.text = str(numero)  # ← met à jour le label à chaque nouvelle vague
	if numero == 20:
		show_bossBar()
	
func show_bossBar():
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
