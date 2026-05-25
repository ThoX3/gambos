class_name SpawnConfig
extends Resource

@export var ennemis: Array[EntreeEnnemi] = []
@export var boss: Array[EntreeBoss] = []

func get_ennemis_disponibles(numero_vague: int) -> Array[EntreeEnnemi]:
	return ennemis.filter(func(e): return e.vague_apparition <= numero_vague)

func get_boss_pour_vague(numero_vague: int) -> EntreeBoss:
	for b in boss:
		if b.vague_exacte == numero_vague:
			return b
	return null
