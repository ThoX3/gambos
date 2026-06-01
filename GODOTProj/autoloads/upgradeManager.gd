extends Node
class_name upgradeManager

var all_upgrades: Array[upgradeData] = []
var path_to_upgrade = "res://ressources/upgrades/"
const RARITY_WEIGHTS = {
	upgradeData.rarityType.COMMON: 100,
	upgradeData.rarityType.UNCOMMUN: 50,
	upgradeData.rarityType.RARE: 20,
	upgradeData.rarityType.LEGENDARY: 5,
	upgradeData.rarityType.MYTHIC: 1
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
	var pool = all_upgrades.duplicate()
	for i in range (count):
		if pool.is_empty(): break
		var picked = pick_one_weighted(pool)
		match i:
			1:
				while picked.name == str(selected_upgrades[0].name):
					picked = pick_one_weighted(pool)
			2:
				while picked.name == str(selected_upgrades[0].name) or picked.name == str(selected_upgrades[1]):
					picked = pick_one_weighted(pool)
		if picked:
			selected_upgrades.append(picked)
			pool.erase(picked)
	return selected_upgrades
	
func pick_one_weighted(list: Array[upgradeData]) -> upgradeData:
	var total_weight = 0
	for upgrade in list:
		total_weight += RARITY_WEIGHTS[upgrade.rarity]
	var random_value = randi() % total_weight
	var current_sum = 0
	for upgrade in list:
		current_sum += RARITY_WEIGHTS[upgrade.rarity]
		if random_value < current_sum:
			return upgrade
	return null

# --- Logique de coût de base ---
## Calcule le coût par défaut d'une amélioration si aucune fonction spécifique n'est définie.
func get_default_cost(level: int) -> int:
	var cost_multiplier = 2
	var base_cost = 1
	return base_cost + (level * cost_multiplier)

## Retourne le coût de l'amélioration de vie maximum.
func get_cost_health(level: int) -> int:
	return get_default_cost(level)

## Retourne le coût de l'amélioration de vitesse de déplacement.
func get_cost_speed(level: int) -> int:
	return get_default_cost(level)

## Retourne le coût de l'amélioration de dégâts.
func get_cost_damage(level: int) -> int:
	return get_default_cost(level)

## Retourne le coût de l'amélioration de vitesse d'attaque.
func get_cost_attack_speed(level: int) -> int:
	return get_default_cost(level)

## Retourne le coût de l'amélioration de gain d'expérience.
func get_cost_xp_gain(level: int) -> int:
	return get_default_cost(level)

## Retourne le coût de l'amélioration de chance.
func get_cost_luck(level: int) -> int:
	return get_default_cost(level)

## Retourne le coût de l'amélioration de régénération de vie.
func get_cost_regen(level: int) -> int:
	return get_default_cost(level)

## Retourne le coût de l'amélioration permettant de passer des étapes de la carte.
func get_cost_skip_map(level: int) -> int:
	return get_default_cost(level)

## Retourne le coût de l'amélioration des épines défensives.
func get_cost_thorns(level: int) -> int:
	return get_default_cost(level)
	
## Retourne le coût de l'amélioration permettant de reroll les cartes d'upgrades.
func get_cost_reroll(level: int) -> int:
	return get_default_cost(level)


# --- Logique des effets spécifiques aux améliorations ---
## Calcule le bonus de vie maximum en fonction du niveau.
func get_effect_health(level: int) -> float:
	return level * 5.0

## Calcule le bonus de vitesse de déplacement en fonction du niveau.
func get_effect_speed(level: int) -> float:
	return level * 20.0

## Calcule le bonus de dégâts bruts en fonction du niveau.
func get_effect_damage(level: int) -> float:
	return level * 1.0

## Calcule le bonus de cadence de tir en fonction du niveau.
func get_effect_attack_speed(level: int) -> float:
	return level * 0.1

## Calcule le multiplicateur de gain d'expérience en fonction du niveau.
func get_effect_xp_gain(level: int) -> float:
	return 1.0 + level * 0.1

## Calcule le bonus de chance en fonction du niveau.
func get_effect_luck(level: int) -> float:
	return level * 1.0

## Calcule le taux de régénération de vie par seconde en fonction du niveau.
func get_effect_regen(level: int) -> float:
	return level * 0.1

## Retourne les paramètres des épines (dégâts et intervalle de tick) en fonction du niveau.
func get_effect_thorns(level: int) -> Dictionary:
	return {
		"damage": level * 2.0,
		"interval": max(0.2, 1.0 - (level * 0.15))
	}

## Calcule le nombre de niveaux de carte passés initialement.
func get_effect_skip_map(level: int) -> float:
	return level * 1.0

## Calcule le nombre de projectiles supplémentaires ajoutés.
func get_effect_projectile(level: int) -> float:
	return level * 1.0

## Calcule le nombre de reroll ajoutés.
func get_effect_reroll(level: int) -> int:
	return level
	
