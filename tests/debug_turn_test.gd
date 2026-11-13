extends SceneTree

const Board = preload("res://scripts/board/board_model.gd")
const Combat = preload("res://scripts/combat/combat_controller.gd")
const State = preload("res://scripts/combat/combat_state.gd")
const Rules = preload("res://scripts/combat/combat_rules.gd")
const SCREEN = preload("res://scenes/combat/combat_screen.tscn")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	create_timer(20).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _values(combat: Combat) -> Dictionary:
	var values: Dictionary = {}
	for property: Dictionary in combat.state.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = combat.state.get(property.name)
			values[property.name] = value.herbs if property.name == "run_inventory" else value
	values["board"] = combat.board.cells.duplicate()
	values["seed"] = combat.board.rng.seed
	values["rng"] = combat.board.rng.state
	values["next_step"] = combat.next_step
	return values


func _play(combat: Combat, move: Vector4i, finish: bool = true) -> Array:
	var result := combat.begin_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w))
	var transcript: Array = [result.swapped.duplicate()]
	for step: Board.CascadeStep in result.steps:
		if combat.state.is_finished():
			break
		var reports := combat.resolve_next_step()
		transcript.append([Board.describe_step(step), reports, step.cleared.duplicate(), step.refilled.duplicate()])
	combat.finish_player_resolution()
	if finish:
		combat.end_turn()
		transcript.append(combat.execute_enemy_action())
	transcript.append(_values(combat))
	return transcript


func _latin(board: Board) -> void:
	for y: int in range(7):
		for x: int in range(7):
			board.cells[y * 7 + x] = (x + y) % 4


func _investigate() -> void:
	var board := Board.new()
	_latin(board)
	for cell: int in [17, 23, 24, 25, 31]:
		board.cells[cell] = Board.Tile.SHIELD
	var groups := board.find_matches()
	_check(groups.size() == 1, "Cross is one merged group, not two rewards")
	_check(groups[0].cells == [17, 23, 24, 25, 31] and groups[0].longest_run == 3 and groups[0].rank == 3, "Five-cell cross classified by longest straight run, not union size")
	var step := Board.CascadeStep.new()
	step.matches = groups
	var description := Board.describe_step(step)
	_check(description.unique_count == 5 and description.duplicate_group_cells == 0 and description.groups[0].shared_run_cells == 1, "Diagnostics identify shared raw center and deduplicated output")
	var state := State.new()
	for group: Board.MatchGroup in groups:
		Rules.apply_match(state, group)
	_check(state.guard == 6 and state.ward == 0, "Isolated cross yields 6 Guard, no Ward")
	print("ISOLATED CROSS: " + JSON.stringify(description) + " => Guard +6")
	state.guard = 6
	Rules.apply_match(state, groups[0])
	_check(state.guard == 12, "Existing 6 Guard plus isolated cross also displays 12")
	# Two disconnected M3 groups in the same step legitimately produce 12 Guard.
	_latin(board)
	for cell: int in [0, 1, 2, 46, 47, 48]:
		board.cells[cell] = Board.Tile.SHIELD
	board.cells[45] = Board.Tile.SWORD
	groups = board.find_matches()
	state = State.new()
	for group: Board.MatchGroup in groups:
		Rules.apply_match(state, group)
	_check(groups.size() == 2 and state.guard == 12, "Two distinct Shield M3 groups produce 6 + 6")
	# Find an actual seeded 12-Guard turn without editing combat balance/state.
	var found: bool = false
	for seed_value: int in range(200):
		var combat := Combat.new(seed_value)
		var move: Vector4i = combat.board.legal_moves()[0]
		_play(combat, move, false)
		if combat.state.guard != 12 or combat.pending == null:
			continue
		var shield_steps: Array[int] = []
		for cascade: Board.CascadeStep in combat.pending.steps:
			for group: Board.MatchGroup in cascade.matches:
				if group.tile == Board.Tile.SHIELD and group.rank == 3:
					shield_steps.append(cascade.index)
		print("REAL 12 GUARD: seed=%d swap=%s Shield M3 cascade indices=%s" % [seed_value, move, shield_steps])
		_check(shield_steps.size() == 2, "Real 12 Guard comes from two distinct effects")
		var replay := Combat.new(seed_value)
		replay.diagnostics_enabled = true
		_play(replay, move, false)
		_check(_values(replay) == _values(combat), "Diagnostic logging changes no board, RNG or combat outcome")
		found = true
		break
	_check(found, "Reproducible 12 Guard example found")


