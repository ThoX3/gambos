class_name WaveManager
extends Node

## ─────────────────────────────────────────────
##  WaveManager.gd — Gestionnaire de vagues
## ─────────────────────────────────────────────

@export var vagues: Array[Wave] = []
@export var config: BalancingConfig
@export_range(0.0, 30.0, 0.5) var pause_entre_vagues: float = 3.0

## Active le mode infini : quand toutes les vagues définies sont épuisées,
## le jeu continue en générant des vagues procédurales de plus en plus dures.
@export var mode_infini: bool = true

@export var joueur: Node2D
@export var conteneur_ennemis: Node
@export var scene_dialogue: PackedScene


# ── Signaux ────────────────────────────────────

signal vague_demarree(numero: int, vague: Wave)
signal vague_terminee(numero: int)
signal toutes_vagues_terminees


# ── État interne ───────────────────────────────

enum _Etat { PAUSE, VAGUE, FINI }

var _etat: _Etat           = _Etat.FINI
var _index_vague: int      = 0   # Position dans le tableau vagues[] (plafonnée en mode infini)
var _numero_vague: int     = 0   # Numéro réel toujours croissant (passé aux équations)
var _ennemis_spawnes: int  = 0
var _timer_vague: float    = 0.0
var _timer_spawn: float    = 0.0
var _timer_pause: float    = 0.0
var _intervalle_spawn: float     = 1.0
var _duree_vague_courante: float = 30.0
var _liste_spawn: Array[EnemySpawn] = []
var _vague_procedurale: Wave = null
var _mode_infini_actif: bool = false  # true dès qu'on dépasse les vagues définies


# ── Cycle de vie ───────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	joueur = get_tree().get_first_node_in_group("Player")
	if vagues.is_empty():
		push_warning("WaveManager : aucune vague configurée.")
	if config == null:
		push_error("WaveManager : aucun BalancingConfig assigné dans l'inspecteur !")
	if joueur == null:
		push_error("WaveManager : joueur introuvable.")
	if conteneur_ennemis == null:
		push_error("WaveManager : conteneur_ennemis non assigné.")

func start_waves() -> void:
	_index_vague       = 0
	_numero_vague      = 0
	_timer_pause       = 0.0
	_vague_procedurale = null
	_mode_infini_actif = false
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
		_Etat.FINI:
			pass


# ── Logique de vague ───────────────────────────

func _tick_vague(delta: float) -> void:
	_timer_vague += delta
	_timer_spawn += delta

	var vague := _vague_courante()

	# Spawn des ennemis normaux depuis la liste pré-calculée
	if not vague.est_vague_de_boss \
	and _ennemis_spawnes < _liste_spawn.size() \
	and _timer_spawn >= _intervalle_spawn:
		_timer_spawn = 0.0
		_spawner_depuis_liste(vague)

	# Fin de vague quand la durée est écoulée
	if _timer_vague >= _duree_vague_courante:
		_terminer_vague()


func _demarrer_vague() -> void:
	_numero_vague   += 1
	_ennemis_spawnes = 0
	_timer_vague     = 0.0
	_timer_spawn     = 0.0

	var vague := _vague_courante()

	if vague.est_vague_de_boss:
		_liste_spawn          = []
		_duree_vague_courante = vague.duree
		_intervalle_spawn     = vague.duree   # inutilisé, mais propre
		_etat                 = _Etat.VAGUE
		vague_demarree.emit(_numero_vague, vague)
		_spawner_ennemi(vague)
		_lancer_dialogue_boss()
	else:
		_liste_spawn          = _generer_liste_spawn(vague, _numero_vague)
		_duree_vague_courante = _calculer_duree(_numero_vague)
		_intervalle_spawn     = _duree_vague_courante / max(float(_liste_spawn.size()), 1.0)
		_etat                 = _Etat.VAGUE
		vague_demarree.emit(_numero_vague, vague)


func _terminer_vague() -> void:
	vague_terminee.emit(_numero_vague)
	_vague_procedurale = null

	# Avance dans la liste tant qu'il reste des vagues définies
	if _index_vague < vagues.size() - 1:
		_index_vague += 1
		_etat = _Etat.PAUSE
		return

	# Toutes les vagues définies sont épuisées
	if mode_infini:
		_mode_infini_actif = true
		_vague_procedurale = null
		_etat = _Etat.PAUSE
	else:
		_etat = _Etat.FINI
		toutes_vagues_terminees.emit()


# ── Résolution de la vague courante ───────────

func _vague_courante() -> Wave:
	if not _mode_infini_actif:
		return vagues[_index_vague]

	# Mode infini : copie légère de la dernière vague NORMALE comme gabarit
	if _vague_procedurale == null:
		var gabarit: Wave = null
		for i in range(vagues.size() - 1, -1, -1):
			if not vagues[i].est_vague_de_boss:
				gabarit = vagues[i]
				break
		if gabarit == null:
			push_error("WaveManager : aucune vague normale trouvée comme gabarit !")
			return vagues[vagues.size() - 1]
		_vague_procedurale                   = Wave.new()
		_vague_procedurale.est_vague_de_boss = false
		_vague_procedurale.zone              = gabarit.zone
		_vague_procedurale.marge_bords       = gabarit.marge_bords
		_vague_procedurale.rayon_cercle      = gabarit.rayon_cercle
		_vague_procedurale.position_fixe     = gabarit.position_fixe
		_vague_procedurale.types_ennemis     = gabarit.types_ennemis
	return _vague_procedurale


# ── Équations de l'équilibrage ─────────────────

