extends CharacterBody2D

signal health_depleted

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var Stats: Resource
@export var speed: float = 100
@export var projectile_data: ProjectileData
@export var projectile_scene: PackedScene
@export var knockback_force: float = 300.0
var _knockback_velocity: Vector2 = Vector2.ZERO

@export var invincibility_duration: float = 1.5
var is_invincible: bool = false
var blink_timer: float = 0.0
var _fire_timer: float = 0.0

var xp_multiplier: float = 1.0
var regen_rate: float = 0.0
var _regen_timer: float = 0.0
var thorns_damage: int = 0

@export var projectile_sable_data: ProjectileDataSable
@export var projectile_sable_scene: PackedScene  # la même scène que le boss : projectile_sable.tscn
var _attaque_sable_debloquee: bool = false
var _sable_fire_timer: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
	$AnimatedSprite2D.play("walk")
	$LevelUpOver.hide()
	$LevelUpUnder.hide()
	_on_initialize()
	# Charger l'état de débloquage depuis la sauvegarde
	if SaveManager.current_save:
		_attaque_sable_debloquee = SaveManager.current_save.boss_araignee_battu
			
	if projectile_sable_data:
		projectile_sable_data = projectile_sable_data.duplicate()
	if projectile_data:
		projectile_data = projectile_data.duplicate()
	call_deferred("enable_camera_smoothing")
	GameManager.boss_araignee_vaincu.connect(_on_boss_araignee_vaincu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if regen_rate > 0 and Stats.current_health < Stats.max_health and Stats.current_health > 0:
		_regen_timer += delta
		if _regen_timer >= 1.0:
			_regen_timer -= 1.0
			Stats.current_health += regen_rate
			if Stats.current_health > Stats.max_health:
				Stats.current_health = Stats.max_health
			GameManager.health_changed.emit()

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Velocity de mouvement normal
	var move_velocity = Vector2.ZERO
	if direction:
		move_velocity = direction * speed
		animated_sprite_2d.flip_h = direction.x > 0

	# Amortissement du knockback (indépendant de la velocity de déplacement)
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_force * 2 * delta)

	# On combine les deux
	velocity = move_velocity + _knockback_velocity

	move_and_slide()
	
	if is_invincible:
		_handle_blinking(delta)
		
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	
	if overlapping_mobs.size() > 0 and not is_invincible:
		Stats.current_health -= overlapping_mobs[0].attack_damage
		# Thorns damage
		if thorns_damage > 0 and overlapping_mobs[0].has_method("take_damage"):
			overlapping_mobs[0].take_damage(thorns_damage)
			
		# Calcul de la direction opposée à l'ennemi
		var knockback_dir = overlapping_mobs[0].global_position.direction_to(global_position)
		_knockback_velocity = knockback_dir * knockback_force  # ← remplace le commentaire
		GameManager.health_changed.emit()
		if Stats.current_health <= 0.0:
			%HurtBox.monitoring = false
			health_depleted.emit()
			GameManager.GameOver.emit()
		else:
			
			AudioManager.play_sound_2d("GAMBOS_hurt", global_position)
			start_invincibility() 
	
	# --- Tir automatique ---
	if projectile_data and projectile_scene:
		_fire_timer += delta
		if _fire_timer >= 1.0 / projectile_data.fire_rate:
			_fire_timer = 0.0
			var targets = _get_nearest_enemies(projectile_data.projectile_count)
			for target in targets:
				_shoot_single(target)
	
	# --- Attaque sable (stick droit) ---
	if _attaque_sable_debloquee and projectile_sable_data and projectile_sable_scene:
		_sable_fire_timer -= delta
		var stick = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if stick.length() > 0.2 and _sable_fire_timer <= 0.0:
			_sable_fire_timer = projectile_sable_data.cooldown
			_tirer_sable(stick.normalized())


func gainXP(value: int):
	Stats.currentXp += int(value * xp_multiplier)
	
	if Stats.currentXp >= Stats.requiredXp:
		levelUp()
	
	GameManager.xp_changed.emit()

