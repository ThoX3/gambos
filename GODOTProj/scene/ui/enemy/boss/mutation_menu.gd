extends Control

@onready var bouton_option_1: Button = $HBoxContainer/Button1
@onready var bouton_option_2: Button = $HBoxContainer/Button2
@onready var bouton_option_3: Button = $HBoxContainer/Button3

var _stats_joueur: Resource = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	hide()
	
	bouton_option_1.pressed.connect(func(): _on_choix_mutation(1))
	bouton_option_2.pressed.connect(func(): _on_choix_mutation(2))
	bouton_option_3.pressed.connect(func(): _on_choix_mutation(3))
	
	GameManager.boss_araignee_vaincu.connect(_ouvrir_menu_mutation)

func _ouvrir_menu_mutation() -> void:
	print("🧬 Signal reçu ! Le Boss est vaincu, ouverture du menu.")
	
	get_tree().paused = true
	
	var joueur = get_tree().get_first_node_in_group("Player")
	if joueur and "Stats" in joueur:
		_stats_joueur = joueur.Stats
	
	bouton_option_1.text = "Mutation : Souffle de Sable\nTirez du sable avec le stick droit !"
	bouton_option_2.text = "Mutation : Propulsion Instinctive\nStick droit pour dasher et traverser le danger sans subir de dégâts !"
	bouton_option_3.text = "Mutation : Onde de Choc\nStick droit pour terrasser les ennemis autour de vous !"
	
	# 4. Affichage et focus pour la manette/clavier
	show()
	bouton_option_1.grab_focus()

func _on_choix_mutation(index: int) -> void:
	if _stats_joueur == null:
		_fermer_menu()
		return
		
	match index:
		1:
			var joueur = get_tree().get_first_node_in_group("Player")
			if joueur:
				joueur._attaque_sable_debloquee = true
				if joueur.projectile_sable_data == null:
					push_warning("Pense à assigner un ProjectileDataSable dans l'inspecteur du joueur !")	
			print("🧬 Mutation appliquée : Attaque de sable débloquée !")
		2:
			var joueur = get_tree().get_first_node_in_group("Player")
			if joueur:
				if not joueur.has_node("CapaciteDash"):
					var nouveau_dash = Node2D.new()
					nouveau_dash.set_script(preload("res://ressources/upgrades/dash.gd")) 
					nouveau_dash.name = "CapaciteDash"
					joueur.add_child(nouveau_dash)
					print("🧬 Mutation appliquée : Le nœud de Dash a été greffé sur le joueur.")
		3:
			var joueur = get_tree().get_first_node_in_group("Player")
			if joueur:
				if not joueur.has_node("CapaciteChoc"):
					var nouveau_choc = Node2D.new()
					nouveau_choc.set_script(preload("res://ressources/upgrades/choc.gd")) # Aligne le chemin de ton fichier
					nouveau_choc.name = "CapaciteChoc"
					
					joueur.add_child(nouveau_choc)
					print("🧬 Mutation appliquée : Le nœud d'Onde de Choc est greffé sur le joueur.")
			
	GameManager.health_changed.emit()
	
	_fermer_menu()

func _fermer_menu() -> void:
	hide()
	get_tree().paused = false 
