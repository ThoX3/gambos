extends Area2D
class_name Projectile

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var range: float = 500.0
var damage: int = 2
var _distance_traveled: float = 0.0
var _is_destroyed: bool = false  # Empêche les doubles impacts

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play("create")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _is_destroyed:
		return
		
	var movement = direction * speed * delta
	global_position += movement
	_distance_traveled += movement.length()
	
	if _distance_traveled >= range:
		_destroy()

func setup(data: ProjectileData, target_direction: Vector2) -> void:
	direction = target_direction.normalized()
	speed = data.speed
	range = data.range
	damage = data.damage

func _on_body_entered(body: Node2D) -> void:
	if _is_destroyed:
		return
	if body is Enemy_Base:
		body.take_damage(damage)
		_destroy()

func _destroy() -> void:
	_is_destroyed = true
	# Désactive la collision immédiatement pour éviter les doubles impacts
	$CollisionShape2D.set_deferred("disabled", true)
	_sprite.play("destroy")

func _on_animation_finished() -> void:
	if _sprite.animation == "create":
		_sprite.play("move")
	elif _sprite.animation == "destroy":
		queue_free()
