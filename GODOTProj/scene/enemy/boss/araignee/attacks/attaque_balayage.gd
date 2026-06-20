extends BossAttack

func _init() -> void:
	id = "balayage"
	portee_min = 200.0
	portee_max = 500.0
	combo_suivant_id = "broyage"
	
func executer(boss) -> void:
	var direction_originale = boss.sprite.flip_h
	
	# --- CORRECTION : On réinitialise TOUJOURS ces variables au début de l'attaque ---
	var position_joueur_frame_9 = Vector2.ZERO
	var a_tire_projectile = false
	var cone_active = false
	var a_inflige_degats_corps = false
	
	boss.sprite.play("attack3")	
	
	while is_instance_valid(boss) and boss.is_inside_tree() and boss.sprite.is_playing() and boss.sprite.animation == "attack3":
		var frame_actuelle = boss.sprite.frame
		
		# --- PHASE 1 : Animation classique ---
		if frame_actuelle >= 3 and frame_actuelle <= 7:
			boss.sprite.flip_h = not direction_originale
		else:
			boss.sprite.flip_h = direction_originale
			
		# --- PHASE 2 : Le Dash ---
		if frame_actuelle == 8:
			var vitesse_dash = 2500.0
			var delta = boss.get_process_delta_time()
			boss.global_position = boss.global_position.move_toward(boss.player.global_position, vitesse_dash * delta)
			
		if frame_actuelle == 9:
			if position_joueur_frame_9 == Vector2.ZERO:
				position_joueur_frame_9 = boss.player.global_position
			
		# --- PHASE 3 : Le tir du projectile et le cône ---
		elif frame_actuelle >= 10 and frame_actuelle <= 12:
			
			# Attaque au corps-à-corps (Cône mathématique)
			if not cone_active:
				var portee_cone = 150.0 
				var distance = boss.global_position.distance_to(boss.player.global_position)
				
				if distance <= portee_cone and not a_inflige_degats_corps:
					var direction_regard = Vector2.LEFT if boss.sprite.flip_h else Vector2.RIGHT
					var direction_vers_joueur = boss.global_position.direction_to(boss.player.global_position)
					var angle_ecart = direction_regard.angle_to(direction_vers_joueur)
					
					if abs(angle_ecart) <= deg_to_rad(45.0):
						if boss.player.has_method("take_damage"):
							boss.player.take_damage(boss.degats_balayage_corps)
							
						a_inflige_degats_corps = true 
				cone_active = true 
				
			# Tir multiple de projectiles
			if not a_tire_projectile:
				if position_joueur_frame_9 == Vector2.ZERO:
					position_joueur_frame_9 = boss.player.global_position
					
				_lancer_plusieurs_projectiles(boss, position_joueur_frame_9)
				a_tire_projectile = true
				
		# --- PHASE 4 : Fin de l'attaque ---
		elif frame_actuelle > 12:
			cone_active = false
			# On peut aussi reset ici par sécurité, mais le reset en début de fonction suffit
				
		if not is_instance_valid(boss) or not boss.is_inside_tree():
			return
			
		await boss.get_tree().process_frame
		
	if is_instance_valid(boss) and boss.is_inside_tree():
		boss.sprite.flip_h = direction_originale
		if boss.has_node("ConeHitbox"):
			boss.get_node("ConeHitbox").visible = false
			boss.get_node("ConeHitbox/CollisionPolygon2D").set_deferred("disabled", true)
			
func _lancer_plusieurs_projectiles(boss, cible: Vector2) -> void:
	if boss.projectile_scene != null:
		var direction_centrale = boss.global_position.direction_to(cible)
		
		var nombre_projectiles = 3
		var ecart_angulaire = deg_to_rad(45.0) # Angle entre chaque projectile (15 degrés ici)
		
		var angle_depart = - (nombre_projectiles - 1) * ecart_angulaire / 2.0
		
		for i in range(nombre_projectiles):
			var proj = boss.projectile_scene.instantiate()
			
			boss.get_parent().add_child(proj)
			
			proj.global_position = boss.global_position
			
			if "degats" in proj:
				proj.degats = boss.degats_projectile
				
			var angle_deviation = angle_depart + (i * ecart_angulaire)
			var direction_finale = direction_centrale.rotated(angle_deviation)
			
			if "direction" in proj:
				proj.direction = direction_finale
				
			boss.get_parent().add_child(proj)
