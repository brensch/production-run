extends Control

# Configuration
@export var grid_width: int = 8
@export var grid_height: int = 8

var slot_scene = preload("res://grid_slot.tscn")

@onready var sidebar = $HBoxContainer/StreamerLog
@onready var sim_manager = $SimulationManager
@onready var run_button = $CanvasLayer/RunButton
@onready var grid_container = $HBoxContainer/AspectRatioContainer/GridContainer

func _ready():
	# 1. Initialize Backend
	sim_manager.init_grid(grid_width, grid_height)
	
	# 2. Generate Frontend
	generate_grid_visuals()
	
	# 3. Wiring (Same as before)
	get_tree().root.size_changed.connect(_on_resize)
	_on_resize()
	run_button.pressed.connect(_on_run_pressed)
	
	for card in $CanvasLayer/HandContainer.get_children():
		card.hovered.connect(sidebar.add_log)
		
func generate_grid_visuals():
	# Set the container constraints
	grid_container.columns = grid_width
	
	# Loop and Instantiate
	for i in range(grid_width * grid_height):
		var new_slot = slot_scene.instantiate()
		
		# Add to scene tree
		grid_container.add_child(new_slot)
		
		# Inject Dependency
		new_slot.setup(i, sim_manager)

func _on_resize():
	var window_size = get_viewport_rect().size
	sidebar.visible = window_size.x > 1000

@onready var score_label = $CanvasLayer/ScoreLabel # Adjust path if needed

func _on_run_pressed():
	# 1. Calculate the future (Instant)
	print("Calculating 100 ticks...")
	var full_history = sim_manager.run_batch(100)
	
	# 2. Update Final Score immediately (or you can update it during playback)
	score_label.text = "Final Score: " + str(sim_manager.score)
	
	# 3. Start the Visual Playback
	play_back_history(full_history)
func play_back_history(history: Array):
	var current_playback_tick = -1
	var playback_speed = 0.2 
	
	for transition in history:
		if transition["tick_id"] > current_playback_tick:
			current_playback_tick = transition["tick_id"]
			playback_speed = max(0.01, playback_speed * 0.95)
			await get_tree().create_timer(playback_speed).timeout 
		
		if transition["op"] == "move":
			var start_slot = grid_container.get_child(transition["from"])
			var end_slot = grid_container.get_child(transition["to"])
			
			var start_pos = start_slot.global_position + (start_slot.size / 2)
			var end_pos = end_slot.global_position + (end_slot.size / 2)
			
			animate_payload(start_pos, end_pos)
			
		elif transition["op"] == "create":
			var slot = grid_container.get_child(transition["at"])
			
			var flash = ColorRect.new()
			flash.color = Color.WHITE
			flash.size = Vector2(20, 20)
			
			# --- FIX: ADD TO MAIN GAME, NOT SLOT ---
			# This prevents the GridSlot container from resetting the Label rotation
			add_child(flash)
			
			# Calculate center manually since we aren't inside the slot anymore
			var center_pos = slot.global_position + (slot.size / 2)
			flash.global_position = center_pos - (flash.size / 2)
			
			var t = create_tween()
			t.tween_property(flash, "modulate:a", 0.0, 0.2)
			t.tween_callback(flash.queue_free)

func animate_payload(start_pos, end_pos):
	var icon = ColorRect.new() # Simple white dot for the ore
	icon.color = Color.YELLOW
	icon.size = Vector2(10, 10)
	# Center the dot
	icon.position = -icon.size / 2 
	
	add_child(icon)
	icon.global_position = start_pos
	
	var tween = create_tween()
	tween.tween_property(icon, "global_position", end_pos, 0.2) # 0.2s travel time
	tween.tween_callback(icon.queue_free)
	
	
