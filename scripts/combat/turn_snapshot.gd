extends RefCounted
## One stable pre-turn checkpoint. No mutable state or inventory aliases are saved.
const State = preload("res://scripts/combat/combat_state.gd")
const Board = preload("res://scripts/board/board_model.gd")

var combat_values: Dictionary = {}
var board_cells: Array[int] = []
var rng_seed: int
var rng_state: int
var herbs: int
var bandages: int
var next_step: int


func capture(state: State, board: Board, step: int) -> void:
	# Include every current scalar combat/ability field, including future scalar flags.
	for property: Dictionary in state.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and property.name != "run_inventory":
			var value: Variant = state.get(property.name)
			assert(typeof(value) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING], "Extend snapshot explicitly for new compound combat state")
			combat_values[property.name] = value
	board_cells = board.cells.duplicate()
	rng_seed = board.rng.seed
	rng_state = board.rng.state
	herbs = state.run_inventory.herbs
	bandages = state.run_inventory.bandages
	next_step = step


func restore(state: State, board: Board) -> void:
	board.cells = board_cells.duplicate()
	board.rng.seed = rng_seed
	board.rng.state = rng_state
	for key: String in combat_values:
		state.set(key, combat_values[key])
	# Retain the run-owned inventory object's identity for other adapters.
	state.run_inventory.herbs = herbs
	state.run_inventory.bandages = bandages
