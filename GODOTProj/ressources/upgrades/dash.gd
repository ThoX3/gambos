extends Node2D
class_name CapaciteDash

@export_category("Configuration du Dash")
@export var vitesse_dash: float = 3000.0
@export var duree_dash: float = 0.10
@export var cooldown_dash: float = 0.8

var _joueur: CharacterBody2D = null
var _dash_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _est_en_train_de_dasher: bool = false
var _direction_dash: Vector2 = Vector2.ZERO

func _ready() -> void:
	_joueur = get_parent() as CharacterBody2D
	if not _joueur:
		queue_free() 

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		
	if _est_en_train_de_dasher:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_finir_dash()
			return

		_joueur.global_position += _direction_dash * vitesse_dash * delta

	else:
		if _cooldown_timer <= 0.0:
			var stick = Input.get_vector("look_left", "look_right", "look_up", "look_down")
			if stick.length() > 0.4:
				_initier_dash(stick.normalized())

func _initier_dash(direction: Vector2) -> void:
	_est_en_train_de_dasher = true
	_direction_dash = direction
	_dash_timer = duree_dash
	_cooldown_timer = cooldown_dash
	
	if _joueur.has_method("start_invincibility"):
		_joueur.start_invincibility()
	
	var sprite = _joueur.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.modulate = Color(1.5, 1.5, 2.0) 
		
	Input.start_joy_vibration(0, 0.7, 0.0, 0.15)
	print("💨 Dash activé via script autonome ! Direction: ", _direction_dash)

func _finir_dash() -> void:
	_est_en_train_de_dasher = false
	
	var sprite = _joueur.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.modulate = Color.WHITE
