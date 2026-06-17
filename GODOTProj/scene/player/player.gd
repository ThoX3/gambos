extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var Stats: Resource
const BASE_SPEED: float = 100.0
@export var projectile_data: ProjectileData
@export var projectile_scene: PackedScene
@export var knockback_force: float = 300.0
var _knockback_velocity: Vector2 = Vector2.ZERO

@export var weight: float = 10.0

func get_weight() -> float:
	return weight

@export var invincibility_duration: float = 1.5
var is_invincible: bool = false
var blink_timer: float = 0.0
var _fire_timer: float = 0.0
var prevent_death: bool = false

var _regen_timer: float = 0.0
var _thorns_timer: float = 0.0

@export var projectile_sable_data: ProjectileDataSable
@export var projectile_sable_scene: PackedScene  # la même scène que le boss : projectile_sable.tscn
var _attaque_sable_debloquee: bool = false
var _sable_fire_timer: float = 0.0

var sable_pierce: int = 0
var sable_zone: float = 0.0
var sable_count: int = 0
var sable_bounce: int = 0

var can_shoot: bool = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
	$AnimatedSprite2D.play("walk")
	$LevelUpOver.hide()
	$LevelUpUnder.hide()
	_on_initialize()
			
	if projectile_sable_data:
		projectile_sable_data = projectile_sable_data.duplicate()
	if projectile_data:
		projectile_data = projectile_data.duplicate()
	call_deferred("enable_camera_smoothing")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Stats.regen_rate > 0 and Stats.current_health < Stats.max_health and Stats.current_health > 0:
		_regen_timer += delta
		if _regen_timer >= 1.0:
			_regen_timer -= 1.0
			Stats.current_health += Stats.regen_rate
			if Stats.current_health > Stats.max_health:
				Stats.current_health = Stats.max_health
			GameManager.health_changed.emit()
			
	if Stats.thorns_damage > 0:
		_thorns_timer -= delta
		if _thorns_timer <= 0.0:
			var overlapping_mobs = %HurtBox.get_overlapping_bodies()
			if overlapping_mobs.size() > 0:
				for mob in overlapping_mobs:
					if mob.has_method("take_damage"):
						mob.take_damage(Stats.thorns_damage)
				_thorns_timer = Stats.thorns_interval

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Velocity de mouvement normal
	var move_velocity = Vector2.ZERO
	if direction:
		move_velocity = direction * Stats.speed
		animated_sprite_2d.flip_h = direction.x > 0

	# Amortissement du knockback (indépendant de la velocity de déplacement)
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_force * 2 * delta)

	# On combine les deux
	velocity = move_velocity + _knockback_velocity

	_move_with_push(delta)
	
	# --- Tir automatique ---
	if can_shoot and projectile_data and projectile_scene:
		_fire_timer += delta
		if _fire_timer >= 1.0 / projectile_data.fire_rate:
			_fire_timer = 0.0
			var targets = _get_nearest_enemies(projectile_data.projectile_count)
			if targets.size() > 0:
				_shoot_multiple(targets)
	
	# --- Attaque sable (stick droit) ---
	if can_shoot and SaveManager.current_save.mondes_completes_total >= 1 and projectile_sable_data and projectile_sable_scene:
		_sable_fire_timer -= delta
		var stick = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if stick.length() > 0.2 and _sable_fire_timer <= 0.0:
			_sable_fire_timer = projectile_sable_data.cooldown
			_tirer_sable(stick.normalized())
	
	if is_invincible:
		_handle_blinking(delta)
		
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	
	if overlapping_mobs.size() > 0 and not is_invincible:
		Stats.current_health -= overlapping_mobs[0].attack_damage
		# Thorns damage
		if Stats.thorns_damage > 0 and overlapping_mobs[0].has_method("take_damage"):
			overlapping_mobs[0].take_damage(Stats.thorns_damage)
			
		# Calcul de la direction opposée à l'ennemi
		var knockback_dir = overlapping_mobs[0].global_position.direction_to(global_position)
		_knockback_velocity = knockback_dir * knockback_force  # ← remplace le commentaire
		GameManager.health_changed.emit()
		GameManager.joy_vibration(0, 0.2, 0.5, 0.4)
		if Stats.current_health <= 0.0:
			if prevent_death:
				Stats.current_health = 0.1
				AudioManager.play_sound_2d("gambos_hurt", global_position)
				start_invincibility()
			else:
				%HurtBox.monitoring = false
				death()
		else:
			
			AudioManager.play_sound_2d("gambos_hurt", global_position)
			start_invincibility()

