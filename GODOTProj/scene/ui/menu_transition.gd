# scene/ui/menu_transition.gd
extends Control

signal continuer_pressed
signal sauvegarder_pressed

@export var new_world_messages: Array[String] = [
	"Bravo d'avoir battu l'araignée des sables ! Tu peux maintenant utiliser son attaque de sable [img=24]res://assets/sprites/projectile/projectile_sable_icon.png[/img] avec [img=24]res://assets/sprites/tutorial/xbox_right.png[/img].",
	"Bravo d'avoir battu le poisson globe ! Tu peux maintenant envoyer ses pics [img=24]res://assets/sprites/projectile/pic_attack.png[/img] avec [img=24]res://assets/sprites/pearl_shop/buttons/xbox-y.png[/img] ou en appuyant [img=24]res://assets/sprites/tutorial/xbox_left.png[/img].",
	"Gambos, tu as battu les enemis les plus dangereux des océans. Tu en es maintenant le roi, bravo !"
]

@export var known_world_messages: Array[String] = [
	"Bravo d'avoir battu l'araignée des sables !",
	"Bravo d'avoir battu le poisson globe !",
	"Tu es déjà le roi des océans, petit champion ! Tu n'as pas besoin d'une deuxième couronne !"
]

@onready var btn_continuer = %ContinueButton
@onready var btn_sauvegarder = %SaveButton
@onready var label_dialog = %DialogueLabel

func afficher(nom_monde_suivant: String, index_suivant: int) -> void:
	var message = ""
	
	if index_suivant > SaveManager.current_save.mondes_completes_total:
		var msg_idx = min(index_suivant - 1, new_world_messages.size() - 1)
		message = new_world_messages[msg_idx]
	else:
		var msg_idx = min(index_suivant - 1, known_world_messages.size() - 1)
		message = known_world_messages[msg_idx]
		
	label_dialog.text = "[center]" + message + "\nVeux-tu sauvegarder et quitter ou continuer ?[/center]"
	btn_continuer.text = " Continuer et passer au " + nom_monde_suivant
	
	if index_suivant == 3 and not SaveManager.current_save.gambos_is_king:
		SaveManager.current_save.gambos_is_king = true
		SaveManager.save_game()
		GameManager.gambos_devenu_roi.emit()
	
	visible = true
	get_tree().paused = true
	btn_continuer.grab_focus()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_continuer.pressed.connect(_on_continuer)
	btn_sauvegarder.pressed.connect(_on_sauvegarder)
	visible = false

func _on_continuer() -> void:
	get_tree().paused = false
	visible = false
	continuer_pressed.emit()

func _on_sauvegarder() -> void:
	visible = false
	sauvegarder_pressed.emit()