func _calculer_budget(numero: int) -> float:
	var base     := config.budget_base * (1.0 + config.budget_facteur * pow(float(numero), config.budget_exposant))
	var variance := randf_range(-config.budget_variance, config.budget_variance)
	return base * (1.0 + variance)

func _calculer_duree(numero: int) -> float:
	return config.duree_base + config.duree_par_vague * float(numero - 1)

func _tirer_ratio_intensite(numero: int) -> float:
	var ratio_brut := randf_range(config.intensite_min, config.intensite_max)
	var biais      := clampf(float(numero) / config.biais_vague_max, 0.0, 1.0) * config.biais_amplitude
	return clampf(ratio_brut + (1.0 - ratio_brut) * biais, 0.0, 1.0)


# ── Génération de la liste de spawn ───────────

func _generer_liste_spawn(vague: Wave, numero: int) -> Array[EnemySpawn]:
	var budget := _calculer_budget(numero)
	var ratio  := _tirer_ratio_intensite(numero)

	print("WaveManager [vague %d] budget=%.1f | ratio_intensité=%.2f" % [numero, budget, ratio])

	if vague.types_ennemis.is_empty():
		push_warning("WaveManager : vague %d sans types_ennemis." % numero)
		return []

	var tries := vague.types_ennemis.duplicate()
	tries.sort_custom(func(a, b): return a.cout < b.cout)

	var resultat: Array[EnemySpawn] = []
	var budget_restant := budget

	while budget_restant > 0.0:
		var abordables: Array = tries.filter(func(e): return float(e.cout) <= budget_restant)
		if abordables.is_empty():
			break

		var poids_total := 0.0
		var poids: Array[float] = []
		for e in abordables:
			var p := lerpf(1.0 / float(e.cout), float(e.cout), ratio)
			poids.append(p)
			poids_total += p

		var tirage := randf() * poids_total
		var cumul  := 0.0
		var choix: EnemySpawn = abordables[0]
		for i in range(abordables.size()):
			cumul += poids[i]
			if tirage <= cumul:
				choix = abordables[i]
				break

		resultat.append(choix)
		budget_restant -= float(choix.cout)

	print("WaveManager [vague %d] → %d ennemis générés" % [numero, resultat.size()])
	return resultat


# ── Spawn ──────────────────────────────────────

func _spawner_depuis_liste(vague: Wave) -> void:
	if _ennemis_spawnes >= _liste_spawn.size():
		return
	var cfg: EnemySpawn = _liste_spawn[_ennemis_spawnes]
	var ennemi: Enemy_Base = cfg.scene.instantiate()
	ennemi.stats = cfg.data
	ennemi.global_position = _calculer_position_spawn(vague)
	conteneur_ennemis.add_child(ennemi)
	_ennemis_spawnes += 1

func _spawner_ennemi(vague: Wave) -> void:
	var cfg: EnemySpawn = vague.types_ennemis[randi() % vague.types_ennemis.size()]
	var ennemi: Enemy_Base = cfg.scene.instantiate()
	ennemi.stats = cfg.data
	ennemi.global_position = _calculer_position_spawn(vague)
	conteneur_ennemis.add_child(ennemi)
	_ennemis_spawnes += 1

func _calculer_position_spawn(vague: Wave) -> Vector2:
	match vague.zone:
		Wave.ZoneType.BORDS_ECRAN:          return _spawn_bords_ecran(vague.marge_bords)
		Wave.ZoneType.CERCLE_AUTOUR_JOUEUR: return _spawn_cercle(joueur.global_position, vague.rayon_cercle)
		Wave.ZoneType.POINT_FIXE:           return vague.position_fixe
	return Vector2.ZERO

func _spawn_bords_ecran(marge: float) -> Vector2:
	var cam    := get_viewport().get_camera_2d()
	var centre := cam.global_position if cam else joueur.global_position
	var demi   := get_viewport().get_visible_rect().size * 0.5
	match randi() % 4:
		0: return Vector2(clampf(randf_range(centre.x - demi.x, centre.x + demi.x), 64, 2560),
						  clampf(centre.y - demi.y - marge, 64, 1408))
		1: return Vector2(clampf(randf_range(centre.x - demi.x, centre.x + demi.x), 64, 2560),
						  clampf(centre.y + demi.y + marge, 64, 1408))
		2: return Vector2(clampf(centre.x - demi.x - marge, 64, 2560),
						  clampf(randf_range(centre.y - demi.y, centre.y + demi.y), 64, 1408))
		_: return Vector2(clampf(centre.x + demi.x + marge, 64, 2560),
						  clampf(randf_range(centre.y - demi.y, centre.y + demi.y), 64, 1408))

func _spawn_cercle(centre: Vector2, rayon: float) -> Vector2:
	var angle := randf() * TAU
	return centre + Vector2(cos(angle), sin(angle)) * rayon


# ── Accesseurs publics ─────────────────────────

func get_index_vague() -> int:
	return _numero_vague

func get_progression_vague() -> float:
	if vagues.is_empty() or _etat != _Etat.VAGUE:
		return 0.0
	return clampf(_timer_vague / _duree_vague_courante, 0.0, 1.0)

func est_en_mode_infini() -> bool:
	return _mode_infini_actif


func _lancer_dialogue_boss() -> void:
	if scene_dialogue == null:
		push_error("WaveManager : scène de dialogue non assignée !")
		return
	get_tree().paused = true
	var dialogue = scene_dialogue.instantiate()
	get_tree().current_scene.add_child(dialogue)
