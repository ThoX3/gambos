extends Control

const BACKGROUNDS = {
	upgradeData.rarityType.COMMON: preload("res://assets/sprites/cards/background/Card1.png"),
	upgradeData.rarityType.UNCOMMUN: preload("res://assets/sprites/cards/background/Card2.png"),
	upgradeData.rarityType.RARE: preload("res://assets/sprites/cards/background/Card3.png"),
	upgradeData.rarityType.LEGENDARY: preload("res://assets/sprites/cards/background/Card4.png"),
	upgradeData.rarityType.MYTHIC: preload("res://assets/sprites/cards/background/Card5.png")
}

func setup(data: upgradeData) -> void:
	%Title.text = data.name
	%Icon.texture = data.icon
	%Description.text = data.description
	%Rarity.text = upgradeData.rarityType.keys()[data.rarity]
	var texture_to_use = BACKGROUNDS[data.rarity]
	%TextureButton.texture_normal = texture_to_use
