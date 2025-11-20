extends PanelContainer
class_name MachineCard

signal hovered(card_name)

@export var machine_type: String = "Drill"

func _ready():
	# When the game starts, force the label to match the variable
	if has_node("Label"):
		$Label.text = machine_type

func _get_drag_data(_at_position):
	var preview = Button.new()
	preview.text = machine_type
	set_drag_preview(preview)
	return { "type": machine_type }

func _on_mouse_entered() -> void:
	hovered.emit(machine_type)
