# res://ressources/projectile/ProjectileDataSable.gd
extends Resource
class_name ProjectileDataSable

@export_group("Combat")
@export var damage: int = 2
@export var speed: float = 600.0
@export var range: float = 700.0
#@export var cooldown: float = 0.8
@export var cadence_ratio: float = 2
