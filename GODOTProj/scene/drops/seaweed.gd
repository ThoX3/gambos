extends Area2D

@export var valeur_xp : int = 1
@export var vitesse_aspiration = 400
var cible = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play("Idle")
	scale = Vector2(valeur_xp/20.0+0.5, valeur_xp/20.0+0.5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if cible != null:
		var direction = (cible.global_position - global_position).normalized()
		
		global_position += direction * vitesse_aspiration * delta
		
		if global_position.distance_to(cible.global_position) < 10:
			collect()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		cible = area.get_parent()

func collect():
	cible.gainXP(valeur_xp)
	vitesse_aspiration = 0
	$AnimatedSprite2D.play("Collecte")


func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()
