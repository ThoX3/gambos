extends Area2D

@export var valeur_xp : int = 10
@export var vitesse_aspiration = 400
var cible = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play("Idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if cible != null:
		var direction = (cible.global_position - global_position).normalized()
		
		global_position += direction * vitesse_aspiration * delta
		
		if global_position.distance_to(cible.global_position) < 10:
			collect()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Joueur"):
		cible = body
		monitoring = false

func collect():
	queue_free()
