extends BossAttack

func _init() -> void:
	id = "balayage"
	portee_min = 0.0
	portee_max = 500.0
	poids = 40.0
	cooldown_attaque = 2.0
	combo_suivant_id = "broyage"
	
func executer(boss) -> void:
	var direction_originale = boss.sprite.flip_h
	
	var position_joueur_frame_9 = Vector2.ZERO
	var a_tire_projectile = false
	var cone_active = false
	
	boss.sprite.play("attack3")	
	
	while boss.sprite.is_playing() and boss.sprite.animation == "attack3":
		var frame_actuelle = boss.sprite.frame
		
		# --- PHASE 1 : Animation classique ---
		if frame_actuelle >= 3 and frame_actuelle <= 7:
			boss.sprite.flip_h = not direction_originale
		else:
			boss.sprite.flip_h = direction_originale
			
		# --- PHASE 2 : Le Dash ---
		if frame_actuelle >= 8 and frame_actuelle <= 9:
			var vitesse_dash = 1200.0 
			var delta = boss.get_process_delta_time()
			boss.global_position = boss.global_position.move_toward(boss.player.global_position, vitesse_dash * delta)
			
			# On mémorise la position du joueur pour le futur tir
			if frame_actuelle == 9:
				position_joueur_frame_9 = boss.player.global_position
			
		# --- PHASE 3 : Le tir du projectile et le cône ---
		elif frame_actuelle >= 10 and frame_actuelle <= 12:
			
			if not cone_active:
				var portee_cone = 150.0 
				var distance = boss.global_position.distance_to(boss.player.global_position)
				
				if distance <= portee_cone:
					var direction_regard = Vector2.LEFT if boss.sprite.flip_h else Vector2.RIGHT
					var direction_vers_joueur = boss.global_position.direction_to(boss.player.global_position)
					var angle_ecart = direction_regard.angle_to(direction_vers_joueur)
					
					if abs(angle_ecart) <= deg_to_rad(45.0):
						print("BAM ! Le joueur est dans le cône mathématique !")
				cone_active = true 
				
			# C'est ici que le projectile se lance !
			if not a_tire_projectile:
				if position_joueur_frame_9 == Vector2.ZERO:
					position_joueur_frame_9 = boss.player.global_position
					
				_lancer_projectile(boss, position_joueur_frame_9)
				a_tire_projectile = true
				
		# --- PHASE 4 : Fin de l'attaque ---
		elif frame_actuelle > 12:
			cone_active = false
				
		await boss.get_tree().process_frame
					
	# Remise à zéro à la fin de l'animation
	boss.sprite.flip_h = direction_originale
	if boss.has_node("ConeHitbox"):
		boss.get_node("ConeHitbox").visible = false
		boss.get_node("ConeHitbox/CollisionPolygon2D").set_deferred("disabled", true)

# --- LA FONCTION QUI LANCE LE PROJECTILE ---
func _lancer_projectile(boss, cible: Vector2) -> void:
	# Si l'Araignée sait quel projectile lancer...
	if boss.projectile_scene != null:
		var proj = boss.projectile_scene.instantiate()
		proj.global_position = boss.global_position
		
		var direction = boss.global_position.direction_to(cible)
		if "direction" in proj:
			proj.direction = direction
			
		boss.get_parent().add_child(proj)
		print("✅ Projectile lancé !")
	# Si la case du projectile est vide dans l'éditeur...
	else:
		push_error("❌ ERREUR : Tu as oublié de mettre la scène du projectile dans l'inspecteur du Boss !")
