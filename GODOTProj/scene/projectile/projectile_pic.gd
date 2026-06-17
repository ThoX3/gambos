extends Area2D

var direction: Vector2 = Vector2.ZERO : set = _set_direction
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
	sprite.play("create")
	await sprite.animation_finished
	if est_actif:
		sprite.play("pic")
	await sprite.animation_finished
	if est_actif:
		sprite.play("move")

func _process(delta: float) -> void:
	if est_actif:
		var move = direction * vitesse * delta
		global_position += move
		_distance_traveled += move.length()
		if _distance_traveled >= max_range:
			_destroy()

func _set_direction(nouvelle_direction: Vector2) -> void:
	direction = nouvelle_direction.normalized()
	if direction != Vector2.ZERO:
		var angle_calculé = direction.angle()
		global_rotation = angle_calculé - ANGLE_CORRECTION
		if direction.x > 0:
			sprite.flip_v = true
			global_rotation = angle_calculé + ANGLE_CORRECTION
		else:
			sprite.flip_v = false

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

			if pierce_hp > 0:
				pierce_hp -= body.stats.max_hp if body.stats else 10
			else:
				pierce_hp -= 1

			if pierce_hp <= 0:
				_destroy()
		elif body is TileMap:
			_destroy()
	else:
		# Pic du boss — touche le joueur
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
	sprite.play("destroy")
	await sprite.animation_finished
	queue_free()
