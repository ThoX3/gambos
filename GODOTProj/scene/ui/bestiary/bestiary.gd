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
@onready var player_container: GridContainer = %PlayerContainer
@onready var detail_panel: Control = %DetailPanel
@onready var detail_name: Label = %DetailName
@onready var detail_stats: Label = %DetailStats
@onready var detail_sprite: TextureRect = %DetailSprite
@onready var back_button: Button = %BackButton

const GAMBOS_KEY := "gambos_player"

const GAMBOS_TEXTURE := preload("res://assets/sprites/player/Gambos1.png")
const BASE_PLAYER_STATS: PlayerStat = preload("res://ressources/playerStat.tres")

var _max_wave: int = 0
## true si ouvert depuis le menu pause (la partie est en cours)
var _from_pause: bool = false

func _ready() -> void:
	# Fonctionne même quand le jeu est en pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.pressed.connect(_on_back)

## Ouvre le bestiaire depuis le menu principal
func setup(max_wave_reached: int) -> void:
	_from_pause = false
	_max_wave = max_wave_reached
	_refresh()

## Ouvre le bestiaire par-dessus le menu pause
func setup_from_pause(max_wave_reached: int) -> void:
	_from_pause = true
	_max_wave = max_wave_reached
	_refresh()

func _refresh() -> void:
	_clear_containers()
	_populate_player()
	_populate_enemies()
	_populate_bosses()
	await get_tree().process_frame
	_focus_first_card()

func _focus_first_card() -> void:
	# Cherche le premier CardButton dans les cartes ennemies
	for card in enemy_container.get_children():
		var btn = card.get_node_or_null("%CardButton")
		if btn:
			btn.grab_focus()
			return
	# Sinon essaie les boss
	for card in boss_container.get_children():
		var btn = card.get_node_or_null("%CardButton")
		if btn:
			btn.grab_focus()
			return
	# Fallback sur le bouton retour
	back_button.grab_focus()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	back_button_pressed.emit()

func _clear_containers() -> void:
	for child in enemy_container.get_children():
		child.queue_free()
	for child in boss_container.get_children():
		child.queue_free()
	for child in player_container.get_children():
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

func _populate_player() -> void:
	var card: Control = card_scene.instantiate()
	player_container.add_child(card)
	card.setup_player()
	card.card_selected.connect(_on_player_card_selected)

func _add_card(data: EnemyData, unlocked: bool, is_boss: bool, container: GridContainer) -> void:
	var card: Control = card_scene.instantiate()
	container.add_child(card)
	var kill_count = GameManager.get_total_kill_count(data) if unlocked else 0
	card.setup(data, unlocked, is_boss, kill_count)
	card.card_selected.connect(_on_card_selected.bind(data, unlocked, is_boss))

func _on_player_card_selected() -> void:
	detail_name.text = "Gambos"
	detail_sprite.texture = GAMBOS_TEXTURE

	var save = SaveManager.current_save
	var stats_text := ""
	stats_text += "❤️  PV : %d\n" % int(BASE_PLAYER_STATS.max_health)
	stats_text += "⚔️  Dégâts : %d\n" % BASE_PLAYER_STATS.proj_damage
	stats_text += "💨  Vitesse : %.0f\n" % BASE_PLAYER_STATS.speed
	stats_text += "💀  Morts : %d\n" % save.player_death_count

	detail_stats.text = stats_text

func _on_card_selected(data: EnemyData, unlocked: bool, is_boss: bool) -> void:
	if not unlocked:
		return

	detail_name.text = data.name

	if data.texture is SpriteFrames:
		var sf: SpriteFrames = data.texture
		var anim_name: String = "idle" if sf.has_animation("idle") else sf.get_animation_names()[0]
		if sf.get_frame_count(anim_name) > 0:
			detail_sprite.texture = sf.get_frame_texture(anim_name, 0)
	else:
		detail_sprite.texture = null

	var stats_text := ""
	stats_text += "❤️  PV : %d\n" % data.max_hp
	stats_text += "⚔️  Dégâts : %d\n" % data.attack_damage
	stats_text += "💨  Vitesse : %.0f\n" % data.movement_speed
	stats_text += "✨  XP lâché : %d\n" % data.xp_drop
	if data.pearl_drop_probability > 0.0:
		stats_text += "🦪  Perles : %.0f%%\n" % (data.pearl_drop_probability * 100)
	stats_text += "☠️  Tués : %d\n" % GameManager.get_total_kill_count(data)

	detail_stats.text = stats_text
