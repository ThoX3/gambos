extends Node

signal xp_changed()
signal health_changed()
signal pearls_changed()
signal initialize()
signal start_game()
signal level_up()
signal GameOver()
signal Retry()
signal boss_araignee_vaincu()

var skip_menu: bool = false
var gotoshop: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
