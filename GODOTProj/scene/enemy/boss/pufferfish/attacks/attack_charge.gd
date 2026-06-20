extends BossAttack
class_name AttackChargeFrenetique

func _init() -> void:
	id = "charge_frenetique"
	poids = 3.0
	cooldown_attaque = 6.0
	portee_min = 0.0
	portee_max = 9999.0
	combo_suivant_id = ""


func executer(boss) -> void:
	if not is_instance_valid(boss) or boss._est_mort: return

	# ── VERROU ANTI-RELANCE ───────────────────────────────────────────────
	# Le système de combo de Boss_Base peut rappeler executer() à chaque frame.
	# On pose un verrou via set_meta (que le boss ne touche JAMAIS) : tant qu'une
	# charge est en cours, toute nouvelle invocation ressort immédiatement.
	if boss.get_meta("_charge_en_cours", false):
		return
	boss.set_meta("_charge_en_cours", true)

	# Empêche le mouvement normal d'Enemy_Base pendant toute la charge.
	boss._etat_special_actif = true
	boss._physics_process_special = func(_delta: float): return true

	# 1. Préparation — le boss se fige, PAS encore en charge
	if boss.sprite.sprite_frames.has_animation("prepare_speed"):
		boss.sprite.sprite_frames.set_animation_loop("prepare_speed", false)
		boss.sprite.play("prepare_speed")
		if not await boss._attendre_anim():
			_fin_charge(boss)
			return
	else:
		if not await boss._attendre_timer(0.5):
			_fin_charge(boss)
			return

	if not is_instance_valid(boss) or boss._est_mort:
		_fin_charge(boss)
		return

	# 2. Paramètres de la charge
	var velocity_charge: Vector2 = (boss.player.global_position - boss.global_position).normalized() * boss.vitesse_charge
	var timer_charge: float = boss.duree_charge
	var rebonds_restants: int = boss.nombre_rebonds_max

	if boss.sprite.sprite_frames.has_animation("speed"):
		boss.sprite.play("speed")

	# 3. Boucle de charge — pilotée frame par frame
	while timer_charge > 0.0 and rebonds_restants > 0:
		await boss.get_tree().physics_frame
		# is_instance_valid AVANT toute lecture de propriété : si le boss a été libéré
		# pendant le await, accéder à boss._est_mort planterait ("previously freed").
		if not is_instance_valid(boss) or boss._est_mort or not boss.is_inside_tree():
			_fin_charge(boss)
			return

		var delta: float = boss.get_physics_process_delta_time()
		timer_charge -= delta

		# Mouvement physique propre pour un CharacterBody2D
		boss.velocity = velocity_charge
		boss.move_and_slide()

		var rebond := false
		var normal := Vector2.ZERO

		# Rebond sur un VRAI mur (StaticBody, TileMapLayer avec collision)
		if boss.get_slide_collision_count() > 0:
			normal = boss.get_slide_collision(0).get_normal()
			rebond = true

		# Rebond sur les limites caméra (bords sans collider physique)
		var cam = boss.get_viewport().get_camera_2d()
		if cam != null:
			var marge = 40.0
			var min_x = cam.limit_left + marge
			var max_x = cam.limit_right - marge
			var min_y = cam.limit_top + marge
			var max_y = cam.limit_bottom - marge

			if boss.global_position.x <= min_x:
				boss.global_position.x = min_x + 1.0
				normal += Vector2.RIGHT
				rebond = true
			elif boss.global_position.x >= max_x:
				boss.global_position.x = max_x - 1.0
				normal += Vector2.LEFT
				rebond = true
			if boss.global_position.y <= min_y:
				boss.global_position.y = min_y + 1.0
				normal += Vector2.DOWN
				rebond = true
			elif boss.global_position.y >= max_y:
				boss.global_position.y = max_y - 1.0
				normal += Vector2.UP
				rebond = true

		# Au rebond : on se REDIRIGE TOUT DROIT vers le joueur, mais en garantissant
		# une composante de décollement du mur (sinon collage quand le joueur est
		# dans l'axe du mur). normal pointe vers l'intérieur (loin du mur).
		if rebond:
			rebonds_restants -= 1
			normal = normal.normalized()

			var dir_joueur := velocity_charge.normalized()
			if is_instance_valid(boss.player):
				dir_joueur = (boss.player.global_position - boss.global_position).normalized()

			# Si la direction vers le joueur pointe encore dans le mur, on la "glisse"
			# le long du mur puis on ajoute une poussée minimale vers l'intérieur.
			var poussee_min := 0.5
			if dir_joueur.dot(normal) < poussee_min:
				dir_joueur = (dir_joueur.slide(normal) + normal * poussee_min).normalized()

			velocity_charge = dir_joueur * boss.vitesse_charge

		# Contact avec le joueur pendant la charge → dégâts (pas de poison)
		if is_instance_valid(boss.player) and boss.global_position.distance_to(boss.player.global_position) <= 60.0:
			if boss.player.has_method("take_damage"):
				boss.player.take_damage(boss.degats_charge)

	# 4. Fin de charge
	_fin_charge(boss)

	if not is_instance_valid(boss) or boss._est_mort: return

	if boss.sprite.sprite_frames.has_animation("finish_speed"):
		boss.sprite.sprite_frames.set_animation_loop("finish_speed", false)
		boss.sprite.play("finish_speed")
		if not await boss._attendre_anim(): return
	else:
		if not await boss._attendre_timer(0.3): return

	if not boss._est_mort:
		boss.sprite.play("walk")
	if not await boss._attendre_timer(0.3): return


# Relâche proprement le verrou et rend le contrôle du mouvement au boss
func _fin_charge(boss) -> void:
	if not is_instance_valid(boss):
		return
	boss._etat_special_actif = false
	boss._physics_process_special = Callable()
	boss.set_meta("_charge_en_cours", false)
