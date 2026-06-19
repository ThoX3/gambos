extends Boss_Base

@onready var collision_physique = $CollisionShape2D

@export_category("Paramètres Poisson-Globe")
@export var pic_scene: PackedScene

@export var degats_charge: int = 25
@export var degats_explosion_pics: int = 30
@export var degats_nuage_poison: int = 15

@export var vitesse_charge: float = 800.0
@export var duree_charge: float = 3.0
@export var nombre_rebonds_max: int = 6

@export var rayon_nuage_poison: float = 300.0
@export var duree_nuage_poison: float = 4.0
@export var tick_poison: float = 0.5

@export_category("Effet Poison sur le joueur")
@export var poison_duree: float = 20.0
@export var poison_degats_tick: int = 1
@export var poison_intervalle: float = 1.0
@export var poison_ralenti: float = 0.20

@export var nombre_pics: int = 16
@export var vitesse_pics: float = 600.0

var _attaques_instanciees: Array[BossAttack] = []
var _attaque_forcee: BossAttack = null
var _en_train_de_combo: bool = false
var _derniere_attaque_id: String = ""

var _en_charge: bool = false
var _direction_charge: Vector2 = Vector2.ZERO
var _timer_charge: float = 0.0
var _rebonds_restants: int = 0
var _est_mort: bool = false
var _en_fumee: bool = false
var _echelle_normale: Vector2 = Vector2.ONE


func _ready() -> void:
	super._ready()
	for script in stats.attack_scripts:
		_attaques_instanciees.append(script.new())
	_echelle_normale = scale
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if _est_mort or not is_inside_tree():
		return

	if _en_charge:
		_timer_charge -= delta
		if _timer_charge <= 0.0 or _rebonds_restants <= 0:
			_en_charge = false
		else:
			# Limites de la CAMÉRA (coords monde)
			var cam = get_viewport().get_camera_2d()
			if cam == null:
				_en_charge = false
				return
			var marge = 40.0
			var min_x = cam.limit_left + marge
			var max_x = cam.limit_right - marge
			var min_y = cam.limit_top + marge
			var max_y = cam.limit_bottom - marge

			var rebond = false
			if global_position.x <= min_x or global_position.x >= max_x:
				rebond = true
			if global_position.y <= min_y or global_position.y >= max_y:
				rebond = true

			if rebond:
				_rebonds_restants -= 1
				global_position.x = clampf(global_position.x, min_x + 1, max_x - 1)
				global_position.y = clampf(global_position.y, min_y + 1, max_y - 1)
				# Au rebond : on RE-VISE la position actuelle du joueur
				if is_instance_valid(player):
					_direction_charge = (player.global_position - global_position).normalized()

			global_position += _direction_charge * vitesse_charge * delta

			# Contact avec le joueur pendant la charge → dégâts seulement (pas de poison)
			if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 60.0:
				if player.has_method("take_damage"):
					player.take_damage(degats_charge)
			return

	# Immobile pendant la phase de fumée
	if _en_fumee:
		if is_instance_valid(player):
			var dir_x_f = player.global_position.x - global_position.x
			if abs(dir_x_f) > 1.0:
				sprite.flip_h = dir_x_f > 0
		return

	super._physics_process(delta)

	# Le boss regarde toujours le joueur — APRÈS super pour écraser le flip d'Enemy_Base
	if is_instance_valid(player):
		var dir_x = player.global_position.x - global_position.x
		if abs(dir_x) > 1.0:
			sprite.flip_h = dir_x > 0


func _peut_attaquer() -> bool:
	return not _en_charge

