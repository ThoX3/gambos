extends Node

const FADE_DURATION := 2.0
const VOL_MIN       := -80.0
const VOL_MAX       :=   0.0

var sons = {
	"projectile_pop": preload("res://assets/sounds/effect/pop.mp3"),
	"GAMBOS_hurt": preload("res://assets/sounds/effect/Gambos_hurt.mp3")
}

# ── Définis ici quelles couches s'activent à quelle vague ──
const DEVEROUILLAGE := {
	0: ["bass"],
	7: ["guitar", "piano", "other", "vocals"],
	15: ["drums"]
}

# ── Pistes source ───────────────────────────────────────────
var _pistes := {
	"bass":   preload("res://assets/sounds/map1/map1-bass.mp3"),
	"guitar": preload("res://assets/sounds/map1/map1-guitar.mp3"),
	"other":  preload("res://assets/sounds/map1/map1-other.mp3"),
	"piano":  preload("res://assets/sounds/map1/map1-piano.mp3"),
	"vocals": preload("res://assets/sounds/map1/map1-vocals.mp3"),
	"drums":  preload("res://assets/sounds/map1/map1-drums.mp3"),
}

# ── Lecteurs créés dynamiquement ────────────────────────────
var _players: Dictionary = {}   # "bass" → AudioStreamPlayer

func _ready():
	await get_tree().process_frame
	GameManager.start_game.connect(_init_music)
	GameManager.GameOver.connect(stop_music)
	
# ── Sons spatialisés (inchangé) ─────────────────────────────
func play_sound_2d(nom_du_son: String, position: Vector2) -> void:
	if not sons.has(nom_du_son):
		push_error("Son introuvable : " + nom_du_son)
		return
	var p := AudioStreamPlayer2D.new()
	p.stream       = sons[nom_du_son]
	p.pitch_scale  = randf_range(0.8, 1.3)
	p.global_position = position
	get_tree().current_scene.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	
func _init_music() -> void:
	# Attends que la scène de jeu soit chargée
	var wm := get_tree().get_first_node_in_group("wave_manager")
	wm.vague_demarree.connect(_on_vague_change)
	# Crée tous les lecteurs en silence dans une boucle
	for nom in _pistes:
		var p := AudioStreamPlayer.new()
		p.stream    = _pistes[nom]
		p.volume_db = VOL_MIN
		add_child(p)
		p.play()
		p.finished.connect(p.play)
		_players[nom] = p

	_activer_couches(0)   # Couches de départ (vague 0)

func _on_vague_change(numero: int) -> void:
	_activer_couches(numero)

func _activer_couches(numero_vague: int) -> void:
	if not DEVEROUILLAGE.has(numero_vague):
		return   # Aucune couche à débloquer à cette vague
	for nom in DEVEROUILLAGE[numero_vague]:
		_fade_in(nom)

func _fade_in(nom: String) -> void:
	var p := _players.get(nom) as AudioStreamPlayer
	if p == null or p.volume_db >= VOL_MAX:
		return   # Introuvable ou déjà active
	create_tween().tween_property(p, "volume_db", VOL_MAX, FADE_DURATION)

func stop_music() -> void:
	for p in _players.values():
		var player := p as AudioStreamPlayer
		create_tween().tween_property(player, "volume_db", VOL_MIN, FADE_DURATION)
	# Arrêt réel après le fade
	await get_tree().create_timer(FADE_DURATION).timeout
	for p in _players.values():
		(p as AudioStreamPlayer).stop()

func reset_music() -> void:
	for p in _players.values():
		var player := p as AudioStreamPlayer
		player.volume_db = VOL_MIN
		player.play()
		player.finished.connect(p.play)
	_activer_couches(0)
