extends RefCounted
## Application boundary: validates input and advances each phase exactly once.
const Board = preload("res://scripts/board/board_model.gd")
const State = preload("res://scripts/combat/combat_state.gd")
const Rules = preload("res://scripts/combat/combat_rules.gd")
const Inventory = preload("res://scripts/combat/run_inventory.gd")

var board: Board
var state: State
var pending: Board.SwapResult
var next_step: int = 0


func _init(seed_value: int = 1, inventory: Inventory = null) -> void:
	board = Board.new(seed_value)
	state = State.new(inventory)


func begin_swap(a: Vector2i, b: Vector2i) -> Board.SwapResult:
	if state.phase != State.Phase.PLAYER_INPUT:
		return Board.SwapResult.new()
	var result: Board.SwapResult = board.try_swap(a, b)
	if result.valid:
		pending = result
		next_step = 0
		state.valid_swaps += 1
		state.phase = State.Phase.RESOLVING_BOARD
	return result


func resolve_next_step() -> Array[Dictionary]:
	var reports: Array[Dictionary] = []
	if state.phase != State.Phase.RESOLVING_BOARD or pending == null or next_step >= pending.steps.size():
		return reports
	state.phase = State.Phase.RESOLVING_EFFECTS
	var step: Board.CascadeStep = pending.steps[next_step]
	# Stable row-major order of disjoint groups, independent of detection orientation.
	var groups: Array[Board.MatchGroup] = step.matches.duplicate()
	groups.sort_custom(func(a: Board.MatchGroup, b: Board.MatchGroup) -> bool: return a.cells[0] < b.cells[0])
	for group: Board.MatchGroup in groups:
		var report: Dictionary = Rules.apply_match(state, group)
		report["cascade"] = step.index
		reports.append(report)
	next_step += 1
	# Finish all simultaneous groups, then stop immediately on lethal damage.
	if state.enemy_hp == 0:
		_end(State.Phase.VICTORY)
	else:
		state.phase = State.Phase.RESOLVING_BOARD
	return reports


func finish_player_resolution() -> void:
	if state.phase == State.Phase.RESOLVING_BOARD and pending != null and next_step == pending.steps.size():
		state.phase = State.Phase.POST_MATCH


func can_shield_bash() -> bool:
	return Rules.can_shield_bash(state)


func activate_shield_bash() -> Dictionary:
	var report: Dictionary = Rules.shield_bash(state)
	if report.valid and state.enemy_hp == 0:
		_end(State.Phase.VICTORY)
	return report


func end_turn() -> bool:
	if state.phase != State.Phase.POST_MATCH:
		return false
	state.phase = State.Phase.ENEMY_ACTION
	return true


func execute_enemy_action() -> Dictionary:
	if state.phase != State.Phase.ENEMY_ACTION:
		return {}
	var report: Dictionary = Rules.enemy_attack(state)
	state.enemy_actions += 1
	pending = null
	if state.player_hp == 0:
		_end(State.Phase.DEFEAT)
	else:
		state.turn += 1
		state.enemy_intent = 5 if state.enemy_actions % 2 == 0 else 8
		state.phase = State.Phase.PLAYER_INPUT
	return report


func _end(phase: State.Phase) -> void:
	state.phase = phase
	state.guard = 0
	state.ward = 0
	pending = null
