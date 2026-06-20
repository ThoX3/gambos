class_name Boss_Base
extends Enemy_Base

@export var attack_cooldown: float = 3.0
@export var scene_transition: PackedScene

var _attack_timer: float = 0.0
var is_attacking: bool = false

## true quand le boss est spawné comme un ennemi normal (mode infini) :
## pas de cinématique, pas de pause, pas de barre de vie spéciale.
var spawn_comme_ennemi_normal: bool = false

func _ready() -> void:
	super._ready() 
	if not spawn_comme_ennemi_normal:
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
	
func start_breathing_animation():
	pass
