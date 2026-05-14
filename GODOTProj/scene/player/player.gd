extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var Stats = Resource
@export var speed = 300.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
	$AnimatedSprite2D.play("walk")


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

func gainXP(value: int):
	Stats.currentXp += value
	
	if Stats.currentXp >= Stats.requiredXp:
		levelUp()
	
	GameManager.xp_changed.emit()

func levelUp():
	# Augmentation du niveau
	Stats.level += 1
	
	# Mise a jour de l'xp et du nouveau montant nécéssaire
	Stats.currentXp -= Stats.requiredXp
	Stats.requiredXp = 10*(Stats.level**2)
	
	
