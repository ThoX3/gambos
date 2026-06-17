extends BossAttack

func _init() -> void:
	id               = "gonflement_explosif"
	poids            = 2.0
	cooldown_attaque = 10.0
	portee_max       = 9999.0
	combo_suivant_id = ""

func executer(boss: Node) -> void:
	if not boss.has_method("_lancer_gonflement_explosif"):
		push_warning("attaque_gonflement_explosif : boss incompatible (" + boss.get_script().resource_path + ")")
		return
	await boss.call("_lancer_gonflement_explosif")
