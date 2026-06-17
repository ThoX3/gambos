extends CanvasLayer

signal dialogue_finished

@onready var label: RichTextLabel = $ColorRect/MarginContainer/Label
@onready var color_rect: TextureRect = $ColorRect

@export var lines: Array[String] = []
var current_line_index: int = 0
var is_auto_advance: bool = false
var is_stay_on_screen: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func start_dialogue(dialogue_lines: Array[String], auto_advance: bool = false, stay_on_screen: bool = false) -> void:
	lines = dialogue_lines
	is_auto_advance = auto_advance
	is_stay_on_screen = stay_on_screen
	current_line_index = 0
	if lines.size() > 0:
		label.text = "[center]" + lines[0] + "[/center]"
		if not is_auto_advance and not is_stay_on_screen:
			get_tree().paused = true
		
		color_rect.modulate.a = 0.0
		var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(color_rect, "modulate:a", 1.0, 0.3)
		
		if is_auto_advance and not is_stay_on_screen:
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(_on_auto_advance_timeout)
	else:
		_finish()

func _on_auto_advance_timeout() -> void:
	current_line_index += 1
	if current_line_index < lines.size():
		label.text = "[center]" + lines[current_line_index] + "[/center]"
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(_on_auto_advance_timeout)
	else:
		_finish()

func _input(event: InputEvent) -> void:
	if not visible or is_auto_advance or is_stay_on_screen:
		return
	if event.is_action_pressed("ui_accept"):
		current_line_index += 1
		if current_line_index < lines.size():
			label.text = "[center]" + lines[current_line_index] + "[/center]"
		else:
			_finish()

func _finish() -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if not is_auto_advance and not is_stay_on_screen:
			get_tree().paused = false
		dialogue_finished.emit()
		queue_free()
	)
