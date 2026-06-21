extends BossAttack
class_name AttackCamouflage

func _init() -> void:
	id = "camouflage"
	cooldown_attaque = 12.0
	portee_min = 0.0
	portee_max = 9999.0
	poids = 10.0
	combo_suivant_id = ""


func executer(boss) -> void:
	if not is_instance_valid(boss) or boss._est_mort: return

	# Verrou anti-relance (comme la charge) : le combo peut rappeler executer()
	# à chaque frame, on ne veut PAS réinitialiser la ruée en boucle.
	if boss.get_meta("_camouflage_en_cours", false):
		return
	boss.set_meta("_camouflage_en_cours", true)

	boss._en_camouflage = true

	# Empêche le mouvement normal d'Enemy_Base pendant la ruée.
	boss._etat_special_actif = true
	boss._physics_process_special = func(_delta: float): return true

	# Joue l'anim de camouflage si elle existe
	if boss.sprite.sprite_frames.has_animation("camouflage"):
		boss.sprite.play("camouflage")

	# 1. Devient transparent
	var tween: Tween = boss.create_tween()
	tween.tween_property(boss.sprite, "modulate:a", boss.camouflage_alpha, 0.4)
	if not await boss._attendre_timer(0.4):
		_fin_camouflage(boss)
		return

	if not is_instance_valid(boss) or boss._est_mort:
		_fin_camouflage(boss)
		return

	# 2. Fonce vers le joueur EN RESTANT TRANSPARENT (le suit jusqu'au contact),
	#    avec une durée max de sécurité = camouflage_duree pour ne jamais rester bloqué.
	var timer_max: float = boss.camouflage_duree
	var arrive := false

	while timer_max > 0.0 and not arrive:
		await boss.get_tree().physics_frame
		if not is_instance_valid(boss) or boss._est_mort or not boss.is_inside_tree():
			_fin_camouflage(boss)
			return

		var delta: float = boss.get_physics_process_delta_time()
		timer_max -= delta

		if not is_instance_valid(boss.player):
			break

		# Direction VERS le joueur, recalculée chaque frame (poursuite)
		var dir = (boss.player.global_position - boss.global_position).normalized()
		boss.velocity = dir * boss.camouflage_vitesse_ruee
		boss.move_and_slide()

		# Oriente le sprite à gauche/droite selon la direction horizontale
		if absf(dir.x) > 0.01:
			boss.sprite.flip_h = dir.x > 0

		# Arrivé sur le joueur → dégâts de contact puis on s'arrête
		if boss.global_position.distance_to(boss.player.global_position) <= boss.camouflage_distance_contact:
			if boss.player.has_method("take_damage"):
				boss.player.take_damage(boss.camouflage_degats_contact)
			AudioManager.play_sound_2d("tentacule_impact", boss.global_position)
			arrive = true

	# 3. Redevient visible
	_fin_camouflage(boss)

	if not is_instance_valid(boss) or boss._est_mort: return

	var tween_out: Tween = boss.create_tween()
	tween_out.tween_property(boss.sprite, "modulate:a", 1.0, 0.4)
	if not await boss._attendre_timer(0.4): return

	if not boss._est_mort:
		boss.sprite.play("walk")
	if not await boss._attendre_timer(0.3): return


# Relâche le verrou, l'état spécial, et désactive le camouflage
func _fin_camouflage(boss) -> void:
	if not is_instance_valid(boss):
		return
	boss._en_camouflage = false
	boss._etat_special_actif = false
	boss._physics_process_special = Callable()
	boss.set_meta("_camouflage_en_cours", false)
