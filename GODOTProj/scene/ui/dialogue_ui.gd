extends CanvasLayer

@onready var label_texte: Label = $BoiteDialogue/Texte

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func afficher_texte(contenu: String) -> void:
	label_texte.text = contenu

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().paused = false # On relance le jeu
		queue_free() # On détruit la boîte de dialogue
