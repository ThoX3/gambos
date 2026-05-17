extends Resource
class_name PlayerStat

# leveling and experiencePoint
@export var level : int = 1
@export var requiredXp : int = 10
@export var currentXp : int = 0

# Character Stat
@export var collectRadius : int = 200
@export var max_health : float = 10.0
@export var current_health : float = max_health
