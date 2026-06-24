extends Area2D
class_name Projectile

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var range: float = 500.0
var damage: int = 1
var _distance_traveled: float = 0.0
var _is_destroyed: bool = false  # Empêche les doubles impacts
var _number_of_redirections_left := 0  # Nombre restant de rebondissements
var _should_update_direction := false  # Redirection en cas de rebondissement
var _last_hit_enemy: Node2D = null
var _current_added_range: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio = $AudioStreamPlayer2D

func _ready() -> void:
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play("create")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _is_destroyed:
		return
		
	var movement := direction * speed * delta
	
	global_position += movement
	_distance_traveled += movement.length()
	
	if _distance_traveled >= range:
		_destroy()
		
	if _should_update_direction:
		_should_update_direction = false
		update_direction()

func setup(data: ProjectileData, target_direction: Vector2) -> void:
	direction = target_direction.normalized()
	speed = data.speed
	range = data.range
	damage = data.damage
	_number_of_redirections_left = data.bounce_count
	_current_added_range = range / 2.0

func _on_body_entered(body: Node2D) -> void:
	if _is_destroyed:
		return
	if body is Enemy_Base:
		_last_hit_enemy = body
		var removed_hp: int = body.take_damage(damage)
		
		AudioManager.play_sound_2d("projectile_pop", global_position)
		
		if removed_hp < damage and _number_of_redirections_left > 0:
			damage -= removed_hp
			_number_of_redirections_left -= 1
			_should_update_direction = true
			range += _current_added_range
			_current_added_range /= 2.0
		else:
			_destroy()
	if body is TileMapLayer:
		if not _is_near_map_border():
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

func _get_nearest_enemy() -> Enemy_Base:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	# Filtrer par portée et validité
	var in_range: Array = []
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == _last_hit_enemy:
			continue
		if global_position.distance_to(enemy.global_position) <= range:
			in_range.append(enemy)
			
	if in_range.is_empty():
		return null
	
	# Trier par distance croissante
	in_range.sort_custom(func(a, b):
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	
	# Retourner le plus proche
	return in_range[0]

func update_direction():
	var target = _get_nearest_enemy()
	if target:
		direction = global_position.direction_to(target.global_position).normalized()

func _is_near_map_border() -> bool:
	var main = get_tree().current_scene
	if main and "current_map" in main and main.current_map and "map_size" in main.current_map:
		var map_size = main.current_map.map_size
		var margin = 120.0
		if global_position.x <= margin or global_position.x >= map_size.x - margin or \
		   global_position.y <= margin or global_position.y >= map_size.y - margin:
			return true
	return false
