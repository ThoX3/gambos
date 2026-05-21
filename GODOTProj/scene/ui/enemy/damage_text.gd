extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func afficher_degats(montant: int) -> void:
	text = str(montant)
	
	pivot_offset = size / 2.0
	
	var tween = create_tween().set_parallel(true)
	
	# --- ANIMATION 1 : Le petit bond (Arc de cercle sur Y et axe X aléatoire) ---
	var cible_y = position.y - randf_range(40, 60) # Hauteur du saut
	var cible_x = position.x + randf_range(-30, 30) # Orientation aléatoire sur X
	
	# On fait monter le texte rapidement avec une courbe d'atténuation (Ease Out)
	tween.tween_property(self, "position:y", cible_y, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", cible_x, 0.5).set_trans(Tween.TRANS_LINEAR)
	
	# --- ANIMATION 2 : La Couleur (Rouge -> Blanc) ---
	# On passe du rouge de départ au blanc pur (Color.WHITE) en 0.2 secondes
	tween.tween_property(self, "theme_override_colors/font_color", Color.WHITE, 0.2)
	
	# Création d'un second Tween séquentiel pour la disparition (Fade Out)
	var tween_disparition = create_tween()
	# On attend 0.6 secondes que le bond se termine (effet de pause en l'air)
	tween_disparition.tween_interval(0.6)
	# On fait descendre l'opacité (Modulate Alpha) à 0 en 0.3 secondes
	tween_disparition.tween_property(self, "modulate:a", 0.0, 0.3)
	
	# On détruit automatiquement le nœud quand l'animation est finie
	tween_disparition.tween_callback(queue_free)
