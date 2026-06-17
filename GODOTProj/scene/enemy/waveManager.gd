extends Node

@export var spawn_config: SpawnConfig        # ← le seul fichier de config
@export var config: BalancingConfig
@export_range(0.0, 30.0, 0.5) var pause_entre_vagues: float = 3.0
@export var mode_infini: bool = true
@export var conteneur_ennemis: Node
@export var scene_dialogue: PackedScene
@export var multiplicateur_taille_boss: float = 2.0
@export var vagues_par_monde: int = 20
var joueur: Node2D

signal vague_demarree(numero: int)
signal vague_terminee(numero: int)
signal toutes_vagues_terminees
signal monde_termine(numero_vague: int)

enum _Etat { PAUSE, VAGUE, ATTENTE_ENNEMIS_RESTANTS, FINI }

var _etat: _Etat                          = _Etat.FINI
var _numero_vague: int                    = 0
var _ennemis_spawnes: int                 = 0
var _timer_vague: float                   = 0.0
var _timer_spawn: float                   = 0.0
var _timer_pause: float                   = 0.0
var _intervalle_spawn: float              = 1.0
var _duree_vague_courante: float          = 30.0
var _liste_spawn: Array                   = []
var _boss_courant: EntreeBoss             = null

func _ready() -> void:
	await get_tree().process_frame
	joueur = get_tree().get_first_node_in_group("Player")
	if spawn_config == null: push_error("WaveManager : aucun SpawnConfig assigné !")
	if config == null:       push_error("WaveManager : aucun BalancingConfig assigné !")
	if conteneur_ennemis == null: push_error("WaveManager : conteneur_ennemis non assigné.")

func start_waves(continuer: bool = false) -> void:
	if not continuer:
		_numero_vague = 0
	else:
		var main_node = get_tree().get_first_node_in_group("Main")
		if main_node and main_node.has_node("World/WorldManager"):
			var wm = main_node.get_node("World/WorldManager")
			if wm._mode_infini_actif:
				# En mode infini, on continue simplement à partir de la vague actuelle,
				# pas de recalcul basé sur l'index de monde.
				pass  # _numero_vague garde sa valeur actuelle
			else:
				_numero_vague = wm._index_monde_courant * vagues_par_monde

	_timer_pause  = 0.0
	_boss_courant = null
	_etat = _Etat.PAUSE

func _process(delta: float) -> void:
	match _etat:
		_Etat.PAUSE:
			_timer_pause += delta
			if _timer_pause >= pause_entre_vagues:
				_timer_pause = 0.0
				_demarrer_vague()
		_Etat.VAGUE:
			_tick_vague(delta)
		_Etat.ATTENTE_ENNEMIS_RESTANTS:
			if get_tree().get_nodes_in_group("Enemy").size() == 0:
				monde_termine.emit(_numero_vague)
				_etat = _Etat.FINI
		_Etat.FINI:
			pass

func _tick_vague(delta: float) -> void:
	_timer_vague += delta
	_timer_spawn += delta

	if _boss_courant == null \
	and _ennemis_spawnes < _liste_spawn.size() \
	and _timer_spawn >= _intervalle_spawn:
		_timer_spawn = 0.0
		_spawner_depuis_liste()

	if _timer_vague >= _duree_vague_courante:
		_terminer_vague()

func _demarrer_vague() -> void:
	_numero_vague   += 1
	_ennemis_spawnes = 0
	_timer_vague     = 0.0
	_timer_spawn     = 0.0
	_boss_courant    = null

	var boss_entry := spawn_config.get_boss_pour_vague(_numero_vague)
	if boss_entry != null:
		_boss_courant         = boss_entry
		_liste_spawn          = []
		_duree_vague_courante = boss_entry.duree
		_etat = _Etat.VAGUE
		vague_demarree.emit(_numero_vague)
		_spawner_boss(boss_entry)
		# Pas propre : lancer un signal 
		if joueur:
			joueur.set_physics_process(false)
			if joueur.has_method("disable_input"):
				joueur.disable_input()
	else:
		var disponibles := spawn_config.get_ennemis_disponibles(_numero_vague)
		_liste_spawn          = _generer_liste_spawn(disponibles, _numero_vague)
		_duree_vague_courante = _calculer_duree(_numero_vague)
		_intervalle_spawn     = _duree_vague_courante / max(float(_liste_spawn.size()), 1.0)
		_etat = _Etat.VAGUE
		vague_demarree.emit(_numero_vague)
	
	# Pas propre : lancer un signal 
	if joueur:
		joueur.set_physics_process(true)
		if joueur.has_method("enable_input"):
			joueur.enable_input()	

