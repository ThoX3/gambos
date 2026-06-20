extends Node
class_name upgradeManager

var all_upgrades: Array[upgradeData] = []
var path_to_upgrade = "res://ressources/upgrades/"
const BASE_RARITY_WEIGHTS = {
	upgradeData.rarityType.COMMON: 100.0,
	upgradeData.rarityType.UNCOMMUN: 40.0,
	upgradeData.rarityType.RARE: 15.0,
	upgradeData.rarityType.LEGENDARY: 3.0,
	upgradeData.rarityType.MYTHIC: 0.5
}

func _ready():
	load_upgrades()
	
func load_upgrades():
	var dir = DirAccess.open(path_to_upgrade)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
				var resources = load(path_to_upgrade + file_name.trim_suffix(".remap"))
				if resources is upgradeData:
					all_upgrades.append(resources)
			file_name = dir.get_next()
		dir.list_dir_end()
	print("Upgrades chargées : ", all_upgrades.size())
	
func get_random_upgrades(count: int) -> Array[upgradeData]:
	var selected_upgrades: Array[upgradeData] = []
	var luck_level = SaveManager.current_save.upgrade_luck_level
	var pool = all_upgrades.duplicate()
	var dynamic_weights = calculate_dynamic_weights(luck_level)
	for i in range(count):
		if pool.is_empty(): break
		var picked = pick_one_weighted(pool, dynamic_weights)
		if picked:
			selected_upgrades.append(picked)
			# On garde uniquement les cartes dont le nom est DIFFÉRENT de celle piochée
			pool = pool.filter(func(u): return u.name != picked.name)
			
	return selected_upgrades
	
func pick_one_weighted(list: Array[upgradeData], weights: Dictionary) -> upgradeData:
	if list.is_empty(): 
		return null
	var shuffled_list = list.duplicate()
	shuffled_list.shuffle()
	var total_weight: float = 0.0
	for upgrade in shuffled_list:
		total_weight += weights[upgrade.rarity]
	if total_weight <= 0.0:
		return null
	var random_value = randf() * total_weight
	var current_sum: float = 0.0
	for upgrade in shuffled_list:
		current_sum += weights[upgrade.rarity]
		if random_value < current_sum:
			for data in upgrade.capacities_effects:
				if data.targetCapacity == data.TargetCapacityEffect.PLAYER_HEALTH:
					var player = get_tree().get_first_node_in_group("Player")
					if player and player.Stats.current_health + data.value <= 0:
						return pick_one_weighted(list, weights)
			return upgrade
	return shuffled_list.pick_random()
	
func calculate_dynamic_weights(luck_level: int) -> Dictionary:
	var dyn_weights = {}
	var level_clamped = clamp(luck_level, 0, 20)
	var luck_factor: float = level_clamped / 20.0
	dyn_weights[upgradeData.rarityType.COMMON] = lerp(BASE_RARITY_WEIGHTS[upgradeData.rarityType.COMMON], 1.0, pow(luck_factor, 1.5))
	dyn_weights[upgradeData.rarityType.UNCOMMUN] = BASE_RARITY_WEIGHTS[upgradeData.rarityType.UNCOMMUN] * (1.0 + luck_factor * 1.5)
	dyn_weights[upgradeData.rarityType.RARE] = BASE_RARITY_WEIGHTS[upgradeData.rarityType.RARE] + (luck_factor * 65.0)
	dyn_weights[upgradeData.rarityType.LEGENDARY] = BASE_RARITY_WEIGHTS[upgradeData.rarityType.LEGENDARY] * pow(luck_factor, 2.0) * 15.0
	dyn_weights[upgradeData.rarityType.MYTHIC] = BASE_RARITY_WEIGHTS[upgradeData.rarityType.MYTHIC] * pow(luck_factor, 3.0) * 60.0
	if level_clamped == 0:
		dyn_weights[upgradeData.rarityType.LEGENDARY] = 0.0
		dyn_weights[upgradeData.rarityType.MYTHIC] = 0.0
	return dyn_weights

# --- Logique de coût de base ---
## Calcule le coût par défaut d'une amélioration si aucune fonction spécifique n'est définie.
func get_default_cost(level: int) -> int:
	var cost_multiplier = 2
	var base_cost = 1
	return base_cost + (level * cost_multiplier)

## Retourne le coût de l'amélioration de vie maximum.
func get_cost_health(level: int) -> int:
	return [1, 2, 4, 6, 9, 12, 15, 19, 23, 28, 35][level]

## Retourne le coût de l'amélioration de vitesse de déplacement.
func get_cost_speed(level: int) -> int:
	return [1, 2, 4, 6, 9, 12, 15, 19, 23, 28, 35][level]

## Retourne le coût de l'amélioration de dégâts.
func get_cost_damage(level: int) -> int:
	return [1, 2, 4, 6, 9, 12, 15, 19, 23, 28, 35][level]

