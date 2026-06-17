extends BossAttack

func _init() -> void:
	id               = "explosion_pics"
	poids            = 2.5
	cooldown_attaque = 7.0
	portee_max       = 9999.0
	combo_suivant_id = ""

func executer(boss: Node) -> void:
	if not boss.has_method("_lancer_explosion_pics"):
		push_warning("attaque_explosion_pics : boss incompatible (" + boss.get_script().resource_path + ")")
		return
	await boss.call("_lancer_explosion_pics")
