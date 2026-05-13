extends CharacterBody2D

@export var stats: EnemyData 

@onready var sprite = $Sprite2D

var player = null

func _ready():
	if stats:
		setup_enemy()
		player = get_parent().find_child("Player")
		print(player)
	else:
		push_error("No stats assigned!")

func setup_enemy():
	if stats.texture:
		sprite.texture = stats.texture
	sprite.modulate = stats.aura_color

func _physics_process(delta):
	if not stats or not player:
		return

	var direction = (player.global_position - global_position).normalized()

	velocity = direction * stats.movement_speed
	
	move_and_slide()

	if velocity.x != 0:
		sprite.flip_h = velocity.x > 0
