extends Node


const SAVE_DIR = "user://gambos"
const SAVE_PATH = SAVE_DIR + "/save.tres"

var current_save: SaveData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func save_game() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var err = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			push_error("SaveManager: Failed to create save directory: ", err)
			return

	var result = ResourceSaver.save(current_save, SAVE_PATH)
	if result == OK:
		print("SaveManager: Game saved successfully!")
	else:
		push_error("SaveManager: Failed to save game. Error code: ", result)

func load_game() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		current_save = ResourceLoader.load(SAVE_PATH) as SaveData
		print("SaveManager: Save loaded! Pearls: ", current_save.pearls)
	else:
		current_save = SaveData.new()
		print("SaveManager: No save found. Created new save profile.")
	
	apply_settings()

func apply_settings() -> void:
	if not current_save: return
	
	# Audio Volume
	var master_bus_index = AudioServer.get_bus_index("Master")
	var volume = current_save.setting_master_volume
	var db_value = linear_to_db(volume)
	AudioServer.set_bus_volume_db(master_bus_index, db_value)
	AudioServer.set_bus_mute(master_bus_index, volume <= 0.0)
