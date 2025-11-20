class_name SimulationManager
extends Node

var grid_state: Array[Dictionary] = []
var width: int = 8
var height: int = 8
var score: int = 0
var tick_count: int = 0

func init_grid(w, h):
	width = w
	height = h
	grid_state.resize(w * h)
	for i in range(w*h):
		# Added "dir" (Direction) for the Belt logic
		grid_state[i] = { "type": "Empty", "inventory": 0, "dir": 1 }

func run_tick() -> Array:
	tick_count += 1
	
	# 1. GET THE PLAN (Pure Calculation)
	var transitions = RuleEngine.calculate_tick(grid_state, width, height, tick_count)
	
	# 2. EXECUTE THE PLAN (State Mutation)
	for t in transitions:
		match t["op"]:
			"create":
				grid_state[t["at"]]["inventory"] += t["amount"]
				print("Created ", t["item"], " at ", t["at"])
				
			"move":
				# Basic Validation: Logic check before commit
				# (e.g., ensure source actually still has the item)
				if grid_state[t["from"]]["inventory"] >= t["amount"]:
					grid_state[t["from"]]["inventory"] -= t["amount"]
					grid_state[t["to"]]["inventory"] += t["amount"]
					
			"score":
				score += t["amount"]
				print("Score! +", t["amount"])
				
	# 3. RETURN PLAN TO UI (For Animation)
	return transitions

# THE API FOR THE UI (Placement Phase)
func update_slot(index: int, machine_type: String):
	if index < grid_state.size():
		grid_state[index]["type"] = machine_type
		# Reset inventory to avoid "ghost items" when replacing a machine
		grid_state[index]["inventory"] = 0
		print("Backend: Slot ", index, " updated to ", machine_type)

func clear_slot(index: int):
	if index < grid_state.size():
		# Reset to default empty state
		grid_state[index] = { "type": "Empty", "inventory": 0, "dir": 1 }
		print("Backend: Slot ", index, " cleared.")
		
		
# Runs 100 ticks instantly and returns the FULL history of what happened
func run_batch(amount: int) -> Array:
	var batch_history = []
	
	for i in range(amount):
		# 1. Run one tick (Calculate + Apply)
		var tick_transitions = run_tick()
		
		# 2. Tag these events with the specific tick number
		# This tells the UI: "This move happened on Tick 5, not Tick 99"
		for t in tick_transitions:
			t["tick_id"] = tick_count # tick_count comes from run_tick()
			batch_history.append(t)
			
	return batch_history
	
# Add this to simulation_manager.gd
func update_direction(index: int, new_dir: int):
	if index < grid_state.size():
		grid_state[index]["dir"] = new_dir
		print("Backend: Slot ", index, " rotated to ", new_dir)
