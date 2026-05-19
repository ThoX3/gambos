class_name Wave
extends Resource
 
## ─────────────────────────────────────────────
##  Wave.gd — Resource de configuration d'une vague
## ─────────────────────────────────────────────
 
 
# ── Type de zone d'apparition ──────────────────
enum ZoneType {
	BORDS_ECRAN,           ## Hors des bords visibles de la caméra
	CERCLE_AUTOUR_JOUEUR,  ## Anneau autour de la position du joueur
	POINT_FIXE,            ## Position fixe dans le monde
}
 
 
# ── Paramètres principaux ──────────────────────
 
## Durée totale de la vague (secondes)
@export_range(1.0, 300.0, 0.5) var duree: float = 30.0
 
## Nombre total d'ennemis à faire apparaître sur cette durée
@export_range(1, 500) var nb_ennemis: int = 20
 
## Scènes d'ennemis à instancier.
@export var types_ennemis: Array[EnemySpawn] = []
 
# ── Zone d'apparition ──────────────────────────
 
## Type de zone utilisé pour ce vague
@export var zone: ZoneType = ZoneType.BORDS_ECRAN
 
## [BORDS_ECRAN] Marge hors-écran avant le spawn (px)
@export_range(20.0, 300.0) var marge_bords: float = 80.0
 
## [CERCLE_AUTOUR_JOUEUR] Rayon de l'anneau de spawn (px)
@export_range(100.0, 2000.0) var rayon_cercle: float = 600.0
 
## [POINT_FIXE] Coordonnées du point de spawn dans le monde
@export var position_fixe: Vector2 = Vector2.ZERO
