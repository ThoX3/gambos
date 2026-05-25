class_name EntreeBoss
extends Resource

## La scène du boss
@export var scene: PackedScene
## Les stats du boss
@export var data: EnemyData
## À quelle vague exacte ce boss apparaît
@export_range(1, 999) var vague_exacte: int = 5
## Durée de la vague boss (secondes)
@export_range(1.0, 300.0, 0.5) var duree: float = 60.0
## Nombre de boss à spawner
@export_range(1, 10) var nb_ennemis: int = 1