func _move_with_push(delta: float) -> void:
	var motion = velocity * delta
	for i in 4:
		var collision = move_and_collide(motion)
		if not collision:
			break
		
		var collider = collision.get_collider()
		if collider and collider.has_method("get_weight") and get_weight() > collider.get_weight():
			var push_dir = -collision.get_normal()
			var push_dist = motion.length() * (get_weight() / (get_weight() + collider.get_weight()))
			collider.move_and_collide(push_dir * push_dist)
			
		motion = collision.get_remainder().slide(collision.get_normal())

func gainXP(value: int):
	Stats.currentXp += int(value * Stats.xp_multiplier)
	
	if Stats.currentXp >= Stats.requiredXp:
		levelUp()
	
	GameManager.xp_changed.emit()

func levelUp():
	# Augmentation du niveau
	Stats.level += 1
	
	$LevelUpOver.show()
	$LevelUpOver.play("Level up")
	$LevelUpUnder.show()
	
	# Vibration manette
	GameManager.joy_vibration(0, 0.8, 0.2, 0.1)
	
	# Mise a jour de l'xp et du nouveau montant nécéssaire
	Stats.currentXp -= Stats.requiredXp
	Stats.requiredXp = 10 + (Stats.level ** 2) * 2
	
	GameManager.level_up.emit()
	
func gainPearl(amount: int):
	Stats.collected_pearls += amount
	
	GameManager.pearls_changed.emit()
	
func start_invincibility():
	is_invincible = true
	var timer = get_tree().create_timer(invincibility_duration)
	timer.timeout.connect(_on_invincibility_timeout)
	
func _on_invincibility_timeout():
	is_invincible = false
	animated_sprite_2d.visible = true
	
func _handle_blinking(delta):
	blink_timer += delta
	if blink_timer >= 0.1:
		animated_sprite_2d.visible = not animated_sprite_2d.visible
		blink_timer = 0.0
		
func _on_initialize():
	var save = SaveManager.current_save
	
	if save.run_en_cours and save.run_player_stats != null:
		Stats = save.run_player_stats.duplicate(true)
		
		var lvl_sable_pierce = save.upgrade_projectile_sable_pierce_level
		var lvl_sable_zone = save.upgrade_projectile_sable_zone_damage_level
		var lvl_sable_count = save.upgrade_projectile_sable_count_level
		var lvl_bounce = save.upgrade_projectile_bounce_level
		
		sable_pierce = UpgradeManager.get_effect_projectile_sable_pierce(lvl_sable_pierce)
		sable_zone = UpgradeManager.get_effect_projectile_sable_zone_damage(lvl_sable_zone)
		sable_count = UpgradeManager.get_effect_projectile_sable_count(lvl_sable_count)
		sable_bounce = UpgradeManager.get_effect_projectile_bounce(lvl_bounce)
		
		if projectile_data:
			projectile_data.damage = Stats.proj_damage
			projectile_data.fire_rate = Stats.proj_fire_rate
			projectile_data.range = Stats.proj_range
			projectile_data.projectile_count = Stats.proj_count
			projectile_data.bounce_count = Stats.proj_bounce
			
		$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
		_sync_hud()
		return
		
	var lvl_health = save.upgrade_health_level
	var lvl_speed = save.upgrade_speed_level
	var lvl_xp = save.upgrade_xp_gain_level
	var lvl_regen = save.upgrade_regen_level
	var lvl_collect = save.upgrade_collection_radius_level
	var lvl_bubble = save.upgrade_bubble_division_level
	var lvl_thorns = save.upgrade_thorns_level
	var lvl_damage = save.upgrade_damage_level
	var lvl_atk_spd = save.upgrade_attack_speed_level
	var lvl_bounce = save.upgrade_projectile_bounce_level
	
	var lvl_sable_pierce = save.upgrade_projectile_sable_pierce_level
	var lvl_sable_zone = save.upgrade_projectile_sable_zone_damage_level
	var lvl_sable_count = save.upgrade_projectile_sable_count_level

	sable_pierce = UpgradeManager.get_effect_projectile_sable_pierce(lvl_sable_pierce)
	sable_zone = UpgradeManager.get_effect_projectile_sable_zone_damage(lvl_sable_zone)
	sable_count = UpgradeManager.get_effect_projectile_sable_count(lvl_sable_count)
	sable_bounce = UpgradeManager.get_effect_projectile_bounce(lvl_bounce)

	Stats.max_health = UpgradeManager.get_effect_health(lvl_health)
	Stats.current_health = Stats.max_health
	Stats.level = 1
	Stats.requiredXp = 10
	Stats.currentXp = 0
	Stats.collected_pearls = 0

	Stats.speed = UpgradeManager.get_effect_speed(lvl_speed, BASE_SPEED)
	Stats.xp_multiplier = UpgradeManager.get_effect_xp_gain(lvl_xp)
	Stats.regen_rate = UpgradeManager.get_effect_regen(lvl_regen)
	
	Stats.collectRadius = UpgradeManager.get_effect_collection_radius(lvl_collect)
	$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
	
	var bubble_count = UpgradeManager.get_effect_bubble_division(lvl_bubble)
	
	# Determine thorns tick rate
	var thorns_effects = UpgradeManager.get_effect_thorns(lvl_thorns)
	Stats.thorns_damage = int(thorns_effects["damage"])
	Stats.thorns_interval = thorns_effects["interval"]
	
	if projectile_data:
		Stats.proj_damage = int(UpgradeManager.get_effect_damage(lvl_damage))
		Stats.proj_fire_rate = UpgradeManager.get_effect_attack_speed(lvl_atk_spd)
		Stats.proj_count = bubble_count
		Stats.proj_bounce = UpgradeManager.get_effect_projectile_bounce(lvl_bounce)
		# Initialize projectile_data
		projectile_data.damage = Stats.proj_damage
		projectile_data.fire_rate = Stats.proj_fire_rate
		projectile_data.projectile_count = Stats.proj_count
		projectile_data.bounce_count = Stats.proj_bounce
	_sync_hud()

