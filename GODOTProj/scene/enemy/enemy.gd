extends CharacterBody2D
class_name Enemy_Base

@export var stats: EnemyData
@onready var attack_damage = stats.attack_damage

@onready var sprite = $AnimatedSprite2D

var player = null

func _ready():
	if stats:
		setup_enemy()
		stats.hp = stats.max_hp
		# On récupère le joueur via le groupe au démarrage
		player = get_tree().get_first_node_in_group("Player")
		add_to_group("Enemy")
	else:
		push_error("No stats assigned!")

func setup_enemy():
	if stats.texture:
		sprite.sprite_frames = stats.texture
		sprite.play("walk")

func _physics_process(_delta):
	if not stats:
		return
		
	if not player or not is_instance_valid(player):
		print("DÉBOGAGE: Je ne trouve pas le joueur ! Vérifie le groupe 'Player'")
		return

	# 1. Calcul de la direction directe vers le joueur (Méthode GDQuest)
	var direction = global_position.direction_to(player.global_position)
	
	# 2. Retournement du sprite selon l'axe X
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
	
	# 3. Application de la vitesse brute sur le vecteur directionnel
	velocity = direction * stats.movement_speed

	# 4. Déplacement et gestion automatique du glissement physique contre le joueur/obstacles
	move_and_slide()

func take_damage(amount: int) -> void:
	stats.hp -= amount
	print(stats.hp)
	if stats.hp <= 0:
		queue_free()
