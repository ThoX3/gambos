class_name WaveManager
extends Node

## ─────────────────────────────────────────────
##  WaveManager.gd — Gestionnaire de vagues
## ─────────────────────────────────────────────

## Liste ordonnée des vagues de la partie
@export var vagues: Array[Wave] = []

## Fichier unique de configuration de l'équilibrage
@export var config: BalancingConfig

## Pause entre deux vagues (secondes)
@export_range(0.0, 30.0, 0.5) var pause_entre_vagues: float = 3.0

## Si vrai, la liste boucle indéfiniment (mode sans fin)
@export var boucler: bool = false

## Nœud joueur — sert à calculer les positions de spawn
@export var joueur: Node2D

## Conteneur parent des ennemis instanciés
@export var conteneur_ennemis: Node

@export var scene_dialogue: PackedScene


# ── Signaux ────────────────────────────────────

signal vague_demarree(numero: int, vague: Wave)
signal vague_terminee(numero: int)
signal toutes_vagues_terminees


# ── État interne ───────────────────────────────

enum _Etat { PAUSE, VAGUE, FINI }

var _etat: _Etat          = _Etat.FINI
var _index_vague: int     = 0
var _ennemis_spawnes: int = 0
var _timer_vague: float   = 0.0
var _timer_spawn: float   = 0.0
var _timer_pause: float   = 0.0
var _intervalle_spawn: float = 1.0
var _duree_vague_courante: float = 30.0

## Liste d'ennemis pré-calculée pour la vague courante
var _liste_spawn: Array[EnemySpawn] = []


# ── Cycle de vie ───────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	joueur = get_tree().get_first_node_in_group("Player")

	if vagues.is_empty():
		push_warning("WaveManager : aucune vague configurée.")
		return
	if config == null:
		push_error("WaveManager : aucun BalancingConfig assigné dans l'inspecteur !")
		return
	if joueur == null:
		push_error("WaveManager : joueur introuvable.")
		return
	if conteneur_ennemis == null:
		push_error("WaveManager : conteneur_ennemis non assigné.")
		return


func _process(delta: float) -> void:
	match _etat:
		_Etat.PAUSE:
			_timer_pause += delta
			if _timer_pause >= pause_entre_vagues:
				_timer_pause = 0.0
				_demarrer_vague(_index_vague)

		_Etat.VAGUE:
			_tick_vague(delta)

		_Etat.FINI:
			pass


# ── Logique de vague ───────────────────────────

func _tick_vague(delta: float) -> void:
	_timer_vague += delta
	_timer_spawn += delta

	if _ennemis_spawnes < _liste_spawn.size() and _timer_spawn >= _intervalle_spawn:
		_timer_spawn = 0.0
		_spawner_depuis_liste(vagues[_index_vague])

	if _timer_vague >= _duree_vague_courante:
		_terminer_vague()


func _demarrer_vague(index: int) -> void:
	var vague := vagues[index]

	_ennemis_spawnes = 0
	_timer_vague     = 0.0
	_timer_spawn     = 0.0

	if vague.est_vague_de_boss:
		_liste_spawn             = []
		_duree_vague_courante    = vague.duree
		_intervalle_spawn        = vague.duree
		_etat                    = _Etat.VAGUE
		vague_demarree.emit(index, vague)
		_spawner_ennemi(vague)
		_lancer_dialogue_boss()
	else:
		var numero := index + 1   # 1-based
		_liste_spawn          = _generer_liste_spawn(vague, numero)
		_duree_vague_courante = _calculer_duree(numero)
		_intervalle_spawn     = _duree_vague_courante / max(float(_liste_spawn.size()), 1.0)
		_etat                 = _Etat.VAGUE
		vague_demarree.emit(index, vague)


func _terminer_vague() -> void:
	vague_terminee.emit(_index_vague)
	_index_vague += 1

	if _index_vague >= vagues.size():
		if boucler:
			_index_vague = 0
		else:
			_etat = _Etat.FINI
			toutes_vagues_terminees.emit()
			return

	_etat = _Etat.PAUSE


# ── Équations de l'équilibrage ─────────────────
#
#  Tout est calculé à partir de config (BalancingConfig).
#  Tu n'as qu'à modifier ce fichier .tres pour rééquilibrer le jeu.

func _calculer_budget(numero: int) -> float:
	var base   := config.budget_base * (1.0 + config.budget_facteur * pow(float(numero), config.budget_exposant))
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

		# Sélection pondérée :
		#   ratio=0.0 → favorise les ennemis peu coûteux (beaucoup d'ennemis faibles)
		#   ratio=1.0 → favorise les ennemis coûteux   (peu d'ennemis forts)
		var poids_total := 0.0
		var poids: Array[float] = []
		for e in abordables:
			var p_masse := 1.0 / float(e.cout)
			var p_elite := float(e.cout)
			var p       := lerpf(p_masse, p_elite, ratio)
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
	var config_ennemi: EnemySpawn = _liste_spawn[_ennemis_spawnes]
	var ennemi: Enemy_Base = config_ennemi.scene.instantiate()
	ennemi.stats = config_ennemi.data
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
		Wave.ZoneType.BORDS_ECRAN:
			return _spawn_bords_ecran(vague.marge_bords)
		Wave.ZoneType.CERCLE_AUTOUR_JOUEUR:
			return _spawn_cercle(joueur.global_position, vague.rayon_cercle)
		Wave.ZoneType.POINT_FIXE:
			return vague.position_fixe
	return Vector2.ZERO


func _spawn_bords_ecran(marge: float) -> Vector2:
	var cam    := get_viewport().get_camera_2d()
	var centre := cam.global_position if cam else joueur.global_position
	var demi   := get_viewport().get_visible_rect().size * 0.5
	var bornXmin := 64
	var bornXmax := 2624 - 64
	var bornYmin := 64
	var bornYmax := 1472 - 64

	match randi() % 4:
		0: return Vector2(clampf(randf_range(centre.x - demi.x, centre.x + demi.x), bornXmin, bornXmax),
						  clampf(centre.y - demi.y - marge, bornYmin, bornYmax))
		1: return Vector2(clampf(randf_range(centre.x - demi.x, centre.x + demi.x), bornXmin, bornXmax),
						  clampf(centre.y + demi.y + marge, bornYmin, bornYmax))
		2: return Vector2(clampf(centre.x - demi.x - marge, bornXmin, bornXmax),
						  clampf(randf_range(centre.y - demi.y, centre.y + demi.y), bornYmin, bornYmax))
		_: return Vector2(clampf(centre.x + demi.x + marge, bornXmin, bornXmax),
						  clampf(randf_range(centre.y - demi.y, centre.y + demi.y), bornYmin, bornYmax))


func _spawn_cercle(centre: Vector2, rayon: float) -> Vector2:
	var angle := randf() * TAU
	return centre + Vector2(cos(angle), sin(angle)) * rayon


# ── Accesseurs publics ─────────────────────────

func get_index_vague() -> int:
	return _index_vague

func get_progression_vague() -> float:
	if vagues.is_empty() or _etat != _Etat.VAGUE:
		return 0.0
	return clampf(_timer_vague / _duree_vague_courante, 0.0, 1.0)


func _lancer_dialogue_boss() -> void:
	if scene_dialogue == null:
		push_error("WaveManager : scène de dialogue non assignée !")
		return
	get_tree().paused = true
	var dialogue = scene_dialogue.instantiate()
	get_tree().current_scene.add_child(dialogue)
