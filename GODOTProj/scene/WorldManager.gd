# scene/world_manager.gd
class_name WorldManager
extends Node

@export var mondes: Array[WorldConfig] = []
@export var mode_infini_config: Array[WorldConfig] = [] 

var _index_monde_courant: int = 0
var _mode_infini_actif: bool = false
var _vague_debut_infini: int = -1
var _segment_infini_courant: int = -1

signal segment_infini_change(config: WorldConfig)
signal monde_change(nouveau_monde: WorldConfig)
signal partie_terminee_tous_mondes  # déclenche le mode infini

func demarrer_depuis_sauvegarde() -> void:
	_index_monde_courant = SaveManager.current_save.monde_actuel_index
	_appliquer_monde(_index_monde_courant)

func passer_monde_suivant() -> void:
	SaveManager.current_save.mondes_completes += 1
	_index_monde_courant += 1
	SaveManager.current_save.mondes_completes_total = max(
		SaveManager.current_save.mondes_completes_total,
		_index_monde_courant
	)

	if _index_monde_courant >= mondes.size():
		_mode_infini_actif = true
		partie_terminee_tous_mondes.emit()
		_appliquer_monde_infini()
	else:
		SaveManager.current_save.monde_actuel_index = _index_monde_courant
		SaveManager.save_game()
		_appliquer_monde(_index_monde_courant)

func get_monde_courant() -> WorldConfig:
	if _mode_infini_actif:
		return mode_infini_config[max(_segment_infini_courant, 0)] if not mode_infini_config.is_empty() else null
	return mondes[_index_monde_courant]

func _appliquer_monde(index: int) -> void:
	monde_change.emit(mondes[index])

func _appliquer_monde_infini() -> void:
	if mode_infini_config.is_empty():
		push_error("WorldManager : mode_infini_config est vide dans l'inspecteur !")
		return
	_segment_infini_courant = 0
	monde_change.emit(mode_infini_config[0])

func get_nom_monde_suivant() -> String:
	var index_suivant := _index_monde_courant + 1
	if index_suivant >= mondes.size():
		return "Mode Infini"
	return mondes[index_suivant].nom

func verifier_segment_infini(numero_vague: int) -> void:
	if not _mode_infini_actif or mode_infini_config.is_empty():
		return
	# On mémorise la première vague de l'infini, une seule fois (pas de 61 en dur)
	if _vague_debut_infini < 0:
		_vague_debut_infini = numero_vague

	var total_cycle := 0
	for cfg in mode_infini_config:
		total_cycle += max(cfg.vagues_par_monde, 1)

	var position := (numero_vague - _vague_debut_infini) % total_cycle
	var index := 0
	var cumul := 0
	for i in mode_infini_config.size():
		cumul += max(mode_infini_config[i].vagues_par_monde, 1)
		if position < cumul:
			index = i
			break

	if index != _segment_infini_courant:
		_segment_infini_courant = index
		segment_infini_change.emit(mode_infini_config[index])