func _run() -> void:
	_investigate()
	for seed_value: int in range(20):
		var combat := Combat.new(seed_value)
		combat.state.player_hp = 73
		combat.state.player_max_hp = 111
		combat.state.guard = 8
		combat.state.ward = 13
		combat.state.ap = 6
		combat.state.herb_budget = 2
		combat.state.run_inventory.herbs = 9
		combat.state.enemy_hp = 1000
		combat.state.enemy_max_hp = 1000
		var inventory = combat.state.run_inventory
		var before := _values(combat)
		var move: Vector4i = combat.board.legal_moves()[0]
		combat.activate_shield_bash()
		var first := _play(combat, move)
		_check(combat.can_debug_undo() and combat.debug_undo_last_turn(), "Undo after completed turn")
		_check(before == _values(combat), "Every scalar, board, RNG, HP/Guard/Ward/AP, enemy, intent, herbs/budget, phase and counters restored")
		_check(combat.state.run_inventory == inventory, "Run inventory identity preserved")
		_check(combat.can_shield_bash(), "Ability availability restored from resources/phase")
		_check(not combat.debug_undo_last_turn(), "Only one checkpoint, no multi-step history or redo")
		combat.activate_shield_bash()
		var second := _play(combat, move)
		_check(first == second, "Deterministic replay includes cascades, refills, effects and enemy action")
	var combat := Combat.new(1)
	combat.state.enemy_hp = 1000
	combat.state.enemy_max_hp = 1000
	var move: Vector4i = combat.board.legal_moves()[0]
	var before := _values(combat)
	var result := combat.begin_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w))
	_check(not combat.can_debug_undo() and not combat.debug_undo_last_turn(), "Undo blocked during board resolution")
	combat.state.phase = State.Phase.RESOLVING_EFFECTS
	_check(not combat.debug_undo_last_turn(), "Undo blocked during effects")
	combat.state.phase = State.Phase.RESOLVING_BOARD
	for step: Board.CascadeStep in result.steps:
		combat.resolve_next_step()
	combat.finish_player_resolution()
	_check(combat.state.phase == State.Phase.POST_MATCH and combat.debug_undo_last_turn(), "Undo allowed during post-match decision")
	_check(before == _values(combat) and combat.pending == null, "Undo clears pending resolution and restores pre-swap state")
	# Actually spend herbs budget, AP, Ward and HP before restoring.
	combat = Combat.new(4)
	combat.state.ap = 6
	combat.state.guard = 8
	combat.state.ward = 2
	combat.state.herb_budget = 1
	combat.state.run_inventory.herbs = 7
	before = _values(combat)
	combat.activate_shield_bash()
	var herb := Board.MatchGroup.new()
	herb.tile = Board.Tile.HERB
	herb.longest_run = 5
	Rules.apply_match(combat.state, herb)
	combat.state.phase = State.Phase.POST_MATCH
	combat.end_turn()
	_check(not combat.debug_undo_last_turn(), "Undo blocked during enemy action")
	combat.execute_enemy_action()
	_check(combat.state.herb_budget == 0 and combat.state.run_inventory.herbs == 8 and combat.state.ap == 3 and combat.state.ward == 0 and combat.state.player_hp == 97, "Resources really changed before restoration")
	_check(combat.debug_undo_last_turn() and before == _values(combat), "Restore exhausted herb budget and spent resources")
	# First action of a new turn replaces the one older checkpoint.
	combat = Combat.new(3)
	move = combat.board.legal_moves()[0]
	_play(combat, move)
	before = _values(combat)
	combat.begin_swap(Vector2i.ZERO, Vector2i(6, 6))
	move = combat.board.legal_moves()[0]
	_play(combat, move, false)
	_check(combat.debug_undo_last_turn() and before == _values(combat), "New turn replaces older checkpoint; invalid swap creates none")
	combat = Combat.new(1)
	before = _values(combat)
	move = combat.board.legal_moves()[0]
	_play(combat, move)
	combat.begin_swap(Vector2i.ZERO, Vector2i(6, 6))
	_check(combat.debug_undo_last_turn() and before == _values(combat), "Invalid action on next turn retains previous completed turn's checkpoint")
	for defeat: bool in [false, true]:
		combat = Combat.new(1)
		if defeat:
			combat.state.player_hp = 1
			combat.state.enemy_hp = 1000
			combat.state.enemy_max_hp = 1000
			combat.state.enemy_intent = 1000
			before = _values(combat)
			move = combat.board.legal_moves()[0]
			_play(combat, move)
			_check(combat.state.phase == State.Phase.DEFEAT, "Real defeat reached")
		else:
			combat.state.enemy_hp = 1
			combat.state.guard = 8
			combat.state.ap = 3
			combat.state.ward = 5
			before = _values(combat)
			combat.activate_shield_bash()
			_check(combat.state.phase == State.Phase.VICTORY, "Ability victory reached")
		_check(combat.debug_undo_last_turn() and before == _values(combat), "Undo terminal outcome restores full pre-turn state")
	combat = Combat.new()
	combat.developer_tools_enabled = false
	move = combat.board.legal_moves()[0]
	_play(combat, move, false)
	_check(not combat.can_debug_undo() and not combat.debug_undo_last_turn(), "Release/non-developer mode cannot create or use Undo")
	await _ui_test()
	print("Diagnostics/Undo tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _ui_test() -> void:
	root.size = Vector2i(1280, 720)
	var screen = SCREEN.instantiate()
	screen.debug_match_logging = false
	root.add_child(screen)
	await process_frame
	await process_frame
	var combat: Combat = screen.combat
	_check("DEBUG" in screen.debug_undo_button.text and screen.debug_undo_button.disabled, "Clearly labeled developer button initially unavailable")
	combat.state.guard = 8
	combat.state.ward = 4
	combat.state.ap = 3
	combat.state.enemy_hp = 1
	_latin(combat.board)
	combat.board.cells[2] = Board.Tile.SWORD
	combat.board.cells[8] = Board.Tile.SWORD
	var before := _values(combat)
	screen._sync_state()
	screen.shield_bash_button.pressed.emit()
	_check(combat.state.is_finished() and not screen.debug_undo_button.disabled, "Undo UI enabled after victory")
	var actions: Array = []
	screen.board_resolved.connect(func(result) -> void: actions.append(result))
	screen.debug_undo_button.pressed.emit()
	_check(before == _values(combat) and screen.hero_hp_bar.value == combat.state.player_hp and screen.enemy_hp_bar.value == 1, "UI undo restores state and HP bindings")
	_check(screen.defense_meter.guard == 8 and screen.defense_meter.ward == 4 and screen.ap_meter.amount == 3, "UI defense/AP restored")
	_check(screen.selected == -1 and screen.moves == 0 and not screen.tiles[0].disabled and screen.debug_undo_button.disabled, "UI selection cleared and functional input restored")
	_check(actions.is_empty(), "UI restore emits no gameplay action")
	# Preview timer begins before model resolution: the UI lock still protects Undo.
	screen.shield_bash_button.pressed.emit()
	screen.debug_undo_button.pressed.emit()
	var move := Vector4i(1, 0, 1, 1)
	screen.tiles[move.y * 7 + move.x].pressed.emit()
	screen.tiles[move.w * 7 + move.z].pressed.emit()
	_check(screen.resolving and screen.debug_undo_button.disabled, "Undo disabled during visual preview/resolution")
	screen.debug_undo_button.pressed.emit()
	_check(screen.resolving, "Undo handler cannot interrupt pending animation callback")
	while screen.resolving:
		await process_frame
	_check(not screen.debug_undo_button.disabled, "Undo re-enabled after resolution/terminal result")
	_check(combat.state.phase == State.Phase.VICTORY, "Real board damage reached victory before UI Undo")
	screen.debug_undo_button.pressed.emit()
	_check(before == _values(combat), "UI can undo a lethal board swap")
	screen.queue_free()
	await process_frame
	screen = SCREEN.instantiate()
	screen.debug_match_logging = false
	root.add_child(screen)
	await process_frame
	combat = screen.combat
	combat.state.player_hp = 1
	combat.state.enemy_hp = 1000
	combat.state.enemy_max_hp = 1000
	combat.state.enemy_intent = 1000
	before = _values(combat)
	move = combat.board.legal_moves()[0]
	screen.tiles[move.y * 7 + move.x].pressed.emit()
	screen.tiles[move.w * 7 + move.z].pressed.emit()
	while screen.resolving:
		await process_frame
	screen.end_turn_button.pressed.emit()
	_check(screen.debug_undo_button.disabled, "Undo locked during enemy playback")
	while screen.resolving:
		await process_frame
	_check(combat.state.phase == State.Phase.DEFEAT and not screen.debug_undo_button.disabled, "Undo UI available after defeat")
	screen.debug_undo_button.pressed.emit()
	_check(before == _values(combat) and screen.hero_hp_bar.value == 1 and not screen.tiles[0].disabled, "Defeat Undo restores UI and board input without actions")
	screen.queue_free()
	await process_frame
