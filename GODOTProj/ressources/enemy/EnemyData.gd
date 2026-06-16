extends Resource
class_name EnemyData

@export_group("Identity")
@export var texture: SpriteFrames
@export var name: String

@export_group("HP & Defense")
@export var max_hp: int
@export var armor: int

@export_group("Movement")
@export var movement_speed: float
@export var patrol_distance: float
@export var weight: float = 1.0

@export_group("Attack & Combat")
@export var attack_damage: int
@export var attack_range: float
@export var attack_cooldown: float
@export var projectile_type: PackedScene

@export_group("Loot")
@export var xp_drop: int
@export var pearl_drop_probability: float
@export var pearl_drop_range: Vector2i = Vector2i(1, 1)

@export_group("Spawn")
## Coût en budget de difficulté
@export_range(1, 20) var cout: int = 1
## Poids de tirage aléatoire (plus élevé = apparaît plus souvent)
@export_range(1, 100) var poids: int = 10

@export_group("Si Spawner")
@export var ennemis_a_spawner: Array[EntreeEnnemi] = []
@export var nb_spawn_max: int = 4
@export var intervalle_spawn: float = 3.0
@export var spawn_a_la_mort: bool = false
@export var afficher_pulsation: bool = true

@export_group("Si shooterTir")
@export var patterns: Array[ShootingPattern] = []
