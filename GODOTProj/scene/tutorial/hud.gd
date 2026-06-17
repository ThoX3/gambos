extends Control

@export var Stats = Resource

@onready var pearl_box = $Pearls
@onready var pearl_label = $Pearls/MarginContainer/Count

var pearl_tween: Tween

func _ready() -> void:
	GameManager.pearls_changed.connect(_on_pearls_changed)
	pearl_box.modulate.a = 0
	pearl_box.visible = false
	
func _update_health_bar():
	%HP_Bar.max_value = Stats.max_health
	%HP_Bar.value = Stats.current_health
	%HP.text = str(max(int(ceil(Stats.current_health)), 0)) + " / " + str(int(Stats.max_health))
	
func _on_pearls_changed():
	pearl_label.text = str(SaveManager.current_save.pearls + Stats.collected_pearls)
	
	if pearl_tween and pearl_tween.is_valid():
		pearl_tween.kill()
		
	pearl_tween = create_tween()
	
	pearl_box.visible = true
	pearl_box.scale = Vector2(1.2, 1.2) 
		
	pearl_tween.set_parallel(true)
	pearl_tween.tween_property(pearl_box, "modulate:a", 1.0, 0.1)
	pearl_tween.tween_property(pearl_box, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE)
	pearl_tween.set_parallel(false) 
	
	pearl_tween.tween_interval(2.0)
	
	pearl_tween.tween_property(pearl_box, "modulate:a", 0.0, 0.5)
	
	pearl_tween.tween_callback(func(): pearl_box.visible = false)
