extends Area2D

var direction: Vector2 = Vector2.ZERO
@export var vitesse: float = 600.0
@export var degats: int = 10
var est_actif: bool = true
var appartient_au_joueur: bool = false  # ← NOUVEAU

@onready var sprite = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("create")
	await sprite.animation_finished
	if est_actif:
		sprite.play("move")

func _process(delta: float) -> void:
	if est_actif:
		global_position += direction * vitesse * delta

func _on_body_entered(body: Node2D) -> void:
	if not est_actif:
		return
	
	Input.start_joy_vibration(0, 0.2, 0.5, 0.2)
	if appartient_au_joueur:
		# --- Logique joueur : touche les ennemis ---
		if body is Enemy_Base:
			est_actif = false
			set_deferred("monitoring", false)
			body.take_damage(degats)
			sprite.play("destroy")
			await sprite.animation_finished
			queue_free()
		elif body is TileMap:
			est_actif = false
			set_deferred("monitoring", false)
			sprite.play("destroy")
			await sprite.animation_finished
			queue_free()
	else:
		# --- Logique boss : touche le joueur (comportement original intact) ---
		if body.is_in_group("Player") or body is TileMap:
			est_actif = false
			set_deferred("monitoring", false)
			if body.is_in_group("Player"):
				print("Sable dans les yeux ! Dégâts au joueur !")
				body.take_damage(degats)
				print(degats)
			sprite.play("destroy")
			await sprite.animation_finished
			queue_free()
