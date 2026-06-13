# scene/ui/menu_transition.gd
extends Control

signal continuer_pressed
signal sauvegarder_pressed

@onready var btn_continuer = $VBox/BtnContinuer
@onready var btn_sauvegarder = $VBox/BtnSauvegarder
@onready var label_monde = $VBox/LabelMonde

func afficher(nom_monde_suivant: String) -> void:
	label_monde.text = "Prochain monde : " + nom_monde_suivant
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
