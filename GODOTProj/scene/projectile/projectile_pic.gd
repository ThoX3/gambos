extends Area2D

var direction: Vector2 = Vector2.ZERO : set = _set_direction
@export var vitesse: float = 300.0
@export var degats: int = 30

var est_actif: bool = true
var appartient_au_joueur: bool = false
var _last_hit_enemy: Node2D = null
var max_range: float = 600.0
var _distance_traveled: float = 0.0
var divisions_remaining: int = 0

@onready var sprite = $AnimatedSprite2D

const ANGLE_CORRECTION: float = 0

func _ready() -> void:
	# La direction a pu être assignée avant _ready : on applique la rotation maintenant
	_appliquer_rotation()
	sprite.play("pic")

func _process(delta: float) -> void:
	if est_actif:
		var move = direction * vitesse * delta
		global_position += move
		_distance_traveled += move.length()
		if _distance_traveled >= max_range:
			_destroy()

func _set_direction(nouvelle_direction: Vector2) -> void:
	direction = nouvelle_direction.normalized()
	# Si le sprite est déjà prêt, on applique tout de suite ; sinon _ready s'en chargera
	if is_inside_tree() and sprite != null:
		_appliquer_rotation()

func _appliquer_rotation() -> void:
	if direction == Vector2.ZERO or sprite == null:
		return
	# Oriente le projectile dans la direction de tir
	rotation = direction.angle() + ANGLE_CORRECTION

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
		elif body is TileMapLayer:
			if not _is_near_map_border():
				_destroy()
	else:
		if body.is_in_group("Player"):
			body.take_damage(degats)
			_destroy()
		elif body is TileMapLayer:
			if not _is_near_map_border():
				_destroy()

func _is_near_map_border() -> bool:
	var main = get_tree().current_scene
	if main and "current_map" in main and main.current_map and "map_size" in main.current_map:
		var map_size = main.current_map.map_size
		var margin = 120.0
		if global_position.x <= margin or global_position.x >= map_size.x - margin or \
		   global_position.y <= margin or global_position.y >= map_size.y - margin:
			return true
	return false
	
func _destroy() -> void:
	if not est_actif:
		return
	est_actif = false
	set_deferred("monitoring", false)
	
	if divisions_remaining > 0:
		_spawn_division(PI / 6.0)
		_spawn_division(-PI / 6.0)
		
	queue_free()

func _spawn_division(angle_offset: float) -> void:
	var proj = load("res://scene/projectile/projectile_pic.tscn").instantiate()
	proj.global_position = global_position
	proj.direction = direction.rotated(angle_offset)
	proj.vitesse = vitesse
	proj.degats = max(1, int(degats * 0.75))
	proj.max_range = max_range * 0.5
	proj.divisions_remaining = divisions_remaining - 1
	proj.appartient_au_joueur = appartient_au_joueur
	proj.collision_layer = collision_layer
	proj.collision_mask = collision_mask
	proj.scale = scale * 0.5
	
	get_parent().call_deferred("add_child", proj)

