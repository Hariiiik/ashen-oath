extends SceneTree

const Board = preload("res://scripts/board/board_model.gd")
const State = preload("res://scripts/combat/combat_state.gd")
const Rules = preload("res://scripts/combat/combat_rules.gd")
const Combat = preload("res://scripts/combat/combat_controller.gd")
const Inventory = preload("res://scripts/combat/run_inventory.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _group(tile: int, length: int, first: int = 0) -> Board.MatchGroup:
	var group := Board.MatchGroup.new()
	group.tile = tile
	group.longest_run = length
	for i: int in range(length):
		group.cells.append(first + i)
	return group


func _fixture(combat: Combat, steps: Array[Board.CascadeStep]) -> void:
	combat.pending = Board.SwapResult.new()
	combat.pending.valid = true
	combat.pending.steps = steps
	combat.next_step = 0
	combat.state.phase = State.Phase.RESOLVING_BOARD


func _step(groups: Array[Board.MatchGroup], index: int = 0) -> Board.CascadeStep:
	var step := Board.CascadeStep.new()
	step.index = index
	step.matches = groups
	return step


func _test_full_encounter() -> void:
	# Complete an unmodified default encounter using only legal board swaps.
	var combat := Combat.new(1)
	for turn_index: int in range(30):
		if combat.state.is_finished():
			break
		var best: Vector4i = combat.board.legal_moves()[0]
		var best_damage: int = -1
		for move: Vector4i in combat.board.legal_moves():
			var probe := Board.new(1)
			probe.cells = combat.board.cells.duplicate()
			probe.rng.state = combat.board.rng.state
			var preview := probe.try_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w))
			var damage: int = 0
			for step: Board.CascadeStep in preview.steps:
				for group: Board.MatchGroup in step.matches:
					if group.tile == Board.Tile.SWORD:
						damage += [6, 12, 18][group.rank - 3]
			if damage > best_damage:
				best_damage = damage
				best = move
		var result := combat.begin_swap(Vector2i(best.x, best.y), Vector2i(best.z, best.w))
		_check(result.valid, "Full encounter uses legal swaps only")
		for step: Board.CascadeStep in result.steps:
			if combat.state.is_finished():
				break
			combat.resolve_next_step()
		combat.finish_player_resolution()
		combat.end_turn()
		combat.execute_enemy_action()
	_check(combat.state.phase == State.Phase.VICTORY and combat.state.player_hp > 0, "Default encounter is winnable without altering combat state")
	print("Default encounter: victory in %d swaps, %d HP remaining" % [combat.state.valid_swaps, combat.state.player_hp])


