extends BossAttack
class_name AttackCamouflage

func _init() -> void:
	id = "camouflage"
	cooldown_attaque = 12.0
	portee_min = 0.0
	portee_max = 600.0
	poids = 10.0
	combo_suivant_id = ""


func executer(boss) -> void:
	if boss._est_mort or not is_instance_valid(boss): return

	boss._en_camouflage = true

	var tween := boss.create_tween()
	tween.tween_property(boss.sprite, "modulate:a", boss.camouflage_alpha, 0.4)

	if not await boss._attendre_timer(boss.camouflage_duree): return

	var tween_out := boss.create_tween()
	tween_out.tween_property(boss.sprite, "modulate:a", 1.0, 0.4)
	if not await boss._attendre_timer(0.4): return

	boss._en_camouflage = false

	if not await boss._attendre_timer(0.3): return
