extends BossAttack

func _init() -> void:
	id = "embuscade" 

func executer(boss) -> void:
	# ==========================================
	# PHASE 1 : Il creuse et rentre dans le trou
	# ==========================================
	boss.sprite.play("attack1.1") 
	await boss.sprite.animation_finished
	
	if not is_instance_valid(boss) or not boss.is_inside_tree():
		return
		
	# ==========================================
	# PHASE 2 : Poursuite souterraine
	# ==========================================
	boss.sprite.play("attack1.2")
	var vitesse_souterraine = boss.vitesse_embuscade
	
	while is_instance_valid(boss) and boss.is_inside_tree() and boss.global_position.distance_to(boss.player.global_position) > 80.0:		
		var delta = boss.get_process_delta_time()
		boss.global_position = boss.global_position.move_toward(boss.player.global_position, vitesse_souterraine * delta)
		
		if boss.global_position.x > boss.player.global_position.x:
			boss.sprite.flip_h = true
		else:
			boss.sprite.flip_h = false
		
		if not is_instance_valid(boss) or not boss.is_inside_tree():
			return
			
		await boss.get_tree().process_frame
	
	if not is_instance_valid(boss) or not boss.is_inside_tree():
		return
		
	# ==========================================
	# PHASE 3 : Il sort du sol (Frames actives)
	# ==========================================
	var rayon_original = boss.collision_physique.shape.radius
	var degats_originaux = boss.stats.attack_damage
	
	var est_agrandi = false
	var a_inflige_degats = false
	
	boss.sprite.play("attack1.3")
	
	while is_instance_valid(boss) and boss.is_inside_tree() and boss.sprite.is_playing() and boss.sprite.animation == "attack1.3":		
		var frame_actuelle = boss.sprite.frame
		
		# --- FENÊTRE D'ATTAQUE (Frames 9 à 12) ---
		if frame_actuelle >= 5 and frame_actuelle <= 13:
			if not est_agrandi:
				boss.stats.attack_damage = boss.degats_embuscade
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
