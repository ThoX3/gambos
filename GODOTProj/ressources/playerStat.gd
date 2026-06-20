extends Resource
class_name PlayerStat

# Leveling and experience points
@export var level : int = 1
@export var requiredXp : int = 10
@export var currentXp : int = 0

# Collected pearls
@export var collected_pearls: int = 0

# Character Stat
@export var collectRadius : int = 200
@export var max_health : int = 10
@export var current_health : int = max_health

# Run specifics (moved from player.gd)
@export var speed: int = 150
@export var xp_multiplier: float = 1.0
@export var regen_rate: float = 0.0
@export var thorns_damage: int = 0
@export var thorns_interval: float = 0.0

@export var proj_damage: int = 2
@export var proj_fire_rate: float = 1.0
@export var proj_range: int = 400
@export var proj_count: int = 1
@export var proj_bounce: int = 0
