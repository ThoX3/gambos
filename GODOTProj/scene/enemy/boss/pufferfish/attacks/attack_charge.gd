extends BossAttack

func _init() -> void:
	id               = "charge_frenetique"
	poids            = 3.0
	cooldown_attaque = 6.0
	portee_max       = 9999.0
	combo_suivant_id = ""

func executer(boss: Node) -> void:
	if not boss.has_method("_lancer_charge"):
		push_warning("attaque_charge : boss incompatible (" + boss.get_script().resource_path + ")")
		return
	await boss.call("_lancer_charge")
