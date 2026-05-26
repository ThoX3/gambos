extends Area2D

var direction: Vector2 = Vector2.ZERO
var vitesse: float = 600.0 

var est_actif: bool = true 

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
		
	if body.is_in_group("Player") or body is TileMap:
		
		est_actif = false 
		
		set_deferred("monitoring", false)
		
		if body.is_in_group("Player"):
			print("Sable dans les yeux ! Dégâts au joueur !")
			body.take_damage(1)
			
		sprite.play("destroy")
		
		await sprite.animation_finished
		
		queue_free()
