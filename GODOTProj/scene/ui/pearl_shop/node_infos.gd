extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer.visible = false
	$LockedDesc.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_infos(title: String, description: String, locked_text: String = ""):
	$Title.text = title
	$Description.text = description
	
	if locked_text != "":
		$VBoxContainer.visible = true
		$LockedDesc.visible = true
		$LockedDesc.text = locked_text
	else:
		$VBoxContainer.visible = false
		$LockedDesc.visible = false
