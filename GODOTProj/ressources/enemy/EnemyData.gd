extends Resource
class_name EnemyData

@export_group("Identity")
@export var texture: SpriteFrames

@export_group("HP & Defense")
@export var max_hp: int
@export var armor: int

@export_group("Movement")
@export var movement_speed: float
@export var patrol_distance: float

@export_group("Attack & Combat")
@export var attack_damage: int
@export var attack_range: float
@export var attack_cooldown: float
@export var projectile_type: PackedScene

@export_group("Loot")
@export var xp_drop: int
@export var pearl_drop_probability: float
