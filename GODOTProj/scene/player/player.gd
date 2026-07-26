extends CharacterBody2D

# Propriétés de base
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var corpse_scene: PackedScene
@export var stats: Resource
@export var weight: float = 10.0
@export var knockback_force: float = 300.0
var _knockback_velocity: Vector2 = Vector2.ZERO
@export var invincibility_duration: float = 1.5
var is_invincible: bool = false  # ne peut recevoir aucun dégat
var prevent_death: bool = false  # minore les hp à 0.1
var can_shoot: bool = true  # tire plus aucun projectile
var can_level_up: bool = true  # accumule l'xp sans level up
var blink_timer: float = 0.0
var _regen_timer: float = 0.0
var _thorns_timer: float = 0.0

# Stats des armes
# Bulles
@export var projectile_data: ProjectileData
@export var projectile_scene: PackedScene
var _fire_timer: float = 0.0
const BUBBLE_SPEED_FACTOR: float = 1.2 
# Sable
@export var projectile_sable_data: ProjectileDataSable
@export var projectile_sable_scene: PackedScene  
var _sable_fire_timer: float = 0.0
var sable_pierce: int = 0
var sable_zone: float = 0.0
var sable_count: int = 0
# Pics
@export var projectile_pics_data: ProjectileDataPics
@export var pics_scene: PackedScene
var _pics_fire_timer: float = 0.0
var pic_push: float = 0.0
var pic_division: int = 0

# Effets
# Poison
var _poison_actif: bool = false
var _poison_timer_total: float = 0.0     
var _poison_tick_timer: float = 0.0     
var _poison_degats_tick: int = 2         
var _poison_intervalle: float = 1.0     
var _poison_speed_mult: float = 1.0      

func get_weight() -> float:
	return weight


# ════════════════════════════════════════════════════════════════════
#  INITIALISATION
# ════════════════════════════════════════════════════════════════════
func _ready() -> void:
	$Area2D/PlayerCollectRadius.shape.radius = stats.collectRadius
	if SaveManager.current_save:
		if not SaveManager.current_save.tutorial_completed:
			$AnimatedSprite2D.play("tuto")
		elif SaveManager.current_save.gambos_is_king:
			$AnimatedSprite2D.play("king_walk")
		else:
			$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("walk")
	$LevelUpOver.hide()
	$LevelUpUnder.hide()
	_on_initialize()
	
	GameManager.gambos_devenu_roi.connect(_on_gambos_devenu_roi)
	
	update_deep_sea_light()

	if projectile_data:
		projectile_data = projectile_data.duplicate()
	if projectile_sable_data:
		projectile_sable_data = projectile_sable_data.duplicate()
	if projectile_pics_data:
		projectile_pics_data = projectile_pics_data.duplicate()

func update_deep_sea_light() -> void:
	if has_node("DeepSeaLight"):
		await get_tree().process_frame
		if get_tree().get_nodes_in_group("deep_sea").size() > 0:
			$DeepSeaLight.show()
		else:
			$DeepSeaLight.hide()
	call_deferred("enable_camera_smoothing")
	
func enable_camera_smoothing():
	$Camera.position_smoothing_enabled = true

func _on_initialize():
	var save = SaveManager.current_save

	if save.run_en_cours and save.run_player_stats != null:
		initialize_stats_from_saved_run(save)
	else:
		initialize_stats_from_scratch(save)
		
	# Sync HUD
	var main_node = get_tree().get_first_node_in_group("Main")
	if main_node and main_node.has_node("UI/Hud"):
		var hud = main_node.get_node("UI/Hud")
		hud.Stats = stats
		hud._update_health_bar()
		hud._update_progres_bar()
		hud._update_level()

func initialize_stats_from_saved_run(save):
	stats = save.run_player_stats.duplicate(true)

	var lvl_sable_pierce = save.upgrade_projectile_sable_pierce_level
	var lvl_sable_zone = save.upgrade_projectile_sable_zone_damage_level
	var lvl_sable_count = save.upgrade_projectile_sable_count_level

	sable_pierce = UpgradeManager.get_effect_projectile_sable_pierce(lvl_sable_pierce)
	sable_zone = UpgradeManager.get_effect_projectile_sable_zone_damage(lvl_sable_zone)
	sable_count = UpgradeManager.get_effect_projectile_sable_count(lvl_sable_count)
	
	var lvl_pic_push = save.upgrade_projectile_pic_push_level
	var lvl_pic_division = save.upgrade_projectile_pic_division_level
	
	pic_push = UpgradeManager.get_effect_projectile_pic_push(lvl_pic_push)
	pic_division = UpgradeManager.get_effect_projectile_pic_division(lvl_pic_division)

	if projectile_data:
		projectile_data.damage = stats.proj_damage
		projectile_data.fire_rate = stats.proj_fire_rate
		projectile_data.range = stats.proj_range
		projectile_data.projectile_count = stats.proj_count
		projectile_data.bounce_count = stats.proj_bounce

	$Area2D/PlayerCollectRadius.shape.radius = stats.collectRadius
	