func _run() -> void:
	for length: int in [3, 4, 5, 6, 7]:
		var tier: int = mini(length, 5) - 3
		for tile: int in range(4):
			var state := State.new()
			var report: Dictionary = Rules.apply_match(state, _group(tile, length))
			_check(report.rank == mini(length, 5), "Match rank including 5+")
			match tile:
				Board.Tile.SWORD:
					_check(state.enemy_hp == 40 - [6, 12, 18][tier], "Sword testing damage")
					_check(report.critical == (tier > 0) and report.ignores_armor == (tier == 2), "Critical and armor bypass")
				Board.Tile.SHIELD:
					_check(state.guard == (6 if tier == 0 else 0), "Shield Guard selection")
					_check(state.ward == ([0, 8, 12][tier]), "Shield Ward selection")
				Board.Tile.HERB:
					_check(state.run_inventory.herbs == [1, 2, 3][tier], "Herb reward")
					_check(state.player_hp == state.player_max_hp, "Herbs never automatically heal")
				Board.Tile.ACTION:
					_check(state.ap == [2, 3, 5][tier], "Action reward")
	var state := State.new()
	state.enemy_armor = 4
	Rules.apply_match(state, _group(Board.Tile.SWORD, 3))
	Rules.apply_match(state, _group(Board.Tile.SWORD, 5))
	_check(state.enemy_hp == 20, "M3 respects armor, M5 bypasses it")
	state = State.new()
	state.player_hp = 30
	state.herb_budget = 2
	Rules.apply_match(state, _group(Board.Tile.HERB, 5))
	Rules.apply_match(state, _group(Board.Tile.HERB, 4))
	_check(state.run_inventory.herbs == 2 and state.herb_budget == 0 and state.player_hp == 30, "Herb budget cap, exhausted matches and no healing")
	var next_encounter := State.new(state.run_inventory)
	_check(next_encounter.run_inventory.herbs == 2 and next_encounter.herb_budget == 10, "Herbs persist in shared run memory, encounter budget resets")
	Rules.apply_match(state, _group(Board.Tile.ACTION, 5))
	Rules.apply_match(state, _group(Board.Tile.ACTION, 5))
	_check(state.ap == 6, "Stored AP cap")
	state = State.new()
	state.guard = 3
	state.ward = 4
	state.enemy_intent = 8
	var attack: Dictionary = Rules.enemy_attack(state)
	_check(attack.guard == 3 and attack.ward == 4 and attack.hp == 1, "Guard -> Ward -> HP priority")
	_check(state.player_hp == 99 and state.guard == 0 and state.ward == 0, "Damage deducted")
	state.guard = 10
	state.ward = 9
	state.enemy_intent = 5
	Rules.enemy_attack(state)
	_check(state.guard == 0 and state.ward == 9, "Unused Guard expires while Ward persists")
	Rules.enemy_attack(state)
	_check(state.ward == 4 and state.player_hp == 99, "Ward consumed before HP on later attack")
	var combat := Combat.new()
	_check(combat.state.enemy_intent == 5 and combat.state.turn == 1, "Initial enemy intent and turn")
	var original: Array[int] = combat.board.cells.duplicate()
	combat.begin_swap(Vector2i.ZERO, Vector2i(6, 6))
	_check(combat.state.valid_swaps == 0 and combat.state.turn == 1 and combat.state.phase == State.Phase.PLAYER_INPUT and combat.board.cells == original, "Invalid swap preserves turn and board")
	_check(combat.execute_enemy_action().is_empty(), "Enemy cannot act during input")
	_fixture(combat, [_step([_group(Board.Tile.ACTION, 3)])])
	combat.finish_player_resolution()
	_check(combat.state.phase == State.Phase.RESOLVING_BOARD, "Cannot skip unresolved cascade")
	combat.resolve_next_step()
	_check(combat.resolve_next_step().is_empty() and combat.state.ap == 2, "Step cannot apply twice")
	combat.finish_player_resolution()
	_check(combat.state.phase == State.Phase.POST_MATCH, "All steps complete before player decision phase")
	_check(combat.execute_enemy_action().is_empty(), "No retaliation before explicit End Turn")
	combat.end_turn()
	combat.execute_enemy_action()
	_check(combat.state.enemy_intent == 8 and combat.state.turn == 2 and combat.state.player_hp == 95, "First retaliation and next intent")
	_fixture(combat, [_step([_group(Board.Tile.ACTION, 3)])])
	combat.resolve_next_step()
	combat.finish_player_resolution()
	combat.end_turn()
	combat.execute_enemy_action()
	_check(combat.state.enemy_intent == 5 and combat.state.turn == 3 and combat.state.player_hp == 87, "Alternating 5/8 attacks")
	combat = Combat.new()
	combat.state.enemy_hp = 1
	combat.state.ward = 8
	# Deliberately reversed groups: controller processes row-major, all within lethal step.
	_fixture(combat, [_step([_group(Board.Tile.HERB, 3, 10), _group(Board.Tile.SWORD, 3)]), _step([_group(Board.Tile.ACTION, 5)], 1)])
	var reports: Array[Dictionary] = combat.resolve_next_step()
	_check(reports.size() == 2 and reports[0].tile == Board.Tile.SWORD and combat.state.run_inventory.herbs == 1, "Deterministic order and all simultaneous groups resolve")
	_check(combat.state.phase == State.Phase.VICTORY and combat.state.ward == 0, "Victory clears Ward")
	combat.finish_player_resolution()
	_check(combat.execute_enemy_action().is_empty() and combat.state.player_hp == 100 and combat.state.enemy_actions == 0, "Victory prevents retaliation")
	_check(combat.resolve_next_step().is_empty() and combat.state.ap == 0, "No later cascade effects after lethal step")
	original = combat.board.cells.duplicate()
	var move: Vector4i = combat.board.legal_moves()[0]
	_check(not combat.begin_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w)).valid and combat.board.cells == original, "Victory blocks board input")
	combat = Combat.new()
	combat.state.player_hp = 1
	combat.state.ward = 1
	combat.state.phase = State.Phase.ENEMY_ACTION
	combat.execute_enemy_action()
	_check(combat.state.phase == State.Phase.DEFEAT and combat.state.player_hp == 0 and combat.state.ward == 0, "Defeat clamps HP and clears Ward")
	_check(not combat.begin_swap(Vector2i.ZERO, Vector2i.RIGHT).valid, "Defeat blocks input")
	var saw_cascades: bool = false
	for seed_value: int in range(40):
		combat = Combat.new(seed_value)
		combat.state.enemy_hp = 1000
		combat.state.enemy_max_hp = 1000
		move = combat.board.legal_moves()[0]
		var result := combat.begin_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w))
		_check(result.valid and combat.state.valid_swaps == 1 and combat.state.phase == State.Phase.RESOLVING_BOARD, "Real board starts one combat turn")
		_check(not combat.begin_swap(Vector2i.ZERO, Vector2i.RIGHT).valid, "Controller rejects input while resolving")
		var expected_damage: int = 0
		var expected_guard: int = 0
		var expected_ward: int = 0
		var expected_herbs: int = 0
		var expected_ap: int = 0
		for step: Board.CascadeStep in result.steps:
			var seen: Dictionary = {}
			for group: Board.MatchGroup in step.matches:
				for cell: int in group.cells:
					_check(not seen.has(cell), "No duplicated cells delivered to combat")
					seen[cell] = true
				var tier: int = group.rank - 3
				match group.tile:
					Board.Tile.SWORD: expected_damage += [6, 12, 18][tier]
					Board.Tile.SHIELD:
						if tier == 0: expected_guard += 6
						else: expected_ward += [0, 8, 12][tier]
					Board.Tile.HERB: expected_herbs += [1, 2, 3][tier]
					Board.Tile.ACTION: expected_ap += [2, 3, 5][tier]
			reports = combat.resolve_next_step()
			_check(reports.size() == step.matches.size(), "One immediate effect per distinct match group")
		_check(combat.state.enemy_hp == 1000 - expected_damage and combat.state.guard == expected_guard and combat.state.ward == expected_ward, "All cascade combat effects exactly once")
		_check(combat.state.run_inventory.herbs == mini(10, expected_herbs) and combat.state.ap == mini(6, expected_ap), "All cascade resource effects capped")
		combat.finish_player_resolution()
		combat.end_turn()
		combat.execute_enemy_action()
		_check(combat.state.turn == 2 and combat.state.enemy_actions == 1 and combat.state.valid_swaps == 1, "Cascades/AP never buy extra swaps or enemy actions")
		saw_cascades = saw_cascades or result.steps.size() > 1
	_check(saw_cascades, "Real board test includes multiple cascades")
	# Real overlapping cross: merged nine cells must yield one M5 effect, not two.
	combat = Combat.new()
	for y: int in range(7):
		for x: int in range(7):
			combat.board.cells[y * 7 + x] = (x + y) % 4
	for i: int in range(1, 6):
		combat.board.cells[3 * 7 + i] = Board.Tile.SWORD
		combat.board.cells[i * 7 + 3] = Board.Tile.SWORD
	_fixture(combat, [_step(combat.board.find_matches())])
	reports = combat.resolve_next_step()
	_check(reports.size() == 1 and reports[0].cells.size() == 9 and combat.state.enemy_hp == 22, "Cross receives one deduplicated Match-5 effect")
	_test_full_encounter()
	print("Combat tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
