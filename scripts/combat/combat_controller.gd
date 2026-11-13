extends RefCounted
## Application boundary: validates input and advances each phase exactly once.
const Board = preload("res://scripts/board/board_model.gd")
const State = preload("res://scripts/combat/combat_state.gd")
const Rules = preload("res://scripts/combat/combat_rules.gd")
const Inventory = preload("res://scripts/combat/run_inventory.gd")
const Snapshot = preload("res://scripts/combat/turn_snapshot.gd")

var board: Board
var state: State
var pending: Board.SwapResult
var next_step: int = 0
var developer_tools_enabled: bool = OS.is_debug_build()
var diagnostics_enabled: bool = false
var _pre_turn: Snapshot


func _init(seed_value: int = 1, inventory: Inventory = null) -> void:
	board = Board.new(seed_value)
	state = State.new(inventory)


func begin_swap(a: Vector2i, b: Vector2i) -> Board.SwapResult:
	if state.phase != State.Phase.PLAYER_INPUT:
		return Board.SwapResult.new()
	if board.is_valid_swap(a, b):
		_capture_pre_turn()
	_trace("swap_requested", {"a": a, "b": b, "board": board.cells.duplicate(), "rng_seed": str(board.rng.seed), "rng_state": str(board.rng.state), "resources": _resources()})
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
	_trace("cascade", Board.describe_step(step))
	# Stable row-major order of disjoint groups, independent of detection orientation.
	var groups: Array[Board.MatchGroup] = step.matches.duplicate()
	groups.sort_custom(func(a: Board.MatchGroup, b: Board.MatchGroup) -> bool: return a.cells[0] < b.cells[0])
	for group: Board.MatchGroup in groups:
		var before: Dictionary = _resources()
		var report: Dictionary = Rules.apply_match(state, group)
		report["cascade"] = step.index
		reports.append(report)
		_trace("effect", {"cascade": step.index, "group": Board.describe_group(group), "effect": report, "before": before, "after": _resources()})
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
	if can_shield_bash():
		_capture_pre_turn()
	var before: Dictionary = _resources()
	var report: Dictionary = Rules.shield_bash(state)
	_trace("shield_bash", {"effect": report, "before": before, "after": _resources()})
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
	var before: Dictionary = _resources()
	var report: Dictionary = Rules.enemy_attack(state)
	_trace("enemy_action", {"effect": report, "before": before, "after": _resources()})
	state.enemy_actions += 1
	pending = null
	if state.player_hp == 0:
		_end(State.Phase.DEFEAT)
	else:
		state.turn += 1
		state.enemy_intent = 5 if state.enemy_actions % 2 == 0 else 8
		state.phase = State.Phase.PLAYER_INPUT
	return report


func _capture_pre_turn() -> void:
	if not developer_tools_enabled or state.phase != State.Phase.PLAYER_INPUT:
		return
	if _pre_turn != null and int(_pre_turn.combat_values.turn) == state.turn:
		return
	_pre_turn = Snapshot.new()
	_pre_turn.capture(state, board, next_step)


func can_debug_undo() -> bool:
	return developer_tools_enabled and _pre_turn != null and state.phase in [State.Phase.PLAYER_INPUT, State.Phase.POST_MATCH, State.Phase.VICTORY, State.Phase.DEFEAT]


func debug_undo_last_turn() -> bool:
	if not can_debug_undo():
		return false
	_pre_turn.restore(state, board)
	next_step = _pre_turn.next_step
	pending = null
	_pre_turn = null
	_trace("undo", {"board": board.cells.duplicate(), "rng_state": str(board.rng.state), "resources": _resources()})
	return true


func _resources() -> Dictionary:
	return {"hero_hp": state.player_hp, "enemy_hp": state.enemy_hp, "guard": state.guard, "ward": state.ward, "ap": state.ap, "herbs": state.run_inventory.herbs, "budget": state.herb_budget}


func _trace(event: String, detail: Dictionary) -> void:
	if developer_tools_enabled and diagnostics_enabled:
		print("[COMBAT DEBUG] " + JSON.stringify({"event": event, "turn": state.turn, "phase": State.Phase.keys()[state.phase], "detail": detail}))


func _end(phase: State.Phase) -> void:
	state.phase = phase
	state.guard = 0
	state.ward = 0
	pending = null
	_trace("combat_ended", {"resources": _resources()})
