class_name Boss_Base
extends Enemy_Base

@export var attack_cooldown: float = 3.0
@export var scene_transition: PackedScene
@export var orb_mutation_scene: PackedScene

var _attack_timer: float = 0.0
var is_attacking: bool = false

func _ready() -> void:
	super._ready() 
	_lancer_transition_boss()
	_attack_timer = attack_cooldown

func _physics_process(delta: float) -> void:
	if not stats or not is_instance_valid(player):
		return

	if not is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0 and _peut_attaquer():
			_start_attack()
		else:
			super._physics_process(delta)
	else:
		_process_attack(delta)

# ── Méthodes "Virtuelles" (À surcharger dans les scripts de tes vrais boss) ──

func _start_attack() -> void:
	is_attacking = true
	_attack_timer = attack_cooldown

func _process_attack(_delta: float) -> void:
	pass

func _peut_attaquer() -> bool:
	return true

func _end_attack() -> void:
	is_attacking = false
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
		
func _lancer_transition_boss() -> void:
	get_tree().paused = true

	if scene_transition != null:
		var transition_instance = scene_transition.instantiate()
		get_tree().root.add_child(transition_instance)
		
		transition_instance.process_mode = Node.PROCESS_MODE_ALWAYS

		if transition_instance.has_signal("transition_terminee"):
			await transition_instance.transition_terminee
		elif transition_instance.has_node("AnimationPlayer"):
			var anim_player = transition_instance.get_node("AnimationPlayer") as AnimationPlayer
			anim_player.play("intro") 
			await anim_player.animation_finished
		else:
			await get_tree().create_timer(3.0).timeout
		
		transition_instance.queue_free()

	get_tree().paused = false

	await get_tree().create_timer(2.0).timeout
	
func _on_boss_mort() -> void:
	# 1. Sauvegardes et signaux d'origine
	SaveManager.current_save.boss_araignee_battu = true
	SaveManager.save_game()
	GameManager.boss_araignee_vaincu.emit()
	
	print("💀 MORT DU BOSS : On fige le jeu immédiatement.")
	
	# 2. On fige le jeu ICI, depuis le boss
	# Comme ça, aucune action ou frame parasite ne peut continuer
	if is_inside_tree():
		get_tree().paused = true
	
	# 3. On demande à l'UI de s'afficher
	get_tree().call_group("MutationUI", "_ouvrir_menu")
	
	# 4. Le boss peut mourir en paix, le jeu est déjà gelé
	queue_free()
