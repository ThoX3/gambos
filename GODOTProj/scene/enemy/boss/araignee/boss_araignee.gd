extends Boss_Base

@onready var collision_physique = $CollisionShape2D

@export_category("Paramètres Araignée")
@export var projectile_scene: PackedScene 
@export var degats_broyage: int = 25
@export var degats_balayage_corps: int = 20
@export var degats_projectile: int = 30
@export var vitesse_embuscade: int = 1200
@export var degats_embuscade: int = 35

var _attaques_instanciees: Array[BossAttack] = []
var _attaque_forcee: BossAttack = null
var _en_train_de_combo: bool = false
var _derniere_attaque_id: String = "" 

func _ready() -> void:
	super._ready()
	for script in stats.attack_scripts:
		_attaques_instanciees.append(script.new())

func _peut_attaquer() -> bool:
	return true

func _start_attack() -> void:
	if _en_train_de_combo:
		return
		
	super._start_attack()
	_en_train_de_combo = true
	
	var distance = global_position.distance_to(player.global_position)
	var temps_actuel = Time.get_ticks_msec()
	
	print("\n--- DEBUT SEQUENCE ATTAQUE INTELLIGENTE ---")
	
	var attaque_choisie: BossAttack = null
	
	while _en_train_de_combo:
		distance = global_position.distance_to(player.global_position)
		temps_actuel = Time.get_ticks_msec()
		attaque_choisie = null
		
		if _attaque_forcee != null:
			var cool_ok = temps_actuel >= _attaque_forcee._prochain_lancement_possible
			if cool_ok:
				attaque_choisie = _attaque_forcee
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
				print("=> Fin de séquence : Aucune attaque valide ou disponible à cette distance.")
				break
				
			var tirage = randf_range(0.0, somme_des_poids)
			var poids_cumule: float = 0.0
			
			for attaque in attaques_possibles:
				poids_cumule += autocomplete_poids(attaque)
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

func autocomplete_poids(attaque: BossAttack) -> float:
	return attaque.poids if "poids" in attaque else 1.0
		
func _declencher_nova() -> void:
	var nombre_projectiles = 8
	var angle_step = TAU / float(nombre_projectiles)
	
	for i in range(nombre_projectiles):
		var proj = projectile_scene.instantiate()
		var angle = i * angle_step
		proj.global_position = self.global_position
		
		if "direction" in proj:
			proj.direction = Vector2(cos(angle), sin(angle))
		
		get_parent().add_child(proj)

func take_damage(amount: int) -> int:
	var loss_hp: int = super.take_damage(amount)
	GameManager.boss_health_changed.emit(stats.max_hp ,hp)
	if not is_instance_valid(self) or is_queued_for_deletion():
		_on_boss_mort()
	return loss_hp

func _on_boss_mort() -> void:
	SaveManager.save_game()
	GameManager.boss_araignee_vaincu.emit()

func _sauvegarder_victoire() -> void:
	SaveManager.save_game()
