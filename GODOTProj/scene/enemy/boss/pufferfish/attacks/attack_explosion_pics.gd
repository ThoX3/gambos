extends BossAttack
class_name AttackExplosionPics

func _init() -> void:
	id = "explosion_pics"
	poids = 2.5
	cooldown_attaque = 7.0
	portee_min = 0.0
	portee_max = 9999.0
	combo_suivant_id = ""


func executer(boss) -> void:
	if boss._est_mort or not is_instance_valid(boss): return

	boss.sprite.sprite_frames.set_animation_loop("explode", false)
	boss.sprite.play("explode")
	if not await boss._attendre_timer(0.4): return

	_tirer_pics_en_cercle(boss)

	if not boss._est_mort:
		boss.sprite.play("walk")
	if not await boss._attendre_timer(0.3): return


func _tirer_pics_en_cercle(boss) -> void:
	if boss.pic_scene == null:
		push_warning("[Poisson] pic_scene non assignée !")
		return
	var angle_step = TAU / float(boss.nombre_pics)
	for i in range(boss.nombre_pics):
		var proj = boss.pic_scene.instantiate()
		var angle = i * angle_step
		proj.global_position = boss.global_position
		if "vitesse" in proj:
			proj.vitesse = boss.vitesse_pics
		if "degats" in proj:
			proj.degats = boss.degats_explosion_pics
		boss.get_parent().add_child(proj)
		# direction APRÈS add_child pour que @onready soit prêt
		if "direction" in proj:
			proj.direction = Vector2(cos(angle), sin(angle))
