extends CharacterBody2D

@export var stats: EnemyData 

@onready var sprite = $Sprite2D

var direction = -1 
var start_x = 0.0

func _ready():
	if stats:
		setup_enemy()
		start_x = global_position.x
	else:
		push_error("No stats assigned!")

func setup_enemy():
	if stats.texture:
		sprite.texture = stats.texture
	sprite.modulate = stats.aura_color

func _physics_process(delta):
	if not stats:
		return

	velocity.x = direction * stats.movement_speed
	move_and_slide()

	var current_distance = abs(global_position.x - start_x)

	if current_distance >= stats.patrol_distance or is_on_wall():
		direction *= -1
		
		sprite.flip_h = (direction > 0)