func _start_attack() -> void:
	if _en_train_de_combo:
		return
	super._start_attack()
	is_attacking = false
	_en_train_de_combo = true

	var distance = global_position.distance_to(player.global_position)
	var temps_actuel = Time.get_ticks_msec()
	var attaque_choisie: BossAttack = null

	while _en_train_de_combo:
		if _est_mort or not is_instance_valid(self) or not is_inside_tree():
			return
		distance = global_position.distance_to(player.global_position)
		temps_actuel = Time.get_ticks_msec()
		attaque_choisie = null

		if _attaque_forcee != null:
			if temps_actuel >= _attaque_forcee._prochain_lancement_possible:
				attaque_choisie = _attaque_forcee
			else:
				_attaque_forcee = null

		if attaque_choisie == null:
			var attaques_possibles: Array[BossAttack] = []
			var somme_des_poids: float = 0.0
			for attaque in _attaques_instanciees:
				var cool_ok = temps_actuel >= attaque._prochain_lancement_possible
				var pas_rep = attaque.id != _derniere_attaque_id
				var dist_ok = true
				if attaque.portee_max <= 200.0:
					dist_ok = distance <= attaque.portee_max
				if cool_ok and pas_rep and dist_ok:
					attaques_possibles.append(attaque)
					somme_des_poids += _poids(attaque)

			if attaques_possibles.is_empty():
				break

			var tirage = randf_range(0.0, somme_des_poids)
			var cumul: float = 0.0
			for attaque in attaques_possibles:
				cumul += _poids(attaque)
				if tirage <= cumul:
					attaque_choisie = attaque
					break

		if attaque_choisie != null:
			_derniere_attaque_id = attaque_choisie.id
			attaque_choisie._prochain_lancement_possible = temps_actuel + int(attaque_choisie.cooldown_attaque * 1000.0)
			await attaque_choisie.executer(self)
			if _est_mort or not is_instance_valid(self) or not is_inside_tree():
				return
			_attaque_forcee = null
			if attaque_choisie.combo_suivant_id != "":
				for attaque in _attaques_instanciees:
					if attaque.id == attaque_choisie.combo_suivant_id:
						_attaque_forcee = attaque
						break
			if _attaque_forcee != null:
				await get_tree().create_timer(0.05).timeout
			else:
				break
		else:
			break

	_en_train_de_combo = false
	_attaque_forcee = null
	_attack_timer = 0.15
	_end_attack()
	if not _est_mort:
		sprite.play("walk")


# ── Attaques ──────────────────────────────────────────────────────────

func _lancer_charge() -> void:
	# 1. Préparation — le boss se fige, PAS encore en charge
	if sprite.sprite_frames.has_animation("prepare_speed"):
		sprite.sprite_frames.set_animation_loop("prepare_speed", false)
		sprite.play("prepare_speed")
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout

	if _est_mort or not is_instance_valid(self): return

	# 2. Déclenchement de la charge APRÈS prepare_speed
	_direction_charge = (player.global_position - global_position).normalized()
	_timer_charge     = duree_charge
	_rebonds_restants = nombre_rebonds_max
	_en_charge        = true

	if sprite.sprite_frames.has_animation("speed"):
		sprite.play("speed")

	# 3. Attente de la fin de la charge (rebonds)
	while _en_charge:
		if _est_mort or not is_instance_valid(self) or not is_inside_tree():
			return
		await get_tree().process_frame
		# Re-check APRÈS l'await : le nœud peut avoir été libéré pendant la frame
		if _est_mort or not is_instance_valid(self) or not is_inside_tree():
			return

	if _est_mort or not is_instance_valid(self): return

	# 4. Fin de charge
	if sprite.sprite_frames.has_animation("finish_speed"):
		sprite.sprite_frames.set_animation_loop("finish_speed", false)
		sprite.play("finish_speed")
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout

	if not _est_mort:
		sprite.play("walk")
	await get_tree().create_timer(0.3).timeout


