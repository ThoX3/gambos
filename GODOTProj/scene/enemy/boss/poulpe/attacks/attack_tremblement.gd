extends BossAttack
class_name AttackTremblement

func _init() -> void:
	id = "tremblement"
	cooldown_attaque = 8.0
	portee_min = 0.0
	portee_max = 600.0
	poids = 10.0
	combo_suivant_id = ""


func executer(boss) -> void:
	if not is_instance_valid(boss) or boss._est_mort: return

	if boss.sprite.sprite_frames.has_animation("prepare_tremblement"):
		boss.sprite.sprite_frames.set_animation_loop("prepare_tremblement", false)
		boss.sprite.play("prepare_tremblement")
		if not await boss._attendre_anim(): return
	else:
		if not await boss._attendre_timer(0.5): return

	if not is_instance_valid(boss) or boss._est_mort: return

	if boss.sprite.sprite_frames.has_animation("tremblement"):
		boss.sprite.sprite_frames.set_animation_loop("tremblement", false)
		boss.sprite.play("tremblement")

	# Secousse de caméra (lancée en parallèle, ne bloque pas la suite)
	_secouer_camera(boss)

	# Dégâts de zone autour du boss
	if is_instance_valid(boss.player) and boss.global_position.distance_to(boss.player.global_position) <= boss.rayon_tremblement:
		if boss.player.has_method("take_damage"):
			boss.player.take_damage(boss.degats_tremblement)
		if boss.player.has_method("apply_stun"):
			boss.player.apply_stun(0.6)

	if boss.sprite.sprite_frames.has_animation("tremblement"):
		if not await boss._attendre_anim(): return

	if not boss._est_mort:
		boss.sprite.play("walk")
	if not await boss._attendre_timer(0.4): return


func _secouer_camera(boss) -> void:
	if not is_instance_valid(boss):
		return
	var cam = boss.get_viewport().get_camera_2d()
	if cam == null:
		return

	# Si la caméra a sa propre méthode shake(), on l'utilise.
	if cam.has_method("shake"):
		cam.shake()
		return

	# Sinon : secousse directe via l'offset de la caméra (autonome).
	var duree := 0.5
	var intensite := 10.0       # amplitude max de la secousse (pixels)
	var ecoule := 0.0
	var offset_initial: Vector2 = cam.offset

	while ecoule < duree:
		await boss.get_tree().process_frame
		if not is_instance_valid(boss) or not is_instance_valid(cam):
			break
		ecoule += boss.get_process_delta_time()
		# La force décroît au fil du temps (secousse qui s'estompe)
		var force: float = intensite * (1.0 - ecoule / duree)
		cam.offset = offset_initial + Vector2(randf_range(-force, force), randf_range(-force, force))

	# Remet la caméra à sa position d'origine
	if is_instance_valid(cam):
		cam.offset = offset_initial