func initialize_stats_from_scratch(save):
	var lvl_health = save.upgrade_health_level
	var lvl_health_2 = save.upgrade_health_2_level
	var lvl_speed = save.upgrade_speed_level
	var lvl_speed_2 = save.upgrade_speed_2_level
	var lvl_xp = save.upgrade_xp_gain_level
	var lvl_regen = save.upgrade_regen_level
	var lvl_collect = save.upgrade_collection_radius_level
	var lvl_bubble = save.upgrade_bubble_division_level
	var lvl_thorns = save.upgrade_thorns_level
	var lvl_damage = save.upgrade_damage_level
	var lvl_damage_2 = save.upgrade_damage_2_level
	var lvl_atk_spd = save.upgrade_attack_speed_level
	var lvl_atk_spd_2 = save.upgrade_attack_speed_2_level
	var lvl_bounce = save.upgrade_projectile_bounce_level

	var lvl_sable_pierce = save.upgrade_projectile_sable_pierce_level
	var lvl_sable_zone = save.upgrade_projectile_sable_zone_damage_level
	var lvl_sable_count = save.upgrade_projectile_sable_count_level

	sable_pierce = UpgradeManager.get_effect_projectile_sable_pierce(lvl_sable_pierce)
	sable_zone = UpgradeManager.get_effect_projectile_sable_zone_damage(lvl_sable_zone)
	sable_count = UpgradeManager.get_effect_projectile_sable_count(lvl_sable_count)
	
	var lvl_pic_push = save.upgrade_projectile_pic_push_level
	var lvl_pic_division = save.upgrade_projectile_pic_division_level
	
	pic_push = UpgradeManager.get_effect_projectile_pic_push(lvl_pic_push)
	pic_division = UpgradeManager.get_effect_projectile_pic_division(lvl_pic_division)

	stats.max_health = UpgradeManager.get_effect_health(lvl_health) + UpgradeManager.get_effect_health_2(lvl_health_2)
	stats.current_health = stats.max_health
	stats.level = 1
	stats.requiredXp = 10
	stats.currentXp = 0
	stats.collected_pearls = 0

	stats.speed = UpgradeManager.get_effect_speed(lvl_speed) + UpgradeManager.get_effect_speed_2(lvl_speed_2)
	stats.xp_multiplier = UpgradeManager.get_effect_xp_gain(lvl_xp)
	stats.regen_rate = UpgradeManager.get_effect_regen(lvl_regen)

	stats.collectRadius = UpgradeManager.get_effect_collection_radius(lvl_collect)
	$Area2D/PlayerCollectRadius.shape.radius = stats.collectRadius

	var bubble_count = UpgradeManager.get_effect_bubble_division(lvl_bubble)

	var thorns_effects = UpgradeManager.get_effect_thorns(lvl_thorns)
	stats.thorns_damage = int(thorns_effects["damage"])
	stats.thorns_interval = thorns_effects["interval"]

	if projectile_data:
		stats.proj_damage = int(UpgradeManager.get_effect_damage(lvl_damage) + UpgradeManager.get_effect_damage_2(lvl_damage_2))
		stats.proj_fire_rate = UpgradeManager.get_effect_attack_speed(lvl_atk_spd) + UpgradeManager.get_effect_attack_speed_2(lvl_atk_spd_2)
		stats.proj_count = bubble_count
		stats.proj_bounce = UpgradeManager.get_effect_projectile_bounce(lvl_bounce)
		projectile_data.damage = stats.proj_damage
		projectile_data.fire_rate = stats.proj_fire_rate
		projectile_data.projectile_count = stats.proj_count
		projectile_data.bounce_count = stats.proj_bounce	
		
# ════════════════════════════════════════════════════════════════════
#  CYCLE DE VIE
# ════════════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	_tick_poison(delta)

	if stats.regen_rate > 0 and stats.current_health < stats.max_health and stats.current_health > 0:
		_regen_timer += delta
		if _regen_timer >= 1.0:
			_regen_timer -= 1.0
			stats.current_health += stats.regen_rate
			if stats.current_health > stats.max_health:
				stats.current_health = stats.max_health
			GameManager.health_changed.emit()

	if stats.thorns_damage > 0:
		_thorns_timer -= delta
		if _thorns_timer <= 0.0:
			if %HurtBox.monitoring:
				var overlapping_mobs = %HurtBox.get_overlapping_bodies()
				if overlapping_mobs.size() > 0:
					for mob in overlapping_mobs:
						if mob.has_method("take_damage"):
							mob.take_damage(stats.thorns_damage)
				_thorns_timer = stats.thorns_interval