func _lancer_gonflement_explosif() -> void:
	if _est_mort or not is_instance_valid(self): return
	sprite.sprite_frames.set_animation_loop("explode", false)
	sprite.play("explode")
	await sprite.animation_finished
	if _est_mort or not is_instance_valid(self): return
	_tirer_pics_en_cercle()

	# Phase fumée : invulnérable et immobile dès maintenant
	_en_fumee = true

	# 1. prepare_fumee — transition AVANT le grossissement
	if sprite.sprite_frames.has_animation("prepare_fumee"):
		sprite.sprite_frames.set_animation_loop("prepare_fumee", false)
		sprite.play("prepare_fumee")
		await sprite.animation_finished
		if _est_mort or not is_instance_valid(self): return

	# 2. fumee — c'est ICI qu'il grandit x3
	scale = _echelle_normale * 3.0
	sprite.play("fumee")
	await _creer_nuage_poison()

	# Fin de la phase fumée : on rétablit tout
	scale = _echelle_normale
	_en_fumee = false

	if not _est_mort:
		sprite.play("walk")
	await get_tree().create_timer(0.4).timeout


func _lancer_explosion_pics() -> void:
	if _est_mort or not is_instance_valid(self): return
	sprite.sprite_frames.set_animation_loop("explode", false)
	sprite.play("explode")
	await get_tree().create_timer(0.4).timeout
	if _est_mort or not is_instance_valid(self): return
	_tirer_pics_en_cercle()
	if not _est_mort:
		sprite.play("walk")
	await get_tree().create_timer(0.3).timeout


# ── Helpers ───────────────────────────────────────────────────────────

func _tirer_pics_en_cercle() -> void:
	if pic_scene == null:
		push_warning("[Poisson] pic_scene non assignée !")
		return
	var angle_step = TAU / float(nombre_pics)
	for i in range(nombre_pics):
		var proj = pic_scene.instantiate()
		var angle = i * angle_step
		proj.global_position = global_position
		if "vitesse" in proj:
			proj.vitesse = vitesse_pics
		if "degats" in proj:
			proj.degats = degats_explosion_pics
		get_parent().add_child(proj)
		# direction APRÈS add_child pour que @onready soit prêt
		if "direction" in proj:
			proj.direction = Vector2(cos(angle), sin(angle))


func _creer_nuage_poison() -> void:
	var elapsed: float = 0.0
	var tick_elapsed: float = 0.0
	while elapsed < duree_nuage_poison:
		if _est_mort or not is_instance_valid(self): return
		var delta = get_process_delta_time()
		elapsed      += delta
		tick_elapsed += delta
		if tick_elapsed >= tick_poison:
			tick_elapsed = 0.0
			if is_instance_valid(player) and global_position.distance_to(player.global_position) <= rayon_nuage_poison:
				if player.has_method("take_damage"):
					player.take_damage(degats_nuage_poison)
				if player.has_method("apply_poison"):
					player.apply_poison(poison_duree, poison_degats_tick, poison_intervalle, poison_ralenti)
		await get_tree().process_frame


func _poids(attaque: BossAttack) -> float:
	return attaque.poids if "poids" in attaque else 1.0


# ── Mort ──────────────────────────────────────────────────────────────

func take_damage(amount: int) -> int:
	if _est_mort or is_queued_for_deletion():
		return 0
	# Invulnérable pendant la phase de fumée
	if _en_fumee:
		return 0
	var loss_hp: int = super.take_damage(amount)
	if not spawn_comme_ennemi_normal:
		GameManager.boss_health_changed.emit(stats.max_hp, hp)
	# Effet visuel de hit (flash blanc rapide en plus du rouge d'Enemy_Base)
	_effet_hit()
	return loss_hp


func _effet_hit() -> void:
	if not is_instance_valid(sprite):
		return
	# Petit "punch" d'échelle (sauf pendant la fumée où le scale est géré)
	if not _en_fumee:
		var tween := create_tween()
		var base = _echelle_normale
		tween.tween_property(self, "scale", base * 1.12, 0.05)
		tween.tween_property(self, "scale", base, 0.08)


func _on_boss_mort() -> void:
	if _est_mort:
		return
	_est_mort = true
	SaveManager.save_game()
	GameManager.boss_poisson_vaincu.emit()
	if is_inside_tree():
		get_tree().paused = true
	get_tree().call_group("MutationUI", "_ouvrir_menu")
	queue_free()


func _sauvegarder_victoire() -> void:
	SaveManager.save_game()
