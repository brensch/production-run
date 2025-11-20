class_name SimulationContext
extends RefCounted

# READ-ONLY SNAPSHOTS
var grid_snapshot: Array[Dictionary] # The state of every machine at tick start
var grid_width: int
var grid_height: int
var current_tick: int

# HELPER: Safe access to avoid index-out-of-bounds logic in every machine
func get_slot(index: int) -> Dictionary:
	if index >= 0 and index < grid_snapshot.size():
		return grid_snapshot[index]
	return {} # Return empty dict if invalid

# HELPER: Adjacency Logic (The "Local" view)
func get_neighbor_index(my_index: int, direction: int) -> int:
	# Direction: 0=Up, 1=Right, 2=Down, 3=Left
	var x = my_index % grid_width
	var y = my_index / grid_width
	
	match direction:
		0: y -= 1
		1: x += 1
		2: y += 1
		3: x -= 1
	
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return -1 # Invalid/Off-grid
		
	return y * grid_width + x
