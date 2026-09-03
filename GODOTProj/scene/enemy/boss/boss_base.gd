class_name Boss_Base
extends Enemy_Base

@export var attack_cooldown: float = 3.0
@export var transition_texture: Texture2D
@export var transition_text: String = "UN BOSS EST APPARU !"

const TRANSITION_BOSS_SCENE = preload("res://scene/ui/enemy/boss/transition_boss.tscn")

var _attack_timer: float = 0.0
var is_attacking: bool = false

@export var debug_combos: bool = false

var _attaques_instanciees: Array[BossAttack] = []
var _attaque_forcee: BossAttack = null
var _en_train_de_combo: bool = false
var _derniere_attaque_id: String = ""

## true quand le boss est spawné comme un ennemi normal (mode infini) :
## pas de cinématique, pas de pause, pas de barre de vie spéciale.
var spawn_comme_ennemi_normal: bool = false

func _ready() -> void:
	super._ready() 
	if not spawn_comme_ennemi_normal:
		_lancer_transition_boss()
	_attack_timer = attack_cooldown
	
	if stats and "attack_scripts" in stats:
		for script in stats.attack_scripts:
			_attaques_instanciees.append(script.new())

func _physics_process(delta: float) -> void:
	if not stats or not is_instance_valid(player):
		return

	if not is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0 and _peut_attaquer():
			_start_attack()
		else:
			super._physics_process(delta)
	else:
		_process_attack(delta)

# ── Méthodes "Virtuelles" (À surcharger dans les scripts de tes vrais boss) ──

func _start_attack() -> void:
	if _en_train_de_combo:
		return
		
	is_attacking = true
	_en_train_de_combo = true
	
	var distance = global_position.distance_to(player.global_position)
	var temps_actuel = Time.get_ticks_msec()
	
	if debug_combos:
		print("\n--- DEBUT SEQUENCE ATTAQUE INTELLIGENTE ---")
	
	var attaque_choisie: BossAttack = null
	
	while _en_train_de_combo:
		if not is_instance_valid(self) or not is_inside_tree():
			return
		if not is_instance_valid(player) or ("is_dead" in player and player.is_dead):
			break
			
		distance = global_position.distance_to(player.global_position)
		temps_actuel = Time.get_ticks_msec()
		attaque_choisie = null
		
		if _attaque_forcee != null:
			var cool_ok = temps_actuel >= _attaque_forcee._prochain_lancement_possible
			if cool_ok:
				attaque_choisie = _attaque_forcee
				if debug_combos:
					print("COMBO SCRIPTÉ : ", attaque_choisie.id)
			else:
				_attaque_forcee = null
		
		if attaque_choisie == null:
			var attaques_possibles: Array[BossAttack] = []
			var somme_des_poids: float = 0.0
			
			for attaque in _attaques_instanciees:
				var cool_ok = temps_actuel >= attaque._prochain_lancement_possible
				var pas_repetition = attaque.id != _derniere_attaque_id
				
				var dist_ok = true
				if attaque.portee_max <= 200.0:
					dist_ok = distance <= attaque.portee_max
				
				if cool_ok and pas_repetition and dist_ok:
					attaques_possibles.append(attaque)
					somme_des_poids += attaque.poids
					
			if attaques_possibles.is_empty():
				if debug_combos:
					print("=> Fin de séquence : Aucune attaque valide ou disponible à cette distance.")
				break
				
			var tirage = randf_range(0.0, somme_des_poids)
			var poids_cumule: float = 0.0
			
			for attaque in attaques_possibles:
				poids_cumule += (attaque.poids if "poids" in attaque else 1.0)
				if tirage <= poids_cumule:
					attaque_choisie = attaque
					break
		
		if attaque_choisie != null:
			_derniere_attaque_id = attaque_choisie.id
			attaque_choisie._prochain_lancement_possible = temps_actuel + int(attaque_choisie.cooldown_attaque * 1000.0)
			
			await attaque_choisie.executer(self) 
			
			if not is_instance_valid(self) or not is_inside_tree():
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

func _process_attack(_delta: float) -> void:
	pass

# ── Awaits sécurisés (appelés par les scripts BossAttack) ──
func _attendre_frame() -> bool:
	if not is_instance_valid(self) or not is_inside_tree():
		return false
	await get_tree().process_frame
	while is_instance_valid(self) and is_inside_tree() and get_tree().paused:
		await get_tree().process_frame
	return is_instance_valid(self) and is_inside_tree()

func _attendre_timer(duree: float) -> bool:
	if not is_instance_valid(self) or not is_inside_tree():
		return false
	await get_tree().create_timer(duree, false).timeout
	return is_instance_valid(self) and is_inside_tree()

func _attendre_anim() -> bool:
	if not is_instance_valid(self) or not is_inside_tree():
		return false
	await sprite.animation_finished
	return is_instance_valid(self) and is_inside_tree()

func _peut_attaquer() -> bool:
	return true

func _end_attack() -> void:
	is_attacking = false
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
		
func _lancer_transition_boss() -> void:
	get_tree().paused = true

	var transition_instance = TRANSITION_BOSS_SCENE.instantiate()
	get_tree().root.add_child(transition_instance)
	
	transition_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	transition_instance.setup(transition_text, transition_texture)
	
	await transition_instance.play_transition()
	
	get_tree().paused = false

	await get_tree().create_timer(2.0).timeout
	
func start_breathing_animation():
	pass