## Retourne le coût de l'amélioration de vitesse d'attaque.
func get_cost_attack_speed(level: int) -> int:
	return [2, 3, 4, 6, 10, 14, 18, 23, 30, 38, 45][level]

## Retourne le coût de l'amélioration de gain d'expérience.
func get_cost_xp_gain(level: int) -> int:
	return 5 + level**2 - level

## Retourne le coût de l'amélioration de chance.
func get_cost_luck(level: int) -> int:
	return 25 + 4 * level**2

## Retourne le coût de l'amélioration de régénération de vie.
func get_cost_regen(level: int) -> int:
	return 3 + 5 * level

## Retourne le coût de l'amélioration permettant de modifier la vitesse du jeu en combat.
func get_cost_ingame_speed(level: int) -> int:
	return max(20, 9 ** (level + 1) - 5) 

## Retourne le coût de l'amélioration des épines défensives.
func get_cost_thorns(level: int) -> int:
	return 5 + level**2 - level

## Retourne le coût de l'amélioration permettant de reroll les cartes d'upgrades.
func get_cost_reroll(level: int) -> int:
	return [10, 25, 50, 100][level]
	
## Retourne le coût de l'amélioration permettant d'agrandir la zone de collection.
func get_cost_collection_radius(level: int) -> int:
	return get_default_cost(level) * (level +10)

## Retourne le coût de l'amélioration permettant de tirer plusieus bulles.
func get_cost_bubble_division(level: int) -> int:
	return [50, 250, 700, 1200][level]

## Retourne le coût de l'amélioration permettant les ricochets de projectiles.
func get_cost_projectile_bounce(level: int) -> int:
	return 25 + 2 * 6**level

## Retourne le coût de l'amélioration permettant au projectile de sable de transpercer.
func get_cost_projectile_sable_pierce(level: int) -> int:
	return 10 + 2 * 4**level

## Retourne le coût de l'amélioration permettant au projectile de sable de faire des dégâts de zone.
func get_cost_projectile_sable_zone_damage(level: int) -> int:
	return 10 + 2 * 4**level

## Retourne le coût de l'amélioration ajoutant des projectiles de sable.
func get_cost_projectile_sable_count(level: int) -> int:
	return 15 + 2 * 5**level
	
	
# --- Logique des effets spécifiques aux améliorations ---
## Calcule le bonus de vie maximum en fonction du niveau.
func get_effect_health(level: int) -> float:
	return 10.0 + (level * 5.0)

## Calcule le bonus de vitesse de déplacement en fonction du niveau.
func get_effect_speed(level: int, base_speed: float = 100.0) -> float:
	return base_speed + (level * 20.0)

## Calcule le bonus de dégâts bruts en fonction du niveau.
func get_effect_damage(level: int) -> float:
	return 1.0 + (level * 2.0)

## Calcule le bonus de cadence de tir en fonction du niveau.
func get_effect_attack_speed(level: int) -> float:
	return 0.5 + (level * 0.1)

## Calcule le multiplicateur de gain d'expérience en fonction du niveau.
func get_effect_xp_gain(level: int) -> float:
	return 1.0 + level * 0.1

## Calcule le bonus de chance en fonction du niveau.
func get_effect_luck(level: int) -> float:
	return level * 1.0

## Calcule le taux de régénération de vie par seconde en fonction du niveau.
func get_effect_regen(level: int) -> float:
	return level * 0.05

## Retourne les paramètres des épines (dégâts et intervalle de tick) en fonction du niveau.
func get_effect_thorns(level: int) -> Dictionary:
	return {
		"damage": level * 2.0,
		"interval": max(0.2, 1.0 - (level * 0.15))
	}

## Calcule la vitesse du jeu selon le niveau. Non utilisé pour le moment, c'est hud.gd qui gère cela.
func get_effect_ingame_speed(level: int) -> float:
	return level * 1.0

## Retourne le nombre de relances gratuites accordées.
func get_effect_reroll(level: int) -> int:
	return level * 1
	
## Calcule le multiplicateur de rayon de collection.
func get_effect_collection_radius(level: int) -> float:
	return 200.0 + (level * 15.0)

## Calcule le nombre de projectiles supplémentaires ajoutés.
func get_effect_projectile(level: int) -> float:
	return 1.0 + (level * 1.0)
	
# --- Effets des armes ---
## Calcule le nombre de bulles envoyées.
func get_effect_bubble_division(level: int) -> int:
	return 1 + level * 1

## Calcule le nombre potentiel de rebonds des projectiles.
func get_effect_projectile_bounce(level: int) -> int:
	return level * 1

## Calcule la réserve de PV que le projectile de sable peut transpercer.
func get_effect_projectile_sable_pierce(level: int) -> int:
	return level * 30

## Calcule le rayon d'explosion (dégâts de zone) du projectile de sable.
func get_effect_projectile_sable_zone_damage(level: int) -> float:
	return 24.0 + level * 16.0

## Calcule le nombre de paires de projectiles de sable supplémentaires.
func get_effect_projectile_sable_count(level: int) -> int:
	return level * 1
