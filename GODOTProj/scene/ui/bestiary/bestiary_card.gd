extends Control

## Carte d'un ennemi dans le bestiaire.
## Si non débloqué : sprite en silhouette noire + "???" comme nom.

signal card_selected

@onready var sprite: TextureRect = %CardSprite
@onready var name_label: Label = %CardName
@onready var button: Button = %CardButton

var _data: EnemyData = null
var _unlocked: bool = false
var _is_boss: bool = false

func setup(data: EnemyData, unlocked: bool, is_boss: bool) -> void:
	_data = data
	_unlocked = unlocked
	_is_boss = is_boss

	# Sprite
	if data.texture is SpriteFrames:
		var sf: SpriteFrames = data.texture
		var anim_name: String = "idle" if sf.has_animation("idle") else sf.get_animation_names()[0]
		if sf.get_frame_count(anim_name) > 0:
			sprite.texture = sf.get_frame_texture(anim_name, 0)

	if unlocked:
		# Sprite normal
		sprite.modulate = Color.WHITE
		# Nom lisible
		if data.has_method("get") and data.get("name") != null:
			name_label.text = data.get("name")
		else:
			name_label.text = data.resource_path.get_file().get_basename()
	else:
		# Silhouette noire
		sprite.modulate = Color(0, 0, 0, 1)
		name_label.text = "???"

	button.pressed.connect(func(): card_selected.emit())
