class_name EnemySpawn
extends Resource

@export var scene: PackedScene
@export var data: EnemyData

## Coût en budget de difficulté de cet ennemi.
## Hermit = 1 (faible), Crab = 2 (moyen), Boss = non utilisé (vague fixe)
@export_range(1, 20) var cout: int = 1
