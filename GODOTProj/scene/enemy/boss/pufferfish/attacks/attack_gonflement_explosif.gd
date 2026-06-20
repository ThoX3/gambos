extends BossAttack
class_name AttackGonflementExplosif

func _init() -> void:
	id = "gonflement_explosif"
	poids = 2.0
	cooldown_attaque = 10.0
	portee_min = 0.0
	portee_max = 9999.0
	combo_suivant_id = ""


func executer(boss) -> void:
	if boss._est_mort or not is_instance_valid(boss): return

	boss.sprite.sprite_frames.set_animation_loop("explode", false)
	boss.sprite.play("explode")
	if not await boss._attendre_anim(): return

	_tirer_pics_en_cercle(boss)

	# Phase fumée : invulnérable et immobile dès maintenant
	boss._en_fumee = true
	boss._etat_special_actif = true
	boss._physics_process_special = func(_delta: float):
		if is_instance_valid(boss.player):
			var dir_x_f = boss.player.global_position.x - boss.global_position.x
			if abs(dir_x_f) > 1.0:
				boss.sprite.flip_h = dir_x_f > 0
		return true  # le boss reste immobile tant que _en_fumee est actif (libéré explicitement plus bas)

	# 1. prepare_fumee — transition AVANT le grossissement
	if boss.sprite.sprite_frames.has_animation("prepare_fumee"):
		boss.sprite.sprite_frames.set_animation_loop("prepare_fumee", false)
		boss.sprite.play("prepare_fumee")
		if not await boss._attendre_anim():
			_fin_phase_fumee(boss)
			return

	if boss._est_mort or not is_instance_valid(boss):
		_fin_phase_fumee(boss)
		return

	# 2. fumee — c'est ICI qu'il grandit pour couvrir le rayon du nuage
	_appliquer_echelle_nuage(boss)
	boss.sprite.play("fumee")
	await _creer_nuage_poison(boss)

	# Fin de la phase fumée : on rétablit tout
	_fin_phase_fumee(boss)

	if boss._est_mort or not is_instance_valid(boss): return

	if not boss._est_mort:
		boss.sprite.play("walk")
	if not await boss._attendre_timer(0.4): return


func _fin_phase_fumee(boss) -> void:
	boss.scale = boss._echelle_normale
	boss._en_fumee = false
	boss._etat_special_actif = false
	boss._physics_process_special = Callable()


# Calcule l'échelle du boss pour que sa taille visible corresponde à rayon_nuage_poison.
# Ainsi, changer rayon_nuage_poison dans l'inspecteur change AUSSI la taille visuelle.
func _appliquer_echelle_nuage(boss) -> void:
	# Rayon visible du boss à l'échelle 1 (moitié de la plus grande dimension de la texture)
	var rayon_base := 32.0  # fallback si la texture est introuvable
	var sf = boss.sprite.sprite_frames
	var anim = boss.sprite.animation
	if sf != null and sf.has_animation(anim) and sf.get_frame_count(anim) > 0:
		var tex = sf.get_frame_texture(anim, boss.sprite.frame)
		if tex != null:
			rayon_base = maxf(tex.get_size().x, tex.get_size().y) * 0.5

	if rayon_base <= 0.0:
		rayon_base = 32.0

	var facteur: float = boss.rayon_nuage_poison / rayon_base
	boss.scale = Vector2(facteur, facteur)


func _tirer_pics_en_cercle(boss) -> void:
	if boss.pic_scene == null:
		push_warning("[Poisson] pic_scene non assignée !")
		return
	var angle_step = TAU / float(boss.nombre_pics)
	for i in range(boss.nombre_pics):
		var proj = boss.pic_scene.instantiate()
		var angle = i * angle_step
		proj.global_position = boss.global_position
		if "vitesse" in proj:
			proj.vitesse = boss.vitesse_pics
		if "degats" in proj:
			proj.degats = boss.degats_explosion_pics
		boss.get_parent().add_child(proj)
		# direction APRÈS add_child pour que @onready soit prêt
		if "direction" in proj:
			proj.direction = Vector2(cos(angle), sin(angle))


func _creer_nuage_poison(boss) -> void:
	var elapsed: float = 0.0
	var tick_elapsed: float = 0.0
	while elapsed < boss.duree_nuage_poison:
		if boss._est_mort or not is_instance_valid(boss): return
		var delta = boss.get_process_delta_time()
		elapsed += delta
		tick_elapsed += delta
		if tick_elapsed >= boss.tick_poison:
			tick_elapsed = 0.0
			if is_instance_valid(boss.player) and boss.global_position.distance_to(boss.player.global_position) <= boss.rayon_nuage_poison:
				if boss.player.has_method("take_damage"):
					boss.player.take_damage(boss.degats_nuage_poison)
				if boss.player.has_method("apply_poison"):
					boss.player.apply_poison(boss.poison_duree, boss.poison_degats_tick, boss.poison_intervalle, boss.poison_ralenti)
		if not await boss._attendre_frame(): return
