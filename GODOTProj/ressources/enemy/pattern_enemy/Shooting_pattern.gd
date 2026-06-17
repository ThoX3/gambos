class_name ShootingPattern
extends Resource
enum TypePattern {
	VISE_JOUEUR,     ## 1 projectile droit vers le joueur
	RAFALE,          ## N projectiles vers le joueur en éventail
	CERCLE,          ## N projectiles dans toutes les directions
	CERCLE_TOURNE,   ## Cercle qui tourne d'un offset à chaque tir
}

# ── Type et cadence ─────────────────────────────────────────
@export var type: TypePattern = TypePattern.VISE_JOUEUR

## Secondes entre chaque salve
@export_range(0.1, 10.0, 0.1) var cadence: float = 2.0

# ── Projectiles ─────────────────────────────────────────────
@export_group("Projectile")

@export var scene_projectile: PackedScene
@export_range(1, 100) var degats: int = 5
@export_range(50.0, 800.0, 10.0) var vitesse: float = 200.0
@export_range(0.5, 10.0, 0.1) var duree_vie: float = 3.0

# ── Paramètres du pattern ───────────────────────────────────
@export_group("Pattern")

@export_range(1, 36) var nb_projectiles: int = 8
@export_range(10.0, 360.0, 5.0) var angle_eventail: float = 90.0
@export_range(0.0, 90.0, 1.0) var offset_rotation: float = 15.0