func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Velocity de mouvement normal (avec multiplicateur de poison)
	var move_velocity = Vector2.ZERO
	if direction:
		move_velocity = direction * stats.speed * _poison_speed_mult
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
		var stick: Vector2 = Input.get_vector("shoot_left", "shoot_right", "shoot_up", "shoot_down")
		if stick.length() > 0.2 and _sable_fire_timer <= 0.0:
			_sable_fire_timer = (1.0 / max(0.01, stats.proj_fire_rate)) * projectile_sable_data.cadence_ratio
			_tirer_sable(stick.normalized())

	# --- Attaque Pics (touche Y / clic stick droit) ---
	if can_shoot and SaveManager.current_save.mondes_completes_total >= 2 and pics_scene:
		_pics_fire_timer -= delta
		var pics_presse: bool = Input.is_action_pressed("shoot_center")
		if pics_presse and _pics_fire_timer <= 0.0:
			_pics_fire_timer = (1.0 / max(0.01, stats.proj_fire_rate)) * projectile_pics_data.cadence_ratio
			_tirer_pics_en_cercle()
	
	if is_invincible:
		_handle_blinking(delta)
		
	if %HurtBox.monitoring:
		var overlapping_mobs = %HurtBox.get_overlapping_bodies()
		
		if overlapping_mobs.size() > 0 and not is_invincible:
			stats.current_health -= overlapping_mobs[0].attack_damage
			# Thorns damage
			if stats.thorns_damage > 0 and overlapping_mobs[0].has_method("take_damage"):
				overlapping_mobs[0].take_damage(stats.thorns_damage)
				
			# Calcul de la direction opposée à l'ennemi
			var knockback_dir = overlapping_mobs[0].global_position.direction_to(global_position)
			_knockback_velocity = knockback_dir * knockback_force  
			GameManager.health_changed.emit()
			GameManager.joy_vibration(0, 0.2, 0.5, 0.4)
			if stats.current_health <= 0.0:
				if prevent_death:
					stats.current_health = 0.1
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


# ════════════════════════════════════════════════════════════════════
#  POISON
# ════════════════════════════════════════════════════════════════════

# Appelée par le nuage de fumée du boss poisson
func apply_poison(duree: float = 10.0, degats_tick: int = 2, intervalle: float = 1.0, ralenti_pct: float = 0.20) -> void:
	# Ralentissement via multiplicateur (robuste face aux upgrades de vitesse)
	_poison_speed_mult = 1.0 - ralenti_pct

	# (Re)lance / rafraîchit la durée du poison
	_poison_actif = true
	_poison_timer_total = duree
	_poison_degats_tick = degats_tick
	_poison_intervalle = intervalle
	# On ne reset pas _poison_tick_timer pour ne pas retarder le prochain tick

	_appliquer_teinte_poison()


func _tick_poison(delta: float) -> void:
	if not _poison_actif:
		return

	_poison_timer_total -= delta
	_poison_tick_timer += delta

	# Dégâts périodiques (le poison ignore l'invincibilité / i-frames)
	if _poison_tick_timer >= _poison_intervalle:
		_poison_tick_timer -= _poison_intervalle
		stats.current_health -= _poison_degats_tick
		GameManager.health_changed.emit()
		GameManager.joy_vibration(0, 0.15, 0.3, 0.25)
		if stats.current_health <= 0.0:
			if prevent_death:
				stats.current_health = 0.1
			else:
				_fin_poison()
				%HurtBox.monitoring = false
				death()
				return

	# Fin du poison
	if _poison_timer_total <= 0.0:
		_fin_poison()


func _fin_poison() -> void:
	_poison_actif = false
	_poison_timer_total = 0.0
	_poison_tick_timer = 0.0
	_poison_speed_mult = 1.0
	# Restaure la couleur normale (sauf si en train de clignoter)
	if not is_invincible:
		animated_sprite_2d.modulate = Color.WHITE


func _appliquer_teinte_poison() -> void:
	# Teinte verdâtre uniquement si pas en clignotement d'invincibilité
	if not is_invincible:
		animated_sprite_2d.modulate = Color(0.6, 1.0, 0.6)


