extends BossAttack
class_name AttackTentacule

func _init() -> void:
	id = "tentacule"
	cooldown_attaque = 4.0
	portee_min = 0.0
	portee_max = 150.0
	poids = 10.0
	combo_suivant_id = ""


func executer(boss) -> void:
	if not is_instance_valid(boss) or boss._est_mort: return

	# Animation d'attaque corps à corps
	if boss.sprite.sprite_frames.has_animation("attack"):
		boss.sprite.sprite_frames.set_animation_loop("attack", false)
		boss.sprite.play("attack")
		# Laisse l'anim avancer jusqu'au moment de l'impact (mi-animation)
		if not await boss._attendre_timer(0.2): return
	else:
		if not await boss._attendre_timer(0.4): return

	# Frappe : dégâts si le joueur est à portée au moment de l'impact
	if is_instance_valid(boss.player) and boss.global_position.distance_to(boss.player.global_position) <= boss.portee_tentacule:
		if boss.player.has_method("take_damage"):
			boss.player.take_damage(boss.degats_tentacule)
		AudioManager.play_sound_2d("tentacule_impact", boss.global_position)

	# Attend la fin de l'animation d'attaque
	if boss.sprite.sprite_frames.has_animation("attack"):
		if not await boss._attendre_anim(): return

	if not boss._est_mort:
		boss.sprite.play("walk")
	if not await boss._attendre_timer(0.3): return
