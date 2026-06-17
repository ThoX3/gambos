class_name BalancingConfig
extends Resource

## ═══════════════════════════════════════════════════════════════════
##  BalancingConfig.gd — Fichier unique de configuration de l'équilibrage
##
##  C'est ici que tu règles TOUTE la difficulté du jeu.
##  Le WaveManager lit ce fichier et applique les équations automatiquement
##  à chaque vague selon son numéro.
## ═══════════════════════════════════════════════════════════════════


# ── Budget de difficulté ───────────────────────────────────────────────
##
##  budget(n) = budget_base * (1 + budget_facteur * n ^ budget_exposant)
##
##  Exemples avec les valeurs par défaut (base=10, facteur=0.5, exposant=1.4) :
##    Vague  1 →  15 pts
##    Vague  2 →  21 pts
##    Vague  3 →  27 pts
##    Vague  5 →  42 pts
##    Vague 10 →  89 pts
##    Vague 20 → 208 pts
##
@export_group("📈 Budget de difficulté")

## Points de base à la vague 1 (avant l'exposant)
@export_range(5.0, 200.0, 1.0) var budget_base: float = 10.0

## Vitesse de croissance — augmente le budget à chaque vague
@export_range(0.1, 5.0, 0.05) var budget_facteur: float = 0.5

## Forme de la courbe :
##   1.0 = croissance linéaire
##   1.5 = légèrement exponentielle (recommandé)
##   2.0 = exponentielle forte
@export_range(0.5, 3.0, 0.05) var budget_exposant: float = 1.4

## Variation aléatoire du budget final (ex: 0.15 = ±15%)
## Donne une légère imprévisibilité au nombre total d'ennemis
@export_range(0.0, 0.5, 0.01) var budget_variance: float = 0.15


# ── Ratio intensité (masse vs élite) ──────────────────────────────────
##
##  0.0 = vague "masse"  → beaucoup d'ennemis faibles
##  1.0 = vague "élite"  → peu d'ennemis forts
##
##  Le ratio est tiré aléatoirement entre [intensite_min, intensite_max],
##  puis poussé progressivement vers le haut au fil des vagues.
##
@export_group("⚖️ Ratio intensité (masse ↔ élite)")

## Borne basse du ratio — une vague ne sera jamais en-dessous de ça
@export_range(0.0, 1.0, 0.05) var intensite_min: float = 0.0

## Borne haute du ratio — une vague ne sera jamais au-dessus de ça
@export_range(0.0, 1.0, 0.05) var intensite_max: float = 1.0

## À partir de quelle vague le biais vers "élite" atteint son maximum
## (ex: 20 = pleinement biaisé à partir de la vague 20)
@export_range(5.0, 50.0, 1.0) var biais_vague_max: float = 20.0

## Intensité maximale du biais (ex: 0.6 = le ratio est poussé de 60% vers le haut)
@export_range(0.0, 1.0, 0.05) var biais_amplitude: float = 0.6


# ── Durée des vagues ──────────────────────────────────────────────────
##
##  La durée d'une vague normale est calculée automatiquement pour que
##  les ennemis soient répartis uniformément sur toute la durée.
##  Tu peux aussi forcer une durée fixe si tu préfères.
##
@export_group("⏱️ Durée des vagues")

## Durée de base d'une vague normale (secondes)
@export_range(10.0, 300.0, 5.0) var duree_base: float = 15.0

## Réduction de durée par achat effectué en boutique (secondes)
## Ex: 1.0 → 5 achats = -5s sur la durée de chaque vague
@export_range(0.0, 5.0, 0.01) var reduction_duree_par_achat: float = 0.1

## Durée minimale qu'une vague peut atteindre, peu importe le nombre d'achats
@export_range(1.0, 30.0, 1.0) var duree_minimale: float = 1
