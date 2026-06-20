extends Area2D
class_name ProjectileInk

var direction: Vector2 = Vector2.RIGHT
var speed: float = 150.0          # Vitesse de base réduite (bulle lourde)
var damage: int = 1

# --- Physique "lourde" ---
var _deceleration: float = 25.0   # La bulle ralentit progressivement (traînée due au poids)
var _min_speed_ratio: float = 0.3 # Ne descend jamais en dessous de 30% de la vitesse initiale
var _base_speed: float = 0.0      # Mémorise la vitesse de départ pour calculer le ratio min

# --- Ralentissement infligé à l'ennemi touché ---
@export var slow_ratio: float = 0.5    # L'ennemi tombe à 50% de sa vitesse normale
@export var slow_duration: float = 2.5 # Durée du ralentissement (s)

# --- Cycle de vie ---
var _lifetime: float = 20.0       # Explose après ~20s si rien n'est touché
var _is_destroyed: bool = false   # Empêche les doubles impacts

# --- Assombrissement d'écran ---
@export var screen_darken_color: Color = Color(0, 0, 0, 0.6)
@export var screen_darken_fade_in: float = 0.3
@export var screen_darken_hold: float = 0.8
@export var screen_darken_fade_out: float = 0.6

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio = $AudioStreamPlayer2D
@onready var _lifetime_timer: Timer = $LifetimeTimer


func _ready() -> void:
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play("create")
	body_entered.connect(_on_body_entered)

	_base_speed = speed

	# Timer d'explosion automatique après 20s
	_lifetime_timer.wait_time = _lifetime
	_lifetime_timer.one_shot = true
	_lifetime_timer.timeout.connect(_on_lifetime_timeout)
	_lifetime_timer.start()


func _physics_process(delta: float) -> void:
	if _is_destroyed:
		return

	# Décélération progressive : la bulle "traîne" à cause de son poids
	speed = max(speed - _deceleration * delta, _base_speed * _min_speed_ratio)

	var movement := direction * speed * delta
	global_position += movement


func setup(data: ProjectileData, target_direction: Vector2) -> void:
	direction = target_direction.normalized()
	speed = data.speed
	damage = data.damage
	_base_speed = speed


func _on_body_entered(body: Node2D) -> void:
	if _is_destroyed:
		return

	if body is Enemy_Base:
		body.take_damage(damage)
		_apply_slow(body)
		AudioManager.play_sound_2d("projectile_pop", global_position)
		_destroy()

	elif body is TileMapLayer:
		_destroy()


func _apply_slow(enemy: Enemy_Base) -> void:
	if not ("movement_speed" in enemy):
		return

	# Si l'ennemi n'est pas déjà ralenti, on mémorise sa vitesse d'origine
	if not enemy.has_meta("_ink_base_speed"):
		enemy.set_meta("_ink_base_speed", enemy.movement_speed)

	var base_speed: float = enemy.get_meta("_ink_base_speed")
	enemy.movement_speed = base_speed * slow_ratio

	# Annule un précédent timer de restauration s'il existe encore (réapplique juste la durée)
	if enemy.has_meta("_ink_slow_timer"):
		var old_timer: SceneTreeTimer = enemy.get_meta("_ink_slow_timer")
		if old_timer != null and old_timer.timeout.is_connected(_on_slow_expired):
			old_timer.timeout.disconnect(_on_slow_expired)

	var timer := get_tree().create_timer(slow_duration)
	enemy.set_meta("_ink_slow_timer", timer)
	timer.timeout.connect(_on_slow_expired.bind(enemy))


func _on_slow_expired(enemy: Enemy_Base) -> void:
	if not is_instance_valid(enemy):
		return
	if not enemy.has_meta("_ink_base_speed"):
		return
	enemy.movement_speed = enemy.get_meta("_ink_base_speed")
	enemy.remove_meta("_ink_base_speed")
	enemy.remove_meta("_ink_slow_timer")


func _on_lifetime_timeout() -> void:
	if _is_destroyed:
		return
	_explode()


func _destroy() -> void:
	_is_destroyed = true
	_lifetime_timer.stop()
	# Désactive la collision immédiatement pour éviter les doubles impacts
	$CollisionShape2D.set_deferred("disabled", true)
	_sprite.play("destroy")


func _explode() -> void:
	_destroy()


func _on_animation_finished() -> void:
	if _sprite.animation == "create":
		_sprite.play("move")
	elif _sprite.animation == "destroy":
		queue_free()
