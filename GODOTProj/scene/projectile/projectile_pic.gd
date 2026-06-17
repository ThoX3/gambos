extends Area2D

var direction: Vector2 = Vector2.ZERO
@export var vitesse: float = 300.0
@export var degats: int = 30

var est_actif: bool = true
var appartient_au_joueur: bool = false
var pierce_hp: int = 0
var _last_hit_enemy: Node2D = null
var max_range: float = 600.0
var _distance_traveled: float = 0.0

@onready var sprite = $AnimatedSprite2D

const ANGLE_CORRECTION: float = PI / 4

func _ready() -> void:
	_appliquer_rotation()
	sprite.play("pic")

func _process(delta: float) -> void:
	if est_actif:
		var move = direction * vitesse * delta
		global_position += move
		_distance_traveled += move.length()
		if _distance_traveled >= max_range:
			_destroy()

func _appliquer_rotation() -> void:
	if direction == Vector2.ZERO:
		return
	var angle_calculé = direction.angle()
	if direction.x > 0:
		sprite.flip_v = true
		global_rotation = angle_calculé + ANGLE_CORRECTION
	else:
		sprite.flip_v = false
		global_rotation = angle_calculé - ANGLE_CORRECTION

func _on_body_entered(body: Node2D) -> void:
	if not est_actif:
		return

	GameManager.joy_vibration(0, 0.2, 0.5, 0.2)

	if appartient_au_joueur:
		if body is Enemy_Base:
			if body == _last_hit_enemy:
				return
			_last_hit_enemy = body
			body.take_damage(degats)
			pierce_hp -= body.stats.max_hp if body.stats else 10
			if pierce_hp <= 0:
				_destroy()
		elif body is TileMap:
			_destroy()
	else:
		if body.is_in_group("Player"):
			body.take_damage(degats)
			_destroy()
		elif body is TileMap:
			_destroy()

func _destroy() -> void:
	if not est_actif:
		return
	est_actif = false
	set_deferred("monitoring", false)
	queue_free()
