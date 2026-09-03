extends Control

signal transition_terminee

@onready var animation_player = $AnimationPlayer
@onready var label = $CanvasLayer/NomBoss
@onready var silhouette = $CanvasLayer/SilhouetteBoss

func setup(boss_name: String, texture: Texture2D) -> void:
	if boss_name:
		label.text = boss_name
	if texture:
		silhouette.texture = texture

func play_transition() -> void:
	$CanvasLayer/EffetLumiere.visible = true
	animation_player.play("intro")
	await animation_player.animation_finished

	$CanvasLayer/EffetLumiere.visible = false
	animation_player.play_backwards("intro")
	await animation_player.animation_finished
	
	transition_terminee.emit()
