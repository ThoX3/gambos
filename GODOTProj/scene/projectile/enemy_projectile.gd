class_name EnemyProjectile
extends Area2D

var degats: int      = 5
var vitesse: float   = 200.0
var duree_vie: float = 3.0

var _direction: Vector2 = Vector2.RIGHT
var _timer: float       = 0.0

func init(direction: Vector2, p_degats: int, p_vitesse: float, p_duree_vie: float, p_sprite) -> void:
	_direction = direction.normalized()
	degats     = p_degats
	vitesse    = p_vitesse
	duree_vie  = p_duree_vie
	$AnimatedSprite2D.sprite_frames = p_sprite
	# Oriente le sprite dans la direction de tir
	rotation   = _direction.angle()

func _physics_process(delta: float) -> void:
	position += _direction * vitesse * delta
	_timer   += delta
	if _timer >= duree_vie:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.take_damage(degats)
		queue_free()