func levelUp():
	# Augmentation du niveau
	Stats.level += 1
	
	$LevelUpOver.show()
	$LevelUpOver.play("Level up")
	$LevelUpUnder.show()
	
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
	Stats.max_health = 10.0
	Stats.current_health = Stats.max_health
	Stats.level = 1
	Stats.requiredXp = 10
	Stats.currentXp = 0
	Stats.collectRadius = 200
	Stats.collected_pearls = 0

func apply_pearl_upgrades(save: SaveData) -> void:
	Stats.max_health += save.upgrade_health_level * 5.0
	Stats.current_health = Stats.max_health
	
	speed += save.upgrade_speed_level * 20.0
	
	xp_multiplier = 1.0 + (save.upgrade_xp_gain_level * 0.1)
	regen_rate = save.upgrade_regen_level * 0.1
	thorns_damage = save.upgrade_thorns_level * 2
	
	if projectile_data:
		projectile_data.damage += save.upgrade_damage_level * 1
		projectile_data.fire_rate += save.upgrade_attack_speed_level * 0.1
		projectile_data.projectile_count += save.upgrade_projectile_level

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

func _shoot_single(target: Enemy_Base) -> void:
	var projectile: Projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	var dir = global_position.direction_to(target.global_position)
	projectile.global_position = global_position
	projectile.setup(projectile_data, dir)
	
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
			Stats.current_health += effect.value # A voir si on soigne le montant ajouté
			GameManager.health_changed.emit()
			if Stats.current_health <= 0.0 or Stats.max_health <= 0.0:
				%HurtBox.monitoring = false
				health_depleted.emit()
		capacityEffectData.TargetCapacityEffect.PLAYER_SPEED:
			speed += effect.value
		capacityEffectData.TargetCapacityEffect.PLAYER_COLLECT_RANGE:
			Stats.collectRadius += effect.value
			$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
		capacityEffectData.TargetCapacityEffect.PLAYER_DAMAGE:
			projectile_data.damage += effect.value
		capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_SPEED:
			projectile_data.fire_rate += effect.value
			if projectile_data.fire_rate <= 0.0:
				projectile_data.fire_rate = 0.5
		capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_RANGE:
			projectile_data.range += effect.value

func _add_new_skill(skill: upgradeData.available_skill) -> void:
	match skill:
		upgradeData.available_skill.MORE_PROJECTILE:
			projectile_data.projectile_count += 1

func _upgrade_existing_skill(skill_type: upgradeData.available_skill, effect: skillEffectData) -> void:
	print("En cours")
	
func enable_camera_smoothing():
	$Camera.position_smoothing_enabled = true

func take_damage(degats: float) -> void:
	# Si le joueur clignote déjà, il esquive le coup !
	if is_invincible:
		return
		
	# On retire les PV et on met à jour l'interface
	Stats.current_health -= degats
	GameManager.health_changed.emit()
	
	print("Ouch ! PV restants : ", Stats.current_health)
	
	# Vérification de la mort
	if Stats.current_health <= 0.0:
		%HurtBox.monitoring = false
		health_depleted.emit()
	else:
		# S'il survit, on joue ton son et on lance l'invincibilité
		AudioManager.play_sound_2d("GAMBOS_hurt", global_position)
		start_invincibility()

func _tirer_sable(direction: Vector2) -> void:
	var proj = projectile_sable_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position
	proj.direction = direction
	proj.appartient_au_joueur = true
	proj.vitesse = projectile_sable_data.speed
	proj.degats = projectile_sable_data.damage
	# Correction des layers : le projectile joueur doit voir les ennemis (layer 2)
	proj.collision_layer = 4   # même layer que le projectile normal du joueur
	proj.collision_mask = 2    # détecte les ennemis (layer 2)

func _on_boss_araignee_vaincu() -> void:
	_attaque_sable_debloquee = true
	print("Attaque sable débloquée !")
