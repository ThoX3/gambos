extends Node2D
class_name BaseMap

# Map settings
@export_group("Map settings")
@export var map_name: String = "Unknown Zone"
@export var map_music: AudioStream

# Limits and looping
@export_group("Limits")
## If true, creates invisible walls and locks the camera.
@export var has_hard_borders: bool = true
## The size of the playable area in pixels.
@export var map_size: Vector2 = Vector2(4000, 4000)

@export_group("Looping")
## Warps the player to the other side when crossing horizontal bounds.
@export var loop_horizontally: bool = false
## Warps the player to the other side when crossing vertical bounds.
@export var loop_vertically: bool = false

# Internal references
var player: CharacterBody2D
var camera: Camera2D

func _ready():
	# 1. Play the specific music for this map
	if map_music and has_node("MusicPlayer"):
		$MusicPlayer.stream = map_music
		$MusicPlayer.play()
		
	# 2. Wait for the end of the frame to ensure the Player is fully loaded
	call_deferred("_initialize_map")

func _initialize_map():
	# Find the player using Godot's Group system
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		# Search the player's children for the Camera2D
		for child in player.get_children():
			if child is Camera2D:
				camera = child
				break
				
	# Setup the map logic based on export toggles
	if has_hard_borders:
		setup_borders()

func setup_borders():
	# --- 1. Set Camera Limits ---
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(map_size.x)
		camera.limit_bottom = int(map_size.y)
		camera.limit_smoothed = true

	# --- 2. Generate Physics Walls ---
	# Instead of manually drawing collision boxes, we generate them via code!
	var border_body = StaticBody2D.new()
	border_body.name = "GeneratedBorders"
	add_child(border_body)
	
	var wall_thickness = 100
	
	# Helper function to create a wall
	var create_wall = func(pos: Vector2, extents: Vector2):
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = extents
		shape.shape = rect
		shape.position = pos
		border_body.add_child(shape)

	# Top Wall
	create_wall.call(Vector2(map_size.x / 2, -wall_thickness / 2), Vector2(map_size.x, wall_thickness))
	# Bottom Wall
	create_wall.call(Vector2(map_size.x / 2, map_size.y + wall_thickness / 2), Vector2(map_size.x, wall_thickness))
	# Left Wall
	create_wall.call(Vector2(-wall_thickness / 2, map_size.y / 2), Vector2(wall_thickness, map_size.y + wall_thickness * 2))
	# Right Wall
	create_wall.call(Vector2(map_size.x + wall_thickness / 2, map_size.y / 2), Vector2(wall_thickness, map_size.y + wall_thickness * 2))

func _physics_process(_delta):
	# If we are looping, constantly check the player's position
	if player and (loop_horizontally or loop_vertically):
		handle_looping()

func handle_looping():
	var pos = player.global_position
	var did_warp = false
	
	# Pac-Man style screen wrapping
	if loop_horizontally:
		if pos.x < 0:
			pos.x += map_size.x
			did_warp = true
		elif pos.x > map_size.x:
			pos.x -= map_size.x
			did_warp = true
			
	if loop_vertically:
		if pos.y < 0:
			pos.y += map_size.y
			did_warp = true
		elif pos.y > map_size.y:
			pos.y -= map_size.y
			did_warp = true
			
	# Apply the warp
	if did_warp:
		player.global_position = pos
		
		# CRITICAL: Reset the camera smoothing so it snaps instantly
		# Otherwise, the camera will quickly slide across the entire map
		if camera:
			camera.reset_smoothing()
