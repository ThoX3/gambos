extends Control

signal selected(data: upgradeData)

const BACKGROUNDS = {
	upgradeData.rarityType.COMMON: preload("res://assets/sprites/cards/background/Card2.png"),
	upgradeData.rarityType.UNCOMMUN: preload("res://assets/sprites/cards/background/Card4.png"),
	upgradeData.rarityType.RARE: preload("res://assets/sprites/cards/background/Card6.png"),
	upgradeData.rarityType.LEGENDARY: preload("res://assets/sprites/cards/background/Card8.png"),
	upgradeData.rarityType.MYTHIC: preload("res://assets/sprites/cards/background/Card10.png")
}

const HOVER = {
	upgradeData.rarityType.COMMON: preload("res://assets/sprites/cards/background/Card3.png"),
	upgradeData.rarityType.UNCOMMUN: preload("res://assets/sprites/cards/background/Card5.png"),
	upgradeData.rarityType.RARE: preload("res://assets/sprites/cards/background/Card7.png"),
	upgradeData.rarityType.LEGENDARY: preload("res://assets/sprites/cards/background/Card9.png"),
	upgradeData.rarityType.MYTHIC: preload("res://assets/sprites/cards/background/Card11.png")
}

const STATS = {
	capacityEffectData.TargetCapacityEffect.PLAYER_HEALTH: "Santé max : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_SPEED: "Vitesse de déplacement : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_DAMAGE: "Dégât : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_SPEED: "Vitesse d'attaque : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_RANGE: "Portée d'attaque : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_COLLECT_RANGE: "Portée de collecte : "
}

var current_data: upgradeData

func setup(data: upgradeData) -> void:
	current_data = data
	%Title.text = data.name
	%Icon.texture = data.icon
	%Description.text = data.description
	%Stats.text = ""
	if data.typeEffects == data.effectsType.CAPACITY:
		for effet in data.capacities_effects:
			%Stats.text += STATS[effet.targetCapacity] 
			if effet.value > 0:
				%Stats.text += "+ " + str(effet.value) + "\n"
			else :
				%Stats.text += str(effet.value) + "\n"
	%Rarity.text = upgradeData.rarityType.keys()[data.rarity]
	var texture_normal = BACKGROUNDS[data.rarity]
	var texture_hover = HOVER[data.rarity]
	%TextureButton.texture_normal = texture_normal
	%TextureButton.texture_hover = texture_hover
	%TextureButton.texture_focused = texture_hover

func _on_texture_button_pressed() -> void:
	selected.emit(current_data)
