extends Area2D

@export var pearl_amount : int = 1
@export var vitesse_aspiration_base = 200
@export var angle_spirale_base = 2.0 

var cible = null
var isCollected = false

var vitesse_actuelle = 0.0
var temps_aspiration = 0.0
var sens_spirale = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play("Idle")
	var final_scale : float = clamp(pearl_amount / 20.0 + 0.5, 0.5, 1.5)
	scale = Vector2(final_scale, final_scale)
	
	# Pick a random spin direction (clockwise or counter-clockwise) for visual variety
	sens_spirale = [1, -1].pick_random()
	vitesse_actuelle = vitesse_aspiration_base

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if cible != null and not isCollected:
		temps_aspiration += delta
		
		# 1. Get the direct straight line to the player
		var direction = global_position.direction_to(cible.global_position)
		
		# 2. Calculate the current spiral angle
		# Starts wide, and shrinks to 0 over about ~1 second of flying
		var angle_actuel = max(0.0, angle_spirale_base - (temps_aspiration * 1.5))
		
		# 3. Rotate the vector to create the orbit effect
		direction = direction.rotated(angle_actuel * sens_spirale)
		
		# 4. Accelerate over time for that "quick snap" feel
		vitesse_actuelle += 400.0 * delta
		
		# Apply movement
		global_position += direction * vitesse_actuelle * delta
		
		# Collection check (I slightly increased the grab distance to 15 to prevent orbiting endlessly if moving too fast)
		if global_position.distance_to(cible.global_position) < 15:
			isCollected = true
			collect()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		cible = area.get_parent()

func collect():
	# Vibration
	Input.start_joy_vibration(0, 0.1, 0.0, 0.1)
	
	# Bruitage
	AudioManager.play_sound_2d("pearl_collect", position)
	
	cible.gainPearl(pearl_amount)
	vitesse_actuelle = 0 # Stop movement instantly
	queue_free()
