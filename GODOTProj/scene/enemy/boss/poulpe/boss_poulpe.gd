extends Boss_Base

@onready var collision_physique: CollisionShape2D = $CollisionShape2D

@export_category("Paramètres Poulpe")
@export var ink_bubble_scene: PackedScene

@export var degats_tentacule: int = 25
@export var degats_bulle_encre: int = 15
@export var degats_tremblement: int = 10

@export var vitesse_bulle_encre: float = 150.0
@export var nombre_bulles: int = 2
@export var delai_relance_apres_expiration: float = 5.0

@export var portee_tentacule: float = 90.0
@export var rayon_tremblement: float = 250.0

@export_category("Camouflage")
@export var camouflage_alpha: float = 0.25
@export var camouflage_duree: float = 3.0
@export var camouflage_reduction_degats: float = 0.5
@export var camouflage_vitesse_ruee: float = 350.0   
@export var camouflage_degats_contact: int = 20      
@export var camouflage_distance_contact: float = 50.0



var _est_mort: bool = false
var _echelle_normale: Vector2 = Vector2.ONE

# --- Gestion des bulles d'encre en vol (lu/écrit par AttackBullesEncre) ---
var _bulles_actives: Array[BossInkBubble] = []
var _bulle_en_attente_relance: bool = false

# --- Camouflage (lu/écrit par AttackCamouflage) ---
var _en_camouflage: bool = false

var _etat_special_actif: bool = false
var _physics_process_special: Callable = Callable()

func _ready() -> void:
	super._ready()
	_echelle_normale = scale
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if _est_mort or not is_inside_tree():
		return

	if _etat_special_actif:
		# Une attaque a pris la main sur le mouvement (charge, camouflage, etc.)
		if _physics_process_special.is_valid():
			var continue_special: bool = _physics_process_special.call(delta)
			if not continue_special:
				_etat_special_actif = false
				_physics_process_special = Callable()
		return

	super._physics_process(delta)

	# Le boss regarde toujours le joueur — APRÈS super
	if is_instance_valid(player):
		var dir_x = player.global_position.x - global_position.x
		if abs(dir_x) > 1.0:
			sprite.flip_h = dir_x > 0


func _peut_attaquer() -> bool:
	return not _en_camouflage





# ── Mort ──────────────────────────────────────────────────────────────

func take_damage(amount: int) -> int:
	if _est_mort or is_queued_for_deletion():
		return 0

	var degats_reels := amount
	if _en_camouflage:
		degats_reels = int(round(amount * (1.0 - camouflage_reduction_degats)))

	var loss_hp: int = super.take_damage(degats_reels)
	if not spawn_comme_ennemi_normal:
		GameManager.boss_health_changed.emit(stats.max_hp, hp)
	_effet_hit()
	return loss_hp


func _effet_hit() -> void:
	if not is_instance_valid(sprite):
		return
	var tween := create_tween()
	var base = _echelle_normale
	tween.tween_property(self, "scale", base * 1.12, 0.05)
	tween.tween_property(self, "scale", base, 0.08)


func _on_boss_mort() -> void:
	if _est_mort:
		return
	_est_mort = true
	SaveManager.save_game()
	GameManager.boss_poulpe_vaincu.emit()
	if is_inside_tree():
		get_tree().paused = true
	get_tree().call_group("MutationUI", "_ouvrir_menu")
	queue_free()


func _sauvegarder_victoire() -> void:
	SaveManager.save_game()
