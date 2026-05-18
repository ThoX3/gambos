extends CharacterBody2D

@export var stats: EnemyData 

@onready var sprite = $AnimatedSprite2D
@onready var nav_agent = $NavigationAgent2D

var player = null

func _ready():
	if stats:
		setup_enemy()
		player = get_tree().get_first_node_in_group("Player")
		
		nav_agent.path_desired_distance = 4.0
		nav_agent.target_desired_distance = 4.0
		
		nav_agent.velocity_computed.connect(_on_navigation_agent_2d_velocity_computed)
	else:
		push_error("No stats assigned!")

func setup_enemy():
	if stats.texture:
		sprite.sprite_frames = stats.texture
		sprite.play("walk")

func _physics_process(_delta):
	if not stats:
		return
		
	if not player:
		print("DÉBOGAGE: Je ne trouve pas le joueur ! Vérifie le groupe 'Player'")
		return

	nav_agent.target_position = player.global_position
	
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_path_position = nav_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized() * stats.movement_speed
	
	sprite.flip_h = direction.x < 0
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(direction)
	else:
		# Si l'évitement est coupé, on bouge normalement
		_on_navigation_agent_2d_velocity_computed(direction)

# Ce signal est déclenché par Godot dès que le calcul d'évitement entre ennemis est prêt
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()