func _sync_hud():
	var main_node = get_tree().get_first_node_in_group("Main")
	if main_node and main_node.has_node("UI/Hud"):
		var hud = main_node.get_node("UI/Hud")
		hud.Stats = Stats
		hud._update_health_bar()
		hud._update_progres_bar()
		hud._update_level()

func _on_level_up_over_animation_finished() -> void:
	$LevelUpOver.hide()
	$LevelUpOver.stop()
	$LevelUpUnder.hide()

func _get_nearest_enemies(count: int) -> Array:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	# Filtrer par portée et validité
	var in_range: Array = []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= projectile_data.range:
			in_range.append(enemy)
	
	# Trier par distance croissante
	in_range.sort_custom(func(a, b):
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	
	# Retourner les N plus proches
	return in_range.slice(0, count)

func _shoot_multiple(targets: Array) -> void:
	for i in range(projectile_data.projectile_count):
		# Wrap around targets if there are fewer enemies than projectiles
		var target = targets[i % targets.size()]
		var dir := global_position.direction_to(target.global_position)
		
		var projectile: Projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		
		var p_data := projectile_data.duplicate()
		p_data.damage = max(1, int(projectile_data.damage * pow(0.5, i)))
		
		var current_dir := dir
		if i >= targets.size():
			current_dir = dir.rotated(randf_range(-0.15, 0.15))
			
		projectile.setup(p_data, current_dir)
		projectile.scale = Vector2.ONE * pow(0.75, i)
	
func apply_upgrade(data: upgradeData) -> void:
	if data.typeEffects == upgradeData.effectsType.CAPACITY:
		for effect in data.capacities_effects:
			_apply_capacity_effect(effect)
	elif data.typeEffects == upgradeData.effectsType.SKILL_ADD:
		_add_new_skill(data.skill_add_effects)
	elif data.typeEffects == upgradeData.effectsType.SKILL_UPGRADE:
		for skill in data.skill_upgrade:
			_upgrade_existing_skill(skill, data.skill_upgrade[skill])
			
func _apply_capacity_effect(effect: capacityEffectData) -> void:
	match effect.targetCapacity:
		capacityEffectData.TargetCapacityEffect.PLAYER_HEALTH:
			Stats.max_health += effect.value
			Stats.current_health += max(effect.value, 0) # A voir si on soigne le montant ajouté
			GameManager.health_changed.emit()
			GameManager.joy_vibration(0, 0.2, 0.5, 0.4)
			if Stats.current_health <= 0.0 or Stats.max_health <= 0.0:
				%HurtBox.monitoring = false
				death()
		capacityEffectData.TargetCapacityEffect.PLAYER_SPEED:
			Stats.speed += effect.value
		capacityEffectData.TargetCapacityEffect.PLAYER_COLLECT_RANGE:
			Stats.collectRadius += effect.value
			$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
		capacityEffectData.TargetCapacityEffect.PLAYER_DAMAGE:
			Stats.proj_damage += effect.value
			projectile_data.damage = Stats.proj_damage
		capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_SPEED:
			Stats.proj_fire_rate += effect.value
			if Stats.proj_fire_rate <= 0.0:
				Stats.proj_fire_rate = 0.5
			projectile_data.fire_rate = Stats.proj_fire_rate
		capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_RANGE:
			Stats.proj_range += effect.value
			projectile_data.range = Stats.proj_range

func _add_new_skill(skill: upgradeData.available_skill) -> void:
	match skill:
		upgradeData.available_skill.MORE_PROJECTILE:
			Stats.proj_count += 1
			projectile_data.projectile_count = Stats.proj_count

func _upgrade_existing_skill(skill_type: upgradeData.available_skill, effect: skillEffectData) -> void:
	print("En cours")
	
func enable_camera_smoothing():
	$Camera.position_smoothing_enabled = true

func take_damage(degats: float) -> void:
	if is_invincible:
		return
	
	GameManager.joy_vibration(0, 0.2, 0.5, 0.4)
	
	# On retire les PV et on met à jour l'interface
	Stats.current_health -= degats
	GameManager.health_changed.emit()
	
	# Vérification de la mort
	if Stats.current_health <= 0.0:
		if prevent_death:
			Stats.current_health = 0.1
			AudioManager.play_sound_2d("gambos_hurt", global_position)
			start_invincibility()
		else:
			%HurtBox.monitoring = false
			death()
	else:
		# S'il survit, on joue ton son et on lance l'invincibilité
		AudioManager.play_sound_2d("gambos_hurt", global_position)
		start_invincibility()

func _tirer_sable(direction: Vector2) -> void:
	# Spawn central projectile
	_spawn_single_sable(direction, 1.0, 1.0)
	
	# Level 1: +2 projectiles at +/- 20 degrees
	if sable_count >= 1:
		_spawn_single_sable(direction.rotated(deg_to_rad(20)), 0.5, 0.75)
		_spawn_single_sable(direction.rotated(deg_to_rad(-20)), 0.5, 0.75)
		
	# Level 2: +2 more projectiles at +/- 40 degrees
	if sable_count >= 2:
		_spawn_single_sable(direction.rotated(deg_to_rad(40)), 0.25, 0.5)
		_spawn_single_sable(direction.rotated(deg_to_rad(-40)), 0.25, 0.5)

func _spawn_single_sable(dir: Vector2, damage_multiplier: float, scale_multiplier: float) -> void:
	var proj = projectile_sable_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position
	proj.direction = dir
	proj.appartient_au_joueur = true
	proj.vitesse = projectile_sable_data.speed
	proj.degats = int(projectile_sable_data.damage * damage_multiplier)
	proj.scale = Vector2(scale_multiplier, scale_multiplier)
	
	# Custom upgrades
	proj.pierce_hp = sable_pierce
	proj.zone_radius = sable_zone
	
	# Correction des layers : le projectile joueur doit voir les ennemis (layer 2)
	proj.collision_layer = 4   # même layer que le projectile normal du joueur
	proj.collision_mask = 2    # détecte les ennemis (layer 2)
	
func get_player_stats() -> Dictionary:
	var stats: Dictionary = {}
	stats = {
		"Niveau : " : Stats.level,
		"Vie max : " : Stats.max_health,
		"Vitesse de déplacement : " : Stats.speed,
		"Portée de collect : " : Stats.collectRadius,
		"Dégâts : " : Stats.proj_damage,
		"Vitesse d'attaque : " : Stats.proj_fire_rate,
		"Portée d'attaque : " : Stats.proj_range
	}
	return stats

func death():
	# ── Désactive tout comportement ──────────────────
	set_process(false)
	set_physics_process(false)
	collision_layer = 0
	collision_mask  = 0
	$HurtBox.monitoring = false
	$HurtBox.monitorable = false
	z_index = 10

	# ── Lance l'animation ────────────────────────────
	$AnimatedSprite2D.play("death")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 200.0, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 2.0)\
		.set_ease(Tween.EASE_IN)

	GameManager.joy_vibration(0, 1.0, 0.0, 1.8)

	await tween.finished
	GameManager.GameOver.emit()
