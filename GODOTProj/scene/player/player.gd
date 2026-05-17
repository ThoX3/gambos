extends CharacterBody2D

signal health_depleted

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var Stats: Resource
@export var speed: float = 300.0

@export var invincibility_duration: float = 1.5
var is_invincible: bool = false
var blink_timer: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D/PlayerCollectRadius.shape.radius = Stats.collectRadius
	$AnimatedSprite2D.play("walk")
	$LevelUpOver.hide()
	$LevelUpUnder.hide()
	GameManager.initialize.connect(_on_initialize)



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
	
	const DAMAGE_RATE = 5.0 # Dans l'idéal, les dégats dépendent de l'ennemi
	if is_invincible:
		_handle_blinking(delta)
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs.size() > 0 and not is_invincible:
		Stats.current_health -= DAMAGE_RATE 
		GameManager.health_changed.emit()
		if Stats.current_health <= 0.0:
			%HurtBox.monitoring = false
			health_depleted.emit()
		else:
			start_invincibility() 

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