func _terminer_vague() -> void:
	vague_terminee.emit(_numero_vague)
	_boss_courant = null

	# Vérifie si c'est la fin d'un monde (vague boss franchie)
	if _numero_vague > 0 and _numero_vague % vagues_par_monde == 0:
		_etat = _Etat.ATTENTE_ENNEMIS_RESTANTS
		return

	if not mode_infini and spawn_config.get_ennemis_disponibles(_numero_vague + 1).is_empty() \
	and spawn_config.get_boss_pour_vague(_numero_vague + 1) == null:
		_etat = _Etat.FINI
		toutes_vagues_terminees.emit()
	else:
		_etat = _Etat.PAUSE

# ── Équations d'équilibrage ────────────────────

func _calculer_budget(numero: int) -> float:
	var base     := config.budget_base * (1.0 + config.budget_facteur * pow(float(numero), config.budget_exposant))
	var variance := randf_range(-config.budget_variance, config.budget_variance)
	return base * (1.0 + variance)

func _calculer_duree(numero: int) -> float:
	var base := config.duree_base
	var reduction = (SaveManager.current_save.total_purchases * config.reduction_duree_par_achat) * (max((60-float(numero)),0)/60)
	var duree = max(base - reduction, config.duree_minimale)
	print("WaveManager durée : %fs" %duree)
	return duree

func _tirer_ratio_intensite(numero: int) -> float:
	var ratio_brut := randf_range(config.intensite_min, config.intensite_max)
	var biais      := clampf(float(numero) / config.biais_vague_max, 0.0, 1.0) * config.biais_amplitude
	return clampf(ratio_brut + (1.0 - ratio_brut) * biais, 0.0, 1.0)

# ── Génération de la liste de spawn ───────────

func _generer_liste_spawn(disponibles: Array, numero: int) -> Array:
	var budget := _calculer_budget(numero)
	var ratio  := _tirer_ratio_intensite(numero)

	print("WaveManager [vague %d] budget=%.1f | ratio=%.2f | dispo=%d" \
		  % [numero, budget, ratio, disponibles.size()])

	if disponibles.is_empty():
		push_warning("WaveManager : aucun ennemi disponible pour la vague %d." % numero)
		return []

	var tries := disponibles.duplicate()
	tries.sort_custom(func(a, b): return a.data.cout < b.data.cout)

	var resultat: Array = []
	var budget_restant := budget

	while budget_restant > 0.0:
		var abordables: Array = tries.filter(func(e): return float(e.data.cout) <= budget_restant)
		if abordables.is_empty():
			break

		var poids_total := 0.0
		var poids: Array[float] = []
		for e in abordables:
			var p := float(e.data.poids) * lerpf(1.0 / float(e.data.cout), float(e.data.cout), ratio)
			poids.append(p)
			poids_total += p

		var tirage := randf() * poids_total
		var cumul  := 0.0
		var choix  = abordables[0]
		for i in range(abordables.size()):
			cumul += poids[i]
			if tirage <= cumul:
				choix = abordables[i]
				break

		resultat.append(choix)
		budget_restant -= float(choix.data.cout)

	print("WaveManager [vague %d] → %d ennemis générés" % [numero, resultat.size()])
	return resultat

# ── Spawn ──────────────────────────────────────

