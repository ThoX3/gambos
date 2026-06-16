class_name EnemyShooter
extends Enemy_Base

@export var conteneur_projectiles: Node

# ── Internes ────────────────────────────────────────────────
var _index_pattern: int    = 0
var _timer_tir: float      = 0.0
var _rotation_courante: float = 0.0
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if stats.patterns.is_empty() or player == null:
		return

	var pattern: ShootingPattern = stats.patterns[_index_pattern]
	_timer_tir += delta

	if _timer_tir >= pattern.cadence:
		_timer_tir = 0.0
		_tirer(pattern)
		# Passe au pattern suivant (cycle)
		_index_pattern = (_index_pattern + 1) % stats.patterns.size()

# ── Logique de tir ───────────────────────────────────────────

func _tirer(pattern: ShootingPattern) -> void:
	if pattern.scene_projectile == null:
		push_error("EnemyShooter : aucune scène de projectile dans le pattern !")
		return

	var directions := _calculer_directions(pattern)
	for dir in directions:
		_spawner_projectile(pattern, dir)

func _calculer_directions(pattern: ShootingPattern) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	var vers_joueur := global_position.direction_to(player.global_position)

	match pattern.type:

		ShootingPattern.TypePattern.VISE_JOUEUR:
			directions.append(vers_joueur)

		ShootingPattern.TypePattern.RAFALE:
			var demi := deg_to_rad(pattern.angle_eventail * 0.5)
			var pas : float = deg_to_rad(pattern.angle_eventail) / max(pattern.nb_projectiles - 1, 1)
			var angle_base := vers_joueur.angle()
			for i in range(pattern.nb_projectiles):
				var a := angle_base - demi + pas * i
				directions.append(Vector2.from_angle(a))

		ShootingPattern.TypePattern.CERCLE:
			var pas := TAU / pattern.nb_projectiles
			for i in range(pattern.nb_projectiles):
				directions.append(Vector2.from_angle(pas * i))

		ShootingPattern.TypePattern.CERCLE_TOURNE:
			var pas := TAU / pattern.nb_projectiles
			var offset := deg_to_rad(_rotation_courante)
			for i in range(pattern.nb_projectiles):
				directions.append(Vector2.from_angle(pas * i + offset))
			_rotation_courante += pattern.offset_rotation

	return directions

func _spawner_projectile(pattern: ShootingPattern, direction: Vector2) -> void:
	var proj: EnemyProjectile = pattern.scene_projectile.instantiate()
	proj.init(direction, pattern.degats, pattern.vitesse, pattern.duree_vie, stats.projectile_sprite)

	var parent := conteneur_projectiles if conteneur_projectiles else get_parent()
	parent.add_child(proj)
	_pulser()
	proj.global_position = global_position

func _pulser() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
