extends BossAttack
class_name AttackBullesEncre

func _init() -> void:
	id = "bulles_encre"
	cooldown_attaque = 6.0
	portee_min = 0.0
	portee_max = 600.0
	poids = 10.0
	combo_suivant_id = ""


func executer(boss) -> void:
	if not is_instance_valid(boss) or boss._est_mort: return
	if boss.ink_bubble_scene == null:
		push_warning("[Poulpe] ink_bubble_scene non assignée !")
		return

	# Pas d'animation dédiée aux bulles sur le poulpe → on tire directement.
	boss._bulles_actives.clear()
	for i in range(boss.nombre_bulles):
		_tirer_une_bulle(boss)
		if not await boss._attendre_timer(0.25): return

	# Le boss repasse en walk IMMÉDIATEMENT et rend la main au combo.
	# Les bulles continuent leur vie en arrière-plan (toucher le joueur, expirer,
	# assombrir l'écran, se relancer) sans bloquer le boss.
	if not boss._est_mort:
		boss.sprite.play("walk")


func _tirer_une_bulle(boss) -> void:
	if not is_instance_valid(boss) or boss._est_mort or not is_instance_valid(boss.player):
		return

	var bulle = boss.ink_bubble_scene.instantiate()
	bulle.global_position = boss.global_position
	boss.get_parent().add_child(bulle)

	var dir = (boss.player.global_position - boss.global_position).normalized()
	bulle.setup(dir, boss.vitesse_bulle_encre, boss.degats_bulle_encre)

	bulle.hit_player.connect(_on_bulle_hit_player.bind(boss))
	bulle.expired.connect(_on_bulle_expired.bind(boss))

	boss._bulles_actives.append(bulle)


func _on_bulle_hit_player(bulle, boss) -> void:
	if not is_instance_valid(boss):
		return
	boss._bulles_actives.erase(bulle)

	if boss._bulle_en_attente_relance or boss._est_mort:
		return
	boss._bulle_en_attente_relance = true

	# Fait éclater silencieusement toutes les autres bulles encore en vol
	for b in boss._bulles_actives.duplicate():
		if is_instance_valid(b):
			b.pop_silently()
	boss._bulles_actives.clear()

	# Attend que l'écran d'encre du joueur se dissipe avant de relancer
	await bulle.screen_cleared

	boss._bulle_en_attente_relance = false
	if is_instance_valid(boss) and not boss._est_mort and boss.is_inside_tree():
		_tirer_une_bulle(boss)


func _on_bulle_expired(bulle, boss) -> void:
	if not is_instance_valid(boss):
		return
	boss._bulles_actives.erase(bulle)

	if boss._est_mort:
		return

	if not await boss._attendre_timer(boss.delai_relance_apres_expiration): return
	if is_instance_valid(boss) and not boss._est_mort and boss.is_inside_tree():
		_tirer_une_bulle(boss)
