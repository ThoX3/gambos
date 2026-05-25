class_name SpawnConfig
extends Resource

# ── Zone de spawn ──────────────────────────────

enum ZoneType {
	BORDS_ECRAN,
	CERCLE_AUTOUR_JOUEUR,
	POINT_FIXE,
}

@export_group("Zone de spawn")
@export var zone: ZoneType = ZoneType.BORDS_ECRAN
@export_range(20.0, 300.0) var marge_bords: float = 80.0
@export_range(100.0, 2000.0) var rayon_cercle: float = 600.0
@export var position_fixe: Vector2 = Vector2.ZERO

# ── Ennemis & Boss ─────────────────────────────

@export_group("Ennemis")
@export var ennemis: Array[Resource] = []
@export var boss: Array[Resource] = []

# ── Accesseurs ────────────────────────────────

func get_ennemis_disponibles(numero_vague: int) -> Array:
	return ennemis.filter(func(e): return e is EntreeEnnemi and e.vague_apparition <= numero_vague)

func get_boss_pour_vague(numero_vague: int) -> EntreeBoss:
	for b in boss:
		if b is EntreeBoss and b.vague_exacte == numero_vague:
			return b
	return null
