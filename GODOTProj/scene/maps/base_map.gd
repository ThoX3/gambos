extends Node2D
class_name BaseMap

# --- MAP SETTINGS ---
@export_group("General Settings")
@export var map_name: String = "New Map"
@export var background_music: AudioStream
## The core playable area of the map in pixels
@export var map_size: Vector2 = Vector2(4000, 4000)

# --- TOPOLOGY / LOOPING ---
@export_group("Looping Settings")
## Check to make the map loop left-to-right (Cylinder)
@export var loop_horizontally: bool = false
## Check to make the map loop top-to-bottom
@export var loop_vertically: bool = false

# --- NODE REFERENCES ---
@onready var bgm_player: AudioStreamPlayer2D = $Audio

var player: CharacterBody2D

func _ready() -> void:
	# 1. Start the music immediately if one is assigned
	if background_music:
		bgm_player.stream = background_music
		bgm_player.play()
	
	# 2. Wait exactly one frame to ensure the Player has spawned into the level
	call_deferred("_initialize_map")

func _initialize_map() -> void:
	# Grab the player using Godot groups 
	player = get_tree().get_first_node_in_group("Player")
	
	# Route to the correct setup based on your Inspector toggles
	if loop_horizontally or loop_vertically:
		_setup_holograms()
	else:
		_setup_hard_borders()

func _physics_process(_delta: float) -> void:
	# Only run the shifting logic if we have a player and the map loops
	if player and (loop_horizontally or loop_vertically):
		_check_universe_shift()

func _setup_hard_borders() -> void:
	# --- 1. SET CAMERA LIMITS ---
	# Find the Camera2D attached to the player
	var camera: Camera2D = null
	for child in player.get_children():
		if child is Camera2D:
			camera = child
			break
			
	# If a camera was found, lock its viewing boundaries to the map size
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(map_size.x)
		camera.limit_bottom = int(map_size.y)
		camera.limit_smoothed = true

	# --- 2. GENERATE PHYSICS WALLS ---
	var border_body = StaticBody2D.new()
	border_body.name = "GeneratedBorders"
	
	# Keep the Scene Tree clean by putting it in the Entities node if you made one
	if has_node("Entities"):
		$Entities.add_child(border_body)
	else:
		add_child(border_body)
		
	# Make the walls thick! If they are too thin, players moving at very high speeds 
	# might "tunnel" or phase through them between physics frames.
	var wall_thickness = 200.0 
	
	# An inline helper function to quickly generate the 4 walls without repeating code
	var create_wall = func(pos: Vector2, extents: Vector2):
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = extents
		shape.shape = rect
		shape.position = pos
		border_body.add_child(shape)

	# Build the Top Wall
	create_wall.call(Vector2(map_size.x / 2.0, -wall_thickness / 2.0), Vector2(map_size.x, wall_thickness))
	
	# Build the Bottom Wall
	create_wall.call(Vector2(map_size.x / 2.0, map_size.y + wall_thickness / 2.0), Vector2(map_size.x, wall_thickness))
	
	# Build the Left Wall
	create_wall.call(Vector2(-wall_thickness / 2.0, map_size.y / 2.0), Vector2(wall_thickness, map_size.y + wall_thickness * 2.0))
	
	# Build the Right Wall
	create_wall.call(Vector2(map_size.x + wall_thickness / 2.0, map_size.y / 2.0), Vector2(wall_thickness, map_size.y + wall_thickness * 2.0))

func _setup_holograms() -> void:
	# TODO: Duplicate the FloorLayer to surround the map (1x3 or 3x3 grid)
	pass

func _check_universe_shift() -> void:
	# TODO: Check if the player crossed a threshold. 
	# If yes, shift the player, enemies, and camera backward.
	pass
