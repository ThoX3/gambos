extends Node

const DYNAMIC_FONTS_DIR = "res://assets/fonts/dynamic/"
const PIXEL_FONTS_DIR = "res://assets/fonts/depixel/"
const MODERN_FONTS_DIR = "res://assets/fonts/modern/" 

var font_map = {
	"DePixelBreit.tres": "DePixelBreit.ttf",
	"DePixelHalbfett.tres": "DePixelHalbfett.ttf",
	"DePixelKlein.tres": "DePixelKlein.ttf",
	"DePixelSchmal.tres": "DePixelSchmal.ttf",
	"DePixelIllegible.tres": "DePixelIllegible.ttf"
}

var modern_font_map = {
	"DePixelBreit.tres": "Gobold Regular.otf",
	"DePixelHalbfett.tres": "Gobold Bold.otf",
	"DePixelKlein.tres": "Gobold Lowplus.otf",
	"DePixelSchmal.tres": "Gobold Extra2.otf",
	"DePixelIllegible.tres": "Gobold Uplow.otf"
}

var is_modern_active: bool = false

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	
	# Delay initialization slightly to let SaveManager load
	call_deferred("_init_fonts_from_save")

func _init_fonts_from_save() -> void:
	if SaveManager.current_save:
		if "setting_use_pixel_font" in SaveManager.current_save:
			set_modern_font(not SaveManager.current_save.setting_use_pixel_font)
		else:
			set_modern_font(false)

func set_modern_font(active: bool) -> void:
	is_modern_active = active
	
	for dynamic_res in font_map.keys():
		var font_var: FontVariation = load(DYNAMIC_FONTS_DIR + dynamic_res)
		if not font_var:
			continue
			
		var target_path = ""
		if active:
			# If the modern font file doesn't exist yet, fallback to pixel art
			target_path = MODERN_FONTS_DIR + modern_font_map[dynamic_res]
			if not ResourceLoader.exists(target_path):
				target_path = PIXEL_FONTS_DIR + font_map[dynamic_res]
		else:
			target_path = PIXEL_FONTS_DIR + font_map[dynamic_res]
			
		var base_font: Font = load(target_path)
		if base_font:
			font_var.base_font = base_font
	
	# Update existing nodes in the tree
	_update_all_nodes(get_tree().root)

func _update_all_nodes(node: Node) -> void:
	_apply_filter(node)
	for child in node.get_children():
		_update_all_nodes(child)

func _on_node_added(node: Node) -> void:
	_apply_filter(node)

func _apply_filter(node: Node) -> void:
	if node is Label or node is RichTextLabel or node is Button:
		if is_modern_active:
			node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		else:
			node.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
