extends Area2D

var direction: Vector2 = Vector2.ZERO : set = _set_direction # Utilisez un setter pour changer l'angle dès que la direction change
@export var vitesse: float = 600.0
@export var degats: int = 10
var est_actif: bool = true
var appartient_au_joueur: bool = false

var pierce_hp: int = 0
var zone_radius: float = 0.0
var _last_hit_enemy: Node2D = null

var max_range: float = 1000.0
var _distance_traveled: float = 0.0

@onready var sprite = $AnimatedSprite2D

const ANGLE_CORRECTION : float = 3 * PI / 4 

func _ready() -> void:
	sprite.play("create")
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
		global_rotation = direction.angle() - ANGLE_CORRECTION
		if direction.x > 0:
			sprite.flip_v = true
			global_rotation = angle_calculé + ANGLE_CORRECTION
		else:
			sprite.flip_v = false

func _on_body_entered(body: Node2D) -> void:
	if not est_actif:
		return
	
	if appartient_au_joueur:
		if body is Enemy_Base:
			if body == _last_hit_enemy:
				return
			_last_hit_enemy = body
			
			if zone_radius > 0.0:
				_apply_zone_damage(body)
			else:
				body.take_damage(degats)
			
			if pierce_hp > 0:
				if body.stats:
					pierce_hp -= body.stats.max_hp
				else:
					pierce_hp -= 10 # Fallback
			else:
				pierce_hp -= 1
				
			if pierce_hp > 0:
				# Pierce: continue flying
				pass
			else:
				_destroy()
		elif body is TileMapLayer:
			if not _is_near_map_border():
				_destroy()
	else:
		GameManager.joy_vibration(0, 0.2, 0.5, 0.2)
		if body.is_in_group("Player") or body is TileMapLayer:
			if body.is_in_group("Player"):
				print("Sable dans les yeux ! Dégâts au joueur !")
				body.take_damage(degats)
				print(degats)
				_destroy()
			elif not _is_near_map_border():
				_destroy()

func _destroy() -> void:
	if not est_actif:
		return
	est_actif = false
	set_deferred("monitoring", false)
	
	if zone_radius > 0:
		var scale_factor = max(20.0, zone_radius) / 20.0
		sprite.scale = Vector2(scale_factor, scale_factor)
		
	sprite.play("destroy")
	await sprite.animation_finished
	queue_free()

func _apply_zone_damage(center_body: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var hit_center = false
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= zone_radius:
			var ratio = 1.0 - (dist / zone_radius)
			var zone_dmg = max(1, int(degats * ratio))
			enemy.take_damage(zone_dmg)
			if enemy == center_body:
				hit_center = true
	
	if not hit_center and is_instance_valid(center_body) and center_body.has_method("take_damage"):
		center_body.take_damage(degats)

func _is_near_map_border() -> bool:
	var main = get_tree().current_scene
	if main and "current_map" in main and main.current_map and "map_size" in main.current_map:
		var map_size = main.current_map.map_size
		var margin = 120.0
		if global_position.x <= margin or global_position.x >= map_size.x - margin or \
		   global_position.y <= margin or global_position.y >= map_size.y - margin:
			return true
	return false
