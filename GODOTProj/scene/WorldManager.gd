# scene/world_manager.gd
class_name WorldManager
extends Node

@export var mondes: Array[WorldConfig] = []
@export var mode_infini_config: WorldConfig  # config pour l'infini

var _index_monde_courant: int = 0
var _mode_infini_actif: bool = false

signal monde_change(nouveau_monde: WorldConfig)
signal partie_terminee_tous_mondes  # déclenche le mode infini

func demarrer_depuis_sauvegarde() -> void:
	_index_monde_courant = SaveManager.current_save.monde_actuel_index
	_appliquer_monde(_index_monde_courant)

func passer_monde_suivant() -> void:
	SaveManager.current_save.mondes_completes += 1
	_index_monde_courant += 1

	if _index_monde_courant >= mondes.size():
		_mode_infini_actif = true
		partie_terminee_tous_mondes.emit()
		_appliquer_monde_infini()
	else:
		SaveManager.current_save.monde_actuel_index = _index_monde_courant
		SaveManager.save_game()
		_appliquer_monde(_index_monde_courant)

func get_monde_courant() -> WorldConfig:
	return mondes[_index_monde_courant] if not _mode_infini_actif else mode_infini_config

func _appliquer_monde(index: int) -> void:
	monde_change.emit(mondes[index])

func _appliquer_monde_infini() -> void:
	monde_change.emit(mode_infini_config)

func get_nom_monde_suivant() -> String:
	var index_suivant := _index_monde_courant + 1
	if index_suivant >= mondes.size():
		return "Mode Infini"
	return mondes[index_suivant].nom
