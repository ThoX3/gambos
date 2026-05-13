extends CharacterBody2D

var speed = 150.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta):
	# On définit une direction vers la gauche par défaut
	velocity.x = -speed
	
	# move_and_slide utilise la variable velocity pour déplacer le perso
	move_and_slide()
