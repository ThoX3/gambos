extends BossAttack

func _init() -> void:
	id = "balayage"
	portee_min = 0.0
	portee_max = 250.0
	poids = 40.0
	
	combo_suivant_id = "broyage"
	
func executer(boss) -> void:
	var direction_originale = boss.sprite.flip_h
	
	boss.sprite.play("attack3")	
	
	while boss.sprite.is_playing() and boss.sprite.animation == "attack3":
		var frame_actuelle = boss.sprite.frame
		
		if frame_actuelle >= 3 and frame_actuelle <= 7:
			boss.sprite.flip_h = not direction_originale
		else:
			boss.sprite.flip_h = direction_originale
			
		await boss.get_tree().process_frame
					
	# Sécurité à la fin de l'attaque
	boss.sprite.flip_h = direction_originale
