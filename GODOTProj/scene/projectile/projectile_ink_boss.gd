extends Area2D
class_name BossInkBubble

signal hit_player(bubble)
signal expired(bubble)
signal screen_cleared(bubble)

var damage: int = 1

# --- Poursuite "lourde" ---
var max_speed: float = 80.0       # vitesse max (basse = lent)
var turn_rate: float = 2.0        # capacité à changer de direction (bas = LOURD, tourne lentement)
var _velocity: Vector2 = Vector2.ZERO
var _player: Node2D = null

# --- Cycle de vie ---
var _lifetime: float = 20.0
var _is_destroyed: bool = false

# --- Assombrissement d'écran ---
@export var screen_darken_color: Color = Color(0, 0, 0, 0.6)
@export var screen_darken_fade_in: float = 0.3
@export var screen_darken_hold: float = 0.8
@export var screen_darken_fade_out: float = 0.6

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio = $AudioStreamPlayer2D
var _lifetime_timer: Timer


func _ready() -> void:
	if _sprite != null:
		# Règle les boucles : create joue 1 fois → move boucle à l'infini →
		# destroy joue 1 fois puis la bulle disparaît.
		var sf = _sprite.sprite_frames
		if sf != null:
			if sf.has_animation("create"):
				sf.set_animation_loop("create", false)
			if sf.has_animation("move"):
				sf.set_animation_loop("move", true)
			if sf.has_animation("destroy"):
				sf.set_animation_loop("destroy", false)
		_sprite.animation_finished.connect(_on_animation_finished)
		_sprite.play("create")

	body_entered.connect(_on_body_entered)

	_lifetime_timer = Timer.new()
	_lifetime_timer.wait_time = _lifetime
	_lifetime_timer.one_shot = true
	add_child(_lifetime_timer)
	_lifetime_timer.timeout.connect(_on_lifetime_timeout)
	_lifetime_timer.start()


func setup(player: Node2D, bubble_speed: float, bubble_damage: int) -> void:
	_player = player
	max_speed = bubble_speed
	damage = bubble_damage

	# Ajoute le layer du joueur au masque de collision de la bulle, PAR CODE.
	if _player is CollisionObject2D:
		collision_mask |= _player.collision_layer

	# Vitesse initiale douce vers le joueur
	if is_instance_valid(_player):
		_velocity = (_player.global_position - global_position).normalized() * max_speed * 0.5


func _physics_process(delta: float) -> void:
	if _is_destroyed:
		return

	# Poursuite à tête chercheuse "lourde"
	if is_instance_valid(_player):
		var desired := (_player.global_position - global_position).normalized() * max_speed
		_velocity = _velocity.move_toward(desired, turn_rate * max_speed * delta)

	global_position += _velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if _is_destroyed:
		return

	# Le joueur = la cible passée dans setup (groupe "Player" en filet de sécurité)
	if body == _player or body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		AudioManager.play_sound_2d("projectile_pop", global_position)
		_destroy()
		_darken_screen()
		hit_player.emit(self)
	elif body is TileMapLayer:
		_destroy()
	# (les ennemis touchés sont ignorés : la bulle leur passe au travers)


func _on_lifetime_timeout() -> void:
	if _is_destroyed:
		return
	_destroy()
	expired.emit(self)


func pop_silently() -> void:
	if _is_destroyed:
		return
	_destroy()


func _destroy() -> void:
	_is_destroyed = true
	if is_instance_valid(_lifetime_timer):
		_lifetime_timer.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	# Joue l'animation de destruction ; la bulle disparaît à la fin (voir _on_animation_finished)
	if _sprite != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("destroy"):
		_sprite.play("destroy")
	else:
		queue_free()


func _on_animation_finished() -> void:
	if _sprite.animation == "create":
		_sprite.play("move")          # move boucle à l'infini (réglé dans _ready)
	elif _sprite.animation == "destroy":
		queue_free()                   # fin de destroy → la bulle disparaît


func _darken_screen() -> void:
	# Overlay plein écran via un CanvasLayer → rendu en ESPACE ÉCRAN
	# (indépendant de la caméra), donc couvre toujours tout l'écran.
	var layer := CanvasLayer.new()
	layer.layer = 100   # au-dessus de tout le reste
	get_tree().root.add_child(layer)

	var overlay := ColorRect.new()
	overlay.color = Color(screen_darken_color.r, screen_darken_color.g, screen_darken_color.b, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	layer.add_child(overlay)

	var tween := overlay.create_tween()
	tween.tween_property(overlay, "color:a", screen_darken_color.a, screen_darken_fade_in)
	tween.tween_interval(screen_darken_hold)
	tween.tween_property(overlay, "color:a", 0.0, screen_darken_fade_out)
	tween.tween_callback(layer.queue_free)   # libère le CanvasLayer (et l'overlay avec)

	await get_tree().create_timer(screen_darken_fade_in + screen_darken_hold + screen_darken_fade_out).timeout
	screen_cleared.emit(self)
