extends Control

@export var line_color: Color = Color(0.27, 0.529, 0.702, 1.0)
@export var line_thickness: float = 4.0

func _draw():
	for child in get_children():
		if child.has_method("update_node") and child.parent_node != null:
			var start_pos = child.position + (child.size / 2.0)
			var end_pos = child.parent_node.position + (child.parent_node.size / 2.0)
			
			var current_color = Color.WHITE if child.is_unlocked else line_color
			
			draw_line(start_pos, end_pos, current_color, line_thickness)

func refresh_lines():
	queue_redraw() # Tells Godot to run _draw() again
