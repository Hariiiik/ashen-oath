extends RefCounted
## Pure deterministic board logic. Coordinates are (column, row), storage row-major.

enum Tile { SWORD, SHIELD, HERB, ACTION }
const SIZE: int = 7
const EMPTY: int = -1

class MatchGroup extends RefCounted:
	var tile: int
	var cells: Array[int] = []
	var longest_run: int
	# Diagnostic metadata only; reward classification still uses longest_run.
	var runs: Array[Dictionary] = []
	# 5 represents Match-5+, not a deferred special tile.
	var rank: int:
		get:
			return mini(longest_run, 5)

class CascadeStep extends RefCounted:
	var index: int
	var matches: Array[MatchGroup] = []
	var removed: Array[int] = []
	var cleared: Array[int] = []
	var refilled: Array[int] = []

class SwapResult extends RefCounted:
	var valid: bool = false
	var swapped: Array[int] = []
	var steps: Array[CascadeStep] = []
	var reshuffled: bool = false
	var final_cells: Array[int] = []

var cells: Array[int] = []
var rng := RandomNumberGenerator.new()


func _init(board_seed: int = 1) -> void:
	rng.seed = board_seed
	generate()


func generate() -> void:
	for attempt: int in range(256):
		cells.clear()
		for y: int in range(SIZE):
			for x: int in range(SIZE):
				var choices: Array[int] = []
				for kind: int in range(4):
					if x >= 2 and cells[y * SIZE + x - 1] == kind and cells[y * SIZE + x - 2] == kind:
						continue
					if y >= 2 and cells[(y - 1) * SIZE + x] == kind and cells[(y - 2) * SIZE + x] == kind:
						continue
					choices.append(kind)
				cells.append(choices[rng.randi_range(0, choices.size() - 1)])
		if has_legal_move():
			return
	# Guaranteed stable, playable fallback; no unbounded generation loop.
	cells.clear()
	for y: int in range(SIZE):
		for x: int in range(SIZE):
			cells.append((x + y) % 4)
	cells[2] = Tile.SWORD
	cells[SIZE + 1] = Tile.SWORD


func _inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < SIZE and p.y < SIZE


func _exchange(a: int, b: int) -> void:
	var old: int = cells[a]
	cells[a] = cells[b]
	cells[b] = old


func is_valid_swap(a: Vector2i, b: Vector2i) -> bool:
	if not _inside(a) or not _inside(b) or absi(a.x - b.x) + absi(a.y - b.y) != 1:
		return false
	var ai: int = a.y * SIZE + a.x
	var bi: int = b.y * SIZE + b.x
	if cells[ai] == cells[bi]:
		return false
	_exchange(ai, bi)
	var valid: bool = false
	for group: MatchGroup in find_matches():
		if ai in group.cells or bi in group.cells:
			valid = true
			break
	_exchange(ai, bi)
	return valid


func legal_moves() -> Array[Vector4i]:
	var moves: Array[Vector4i] = []
	for y: int in range(SIZE):
		for x: int in range(SIZE):
			for delta: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var a := Vector2i(x, y)
				var b: Vector2i = a + delta
				if is_valid_swap(a, b):
					moves.append(Vector4i(a.x, a.y, b.x, b.y))
	return moves


func has_legal_move() -> bool:
	for y: int in range(SIZE):
		for x: int in range(SIZE):
			var a := Vector2i(x, y)
			if is_valid_swap(a, a + Vector2i.RIGHT) or is_valid_swap(a, a + Vector2i.DOWN):
				return true
	return false


