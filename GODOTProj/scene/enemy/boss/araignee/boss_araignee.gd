extends Boss_Base

@onready var collision_physique: CollisionShape2D = $CollisionShape2D

@export_category("Paramètres Araignée")
@export var projectile_scene: PackedScene 
@export var degats_broyage: int = 25
@export var degats_balayage_corps: int = 20
@export var degats_projectile: int = 30
@export var vitesse_embuscade: int = 1200
@export var degats_embuscade: int = 35


func _peut_attaquer() -> bool:
	return true


func _declencher_nova() -> void:
	var nombre_projectiles = 8
	var angle_step = TAU / float(nombre_projectiles)
	
	for i in range(nombre_projectiles):
		var proj = projectile_scene.instantiate()
		var angle = i * angle_step
		proj.global_position = self.global_position
		
		if "direction" in proj:
			proj.direction = Vector2(cos(angle), sin(angle))
		
		get_parent().add_child(proj)

func take_damage(amount: int) -> int:
	var loss_hp: int = super.take_damage(amount)
	if not spawn_comme_ennemi_normal:
		GameManager.boss_health_changed.emit(stats.max_hp, hp)
	if not is_instance_valid(self) or is_queued_for_deletion():
		_on_boss_mort()
	return loss_hp

func _on_boss_mort() -> void:
	SaveManager.save_game()
	GameManager.boss_araignee_vaincu.emit()

func _sauvegarder_victoire() -> void:
	SaveManager.save_game()
