class_name Wave
extends Resource

## ─────────────────────────────────────────────
##  WaveData.gd — Resource de configuration d'une vague
##
##  Ne contient QUE ce qui est propre à cette vague.
##  Tout ce qui touche à la difficulté est dans BalancingConfig.
## ─────────────────────────────────────────────


# ── Type de zone d'apparition ──────────────────
enum ZoneType {
	BORDS_ECRAN,           ## Hors des bords visibles de la caméra
	CERCLE_AUTOUR_JOUEUR,  ## Anneau autour de la position du joueur
	POINT_FIXE,            ## Position fixe dans le monde
}


# ── Paramètres principaux ──────────────────────

## Indique si c'est une vague de boss (comportement fixe, budget ignoré)
@export var est_vague_de_boss: bool = false

## [BOSS uniquement] Durée de la vague boss
@export_range(1.0, 300.0, 0.5) var duree: float = 120.0

## [BOSS uniquement] Nombre fixe d'ennemis — ignoré pour les vagues normales
@export_range(1, 10) var nb_ennemis_boss: int = 1

## Ennemis disponibles pour cette vague (avec leur coût défini dans EnemySpawn)
@export var types_ennemis: Array[EnemySpawn] = []


# ── Zone d'apparition ──────────────────────────

@export_group("Zone de spawn")

## Type de zone utilisé pour cette vague
@export var zone: ZoneType = ZoneType.BORDS_ECRAN

## [BORDS_ECRAN] Marge hors-écran avant le spawn (px)
@export_range(20.0, 300.0) var marge_bords: float = 80.0

## [CERCLE_AUTOUR_JOUEUR] Rayon de l'anneau de spawn (px)
@export_range(100.0, 2000.0) var rayon_cercle: float = 600.0

## [POINT_FIXE] Coordonnées du point de spawn dans le monde
@export var position_fixe: Vector2 = Vector2.ZERO
