class_name BossAttack
extends RefCounted

var id: String = ""
var portee_min: float = 0.0
var portee_max: float = 9999.0
var poids: float = 10.0
var cooldown_attaque: float = 0.0
var _prochain_lancement_possible: int = 0

var combo_suivant_id: String = "" 

func peut_attaquer(distance: float, temps_actuel_msec: int) -> bool:
	return distance >= portee_min and distance <= portee_max and temps_actuel_msec >= _prochain_lancement_possible

func executer(boss) -> void:
	pass
