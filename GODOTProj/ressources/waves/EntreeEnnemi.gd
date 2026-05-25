class_name EntreeEnnemi
extends Resource

## La scène de l'ennemi à instancier
@export var scene: PackedScene
## Les stats de l'ennemi (EnemyData, contient cout et poids)
@export var data: EnemyData
## À partir de quelle vague cet ennemi peut apparaître
@export_range(1, 999) var vague_apparition: int = 1
