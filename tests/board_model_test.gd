extends SceneTree

const Board = preload("res://scripts/board/board_model.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _latin(board: Board) -> void:
	board.cells.clear()
	for y: int in range(7):
		for x: int in range(7):
			board.cells.append((x + y) % 4)


func _run() -> void:
	var board := Board.new(42)
	for length: int in [3, 4, 5, 6, 7]:
		for vertical: bool in [false, true]:
			_latin(board)
			for i: int in range(length):
				board.cells[i * 7 if vertical else i] = 0
			if length < 7:
				board.cells[length * 7 if vertical else length] = 1
			var groups := board.find_matches()
			_check(groups.size() == 1, "One straight match expected")
			_check(groups[0].longest_run == length and groups[0].rank == mini(length, 5), "Match length/rank")
			_check(groups[0].cells.size() == length and groups[0].tile == 0, "Match cells/type")
	_latin(board)
	for i: int in range(1, 6):
		board.cells[3 * 7 + i] = 0
		board.cells[i * 7 + 3] = 0
	var seen: Array[int] = []
	for group: Board.MatchGroup in board.find_matches():
		for cell: int in group.cells:
			_check(cell not in seen, "Overlapping matches must be deduplicated")
			seen.append(cell)
	_check(seen.size() == 9, "Cross contains nine unique cells")
	_latin(board)
	_check(board.find_matches().is_empty(), "Latin fixture must be stable")
	_check(not board.has_legal_move(), "Latin fixture must be dead")
	var histogram: Array[int] = board.cells.duplicate()
	histogram.sort()
	_check(board.ensure_playable(), "Dead board reshuffled")
	var after: Array[int] = board.cells.duplicate()
	after.sort()
	_check(histogram == after, "Normal reshuffle preserves tile counts")
	_check(board.find_matches().is_empty() and board.has_legal_move(), "Reshuffle stable and playable")
	var playable: Array[int] = board.cells.duplicate()
	_check(not board.ensure_playable() and board.cells == playable, "Playable board unchanged")
	# Every column has holes, with survivor order known before collapse.
	var survivors: Array = []
	for x: int in range(7):
		var column: Array[int] = []
		for y: int in range(7):
			board.cells[y * 7 + x] = Board.EMPTY if y % 2 == 0 else (x + y) % 4
			if board.cells[y * 7 + x] != Board.EMPTY:
				column.append(board.cells[y * 7 + x])
		survivors.append(column)
	board.gravity_and_refill()
	for x: int in range(7):
		for i: int in range(3):
			_check(board.cells[(4 + i) * 7 + x] == survivors[x][i], "Gravity preserves survivor order")
	for tile: int in board.cells:
		_check(tile >= 0 and tile < 4, "Refill fills every hole with a base tile")
	var saw_cascade: bool = false
	for seed_value: int in range(40):
		board = Board.new(seed_value)
		var twin := Board.new(seed_value)
		_check(board.cells == twin.cells, "Seed reproducibility")
		_check(board.find_matches().is_empty(), "No initial matches")
		_check(board.has_legal_move(), "Initial legal move")
		var original: Array[int] = board.cells.duplicate()
		var rng_state: int = board.rng.state
		_check(not board.try_swap(Vector2i(-1, 0), Vector2i.ZERO).valid, "Out-of-range swap rejected")
		_check(not board.try_swap(Vector2i.ZERO, Vector2i(1, 1)).valid, "Diagonal rejected")
		_check(not board.try_swap(Vector2i.ZERO, Vector2i(2, 0)).valid, "Distant swap rejected")
		var tested_invalid: bool = false
		for y: int in range(7):
			for x: int in range(6):
				var a := Vector2i(x, y)
				var b := a + Vector2i.RIGHT
				if not tested_invalid and not board.is_valid_swap(a, b):
					_check(not board.try_swap(a, b).valid, "Nonmatching swap rejected")
					tested_invalid = true
		_check(tested_invalid and board.cells == original and board.rng.state == rng_state, "Invalid swap rollback preserves board and RNG")
		var move: Vector4i = board.legal_moves()[0]
		var result := board.try_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w))
		var replay := twin.try_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w))
		_check(result.valid and not result.steps.is_empty(), "Valid swap resolves")
		_check(board.cells == twin.cells and result.steps.size() == replay.steps.size(), "Seeded refill/cascade reproducibility")
		for step: Board.CascadeStep in result.steps:
			_check(step.index < result.steps.size() and step.removed.size() >= 3, "Structured cascade step")
			var unique: Dictionary = {}
			for group: Board.MatchGroup in step.matches:
				for cell: int in group.cells:
					_check(not unique.has(cell), "No double-resolved tiles")
					unique[cell] = true
			_check(unique.size() == step.removed.size(), "Removed cells equal match union")
			for cell: int in step.removed:
				_check(step.cleared[cell] == Board.EMPTY, "Matched tiles removed")
			saw_cascade = saw_cascade or step.index > 0
		_check(board.find_matches().is_empty() and board.has_legal_move(), "Resolution leaves stable playable board")
	_check(saw_cascade, "At least one seeded move exercises multiple cascades")
	print("Board tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
