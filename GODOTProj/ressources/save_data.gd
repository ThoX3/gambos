extends Resource
class_name SaveData

# Settings
@export var setting_master_volume: float = 1.0
@export var setting_haptic_strength: float = 1.0
@export var setting_use_pixel_font: bool = true

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
@export var upgrade_ingame_speed_level: int = 0
@export var upgrade_thorns_level: int = 0
@export var upgrade_reroll_level: int = 0
@export var upgrade_collection_radius_level: int = 0

# Pearl weapon upgrades
@export var upgrade_bubble_division_level: int = 0
@export var upgrade_projectile_bounce_level: int = 0
@export var upgrade_projectile_sable_pierce_level: int = 0
@export var upgrade_projectile_sable_zone_damage_level: int = 0
@export var upgrade_projectile_sable_count_level: int = 0

# In-game progress
@export var max_wave_reached: int = 0
@export var mondes_completes_total: int = 0 

# Progression de monde (run en cours)
@export var run_en_cours: bool = false
@export var run_player_stats: PlayerStat
@export var monde_actuel_index: int = 0   # index dans la liste des mondes
@export var vague_actuelle: int = 0
@export var mondes_completes: int = 0