func _spawner_depuis_liste() -> void:
	if _ennemis_spawnes >= _liste_spawn.size():
		return
	var entry = _liste_spawn[_ennemis_spawnes]

	if entry is EntreeBoss:
		var nb = max(entry.nb_ennemis, 1)
		for i in range(nb):
			var boss: Boss_Base = entry.scene.instantiate() as Boss_Base
			boss.stats = entry.data
			boss.spawn_comme_ennemi_normal = true
			boss.global_position = _calculer_position_spawn()
			conteneur_ennemis.add_child(boss)
	else:
		var ennemi: Enemy_Base = entry.scene.instantiate()
		ennemi.stats           = entry.data
		ennemi.global_position = _calculer_position_spawn()
		conteneur_ennemis.add_child(ennemi)

	_ennemis_spawnes += 1

func _spawner_boss(boss_entry: EntreeBoss) -> void:
	for i in range(boss_entry.nb_ennemis):
		var ennemi: Boss_Base = boss_entry.scene.instantiate() as Boss_Base
		ennemi.stats           = boss_entry.data
		ennemi.global_position = _calculer_position_spawn()
		conteneur_ennemis.add_child(ennemi)
		ennemi.scale = Vector2(multiplicateur_taille_boss, multiplicateur_taille_boss)
		conteneur_ennemis.add_child(ennemi)

func _calculer_position_spawn() -> Vector2:
	match spawn_config.zone:
		SpawnConfig.ZoneType.BORDS_ECRAN:          return _spawn_bords_ecran(spawn_config.marge_bords)
		SpawnConfig.ZoneType.CERCLE_AUTOUR_JOUEUR: return _spawn_cercle(joueur.global_position, spawn_config.rayon_cercle)
		SpawnConfig.ZoneType.POINT_FIXE:           return spawn_config.position_fixe
	return Vector2.ZERO

func _spawn_bords_ecran(marge: float) -> Vector2:
	var cam    := get_viewport().get_camera_2d()
	var centre := cam.get_screen_center_position()
	var demi   := get_viewport().get_visible_rect().size * 0.5
	
	var min_x := cam.limit_left + 64.0
	var max_x := cam.limit_right - 64.0
	var min_y := cam.limit_top + 64.0
	var max_y := cam.limit_bottom - 64.0

	var cotes_valides := []
	
	if centre.y - demi.y - marge >= min_y:
		cotes_valides.append(0) # Haut
	if centre.y + demi.y + marge <= max_y:
		cotes_valides.append(1) # Bas
	if centre.x - demi.x - marge >= min_x:
		cotes_valides.append(2) # Gauche
	if centre.x + demi.x + marge <= max_x:
		cotes_valides.append(3) # Droite

	if cotes_valides.is_empty():
		cotes_valides = [0, 1, 2, 3]

	var cote_choisi = cotes_valides.pick_random()

	match cote_choisi:
		0: return Vector2(clampf(randf_range(centre.x - demi.x, centre.x + demi.x), min_x, max_x),
						  centre.y - demi.y - marge)
		1: return Vector2(clampf(randf_range(centre.x - demi.x, centre.x + demi.x), min_x, max_x),
						  centre.y + demi.y + marge)
		2: return Vector2(centre.x - demi.x - marge,
						  clampf(randf_range(centre.y - demi.y, centre.y + demi.y), min_y, max_y))
		_: return Vector2(centre.x + demi.x + marge,
						  clampf(randf_range(centre.y - demi.y, centre.y + demi.y), min_y, max_y))

func _spawn_cercle(centre: Vector2, rayon: float) -> Vector2:
	var angle := randf() * TAU
	return centre + Vector2(cos(angle), sin(angle)) * rayon

# ── Accesseurs publics ─────────────────────────

func get_numero_vague() -> int:
	return _numero_vague

func get_progression_vague() -> float:
	if _etat != _Etat.VAGUE:
		return 0.0
	return clampf(_timer_vague / _duree_vague_courante, 0.0, 1.0)

func est_en_mode_infini() -> bool:
	# En mode infini il n'y a plus de fin définie, les vagues continuent indéfiniment
	return mode_infini and _numero_vague > 0

func _lancer_dialogue_boss() -> void:
	if scene_dialogue == null:
		push_error("WaveManager : scène de dialogue non assignée !")
		return
	get_tree().paused = true
	var dialogue = scene_dialogue.instantiate()
	get_tree().current_scene.add_child(dialogue)
