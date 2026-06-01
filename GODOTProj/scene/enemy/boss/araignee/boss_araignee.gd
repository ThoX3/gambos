extends Boss_Base

signal health_changed(current_hp)

@onready var collision_physique = $CollisionShape2D

@export_category("Paramètres Araignée")
@export var projectile_scene: PackedScene 

var _attaques_instanciees: Array[BossAttack] = []

var _attaque_forcee: BossAttack = null

func _ready() -> void:
	super._ready()
	_lancer_transition_boss()
	for script in stats.attack_scripts:
		_attaques_instanciees.append(script.new())

func _peut_attaquer() -> bool:
	return global_position.distance_to(player.global_position) <= 500.0

func _start_attack() -> void:
	super._start_attack()
	var distance = global_position.distance_to(player.global_position)
	var temps_actuel = Time.get_ticks_msec()
	
	print("\n--- TENTATIVE D'ATTAQUE ---")
	print("Distance joueur : ", distance)
	
	var attaque_choisie: BossAttack = null
	
	if _attaque_forcee != null:
		if _attaque_forcee.peut_attaquer(distance, temps_actuel):
			attaque_choisie = _attaque_forcee
			print("COMBO ! Enchaînement avec : ", attaque_choisie.id)
		else:
			print("Combo brisé : le joueur n'est plus à bonne distance.")
			_attaque_forcee = null
			
	if attaque_choisie == null:
		var attaques_possibles: Array[BossAttack] = []
		var somme_des_poids: float = 0.0
		
		for attaque in _attaques_instanciees:
			var dist_ok = distance >= attaque.portee_min and distance <= attaque.portee_max
			var cool_ok = temps_actuel >= attaque._prochain_lancement_possible
			print(" - Attaque [", attaque.id, "] -> Dist OK? ", dist_ok, " | Cooldown OK? ", cool_ok)
			
			if dist_ok and cool_ok:
				attaques_possibles.append(attaque)
				somme_des_poids += attaque.poids
				
		if attaques_possibles.is_empty():
			print("=> ANNULATION : Aucune attaque n'a passé les filtres.")
			_end_attack()
			return
			
		var tirage = randf_range(0.0, somme_des_poids)
		var poids_cumule: float = 0.0
		
		for attaque in attaques_possibles:
			poids_cumule += attaque.poids
			if tirage <= poids_cumule:
				attaque_choisie = attaque
				break
				
	if attaque_choisie != null:
		print("=> VALIDATION : L'attaque [", attaque_choisie.id, "] est lancée !")
		attaque_choisie._prochain_lancement_possible = temps_actuel + int(attaque_choisie.cooldown_attaque * 1000.0)
		await attaque_choisie.executer(self) 
		
	_attaque_forcee = null 
	if attaque_choisie != null and attaque_choisie.combo_suivant_id != "":
		for attaque in _attaques_instanciees:
			if attaque.id == attaque_choisie.combo_suivant_id:
				_attaque_forcee = attaque
				break
				
	_end_attack()
	
	if _attaque_forcee != null:
		_attack_timer = 0.1
		print("-> Combo détecté : Enchaînement immédiat !")
	else:
		_attack_timer = 1.8
		print("-> Attaque normale : Tempo de repos activé.")
		
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

func take_damage(amount: int) -> void:
	super.take_damage(amount)
	health_changed.emit(hp)
	if not is_instance_valid(self) or is_queued_for_deletion():
		_on_boss_mort()

func _on_boss_mort() -> void:
	# Sauvegarde persistante
	SaveManager.current_save.boss_araignee_battu = true
	SaveManager.save_game()
	# Signal en temps réel pour débloquer sans relancer la partie
	GameManager.boss_araignee_vaincu.emit()

func _sauvegarder_victoire() -> void:
	SaveManager.current_save.boss_araignee_battu = true
	SaveManager.save_game()
