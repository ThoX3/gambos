extends BossAttack

func _init() -> void:
	id = "broyage"
	portee_max = 150.0

func executer(boss) -> void:
	var rayon_original = boss.collision_physique.shape.radius
	var degats_originaux = boss.stats.attack_damage
	
	var est_agrandi = false
	var a_inflige_degats = false
	
	boss.sprite.play("attack2")	
	
	while is_instance_valid(boss) and boss.is_inside_tree() and boss.sprite.is_playing() and boss.sprite.animation == "attack2":
		var frame_actuelle = boss.sprite.frame
		
		# --- FENÊTRE D'ATTAQUE (Frames 15 à 18) ---
		if frame_actuelle >= 15 and frame_actuelle <= 18:
			if not est_agrandi:
				boss.stats.attack_damage = boss.degats_broyage
				boss.collision_physique.shape.radius = rayon_original * 2.0
				est_agrandi = true
				
			if not a_inflige_degats:
				var distance_joueur = boss.global_position.distance_to(boss.player.global_position)
				var rayon_attaque = rayon_original * 2.0
				
				if distance_joueur <= rayon_attaque:
					if boss.player.has_method("take_damage"):
						boss.player.take_damage(boss.stats.attack_damage)
					elif boss.player.has_method("recevoir_degats"):
						boss.player.recevoir_degats(boss.stats.attack_damage)
						
					a_inflige_degats = true
				
		# --- EN DEHORS DE LA FENÊTRE DE FRAPPE ---
		else:
			if est_agrandi:
				boss.collision_physique.shape.radius = rayon_original
				boss.stats.attack_damage = degats_originaux
				est_agrandi = false
		
		if not is_instance_valid(boss) or not boss.is_inside_tree():
			return	
				
		await boss.get_tree().process_frame
		
	# --- NETTOYAGE FINAL ---
	if is_instance_valid(boss) and boss.is_inside_tree():
		boss.collision_physique.shape.radius = rayon_original
		boss.stats.attack_damage = degats_originaux
