class_name EnemySpawner
extends Enemy_Base

@onready var ennemis_a_spawner	= stats.ennemis_a_spawner
@onready var nb_spawn_max		= stats.nb_spawn_max
@onready var intervalle_spawn	= stats.intervalle_spawn
@onready var spawn_a_la_mort	= stats.spawn_a_la_mort
@onready var afficher_pulsation = stats.afficher_pulsation

# ── Internes ──────────────────────────────────────────────────
var _spawnes: int   = 0
var _timer: float   = 0.0

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)   # conserve le déplacement vers le joueur

	if spawn_a_la_mort or _spawnes >= nb_spawn_max:
		return

	_timer += delta
	if _timer >= intervalle_spawn:
		_timer = 0.0
		if afficher_pulsation:
			_pulser()
		_spawner_un_ennemi()

func take_damage(amount: int) -> int:
	# Calcule si cet appel va tuer l'ennemi AVANT d'appeler super
	# (après super, queue_free() est déjà déclenché)
	var va_mourir := not is_queued_for_deletion() and (hp - amount) <= 0

	var removed := super.take_damage(amount)

	if va_mourir and spawn_a_la_mort:
		for i in range(nb_spawn_max):
			_spawner_un_ennemi()

	return removed

# ── Spawn ──────────────────────────────────────────────────────

func _spawner_un_ennemi() -> void:
	if ennemis_a_spawner.is_empty() or not is_instance_valid(get_parent()):
		return

	var entry: EntreeEnnemi = ennemis_a_spawner.pick_random()
	var ennemi: Enemy_Base  = entry.scene.instantiate()
	ennemi.stats            = entry.data
	
	var space_state = get_world_2d().direct_space_state
	var valid_pos = global_position
	for i in range(10):
		var test_pos = global_position + Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
		var query = PhysicsPointQueryParameters2D.new()
		query.position = test_pos
		var intersections = space_state.intersect_point(query)
		var hit_obstacle = false
		for inter in intersections:
			if inter.collider is TileMapLayer:
				hit_obstacle = true
				break
		if not hit_obstacle:
			valid_pos = test_pos
			break

	ennemi.global_position = valid_pos
	get_parent().call_deferred("add_child", ennemi)
	_spawnes += 1

func _pulser() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
