extends Control

## Carte d'un ennemi dans le bestiaire.
## Si non débloqué : sprite en silhouette noire + "???" comme nom.

signal card_selected

@onready var sprite: TextureRect = %CardSprite
@onready var name_label: Label = %CardName
@onready var button: Button = %CardButton
@onready var kill_label: Label = %CardKillCount  # nouveau Label à ajouter dans la scène

const GAMBOS_TEXTURE := preload("res://assets/sprites/player/Gambos1.png")

var _data: EnemyData = null
var _unlocked: bool = false
var _is_boss: bool = false

func setup(data: EnemyData, unlocked: bool, is_boss: bool, kill_count: int = 0) -> void:
	_data = data
	_unlocked = unlocked
	_is_boss = is_boss

	if data.texture is SpriteFrames:
		var sf: SpriteFrames = data.texture
		var anim_name: String = "idle" if sf.has_animation("idle") else sf.get_animation_names()[0]
		if sf.get_frame_count(anim_name) > 0:
			sprite.texture = sf.get_frame_texture(anim_name, 0)

	if unlocked:
		sprite.modulate = Color.WHITE
		name_label.text = data.name if data.name != "" else data.resource_path.get_file().get_basename()
		if kill_label:
			kill_label.text = "💀 %d" % kill_count
			kill_label.visible = true
	else:
		sprite.modulate = Color(0, 0, 0, 1)
		name_label.text = "???"
		if kill_label:
			kill_label.visible = false

	button.pressed.connect(func(): card_selected.emit())

func setup_player() -> void:
	_data = null
	_unlocked = true
	sprite.texture = GAMBOS_TEXTURE
	sprite.modulate = Color.WHITE
	name_label.text = "Gambos"
	if kill_label:
		kill_label.text = "💀 %d" % SaveManager.current_save.player_death_count
		kill_label.visible = true
	button.pressed.connect(func(): card_selected.emit())
