extends Node

const FADE_DURATION := 0.5
const VOL_MIN       := -80.0
const VOL_MAX       :=   0.0

# ═══════════════════════════════════════════════════════════════
#  CONFIGURATION
# ═══════════════════════════════════════════════════════════════

# ── Effets sonores : "clé" → chemin ────────────────────────────
const SONS := {
	"projectile_pop": "res://assets/sounds/effect/pop.mp3",
	"gambos_hurt":    "res://assets/sounds/effect/Gambos_hurt.mp3",
	"menu_press": "res://assets/sounds/menu/Menu_press.mp3",
	"menu_selection": "res://assets/sounds/menu/Menu_select.mp3",
	"pearl_collect": "res://assets/sounds/effect/pearlCollect.mp3",
	"pearl_shop_unlock": "res://assets/sounds/pearl_shop/unlock.mp3",
	"pearl_shop_buy": "res://assets/sounds/pearl_shop/pearls.mp3",
}

# ── Musiques ────────────────────────────────────────────────────
# Chaque musique contient :
#   "pistes"        → dictionnaire "nom" → chemin du fichier
#   "deverouillage" → dictionnaire vague → [noms des pistes à activer]
const MUSIQUES := {

	"map1": {
		"pistes": {
			"bass":   "res://assets/sounds/map1/map1-bass.mp3",
			"guitar": "res://assets/sounds/map1/map1-guitar.mp3",
			"other":  "res://assets/sounds/map1/map1-other.mp3",
			"piano":  "res://assets/sounds/map1/map1-piano.mp3",
			"vocals": "res://assets/sounds/map1/map1-vocals.mp3",
			"drums":  "res://assets/sounds/map1/map1-drums.mp3",
		},
		"deverouillage": {
			0:  ["bass"],
			7:  ["guitar", "piano", "other", "vocals"],
			15: ["drums"],
		}
	},
	
	"map2": {
		"pistes": {
			"bass":   "res://assets/sounds/map2/map2-bass.mp3",
			"drums": "res://assets/sounds/map2/map2-drums.mp3",
			"other":  "res://assets/sounds/map2/map2-other.mp3",
		},
		"deverouillage": {
			21:  ["bass"],
			28:  ["drums"],
			35: ["other"],
		}
	},
	
	"map3": {
		"pistes": {
			"bass":   "res://assets/sounds/map3/map3-bass.mp3",
			"drums": "res://assets/sounds/map3/map3-drums.mp3",
			"other":  "res://assets/sounds/map3/map3-other.mp3",
		},
		"deverouillage": {
			61:  ["other"],
			68:  ["drums"],
			74: ["other"],
		}
	},
	

	"main_menu": {
		"pistes": {
			"theme": "res://assets/sounds/menu/main_menu_theme.mp3",
		},
		"deverouillage": {
			0: ["theme"],
		}
	},
	
	"shop": {
		"pistes": {
			"theme": "res://assets/sounds/menu/shop_theme.mp3",
		},
		"deverouillage": {
			0: ["theme"],
		}
	},

	# Ajouter une nouvelle musique = copier ce bloc et changer les chemins
	# "map2": {
	# 	"pistes": {
	# 		"theme": "res://assets/sounds/map2/map2-theme.mp3",
	# 		"lead":  "res://assets/sounds/map2/map2-lead.mp3",
	# 	},
	# 	"deverouillage": {
	# 		0: ["theme"],
	# 		5: ["lead"],
	# 	}
	# },

	# Musique sans couches (une seule piste, boucle simple)
	# "menu": {
	# 	"pistes": {
	# 		"theme": "res://assets/sounds/menu/menu-theme.mp3",
	# 	},
	# 	"deverouillage": {
	# 		0: ["theme"],
	# 	}
	# },
}


# ═══════════════════════════════════════════════════════════════
#  INTERNES — logique du manager
# ═══════════════════════════════════════════════════════════════

var _sons_charges: Dictionary  = {}  # "clé" → AudioStream
var _players_actifs: Dictionary = {}  # "piste" → AudioStreamPlayer
var _musique_courante: String   = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_precharger_sons()
	await get_tree().process_frame
	GameManager.GameOver.connect(stop_music)


# ── API publique ─────────────────────────────────────────────────

## Lance une musique par son identifiant (défini dans MUSIQUES).
## Si une musique joue déjà, elle fait un fade-out avant le démarrage.
func play_music(id: String) -> void:
	if not MUSIQUES.has(id):
		push_error("AudioManager : musique introuvable → " + id)
		return
	if _musique_courante == id:
		return
	if not _players_actifs.is_empty():
		await stop_music()
	_charger_musique(id)


## Fait un fade-out et coupe tous les players actifs.
func stop_music() -> void:
	for p in _players_actifs.values():
		create_tween().tween_property(p as AudioStreamPlayer, "volume_db", VOL_MIN, FADE_DURATION)
	await get_tree().create_timer(FADE_DURATION).timeout
	for p in _players_actifs.values():
		(p as AudioStreamPlayer).queue_free()
	_players_actifs.clear()
	_musique_courante = ""


## Remet la musique courante à son état initial (vague 0) sans la couper.
func reset_music() -> void:
	for p in _players_actifs.values():
		var player := p as AudioStreamPlayer
		player.volume_db = VOL_MIN
		player.play()
	_activer_couches(0)


## Joue un effet sonore spatialisé (positionné dans le monde 2D).
func play_sound_2d(nom: String, position: Vector2) -> void:
	if not _sons_charges.has(nom):
		push_error("AudioManager : son introuvable → " + nom)
		return
	var p := AudioStreamPlayer2D.new()
	p.stream          = _sons_charges[nom]
	p.pitch_scale     = randf_range(0.8, 1.3)
	p.global_position = position
	p.bus             = "SFX"
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

## Joue un effet sonore non spatialisé (idéal pour l'UI).
func play_sound(nom: String) -> void:
	if not _sons_charges.has(nom):
		push_error("AudioManager : son introuvable → " + nom)
		return
	var p := AudioStreamPlayer.new()
	p.stream      = _sons_charges[nom]
	p.pitch_scale = randf_range(0.8, 1.3)
	p.bus         = "SFX"
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

# ── Internes ─────────────────────────────────────────────────────

func _precharger_sons() -> void:
	for cle in SONS:
		_sons_charges[cle] = load(SONS[cle])


func _charger_musique(id: String) -> void:
	_musique_courante = id
	var config: Dictionary = MUSIQUES[id]

	for nom in config["pistes"]:
		var p := AudioStreamPlayer.new()
		p.stream    = load(config["pistes"][nom])
		p.volume_db = VOL_MIN
		p.bus       = "Music"
		add_child(p)
		p.play()
		p.finished.connect(p.play)  # boucle automatique
		_players_actifs[nom] = p

	_activer_couches(0)


func _activer_couches(numero_vague: int) -> void:
	if _musique_courante.is_empty():
		return
	var deverouillage: Dictionary = MUSIQUES[_musique_courante]["deverouillage"]
	if not deverouillage.has(numero_vague):
		return
	for nom in deverouillage[numero_vague]:
		_fade_in(nom)


func _fade_in(nom: String) -> void:
	var p := _players_actifs.get(nom) as AudioStreamPlayer
	if p == null or p.volume_db >= VOL_MAX:
		return
	create_tween().tween_property(p, "volume_db", VOL_MAX, FADE_DURATION)


# ── Connexions signaux ───────────────────────────────────────────

func _on_vague_change(numero: int) -> void:
	_activer_couches(numero)
