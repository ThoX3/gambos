class_name Boss_Base
extends Enemy_Base

@export var attack_cooldown: float = 3.0
var _attack_timer: float = 0.0
var is_attacking: bool = false

func _ready() -> void:
	super._ready() 
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
		
