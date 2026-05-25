class_name WaveManager
extends Node

## ─────────────────────────────────────────────
##  WaveManager.gd — Gestionnaire de vagues
## ─────────────────────────────────────────────

## Liste ordonnée des vagues de la partie
@export var vagues: Array[Wave] = []

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

## Émis au démarrage de chaque vague (index 0-based, ressource Wave)
signal vague_demarree(numero: int, vague: Wave)

## Émis à la fin de chaque vague
signal vague_terminee(numero: int)

## Émis quand toutes les vagues sont épuisées (et boucler = false)
signal toutes_vagues_terminees


# ── Machine à états interne ────────────────────

enum _Etat { PAUSE, VAGUE, FINI }

var _etat: _Etat = _Etat.PAUSE
var _index_vague: int  = 0
var _ennemis_spawnes: int = 0
var _timer_vague: float  = 0.0
var _timer_spawn: float  = 0.0
var _timer_pause: float  = 0.0
var _intervalle_spawn: float = 1.0


# ── Cycle de vie ───────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	joueur = get_tree().get_first_node_in_group("Player")
	
	if vagues.is_empty():
		push_warning("WaveManager : aucune vague configurée.")
		return
	if joueur == null:
		push_error("WaveManager : la référence 'joueur' n'est pas assignée.")
		return
	if conteneur_ennemis == null:
		push_error("WaveManager : la référence 'conteneur_ennemis' n'est pas assignée.")
		return

	_demarrer_vague(0)


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
	var vague := vagues[_index_vague]

	_timer_vague += delta
	_timer_spawn += delta

	# Spawn d'un ennemi à chaque intervalle calculé
	if _ennemis_spawnes < vague.nb_ennemis and _timer_spawn >= _intervalle_spawn:
		_timer_spawn = 0.0
		_spawner_ennemi(vague)

	# Fin de la vague quand la durée est écoulée
	if _timer_vague >= vague.duree:
		_terminer_vague()


func _demarrer_vague(index: int) -> void:
	var vague := vagues[index]

	_ennemis_spawnes  = 0
	_timer_vague      = 0.0
	_timer_spawn      = 0.0
	_intervalle_spawn = vague.duree / max(float(vague.nb_ennemis), 1)
	_etat             = _Etat.VAGUE

	vague_demarree.emit(index, vague)
	
	if vague.est_vague_de_boss:
		_spawner_ennemi(vague)
		_lancer_dialogue_boss()


func _terminer_vague() -> void:
	vague_terminee.emit(_index_vague)
	_index_vague += 1

	# Boucle ou fin
	if _index_vague >= vagues.size():
		if boucler:
			_index_vague = 0
		else:
			_etat = _Etat.FINI
			toutes_vagues_terminees.emit()
			return

	_etat = _Etat.PAUSE  # Attend pause_entre_vagues avant la prochaine


# ── Spawn ──────────────────────────────────────


func _spawner_ennemi(vague: Wave) -> void:
	var config: EnemySpawn = vague.types_ennemis[randi() % vague.types_ennemis.size()]
	var ennemi: Enemy_Base = config.scene.instantiate()
	ennemi.stats = config.data
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
	var cam  := get_viewport().get_camera_2d()
	var centre := cam.global_position if cam else joueur.global_position
	var demi   := get_viewport().get_visible_rect().size * 0.5
	var bornXmin : int = 0 + 64
	var bornXmax : int = 2624 - 64
	var bornYmin : int = 0 + 64
	var bornYmax : int = 1472 - 64

	# Choisit un bord aléatoire, puis un point aléatoire sur ce bord
	match randi() % 4:
		0: # Haut
			return Vector2(
				clampf(
					randf_range(centre.x - demi.x, centre.x + demi.x), 
					bornXmin, 
					bornXmax),
				clampf(centre.y - demi.y - marge,
					bornYmin,
					bornYmax)
			)
		1: # Bas
			return Vector2(
				clampf(
					randf_range(centre.x - demi.x, centre.x + demi.x),
					bornXmin,
					bornXmax),
				clampf(centre.y + demi.y + marge,
					bornYmin,
					bornYmax)
			)
		2: # Gauche
			return Vector2(
				clampf(centre.x - demi.x - marge,
					bornXmin,
					bornXmax),
				clampf(
					randf_range(centre.y - demi.y, centre.y + demi.y),
					bornYmin,
					bornYmax),
			)
		_: # Droite
			return Vector2(
				clampf(centre.x + demi.x + marge,
					bornXmin,
					bornXmax),
				clampf(
					randf_range(centre.y - demi.y, centre.y + demi.y),
					bornYmin,
					bornYmax),
			)


func _spawn_cercle(centre: Vector2, rayon: float) -> Vector2:
	var angle := randf() * TAU
	return centre + Vector2(cos(angle), sin(angle)) * rayon


# ── Accesseurs publics ─────────────────────────

## Retourne l'index (0-based) de la vague en cours
func get_index_vague() -> int:
	return _index_vague

## Retourne la progression de la vague courante (0.0 → 1.0)
func get_progression_vague() -> float:
	if vagues.is_empty() or _etat != _Etat.VAGUE:
		return 0.0
	return clamp(_timer_vague / vagues[_index_vague].duree, 0.0, 1.0)

func _lancer_dialogue_boss() -> void:
	if scene_dialogue != null:
		# 1. On fige le jeu (les ennemis et le timer s'arrêtent)
		get_tree().paused = true 
		
		# 2. On crée la boîte de dialogue
		var dialogue = scene_dialogue.instantiate()
		get_tree().current_scene.add_child(dialogue)
	else:
		push_error("WaveManager : Tu as oublié d'assigner la scène de dialogue !")
