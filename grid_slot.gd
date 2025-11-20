extends PanelContainer
class_name GridSlot

var slot_index: int = -1
var manager: SimulationManager

# 0=Up, 1=Right, 2=Down, 3=Left
var current_dir: int = 1 
@onready var label = $Label

func setup(index, sim_manager):
	slot_index = index
	manager = sim_manager
	if has_node("BoxNumber"):
		$BoxNumber.text = str(index)
		$BoxNumber.modulate = Color(1, 1, 1, 0.5)

func _ready():
	# Safety Check on load
	fix_pivot()

func _get_drag_data(_at_position):
	if is_slot_empty(): return null
	
	var preview = Button.new()
	preview.text = get_machine_name() # Strip the arrow for the preview
	set_drag_preview(preview)
	
	return { 
		"type": get_machine_name(), 
		"source_index": slot_index 
	}

func _can_drop_data(_pos, data):
	return data.has("type")

func _drop_data(_pos, data):
	# 1. Set Data
	current_dir = 1 # Default to RIGHT
	
	# 2. Update Visuals
	update_label_text(data["type"])
	
	# 3. FIX: Right (1) should be 0 degrees visual
	label.pivot_offset = label.size / 2
	label.rotation_degrees = 0 
	
	fix_pivot()
	
	# 4. Update Backend
	if manager:
		manager.update_slot(slot_index, data["type"])
		manager.update_direction(slot_index, current_dir)
		
		if data.has("source_index"):
			var old_slot = get_parent().get_child(data["source_index"])
			old_slot.clear_visuals()
			manager.clear_slot(data["source_index"])

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_slot_empty():
			rotate_machine()

func rotate_machine():
	# Increment (0->1->2->3->0)
	current_dir = (current_dir + 1) % 4
	
	# FIX: Map Logic ID to Godot Degrees
	# Logic: 0=Up, 1=Right, 2=Down, 3=Left
	# Visual: -90=Up, 0=Right, 90=Down, 180=Left
	
	var new_rotation = 0
	match current_dir:
		0: new_rotation = -90 # Up
		1: new_rotation = 0   # Right
		2: new_rotation = 90  # Down
		3: new_rotation = 180 # Left
	
	# Update Visuals
	fix_pivot()
	label.rotation_degrees = new_rotation
	
	# Update Backend
	if manager:
		manager.update_direction(slot_index, current_dir)

# --- HELPER FUNCTIONS ---

func fix_pivot():
	# This prevents the "180 degree swing" illusion
	# We force Godot to recalculate the size, then set the pivot to the exact center
	if label:
		label.reset_size() # Force label to shrink to text
		label.pivot_offset = label.size / 2

func update_label_text(machine_type):
	# Adds a tiny arrow to the text so you KNOW which way it points
	# This arrow rotates WITH the text, helping your brain track it
	label.text = machine_type + " >"

func get_machine_name() -> String:
	# Strips the arrow out to get the raw name "Drill"
	return label.text.replace(" >", "")

func is_slot_empty() -> bool:
	return label.text == "" or label.text == "[Empty]"

func clear_visuals():
	label.text = ""
	current_dir = 1
	label.rotation_degrees = 0 # Reset to Right/0
