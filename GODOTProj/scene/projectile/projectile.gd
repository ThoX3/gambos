extends Area2D
class_name Projectile

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var range: float = 500.0
var damage: int = 2

var _distance_traveled: float = 0.0
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play("create")

func _physics_process(delta: float) -> void:
	var movement = direction * speed * delta
	global_position += movement
	_distance_traveled += movement.length()
	
	if _distance_traveled >= range:
		queue_free()

# Appelée depuis le player pour initialiser le projectile
func setup(data: ProjectileData, target_direction: Vector2) -> void:
	direction = target_direction.normalized()
	speed = data.speed
	range = data.range
	damage = data.damage

func _on_animation_finished():
	if _sprite.animation == "create":
		_sprite.play("move")
