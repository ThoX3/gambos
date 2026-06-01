extends EnemyData
class_name BossData

@export_group("Attack Pattern")
@export var attack_scripts: Array[Script] = []

@export_group("UI")
@export var scene_transition: PackedScene
@export var boss_ui_scene: PackedScene
