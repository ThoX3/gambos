extends Control

signal selected(data: upgradeData)

# A remplir dans l'éditeur Godot de card.tscn ! On écrit plus les chemins en dur
@export var BACKGROUNDS: Dictionary[upgradeData.rarityType, Texture2D] = {
	upgradeData.rarityType.COMMON: null,
	upgradeData.rarityType.UNCOMMUN: null,
	upgradeData.rarityType.RARE: null,
	upgradeData.rarityType.LEGENDARY: null,
	upgradeData.rarityType.MYTHIC: null
}

# A remplir dans l'éditeur Godot de card.tscn ! On écrit plus les chemins en dur
@export var HOVER: Dictionary[upgradeData.rarityType, Texture2D] = {
	upgradeData.rarityType.COMMON: null,
	upgradeData.rarityType.UNCOMMUN: null,
	upgradeData.rarityType.RARE: null,
	upgradeData.rarityType.LEGENDARY: null,
	upgradeData.rarityType.MYTHIC: null
}

const RARITY_NAME = {
	upgradeData.rarityType.COMMON: "Commun",
	upgradeData.rarityType.UNCOMMUN: "Rare",
	upgradeData.rarityType.RARE: "Épique",
	upgradeData.rarityType.LEGENDARY: "Légendaire",
	upgradeData.rarityType.MYTHIC: "Divin"
}

const STATS = {
	capacityEffectData.TargetCapacityEffect.PLAYER_HEALTH: "Vie max : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_SPEED: "Vitesse de déplacement : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_DAMAGE: "Dégâts : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_SPEED: "Vitesse d'attaque : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_ATTACK_RANGE: "Portée d'attaque : ",
	capacityEffectData.TargetCapacityEffect.PLAYER_COLLECT_RANGE: "Portée de collect : "
}

var current_data: upgradeData

func setup(data: upgradeData) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	var current_stats = player.get_player_stats()
	current_data = data
	%Title.text = data.name
	%Icon.texture = data.icon
	%Description.text = data.description
	%Stats.text = ""
	if data.typeEffects == data.effectsType.CAPACITY:
		for effet in data.capacities_effects:
			%Stats.append_text(STATS[effet.targetCapacity] + "\n")
			var current_value = current_stats[STATS[effet.targetCapacity]]
			var affichage_valeur = effet.value
			if effet.targetCapacity != effet.TargetCapacityEffect.PLAYER_ATTACK_SPEED:
				affichage_valeur = int(effet.value)
			var color = "green" if effet.value > 0 else "red"
			%Stats.append_text(str(current_value) + " -> [color=" + color + "]" + str(current_value + affichage_valeur) + "[/color]\n")
			
			if effet.targetCapacity == capacityEffectData.TargetCapacityEffect.PLAYER_HEALTH:
				var cur_hp = int(player.Stats.current_health)
				%Stats.append_text("Vie actuelle : \n")
				%Stats.append_text(str(cur_hp) + " -> [color=green]" + str(cur_hp + affichage_valeur) + "[/color]\n")
	%Rarity.text = RARITY_NAME[data.rarity]
	var texture_normal = BACKGROUNDS[data.rarity]
	var texture_hover = HOVER[data.rarity]
	%TextureButton.texture_normal = texture_normal
	%TextureButton.texture_hover = texture_hover
	%TextureButton.texture_focused = texture_hover
	
	%TextureButton.focus_entered.connect(_on_focus_entered)
	%TextureButton.focus_exited.connect(_on_focus_exited)

func _on_texture_button_pressed() -> void:
	selected.emit(current_data)

func _on_focus_entered() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.15)

func _on_focus_exited() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
