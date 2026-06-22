extends Boss_Base

@onready var collision_physique = $CollisionShape2D

@export_category("Paramètres Poulpe")
@export var ink_bubble_scene: PackedScene

@export var degats_tentacule: int = 25
@export var degats_bulle_encre: int = 15
@export var degats_tremblement: int = 10

@export var vitesse_bulle_encre: float = 150.0
@export var nombre_bulles: int = 2
@export var delai_relance_apres_expiration: float = 5.0

@export var portee_tentacule: float = 90.0
@export var rayon_tremblement: float = 250.0

@export_category("Camouflage")
@export var camouflage_alpha: float = 0.25
@export var camouflage_duree: float = 3.0
@export var camouflage_reduction_degats: float = 0.5
@export var camouflage_vitesse_ruee: float = 350.0   
@export var camouflage_degats_contact: int = 20      
@export var camouflage_distance_contact: float = 50.0

var _attaques_instanciees: Array[BossAttack] = []
var _attaque_forcee: BossAttack = null
var _en_train_de_combo: bool = false
var _derniere_attaque_id: String = ""

var _est_mort: bool = false
var _echelle_normale: Vector2 = Vector2.ONE

# --- Gestion des bulles d'encre en vol (lu/écrit par AttackBullesEncre) ---
var _bulles_actives: Array[BossInkBubble] = []
var _bulle_en_attente_relance: bool = false

# --- Camouflage (lu/écrit par AttackCamouflage) ---
var _en_camouflage: bool = false

var _etat_special_actif: bool = false
var _physics_process_special: Callable = Callable()

func _ready() -> void:
	super._ready()
	for script in stats.attack_scripts:
		_attaques_instanciees.append(script.new())
	# LOG : liste des attaques chargées au démarrage
	var ids: Array = []
	for a in _attaques_instanciees:
		ids.append(a.id)
	print("[POULPE] attaques chargées : ", ids)
	_echelle_normale = scale
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if _est_mort or not is_inside_tree():
		return

	if _etat_special_actif:
		# Une attaque a pris la main sur le mouvement (charge, camouflage, etc.)
		if _physics_process_special.is_valid():
			var continue_special: bool = _physics_process_special.call(delta)
			if not continue_special:
				_etat_special_actif = false
				_physics_process_special = Callable()
		return

	super._physics_process(delta)

	# Le boss regarde toujours le joueur — APRÈS super
	if is_instance_valid(player):
		var dir_x = player.global_position.x - global_position.x
		if abs(dir_x) > 1.0:
			sprite.flip_h = dir_x > 0


func _peut_attaquer() -> bool:
	return not _en_camouflage


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
				print("[POULPE] attaque FORCÉE (combo) : ", _attaque_forcee.id)
			else:
				_attaque_forcee = null

		if attaque_choisie == null:
			var attaques_possibles: Array[BossAttack] = []
			var somme_des_poids: float = 0.0
			for attaque in _attaques_instanciees:
				var pas_rep = attaque.id != _derniere_attaque_id
				if pas_rep and attaque.peut_attaquer(distance, temps_actuel):
					attaques_possibles.append(attaque)
					somme_des_poids += _poids(attaque)

			# LOG : quelles attaques sont éligibles ce tour-ci ?
			var ids_possibles: Array = []
			for a in attaques_possibles:
				ids_possibles.append(a.id)
			print("[POULPE] distance=", int(distance), " | éligibles=", ids_possibles)

			if attaques_possibles.is_empty():
				print("[POULPE] aucune attaque éligible → fin du combo")
				break

			var tirage = randf_range(0.0, somme_des_poids)
			var cumul: float = 0.0
			for attaque in attaques_possibles:
				cumul += _poids(attaque)
				if tirage <= cumul:
					attaque_choisie = attaque
					break

		if attaque_choisie != null:
			print("[POULPE] >>> LANCE : ", attaque_choisie.id)
			_derniere_attaque_id = attaque_choisie.id
			attaque_choisie._prochain_lancement_possible = temps_actuel + int(attaque_choisie.cooldown_attaque * 1000.0)
			await attaque_choisie.executer(self)
			print("[POULPE] <<< TERMINÉ : ", attaque_choisie.id)
			if _est_mort or not is_instance_valid(self) or not is_inside_tree():
				return
			_attaque_forcee = null
			if attaque_choisie.combo_suivant_id != "":
				for attaque in _attaques_instanciees:
					if attaque.id == attaque_choisie.combo_suivant_id:
						_attaque_forcee = attaque
						break
			if _attaque_forcee != null:
				if not await _attendre_timer(0.05): return
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


# ── Helpers ───────────────────────────────────────────────────────────

func _poids(attaque: BossAttack) -> float:
	return attaque.poids if "poids" in attaque else 1.0


# ── Awaits sécurisés (appelés par les scripts BossAttack via boss._attendre_xxx) ──

func _attendre_frame() -> bool:
	if _est_mort or not is_instance_valid(self) or not is_inside_tree():
		return false
	await get_tree().process_frame
	return _est_mort == false and is_instance_valid(self) and is_inside_tree()


func _attendre_timer(duree: float) -> bool:
	if _est_mort or not is_instance_valid(self) or not is_inside_tree():
		return false
	await get_tree().create_timer(duree, false).timeout  # false = ne pas ignorer la pause
	return _est_mort == false and is_instance_valid(self) and is_inside_tree()

func _attendre_anim() -> bool:
	if _est_mort or not is_instance_valid(self) or not is_inside_tree():
		return false
	await sprite.animation_finished
	return _est_mort == false and is_instance_valid(self) and is_inside_tree()


# ── Mort ──────────────────────────────────────────────────────────────

func take_damage(amount: int) -> int:
	if _est_mort or is_queued_for_deletion():
		return 0

	var degats_reels := amount
	if _en_camouflage:
		degats_reels = int(round(amount * (1.0 - camouflage_reduction_degats)))

	var loss_hp: int = super.take_damage(degats_reels)
	if not spawn_comme_ennemi_normal:
		GameManager.boss_health_changed.emit(stats.max_hp, hp)
	_effet_hit()
	return loss_hp


func _effet_hit() -> void:
	if not is_instance_valid(sprite):
		return
	var tween := create_tween()
	var base = _echelle_normale
	tween.tween_property(self, "scale", base * 1.12, 0.05)
	tween.tween_property(self, "scale", base, 0.08)


func _on_boss_mort() -> void:
	if _est_mort:
		return
	_est_mort = true
	SaveManager.save_game()
	GameManager.boss_poulpe_vaincu.emit()
	if is_inside_tree():
		get_tree().paused = true
	get_tree().call_group("MutationUI", "_ouvrir_menu")
	queue_free()


func _sauvegarder_victoire() -> void:
	SaveManager.save_game()
