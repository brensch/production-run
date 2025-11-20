class_name RuleEngine

# The Registry of Logic
static var library = {
	"Drill": Callable(RuleEngine, "_logic_drill"),
	"Smelter": Callable(RuleEngine, "_logic_smelter"),
	"Exporter": Callable(RuleEngine, "_logic_exporter")
}

# THE MAIN LOOP
static func calculate_tick(current_state: Array, width: int, height: int, tick_num: int) -> Array:
	var transitions = []
	
	# 1. Create the Immutable Context (The Snapshot)
	var context = SimulationContext.new()
	context.grid_snapshot = current_state.duplicate(true) # Deep copy is crucial!
	context.grid_width = width
	context.grid_height = height
	context.current_tick = tick_num
	
	# 2. Ask every machine what it wants to do
	for i in range(current_state.size()):
		var slot = context.grid_snapshot[i]
		if slot["type"] == "Empty": continue
		
		if library.has(slot["type"]):
			var logic_func = library[slot["type"]]
			
			# --- THE CONTRACT ---
			# Input: My State + The World Context + My Location
			# Output: Array of Transitions (What changed)
			var result = logic_func.call(slot, context, i)
			
			if result:
				transitions.append_array(result)
				
	return transitions

# --- MACHINE IMPLEMENTATIONS ---

# CASE A: Local Logic (Only cares about neighbors)
static func _logic_belt(me, ctx: SimulationContext, index: int) -> Array:
	var moves = []
	if me["inventory"] > 0:
		# Calculate target based on my rotation (dir)
		var target_idx = ctx.get_neighbor_index(index, me.get("dir", 1)) # Default Right
		
		if target_idx != -1:
			# Plan the move
			moves.append({
				"op": "move",
				"from": index,
				"to": target_idx,
				"amount": me["inventory"] # Move everything
			})
	return moves

# CASE C: Producer Logic
static func _logic_drill(me, ctx: SimulationContext, index: int) -> Array:
	var transitions = []
	
	# 1. PRODUCTION: Always make more ore (add to self)
	transitions.append({ 
		"op": "create", 
		"at": index, 
		"item": "ore", 
		"amount": 1 
	})
	
	# 2. OUTPUT: If I have ore (from a previous tick), try to push it
	if me["inventory"] > 0:
		# Get neighbor based on my direction (Defaults to 1=Right)
		var dir = me.get("dir", 1)
		var target_idx = ctx.get_neighbor_index(index, dir)
		
		if target_idx != -1:
			transitions.append({
				"op": "move",
				"from": index,
				"to": target_idx,
				"amount": 1 # Rate limit: Output 1 per tick
			})
			
	return transitions
	
static func _logic_smelter(me, ctx: SimulationContext, index: int) -> Array:
	var transitions = []
	
	# 1. PROCESS: If I have items, I should try to move them out
	# (In the future, you'd check if input == "Ore" -> transform to "Bar")
	
	if me["inventory"] > 0:
		# Get neighbor to the Right (default dir=1)
		var dir = me.get("dir", 1) 
		var target_idx = ctx.get_neighbor_index(index, dir)
		
		if target_idx != -1:
			transitions.append({
				"op": "move",
				"from": index,
				"to": target_idx,
				"amount": 1 
			})
			
	return transitions

static func _logic_exporter(me, ctx: SimulationContext, index: int) -> Array:
	if me["inventory"] > 0:
		return [{ "op": "score", "amount": me["inventory"] * 10, "source": index }]
	return []
