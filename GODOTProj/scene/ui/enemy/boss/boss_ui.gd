extends Control

@onready var label_nom: Label = $VBoxContainer/NomBoss
@onready var health_bar: TextureProgressBar = $VBoxContainer/TextureProgressBar

var _tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 1.0, 1.0)

# 1. Cette fonction sera appelée au spawn du boss pour calibrer la barre
func initialiser_boss(nom: String, pv_max: float) -> void:
	if label_nom: label_nom.text = nom
	health_bar.max_value = pv_max
	health_bar.value = pv_max

# 2. Cette fonction sera appelée à chaque fois que le boss prend des dégâts
func mettre_a_jour_pv(pv_actuels: float) -> void:
	# Animation fluide du changement de PV
	var tween = create_tween()
	tween.tween_property(health_bar, "value", pv_actuels, 0.2)
