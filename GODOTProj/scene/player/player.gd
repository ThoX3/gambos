extends CharacterBody2D

signal health_depleted

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var Stats: Resource
@export var speed: float = 300.0
@export var projectile_data: ProjectileData
@export var projectile_scene: PackedScene

@export var invincibility_duration: float = 1.5
var is_invincible: bool = false
var blink_timer: float = 0.0
var _fire_timer: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
	$AnimatedSprite2D.play("walk")
	$LevelUpOver.hide()
	$LevelUpUnder.hide()
	GameManager.initialize.connect(_on_initialize)
	if projectile_data:
		projectile_data = projectile_data.duplicate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction:
		velocity = direction * speed
		animated_sprite_2d.flip_h = direction.x > 0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	move_and_slide()
	
	if is_invincible:
		_handle_blinking(delta)
		
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	
	if overlapping_mobs.size() > 0 and not is_invincible:
		Stats.current_health -= overlapping_mobs[0].attack_damage
		GameManager.health_changed.emit()
		if Stats.current_health <= 0.0:
			%HurtBox.monitoring = false
			health_depleted.emit()
		else:
			start_invincibility() 
	
	# --- Tir automatique ---
	if projectile_data and projectile_scene:
		_fire_timer += delta
		if _fire_timer >= 1.0 / projectile_data.fire_rate:
			_fire_timer = 0.0
			var target = _get_nearest_enemy()
			if target:
				_shoot(target)

func gainXP(value: int):
	Stats.currentXp += value
	
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
	Stats.requiredXp = 10*(Stats.level**2)
	
	GameManager.level_up.emit()
	
	
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


func _on_level_up_over_animation_finished() -> void:
	$LevelUpOver.hide()
	$LevelUpOver.stop()
	$LevelUpUnder.hide()

func _get_nearest_enemy() -> Enemy_Base:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var nearest: Enemy_Base = null
	var nearest_dist: float = projectile_data.range

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest

func _shoot(target: Enemy_Base) -> void:
	for i in range(projectile_data.projectile_count):
		var projectile: Projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		var angle_offset = (i - (projectile_data.projectile_count - 1) / 2.0 ) * 0.2
		var dir = global_position.direction_to(target.global_position).rotated(angle_offset)
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
		capacityEffectData.TargetCapacityEffect.PLAYER_SPEED:
			speed += effect.value
		capacityEffectData.TargetCapacityEffect.PLAYER_COLLECT_RANGE:
			Stats.collectRadius += effect.value
			$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
		capacityEffectData.TargetCapacityEffect.PLAYER_DAMAGE:
			projectile_data.damage += effect.value
		capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_SPEED:
			projectile_data.fire_rate += effect.value
		capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_RANGE:
			projectile_data.range += effect	.value

func _add_new_skill(effect: upgradeData.available_skill) -> void:
	print("En cours")

func _upgrade_existing_skill(skill, value) -> void:
	print("En cours")
