extends BossAttack

func _init() -> void:
	id = "embuscade" 
	portee_min = 250.0
	portee_max = 500.0
	poids = 10.0
	cooldown_attaque = 2.0

func executer(boss) -> void:
	print("Lancement de l'animation...")
	boss.sprite.play("attack1") 
	
	await boss.sprite.animation_finished
	
	print("Animation terminée !")
