extends Resource
class_name ProjectileData

@export_group("Combat")
@export var damage: int = 1
@export var speed: float = 400.0
@export var range: float = 500.0      # portée en pixels
@export var fire_rate: float = 0.5    # tirs par seconde
@export var projectile_count: int = 1