# ════════════════════════════════════════════════════════════════════
#  PROGRESSION
# ════════════════════════════════════════════════════════════════════
func gainXP(value: int):
	stats.currentXp += int(value * stats.xp_multiplier)
	if stats.currentXp >= stats.requiredXp and can_level_up:
		levelUp()
	else:
		GameManager.xp_changed.emit()

func check_level_up():
	if stats.currentXp >= stats.requiredXp and can_level_up:
		levelUp()

func levelUp():
	stats.level += 1
	$LevelUpOver.show()
	$LevelUpOver.play("Level up")
	$LevelUpUnder.show()
	GameManager.joy_vibration(0, 0.8, 0.2, 0.1)
	stats.currentXp -= stats.requiredXp
	stats.requiredXp = 10 + (stats.level ** 2) * 2
	GameManager.level_up.emit()


func gainPearl(amount: int):
	stats.collected_pearls += amount
	GameManager.pearls_changed.emit()


# ════════════════════════════════════════════════════════════════════
#  INVINCIBILITÉ
# ════════════════════════════════════════════════════════════════════
func start_invincibility():
	is_invincible = true
	var timer = get_tree().create_timer(invincibility_duration)
	timer.timeout.connect(_on_invincibility_timeout)


func _on_invincibility_timeout():
	is_invincible = false
	animated_sprite_2d.visible = true
	# Rétablit la teinte poison si toujours empoisonné, sinon couleur normale
	if _poison_actif:
		animated_sprite_2d.modulate = Color(0.6, 1.0, 0.6)
	else:
		animated_sprite_2d.modulate = Color.WHITE


func _handle_blinking(delta):
	blink_timer += delta
	if blink_timer >= 0.1:
		animated_sprite_2d.visible = not animated_sprite_2d.visible
		blink_timer = 0.0
		

func _on_level_up_over_animation_finished() -> void:
	$LevelUpOver.hide()
	$LevelUpOver.stop()
	$LevelUpUnder.hide()


# ════════════════════════════════════════════════════════════════════
#  TIR
# ════════════════════════════════════════════════════════════════════
func _get_nearest_enemies(count: int) -> Array:
	var enemies = get_tree().get_nodes_in_group("Enemy")

	var in_range: Array = []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= projectile_data.range:
			in_range.append(enemy)

	in_range.sort_custom(func(a, b):
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)

	return in_range.slice(0, count)


func _shoot_multiple(targets: Array) -> void:
	for i in range(projectile_data.projectile_count):
		var target = targets[i % targets.size()]
		var dir := global_position.direction_to(target.global_position)

		var projectile: Projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position

		var p_data := projectile_data.duplicate()
		p_data.damage = max(1, int(projectile_data.damage * pow(0.5, i)))
		p_data.speed = max(projectile_data.speed, stats.speed * BUBBLE_SPEED_FACTOR)
		
		var current_dir := dir
		if i >= targets.size():
			current_dir = dir.rotated(randf_range(-0.15, 0.15))

		projectile.setup(p_data, current_dir)
		projectile.scale = Vector2.ONE * pow(0.75, i)


func _tirer_sable(direction: Vector2) -> void:
	_spawn_single_sable(direction, 1.0, 1.0)

	if sable_count >= 1:
		_spawn_single_sable(direction.rotated(deg_to_rad(20)), 0.5, 0.75)
		_spawn_single_sable(direction.rotated(deg_to_rad(-20)), 0.5, 0.75)

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
	proj.degats = max(1, int(stats.proj_damage * damage_multiplier * 3))
	proj.scale = Vector2(scale_multiplier, scale_multiplier)

	proj.pierce_hp = sable_pierce
	proj.zone_radius = sable_zone

	proj.collision_layer = 4   # même layer que le projectile normal du joueur
	proj.collision_mask = 7    # détecte les ennemis (layer 2) et obstacles (layer 1)
	
	
func _tirer_pics_en_cercle() -> void:
	if pics_scene == null:
		push_warning("[Joueur] pics_scene non assignée !")
		return
	var angle_step := TAU / float(projectile_pics_data.count)
	for i in range(projectile_pics_data.count):
		var proj = pics_scene.instantiate()
		var angle := i * angle_step
		proj.global_position = global_position
		proj.vitesse = projectile_pics_data.speed
		proj.degats = max(1, int(stats.proj_damage * 1.5))

		if "divisions_remaining" in proj:
			proj.divisions_remaining = pic_division
		if "max_range" in proj:
			if pic_division > 0:
				proj.max_range = projectile_pics_data.range * 0.5
			else:
				proj.max_range = projectile_pics_data.range

		# ── Empêche le friendly fire : le pic appartient au joueur ──
		if "appartient_au_joueur" in proj:
			proj.appartient_au_joueur = true
		proj.collision_layer = 4   # layer des projectiles du joueur
		proj.collision_mask = 7    # détecte les ennemis et obstacles

		get_parent().add_child(proj)
		# direction APRÈS add_child pour que les @onready du projectile soient prêts
		if "direction" in proj:
			proj.direction = Vector2(cos(angle), sin(angle))
			
	# Repousser les ennemis
	var overlapping_mobs: Array[Node2D] = %PicPushBox.get_overlapping_bodies()
	for body in overlapping_mobs:
		body.velocity_factor = pic_push

