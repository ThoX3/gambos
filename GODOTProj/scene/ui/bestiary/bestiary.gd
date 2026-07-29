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
@onready var detail_stats: RichTextLabel = %DetailStats
@onready var detail_description: Label = %DetailDescription
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
	
	# Toggle l'icon du bouton de retour selon le mode d'input
	if GameManager.game_played_with_controller and back_button.has_meta("icon"):
		back_button.icon = back_button.get_meta("icon")
	else:
		back_button.set_meta("icon", back_button.icon)
		back_button.icon = null

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
	if not GameManager.game_played_with_controller:
		return
		
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
	
func _on_card_focus_entered(card: Control):
	pass

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
	var stats_text := "[center]"
	
	stats_text += "[img=24]res://assets/sprites/bestiary/death_icon.png[/img] Morts : %d\n" % save.player_death_count
	stats_text += "⋅\n"
	
	var basic_stats = [
		{"name": "Vie", "level": save.upgrade_health_level + save.upgrade_health_2_level, "icon": "health.png", "effect": UpgradeManager.get_effect_health(save.upgrade_health_level) + UpgradeManager.get_effect_health_2(save.upgrade_health_2_level), "format": "%d"},
		{"name": "Attaque", "level": save.upgrade_damage_level + save.upgrade_damage_2_level, "icon": "damage.png", "effect": int(UpgradeManager.get_effect_damage(save.upgrade_damage_level) + UpgradeManager.get_effect_damage_2(save.upgrade_damage_2_level)), "format": "%d"},
		{"name": "Vitesse", "level": save.upgrade_speed_level + save.upgrade_speed_2_level, "icon": "speed.png", "effect": UpgradeManager.get_effect_speed(save.upgrade_speed_level) + UpgradeManager.get_effect_speed_2(save.upgrade_speed_2_level), "format": "%.0f"},
		{"name": "Vigueur", "level": save.upgrade_attack_speed_level + save.upgrade_attack_speed_2_level, "icon": "attack_speed.png", "effect": UpgradeManager.get_effect_attack_speed(save.upgrade_attack_speed_level) + UpgradeManager.get_effect_attack_speed_2(save.upgrade_attack_speed_2_level), "format": "%.2f/s"},
		{"name": "Sagesse", "level": save.upgrade_xp_gain_level, "icon": "xp_gain.png", "effect": UpgradeManager.get_effect_xp_gain(save.upgrade_xp_gain_level), "format": "x%.1f"},
		{"name": "Chance", "level": save.upgrade_luck_level, "icon": "luck.png", "effect": null},
		{"name": "Soins", "level": save.upgrade_regen_level, "icon": "regen.png", "effect": UpgradeManager.get_effect_regen(save.upgrade_regen_level), "format": "%.2f/s"},
		{"name": "Célérité", "level": save.upgrade_ingame_speed_level, "icon": "ingame_speed.png", "effect": null},
		{"name": "Épines", "level": save.upgrade_thorns_level, "icon": "thorns.png", "effect": UpgradeManager.get_effect_thorns(save.upgrade_thorns_level)["damage"], "format": "%d"},
		{"name": "Joker", "level": save.upgrade_reroll_level, "icon": "reroll.png", "effect": null},
		{"name": "Aimant", "level": save.upgrade_collection_radius_level, "icon": "collection_zone.png", "effect": UpgradeManager.get_effect_collection_radius(save.upgrade_collection_radius_level), "format": "%.0f"}
	]
	
	var added_basic = false
	for stat in basic_stats:
		if stat.level > 0:
			if stat.effect != null:
				var line_format = "[img=24]res://assets/sprites/pearl_shop/icons/%s[/img] %s : " + stat.format + "\n"
				stats_text += line_format % [stat.icon, stat.name, stat.effect]
			else:
				stats_text += "[img=24]res://assets/sprites/pearl_shop/icons/%s[/img] %s : Nv. %d\n" % [stat.icon, stat.name, stat.level]
			added_basic = true
			
	if added_basic:
		stats_text += "⋅\n"
		
	var bubble_stats = [
		{"name": "Petites bulles", "level": save.upgrade_bubble_division_level, "icon": "bubble_division.png"},
		{"name": "Rebonds", "level": save.upgrade_projectile_bounce_level, "icon": "bubble_bounce.png"}
	]
	for stat in bubble_stats:
		stats_text += "[img=24]res://assets/sprites/pearl_shop/icons/%s[/img] %s : Nv. %d\n" % [stat.icon, stat.name, stat.level]
		
	if save.mondes_completes_total >= 1:
		stats_text += "⋅\n"
		var sable_stats = [
			{"name": "Gravier", "level": save.upgrade_projectile_sable_pierce_level, "icon": "sable_pierce.png"},
			{"name": "Tempête de sable", "level": save.upgrade_projectile_sable_zone_damage_level, "icon": "sable_zone.png"},
			{"name": "Jet de sable", "level": save.upgrade_projectile_sable_count_level, "icon": "sable_count.png"}
		]
		for stat in sable_stats:
			stats_text += "[img=24]res://assets/sprites/pearl_shop/icons/%s[/img] %s : Nv. %d\n" % [stat.icon, stat.name, stat.level]
			
	if save.mondes_completes_total >= 2:
		stats_text += "⋅\n"
		var pic_stats = [
			{"name": "Poussée", "level": save.upgrade_projectile_pic_push_level, "icon": "sable_pierce.png"},
			{"name": "Petits pics", "level": save.upgrade_projectile_pic_division_level, "icon": "sable_zone.png"}
		]
		for stat in pic_stats:
			stats_text += "[img=24]res://assets/sprites/pearl_shop/icons/%s[/img] %s : Nv. %d\n" % [stat.icon, stat.name, stat.level]
			
	stats_text += "[/center]"

	detail_stats.text = stats_text

