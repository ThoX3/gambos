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
			if file_name.ends_with(".tres"):
				var resources = load(path_to_upgrade + file_name)
				if resources is upgradeData:
					all_upgrades.append(resources)
			file_name = dir.get_next()
	print("Upgrades chargées : ", all_upgrades.size())
	
func get_random_upgrades(count: int) -> Array[upgradeData]:
	var selected_upgrades: Array[upgradeData] = []
	var pool = all_upgrades.duplicate()
	for i in range (count):
		if pool.is_empty(): break
		var picked = pick_one_weighted(pool)
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
