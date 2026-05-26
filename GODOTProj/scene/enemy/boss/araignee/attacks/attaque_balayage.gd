extends BossAttack

func _init() -> void:
	id = "balayage"
	portee_min = 0.0
	portee_max = 250.0
	poids = 40.0
	
	combo_suivant_id = "broyage"
	
func executer(boss) -> void:
	boss.sprite.play("attack3")
	await boss.sprite.animation_finished
