extends BossAttack

func _init() -> void:
	id = "broyage"
	portee_max = 150.0

func executer(boss) -> void:
	var rayon_original = boss.collision_physique.shape.radius
	var est_agrandi = false
	
	boss.sprite.play("attack2")	
	
	while is_instance_valid(boss) and boss.is_inside_tree() and boss.sprite.is_playing() and boss.sprite.animation == "attack2":
		var frame_actuelle = boss.sprite.frame
		
		if frame_actuelle >= 15 and frame_actuelle <= 18:
			if not est_agrandi:
				boss.collision_physique.shape.radius = rayon_original * 2.0
				est_agrandi = true
				
		else:
			if est_agrandi:
				boss.collision_physique.shape.radius = rayon_original
				est_agrandi = false
		
		if not is_instance_valid(boss) or not boss.is_inside_tree():
			return	
				
		await boss.get_tree().process_frame
		
	if is_instance_valid(boss) and boss.is_inside_tree():
		boss.collision_physique.shape.radius = rayon_original
