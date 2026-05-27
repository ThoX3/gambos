extends Control

## Bestiaire — affiche les ennemis/boss débloqués selon la vague max atteinte.
## Les ennemis non débloqués apparaissent en silhouette noire.

signal back_button_pressed

## Référence au SpawnConfig pour lire ennemis et boss
@export var spawn_config: SpawnConfig

## Scène de la carte individuelle
@export var card_scene: PackedScene

@onready var enemy_container: GridContainer = %EnemyContainer
@onready var boss_container: GridContainer = %BossContainer
@onready var detail_panel: Control = %DetailPanel
@onready var detail_name: Label = %DetailName
@onready var detail_stats: Label = %DetailStats
@onready var detail_sprite: TextureRect = %DetailSprite
@onready var back_button: Button = %BackButton

var _max_wave: int = 0

func _ready() -> void:
	back_button.pressed.connect(func(): back_button_pressed.emit())

func setup(max_wave_reached: int) -> void:
	_max_wave = max_wave_reached
	_clear_containers()
	_populate_enemies()
	_populate_bosses()

func _clear_containers() -> void:
	for child in enemy_container.get_children():
		child.queue_free()
	for child in boss_container.get_children():
		child.queue_free()

func _populate_enemies() -> void:
	if spawn_config == null:
		push_error("Bestiary: spawn_config non assigné !")
		return
	for entry in spawn_config.ennemis:
		if not entry is EntreeEnnemi:
			continue
		var unlocked: bool = entry.vague_apparition <= _max_wave
		_add_card(entry.data, unlocked, false, enemy_container)

func _populate_bosses() -> void:
	if spawn_config == null:
		return
	for entry in spawn_config.boss:
		if not entry is EntreeBoss:
			continue
		var unlocked: bool = entry.vague_exacte <= _max_wave
		_add_card(entry.data, unlocked, true, boss_container)

func _add_card(data: EnemyData, unlocked: bool, is_boss: bool, container: GridContainer) -> void:
	var card: Control = card_scene.instantiate()
	container.add_child(card)
	card.setup(data, unlocked, is_boss)
	card.card_selected.connect(_on_card_selected.bind(data, unlocked, is_boss))

func _on_card_selected(data: EnemyData, unlocked: bool, is_boss: bool) -> void:
	if not unlocked:
		return

	# Nom
	detail_name.text = data.name

	# Sprite — première frame de l'animation "idle" ou la première dispo
	if data.texture is SpriteFrames:
		var sf: SpriteFrames = data.texture
		var anim_name: String = "idle" if sf.has_animation("idle") else sf.get_animation_names()[0]
		if sf.get_frame_count(anim_name) > 0:
			detail_sprite.texture = sf.get_frame_texture(anim_name, 0)
	else:
		detail_sprite.texture = null

	# Stats
	var stats_text := ""
	stats_text += "❤️  PV : %d\n" % data.max_hp
	#stats_text += "🛡️  Armure : %d\n" % data.armor
	stats_text += "⚔️  Dégâts : %d\n" % data.attack_damage
	stats_text += "💨  Vitesse : %.0f\n" % data.movement_speed
	#if data.attack_cooldown > 0.0:
		#stats_text += "⏱️  Cooldown : %.1f s\n" % data.attack_cooldown
	#if data.attack_range > 0.0:
		#stats_text += "🎯  Portée : %.0f\n" % data.attack_range
	stats_text += "✨  XP lâché : %d\n" % data.xp_drop
	if data.pearl_drop_probability > 0.0:
		stats_text += "🦪  Perles : %.0f%%\n" % (data.pearl_drop_probability * 100)

	detail_stats.text = stats_text
