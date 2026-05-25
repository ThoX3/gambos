class_name Wave
extends Resource

## ─────────────────────────────────────────────
##  WaveData.gd — Resource de configuration d'une vague
##
##  Contient uniquement les paramètres de zone de spawn.
##  Les ennemis et boss sont gérés par SpawnConfig.
## ─────────────────────────────────────────────

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