# ════════════════════════════════════════════════════════════════════
#  UPGRADES
# ════════════════════════════════════════════════════════════════════
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
			stats.max_health += effect.value
			stats.current_health += effect.value
			GameManager.health_changed.emit()
			GameManager.joy_vibration(0, 0.2, 0.5, 0.4)
			if stats.current_health <= 0.0 or stats.max_health <= 0.0:
				%HurtBox.monitoring = false
				death()
		capacityEffectData.TargetCapacityEffect.PLAYER_SPEED:
			stats.speed += effect.value
		capacityEffectData.TargetCapacityEffect.PLAYER_COLLECT_RANGE:
			stats.collectRadius += effect.value
			$Area2D/PlayerCollectRadius.shape.radius = stats.collectRadius
		capacityEffectData.TargetCapacityEffect.PLAYER_DAMAGE:
			stats.proj_damage += effect.value
			projectile_data.damage = stats.proj_damage
		capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_SPEED:
			stats.proj_fire_rate += effect.value
			if stats.proj_fire_rate <= 0.0:
				stats.proj_fire_rate = 0.5
			projectile_data.fire_rate = stats.proj_fire_rate
		capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_RANGE:
			stats.proj_range += effect.value
			projectile_data.range = stats.proj_range


func _add_new_skill(skill: upgradeData.available_skill) -> void:
	match skill:
		upgradeData.available_skill.MORE_PROJECTILE:
			stats.proj_count += 1
			projectile_data.projectile_count = stats.proj_count


func _upgrade_existing_skill(skill_type: upgradeData.available_skill, effect: skillEffectData) -> void:
	print("En cours")


# ════════════════════════════════════════════════════════════════════
#  DÉGÂTS & MORT
# ════════════════════════════════════════════════════════════════════
func take_damage(degats: float) -> void:
	if is_invincible:
		return

	GameManager.joy_vibration(0, 0.2, 0.5, 0.4)

	stats.current_health -= degats
	GameManager.health_changed.emit()

	if stats.current_health <= 0.0:
		if prevent_death:
			stats.current_health = 0.1
			AudioManager.play_sound_2d("gambos_hurt", global_position)
			start_invincibility()
		else:
			%HurtBox.monitoring = false
			death()
	else:
		AudioManager.play_sound_2d("gambos_hurt", global_position)
		start_invincibility()


func get_player_stats() -> Dictionary:
	return {
				"Niveau : " : stats.level,
				"Vie max : " : stats.max_health,
				"Vitesse de déplacement : " : stats.speed,
				"Portée de collect : " : stats.collectRadius,
				"Dégâts : " : stats.proj_damage,
				"Vitesse d'attaque : " : stats.proj_fire_rate,
				"Portée d'attaque : " : stats.proj_range
			}


func death():
	# Désactive tout comportement`
	can_level_up = false
	set_process(false)
	set_physics_process(false)
	collision_layer = 0
	collision_mask  = 0
	$HurtBox.monitoring = false
	$HurtBox.monitorable = false
	z_index = 10

	# Lance l'animation et affiche le cadavre
	var corpse: Node = corpse_scene.instantiate()
	get_parent().add_child(corpse)
	corpse.global_transform = global_transform
	$AnimatedSprite2D.play("death")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 200.0, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 2.0)\
		.set_ease(Tween.EASE_IN)

	GameManager.joy_vibration(0, 1.0, 0.0, 1.8)

	await tween.finished
	GameManager.GameOver.emit()

func _maj_apparence() -> void:
	if SaveManager.current_save:
		if not SaveManager.current_save.tutorial_completed:
			animated_sprite_2d.play("tuto")
		elif SaveManager.current_save.gambos_is_king:
			animated_sprite_2d.play("king_walk")
		else:
			animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("walk")
		
# Bascule en temps réel sur le sprite couronné dès la fin du monde 3
func _on_gambos_devenu_roi() -> void:
	if animated_sprite_2d.animation != "king_walk":
		animated_sprite_2d.play("king_walk")
