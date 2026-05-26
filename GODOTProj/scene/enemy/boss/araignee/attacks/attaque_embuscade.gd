extends BossAttack

func _init() -> void:
	id = "embuscade" 
	portee_min = 150.0
	portee_max = 500.0
	poids = 10.0
	cooldown_attaque = 2.0

func executer(boss) -> void:
	print("Lancement de l'embuscade...")
	
	# ==========================================
	# PHASE 1 : Il creuse et rentre dans le trou
	# ==========================================
	boss.sprite.play("attack1.1") 
	await boss.sprite.animation_finished
	
	# ==========================================
	# PHASE 2 : Poursuite souterraine
	# ==========================================
	boss.sprite.play("attack1.2")
	var vitesse_souterraine = 800.0 
	
	while boss.global_position.distance_to(boss.player.global_position) > 80.0:
		var delta = boss.get_process_delta_time()
		
		boss.global_position = boss.global_position.move_toward(boss.player.global_position, vitesse_souterraine * delta)
		
		if boss.global_position.x > boss.player.global_position.x:
			boss.sprite.flip_h = true
		else:
			boss.sprite.flip_h = false
			
		await boss.get_tree().process_frame

	# ==========================================
	# PHASE 3 : Il sort du sol (Frames actives)
	# ==========================================
	var rayon_original = boss.collision_physique.shape.radius
	var est_agrandi = false
	
	boss.sprite.play("attack1.3")
	
	while boss.sprite.is_playing() and boss.sprite.animation == "attack1.3":
		var frame_actuelle = boss.sprite.frame
		
		if frame_actuelle >= 9 and frame_actuelle <= 12:
			if not est_agrandi:
				boss.collision_physique.shape.radius = rayon_original * 2.0 
				est_agrandi = true
		else:
			if est_agrandi:
				boss.collision_physique.shape.radius = rayon_original
				est_agrandi = false
				
		await boss.get_tree().process_frame
		
	boss.collision_physique.shape.radius = rayon_original
	print("Embuscade terminée !")
