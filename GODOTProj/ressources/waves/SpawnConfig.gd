class_name SpawnConfig
extends Resource

## ─────────────────────────────────────────────
##  SpawnConfig.gd — Configuration globale des spawns
##
##  Un seul fichier pour définir :
##   - quels ennemis apparaissent à partir de quelle vague
##   - quels boss apparaissent à quelle vague exacte
## ─────────────────────────────────────────────


# ── Entrée ennemi normal ───────────────────────

class EntreeEnnemi extends Resource:
	## La scène de l'ennemi à instancier
	@export var scene: PackedScene
	## Les stats de l'ennemi (EnemyData, contient cout et poids)
	@export var data: EnemyData
	## À partir de quelle vague cet ennemi peut apparaître
	@export_range(1, 999) var vague_apparition: int = 1


# ── Entrée boss ────────────────────────────────

class EntreeBoss extends Resource:
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


# ── Listes ────────────────────────────────────

@export var ennemis: Array[EntreeEnnemi] = []
@export var boss: Array[EntreeBoss] = []


# ── Accesseurs ────────────────────────────────

## Retourne les ennemis disponibles pour un numéro de vague donné
func get_ennemis_disponibles(numero_vague: int) -> Array[EntreeEnnemi]:
	return ennemis.filter(func(e): return e.vague_apparition <= numero_vague)

## Retourne le boss prévu pour ce numéro de vague, ou null
func get_boss_pour_vague(numero_vague: int) -> EntreeBoss:
	for b in boss:
		if b.vague_exacte == numero_vague:
			return b
	return null