func _on_card_selected(data: EnemyData, unlocked: bool, is_boss: bool) -> void:
	if not unlocked:
		return

	detail_name.text = data.name
	detail_description.text = data.description

	if data.texture is SpriteFrames:
		var sf: SpriteFrames = data.texture
		var anim_name: String = "idle" if sf.has_animation("idle") else sf.get_animation_names()[0]
		if sf.get_frame_count(anim_name) > 0:
			detail_sprite.texture = sf.get_frame_texture(anim_name, 0)
	else:
		detail_sprite.texture = null

	var stats_text := "[center]"
	stats_text += "[img=24]res://assets/sprites/pearl_shop/icons/health.png[/img] Vie : %d\n" % data.max_hp
	stats_text += "[img=24]res://assets/sprites/pearl_shop/icons/damage.png[/img] Dégâts : %d\n" % data.attack_damage
	stats_text += "[img=24]res://assets/sprites/pearl_shop/icons/speed.png[/img] Vitesse : %.0f\n" % data.movement_speed
	stats_text += "[img=24]res://assets/sprites/collectibles/SeaweedXP_Idle1.png[/img] Algues : %d\n" % data.xp_drop
	if data.pearl_drop_probability > 0.0:
		if data.pearl_drop_range.y > 1 or data.pearl_drop_range.x > 1:
			if data.pearl_drop_range.x == data.pearl_drop_range.y:
				stats_text += "[img=24]res://assets/sprites/collectibles/pearl_icon.png[/img] Perles : %d\n" % data.pearl_drop_range.x
			else:
				stats_text += "[img=24]res://assets/sprites/collectibles/pearl_icon.png[/img] Perles : %d - %d\n" % [data.pearl_drop_range.x, data.pearl_drop_range.y]
		else:
			stats_text += "[img=24]res://assets/sprites/collectibles/pearl_icon.png[/img] Perles : %.0f%%\n" % (data.pearl_drop_probability * 100)
	stats_text += "[img=24]res://assets/sprites/bestiary/death_icon.png[/img] Tués : %d\n" % GameManager.get_total_kill_count(data)
	stats_text += "[/center]"

	detail_stats.text = stats_text
