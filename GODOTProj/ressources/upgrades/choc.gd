extends Node2D
class_name CapaciteChoc

@export_category("Configuration du Choc de Zone")
@export var rayon_choc: float = 1000.0
@export var degats_choc: int = 35
@export var cooldown_choc: float = 1.5

var _joueur: CharacterBody2D = null
var _cooldown_timer: float = 0.0

func _ready() -> void:
	_joueur = get_parent() as CharacterBody2D
	if not _joueur:
		queue_free()

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		return 
		
	var stick = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick.length() > 0.5:
		_declencher_onde_de_choc()

func _declencher_onde_de_choc() -> void:
	_cooldown_timer = cooldown_choc
	
	print("💥 ONDE DE CHOC DEPLOYÉE !")
	
	# Vibration manette lourde et courte
	Input.start_joy_vibration(0, 0.8, 0.8, 0.2)
	
	var ennemis = get_tree().get_nodes_in_group("Enemy")
	
	for ennemi in ennemis:
		if not is_instance_valid(ennemi):
			continue
			
		var distance = _joueur.global_position.distance_to(ennemi.global_position)
		
		if distance <= rayon_choc:
			if ennemi.has_method("take_damage"):
				ennemi.take_damage(degats_choc)
				_appliquer_flash_feedback(ennemi)

func _appliquer_flash_feedback(ennemi: Node2D) -> void:
	var sprite = ennemi.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		var tween = create_tween()
		sprite.modulate = Color(2.0, 1.0, 2.0) 
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
