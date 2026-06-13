extends Area2D

@export var vitesse_aspiration: float = 500.0

var _joueur: CharacterBody2D = null
var _est_aspire: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Sécurité double : on écoute les corps ET les autres zones (ex: rayon de collecte du joueur)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if _est_aspire and is_instance_valid(_joueur):
		global_position = global_position.move_toward(_joueur.global_position, vitesse_aspiration * delta)
		
		# Quand l'orbe atteint le centre du joueur, on déclenche
		if global_position.distance_to(_joueur.global_position) < 15.0:
			_declencher_menu_mutation()

func _on_body_entered(body: Node2D) -> void:
	# Cas 1 : Le corps physique du joueur touche l'orbe
	if body.is_in_group("Player") or "Stats" in body:
		_verrouiller_cible(body)

func _on_area_entered(area: Area2D) -> void:
	# Cas 2 : La zone de collecte (PlayerCollectRadius) ou la Hurtbox du joueur touche l'orbe
	var parent = area.get_parent()
	if is_instance_valid(parent) and (parent.is_in_group("Player") or "Stats" in parent):
		_verrouiller_cible(parent)

func _verrouiller_cible(joueur_cible: CharacterBody2D) -> void:
	if not _est_aspire:
		_joueur = joueur_cible
		_est_aspire = true

func _declencher_menu_mutation() -> void:
	set_process(false) 
	monitoring = false
	monitorable = false
	
	print("🎯 Collecte validée. Tentative d'ouverture forcée de l'UI...")
	
	# Émet le signal au cas où
	if GameManager.has_signal("show_mutation_menu"):
		GameManager.show_mutation_menu.emit()
	
	# PLAN DE SECOURS INFAILLIBLE : On cherche le menu dans l'arbre et on l'ouvre en direct
	get_tree().call_group("MutationUI", "_ouvrir_menu")
		
	Input.start_joy_vibration(0, 0.6, 0.6, 0.2)
	queue_free()
