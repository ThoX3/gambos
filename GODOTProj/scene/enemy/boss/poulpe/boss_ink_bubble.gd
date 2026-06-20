extends Area2D
class_name BossInkBubble

signal hit_player(bubble: BossInkBubble)
signal expired(bubble: BossInkBubble)
signal screen_cleared(bubble: BossInkBubble)

var direction: Vector2 = Vector2.RIGHT
var speed: float = 150.0          # Vitesse de base réduite (bulle lourde)
var damage: int = 1

# --- Physique "lourde" ---
var _deceleration: float = 25.0   # La bulle ralentit progressivement (traînée due au poids)
var _min_speed_ratio: float = 0.3 # Ne descend jamais en dessous de 30% de la vitesse initiale
var _base_speed: float = 0.0

# --- Cycle de vie ---
var _lifetime: float = 20.0       # Explose après ~20s si rien n'est touché
var _is_destroyed: bool = false

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


func setup(start_direction: Vector2, bubble_speed: float, bubble_damage: int) -> void:
	direction = start_direction.normalized()
	speed = bubble_speed
	_base_speed = bubble_speed
	damage = bubble_damage


func _on_body_entered(body: Node2D) -> void:
	if _is_destroyed:
		return

	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		AudioManager.play_sound_2d("projectile_pop", global_position)
		_destroy()
		_darken_screen()
		hit_player.emit(self)

	elif body is TileMapLayer:
		_destroy()


func _on_lifetime_timeout() -> void:
	if _is_destroyed:
		return
	_destroy()
	expired.emit(self)


# Permet au boss de faire éclater une bulle restante sans attendre un impact
func pop_silently() -> void:
	if _is_destroyed:
		return
	_destroy()


func _destroy() -> void:
	_is_destroyed = true
	_lifetime_timer.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	_sprite.play("destroy")


func _on_animation_finished() -> void:
	if _sprite.animation == "create":
		_sprite.play("move")
	elif _sprite.animation == "destroy":
		queue_free()


func _darken_screen() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(screen_darken_color.r, screen_darken_color.g, screen_darken_color.b, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	get_tree().root.add_child(overlay)
	overlay.z_index = 4096

	var tween := overlay.create_tween()
	tween.tween_property(overlay, "color:a", screen_darken_color.a, screen_darken_fade_in)
	tween.tween_interval(screen_darken_hold)
	tween.tween_property(overlay, "color:a", 0.0, screen_darken_fade_out)
	tween.tween_callback(overlay.queue_free)

	# Signale au boss QUAND l'écran redevient clair (fin du fade out)
	await get_tree().create_timer(screen_darken_fade_in + screen_darken_hold + screen_darken_fade_out).timeout
	screen_cleared.emit(self)
