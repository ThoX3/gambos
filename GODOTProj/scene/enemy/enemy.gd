extends CharacterBody2D
class_name Enemy_Base

@export var stats: EnemyData
@onready var attack_damage = stats.attack_damage
@onready var hp = stats.max_hp

@onready var sprite = $AnimatedSprite2D

var player = null
var tutorial_mode: bool = false

func get_weight() -> float:
	return stats.weight if stats else 1.0

@export var SEAWEED_SCENE: PackedScene
@export var PEARL_SCENE: PackedScene
@export var DAMAGE_TEXT_SCENE: PackedScene
@export var SPLASH_EFFECT_SCENE: PackedScene

func _ready():
	if stats:
		setup_enemy()
		# On récupère le joueur via le groupe au démarrage
		player = get_tree().get_first_node_in_group("Player")
		add_to_group("Enemy")
	else:
		push_error("No stats assigned!")

func setup_enemy():
	if stats.texture:
		sprite.sprite_frames = stats.texture
		sprite.play("walk")
		start_breathing_animation()

func _physics_process(delta):
	if not stats:
		return
		
	if not player or not is_instance_valid(player):
		return
		
	if not player.is_physics_processing():
		velocity = Vector2.ZERO
		return

	# Calcul de la direction directe vers le joueur (Méthode GDQuest)
	var direction := global_position.direction_to(player.global_position)
	
	# Retournement du sprite selon l'axe X
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
	
	# Application de la vitesse brute sur le vecteur directionnel
	velocity = direction * stats.movement_speed

	_move_with_push(delta)

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

func take_damage(amount: int) -> int:
	if is_queued_for_deletion():
		return 0

	var removed_hp: int = min(amount, hp)
	
	hp -= amount
	
	if hp <= 0:
		GameManager.register_enemy_kill(stats)
		$CollisionShape2D.set_deferred("disabled", true)
		_creer_splash_mort()
		_drop_experience()
		_drop_pearl()
		queue_free()
	
	# Affichage des dégâts
	_creer_texte_degats(removed_hp)
	
	var tween := create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	return removed_hp
		
func _drop_experience() -> void:
	if tutorial_mode:
		return
		
	var xp_restante : int = stats.xp_drop
	var valeur_max_par_morceau : int = 5
	
	# Rayon et force de l'expulsion
	var force_expulsion : float = 180.0 

	# Tant qu'il reste de l'XP à distribuer
	while xp_restante > 0:
		var valeur_morceau : int = min(xp_restante, valeur_max_par_morceau)
		xp_restante -= valeur_morceau
		
		var new_seaweed = SEAWEED_SCENE.instantiate()
		new_seaweed.xp_amount = valeur_morceau
		new_seaweed.global_position = self.global_position
		
		var angle_aleatoire : float = randf_range(0, PI * 2)
		var direction_expulsion := Vector2.RIGHT.rotated(angle_aleatoire)
		var impulsion := direction_expulsion * randf_range(force_expulsion * 0.6, force_expulsion)
		
		if "velocity" in new_seaweed:
			new_seaweed.velocity = impulsion
		elif "impulsion_depart" in new_seaweed:
			# Si vous préférez nommer votre variable différemment
			new_seaweed.impulsion_depart = impulsion
		
		# Ajout à la scène de manière différée
		get_parent().call_deferred("add_child", new_seaweed)
	
func _drop_pearl() -> void:
	if tutorial_mode:
		var new_pearl = PEARL_SCENE.instantiate()
		new_pearl.global_position = self.global_position
		get_parent().call_deferred("add_child", new_pearl)
		return
		
	if randf() <= stats.pearl_drop_probability:
		var pearl_count := randi_range(stats.pearl_drop_range.x, stats.pearl_drop_range.y)
		
		for __ in range(pearl_count):
			var new_pearl = PEARL_SCENE.instantiate()
			new_pearl.global_position = self.global_position + 15 * Vector2(2 * randf() - 1, 2 * randf() - 1)
			get_parent().call_deferred("add_child", new_pearl)

func _creer_texte_degats(montant: int) -> void:
	if SaveManager.current_save and not SaveManager.current_save.setting_show_damage_numbers:
		return
		
	var texte_instance: Node = DAMAGE_TEXT_SCENE.instantiate()
	
	texte_instance.global_position = self.global_position + Vector2(-20, -40)
	
	get_parent().add_child(texte_instance)
	
	texte_instance.afficher_degats(montant)

func _creer_splash_mort() -> void:
	var splash = SPLASH_EFFECT_SCENE.instantiate()
	
	splash.global_position = self.global_position
	
	get_parent().call_deferred("add_child", splash)

func start_breathing_animation() -> void:
	var tween = create_tween().set_loops()
	
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
