extends Area2D

var direction: Vector2 = Vector2.ZERO
var vitesse: float = 600.0
var degats: int = 2
var est_actif: bool = true
var appartient_au_joueur: bool = false  # ← NOUVEAU

var pierce_hp: int = 0
var zone_radius: float = 0.0
var bounce_count: int = 0
var _last_hit_enemy: Node2D = null

@onready var sprite = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("create")
	await sprite.animation_finished
	if est_actif:
		sprite.play("move")

func _process(delta: float) -> void:
	if est_actif:
		global_position += direction * vitesse * delta

func _on_body_entered(body: Node2D) -> void:
	if not est_actif:
		return
	
	Input.start_joy_vibration(0, 0.2, 0.5, 0.2)
	if appartient_au_joueur:
		# --- Logique joueur : touche les ennemis ---
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
			elif bounce_count > 0:
				# Ricochet
				bounce_count -= 1
				_update_direction()
			else:
				est_actif = false
				set_deferred("monitoring", false)
				sprite.play("destroy")
				await sprite.animation_finished
				queue_free()
		elif body is TileMap:
			if bounce_count > 0:
				bounce_count -= 1
				_update_direction()
			else:
				est_actif = false
				set_deferred("monitoring", false)
				sprite.play("destroy")
				await sprite.animation_finished
				queue_free()
	else:
		# --- Logique boss : touche le joueur (comportement original intact) ---
		if body.is_in_group("Player") or body is TileMap:
			est_actif = false
			set_deferred("monitoring", false)
			if body.is_in_group("Player"):
				print("Sable dans les yeux ! Dégâts au joueur !")
				body.take_damage(10)
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

func _update_direction():
	var target = _get_nearest_enemy()
	if target:
		direction = global_position.direction_to(target.global_position).normalized()
	else:
		est_actif = false
		set_deferred("monitoring", false)
		sprite.play("destroy")
		await sprite.animation_finished
		queue_free()

func _get_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var in_range: Array = []
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == _last_hit_enemy:
			continue
		if global_position.distance_to(enemy.global_position) <= 500.0:
			in_range.append(enemy)
			
	if in_range.is_empty():
		return null
	
	in_range.sort_custom(func(a, b):
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	return in_range[0]
