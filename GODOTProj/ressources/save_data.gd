extends Resource
class_name SaveData

# Pearls 
@export var pearls: int = 0

# Pearl basic upgrades
@export var upgrade_health_level: int = 0
@export var upgrade_speed_level: int = 0
@export var upgrade_damage_level: int = 0
@export var upgrade_attack_speed_level: int = 0
@export var upgrade_xp_gain_level: int = 0
@export var upgrade_luck_level: int = 0
@export var upgrade_regen_level: int = 0
@export var upgrade_skip_map_level: int = 0
@export var upgrade_thorns_level: int = 0
@export var upgrade_reroll_level: int = 0
@export var upgrade_collection_radius_level: int = 0

# Pearl weapon upgrades
@export var upgrade_bubble_division_level: int = 0
@export var upgrade_projectile_bounce_level: int = 0

# In-game progress
@export var boss_araignee_battu: bool = false
@export var max_wave_reached: int = 0

# Progression de monde (run en cours)
@export var run_en_cours: bool = false
@export var monde_actuel_index: int = 0   # index dans la liste des mondes
@export var vague_actuelle: int = 0
@export var mondes_completes: int = 0
