extends Boss_Base

@onready var collision_physique = $CollisionShape2D

@export_category("Paramètres Poisson-Globe")
@export var pic_scene: PackedScene

@export var degats_charge: int = 25
@export var degats_explosion_pics: int = 30
@export var degats_nuage_poison: int = 15

@export var vitesse_charge: float = 800.0
@export var duree_charge: float = 3.0
@export var nombre_rebonds_max: int = 6

@export var rayon_nuage_poison: float = 300.0
@export var duree_nuage_poison: float = 4.0
@export var tick_poison: float = 0.5

@export_category("Effet Poison sur le joueur")
@export var poison_duree: float = 20.0
@export var poison_degats_tick: int = 1
@export var poison_intervalle: float = 1.0
@export var poison_ralenti: float = 0.20

@export var nombre_pics: int = 16
@export var vitesse_pics: float = 600.0

@export_category("Timings (Secondes)")
@export var temps_pre_explosion_pics: float = 0.4
@export var temps_post_explosion_pics: float = 0.3
@export var temps_pre_gonflement: float = 0.4
@export var temps_pre_charge: float = 0.5
@export var temps_fin_charge: float = 0.3
@export var temps_post_charge: float = 0.3



var _est_mort: bool = false
var _en_fumee: bool = false
var _echelle_normale: Vector2 = Vector2.ONE

# --- Délégation du mouvement à l'attaque en cours (charge, phase fumée, etc.) ---
# Une attaque active ce mode en mettant _etat_special_actif = true et en fournissant
# une Callable(delta) -> bool. Tant que la Callable renvoie true, le boss continue de
# lui déléguer _physics_process. Quand elle renvoie false (ou que l'attaque la vide
# explicitement), le boss reprend son comportement normal (Enemy_Base).
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
		# Une attaque a pris la main sur le mouvement.
		# - callable valide → on lui délègue le mouvement frame par frame
		# - callable vide   → le boss reste simplement figé (ex: phase de préparation),
		#   et l'attaque libèrera _etat_special_actif elle-même quand elle aura fini.
		if _physics_process_special.is_valid():
			var continue_special: bool = _physics_process_special.call(delta)
			if not continue_special:
				_etat_special_actif = false
				_physics_process_special = Callable()
		return

	super._physics_process(delta)

	# Le boss regarde toujours le joueur — APRÈS super pour écraser le flip d'Enemy_Base
	if is_instance_valid(player):
		var dir_x = player.global_position.x - global_position.x
		if abs(dir_x) > 1.0:
			sprite.flip_h = dir_x > 0


func _peut_attaquer() -> bool:
	return not _etat_special_actif






# ── Mort ──────────────────────────────────────────────────────────────

func take_damage(amount: int) -> int:
	if _est_mort or is_queued_for_deletion():
		return 0
	# Invulnérable pendant la phase de fumée
	if _en_fumee:
		return 0
	var loss_hp: int = super.take_damage(amount)
	if not spawn_comme_ennemi_normal:
		GameManager.boss_health_changed.emit(stats.max_hp, hp)
	# Effet visuel de hit (flash blanc rapide en plus du rouge d'Enemy_Base)
	_effet_hit()
	return loss_hp


func _effet_hit() -> void:
	if not is_instance_valid(sprite):
		return
	# Petit "punch" d'échelle (sauf pendant la fumée où le scale est géré)
	if not _en_fumee:
		var tween := create_tween()
		var base = _echelle_normale
		tween.tween_property(self, "scale", base * 1.12, 0.05)
		tween.tween_property(self, "scale", base, 0.08)


func _on_boss_mort() -> void:
	if _est_mort:
		return
	_est_mort = true
	SaveManager.save_game()
	GameManager.boss_poisson_vaincu.emit()
	if is_inside_tree():
		get_tree().paused = true
	get_tree().call_group("MutationUI", "_ouvrir_menu")
	queue_free()


func _sauvegarder_victoire() -> void:
	SaveManager.save_game()
