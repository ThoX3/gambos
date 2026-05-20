@tool
extends Resource
class_name upgradeData

enum rarityType {COMMON, UNCOMMUN, RARE, LEGENDARY, MYTHIC}
enum effectsType {CAPACITY, SKILL_ADD, SKILL_UPGRADE}
enum available_skill {DASH, MORE_PROJECTILE}

@export_group("Infos")
@export var name: String
@export var icon: Image
@export var description: String
@export var rarity: rarityType

@export_group("Effects")
@export var typeEffects: effectsType:
	set(value):
		typeEffects = value
		notify_property_list_changed()

@export var capacities_effects: Array[capacityEffectData]
@export var skill_add_effects: available_skill
@export var skill_upgrade: Dictionary[available_skill, skillEffectData]

func _validate_property(property: Dictionary) -> void:
	if property.name == "capacities_effects":
		if typeEffects != effectsType.CAPACITY:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name == "skill_add_effects":
		if typeEffects != effectsType.SKILL_ADD:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name == "skill_upgrade":
		if typeEffects != effectsType.SKILL_UPGRADE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
