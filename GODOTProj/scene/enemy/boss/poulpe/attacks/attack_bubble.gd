extends Node
class_name BossBubbleSystem

## Système AUTONOME de bulles d'encre du boss poulpe (indépendant du combo).
## - Maintient "nombre_bulles" bulles qui poursuivent le joueur.
## - Quand une bulle éclate (contact joueur OU expiration), une nouvelle est
##   relancée "delai_relance" secondes plus tard.

@export var ink_bubble_scene: PackedScene
@export var nombre_bulles: int = 2
@export var vitesse_bulle: float = 80.0
@export var degats_bulle: int = 15
@export var delai_relance: float = 5.0

var _boss: Node2D


func _ready() -> void:
	_boss = get_parent()
	await get_tree().process_frame
	for i in range(nombre_bulles):
		_spawn_bulle()


func _trouver_joueur() -> Node2D:
	if is_instance_valid(_boss) and "player" in _boss and is_instance_valid(_boss.player):
		return _boss.player
	var joueurs = get_tree().get_nodes_in_group("Player")
	if joueurs.size() > 0:
		return joueurs[0]
	return null


func _spawn_bulle() -> void:
	if not is_instance_valid(_boss):
		return
	if ink_bubble_scene == null:
		push_warning("[BulleSystem] ink_bubble_scene non assignée !")
		return

	var joueur = _trouver_joueur()
	if not is_instance_valid(joueur):
		# Joueur pas encore prêt → réessaie un peu plus tard
		await get_tree().create_timer(0.5).timeout
		_spawn_bulle()
		return

	var bulle = ink_bubble_scene.instantiate()
	bulle.global_position = _boss.global_position
	_boss.get_parent().add_child(bulle)
	bulle.setup(joueur, vitesse_bulle, degats_bulle)

	# Quand la bulle éclate (contact OU expiration) → relance après delai_relance
	bulle.hit_player.connect(_on_bulle_detruite)
	bulle.expired.connect(_on_bulle_detruite)


func _on_bulle_detruite(_bulle) -> void:
	await get_tree().create_timer(delai_relance).timeout
	if is_instance_valid(self) and is_instance_valid(_boss):
		_spawn_bulle()
