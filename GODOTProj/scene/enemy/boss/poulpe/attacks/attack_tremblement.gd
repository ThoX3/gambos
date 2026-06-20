extends BossAttack
class_name AttackTremblement

func _init() -> void:
	id = "tremblement"
	cooldown_attaque = 8.0
	portee_min = 0.0
	portee_max = 600.0
	poids = 10.0
	combo_suivant_id = ""


func executer(boss) -> void:
	if boss._est_mort or not is_instance_valid(boss): return

	if boss.sprite.sprite_frames.has_animation("prepare_tremblement"):
		boss.sprite.sprite_frames.set_animation_loop("prepare_tremblement", false)
		boss.sprite.play("prepare_tremblement")
		if not await boss._attendre_anim(): return
	else:
		if not await boss._attendre_timer(0.5): return

	if boss.sprite.sprite_frames.has_animation("tremblement"):
		boss.sprite.sprite_frames.set_animation_loop("tremblement", false)
		boss.sprite.play("tremblement")

	_secouer_camera(boss)

	if is_instance_valid(boss.player) and boss.global_position.distance_to(boss.player.global_position) <= boss.rayon_tremblement:
		if boss.player.has_method("take_damage"):
			boss.player.take_damage(boss.degats_tremblement)
		if boss.player.has_method("apply_stun"):
			boss.player.apply_stun(0.6)

	if not await boss._attendre_anim(): return

	if not boss._est_mort:
		boss.sprite.play("walk")
	if not await boss._attendre_timer(0.4): return


func _secouer_camera(boss) -> void:
	var cam = boss.get_viewport().get_camera_2d()
	if cam == null or not cam.has_method("shake"):
		return
	cam.shake()