func find_matches() -> Array[MatchGroup]:
	var groups: Array[MatchGroup] = []
	for vertical: bool in [false, true]:
		for line: int in range(SIZE):
			var start: int = 0
			while start < SIZE:
				var first: int = start * SIZE + line if vertical else line * SIZE + start
				var kind: int = cells[first]
				var end: int = start + 1
				while end < SIZE:
					var next: int = end * SIZE + line if vertical else line * SIZE + end
					if cells[next] != kind:
						break
					end += 1
				if kind != EMPTY and end - start >= 3:
					var group := MatchGroup.new()
					group.tile = kind
					group.longest_run = end - start
					for pos: int in range(start, end):
						group.cells.append(pos * SIZE + line if vertical else line * SIZE + pos)
					group.runs.append({"orientation": "vertical" if vertical else "horizontal", "length": end - start, "cells": group.cells.duplicate()})
					# Merge every intersecting run, including bridges between groups.
					for i: int in range(groups.size() - 1, -1, -1):
						var intersects: bool = false
						for cell: int in groups[i].cells:
							if cell in group.cells:
								intersects = true
								break
						if intersects:
							group.runs.append_array(groups[i].runs)
							group.longest_run = maxi(group.longest_run, groups[i].longest_run)
							for cell: int in groups[i].cells:
								if cell not in group.cells:
									group.cells.append(cell)
							groups.remove_at(i)
					group.cells.sort()
					groups.append(group)
				start = end
	return groups


func gravity_and_refill() -> void:
	for x: int in range(SIZE):
		var write: int = SIZE - 1
		for y: int in range(SIZE - 1, -1, -1):
			if cells[y * SIZE + x] != EMPTY:
				cells[write * SIZE + x] = cells[y * SIZE + x]
				write -= 1
		for y: int in range(write, -1, -1):
			cells[y * SIZE + x] = rng.randi_range(0, 3)


func ensure_playable() -> bool:
	if not find_matches().is_empty() or has_legal_move():
		return false
	var original: Array[int] = cells.duplicate()
	for attempt: int in range(256):
		cells = original.duplicate()
		for i: int in range(cells.size() - 1, 0, -1):
			_exchange(i, rng.randi_range(0, i))
		if find_matches().is_empty() and has_legal_move():
			return true
	# Pathological tile distributions may not permit a stable permutation.
	generate()
	return true


func try_swap(a: Vector2i, b: Vector2i) -> SwapResult:
	var result := SwapResult.new()
	if not is_valid_swap(a, b):
		result.final_cells = cells.duplicate()
		return result
	result.valid = true
	_exchange(a.y * SIZE + a.x, b.y * SIZE + b.x)
	result.swapped = cells.duplicate()
	var matches: Array[MatchGroup] = find_matches()
	while not matches.is_empty():
		var step := CascadeStep.new()
		step.index = result.steps.size()
		step.matches = matches
		for group: MatchGroup in matches:
			for cell: int in group.cells:
				if cell not in step.removed:
					step.removed.append(cell)
		for cell: int in step.removed:
			cells[cell] = EMPTY
		step.cleared = cells.duplicate()
		gravity_and_refill()
		step.refilled = cells.duplicate()
		result.steps.append(step)
		matches = find_matches()
	result.reshuffled = ensure_playable()
	result.final_cells = cells.duplicate()
	return result


static func diagnostic_positions(indices: Array[int]) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for cell: int in indices:
		positions.append(Vector2i(cell % SIZE, floori(cell / float(SIZE))))
	return positions


static func describe_group(group: MatchGroup) -> Dictionary:
	var runs: Array[Dictionary] = []
	var raw_count: int = 0
	for run: Dictionary in group.runs:
		var indices: Array[int] = run.cells
		raw_count += indices.size()
		runs.append({"orientation": run.orientation, "length": run.length, "positions": diagnostic_positions(indices)})
	return {"group_id": group.cells[0] if not group.cells.is_empty() else -1, "tile": Tile.keys()[group.tile], "rank": group.rank, "longest_run": group.longest_run, "unique_count": group.cells.size(), "positions": diagnostic_positions(group.cells), "raw_runs": runs, "shared_run_cells": maxi(0, raw_count - group.cells.size())}


static func describe_step(step: CascadeStep) -> Dictionary:
	var groups: Array[Dictionary] = []
	var unique: Array[int] = []
	var count: int = 0
	for group: MatchGroup in step.matches:
		groups.append(describe_group(group))
		for cell: int in group.cells:
			count += 1
			if cell not in unique:
				unique.append(cell)
	unique.sort()
	return {"cascade": step.index, "groups": groups, "unique_positions": diagnostic_positions(unique), "unique_count": unique.size(), "duplicate_group_cells": count - unique.size(), "cleared": step.cleared.duplicate(), "refilled": step.refilled.duplicate()}
