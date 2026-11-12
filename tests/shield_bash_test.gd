extends SceneTree

const Combat = preload("res://scripts/combat/combat_controller.gd")
const State = preload("res://scripts/combat/combat_state.gd")
const SCREEN = preload("res://scenes/combat/combat_screen.tscn")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	create_timer(15).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func _snapshot(combat: Combat) -> Dictionary:
	var result: Dictionary = {}
	for property: Dictionary in combat.state.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = combat.state.get(property.name)
			result[property.name] = value.herbs if property.name == "run_inventory" else value
	result["board"] = combat.board.cells.duplicate()
	result["rng"] = combat.board.rng.state
	result["pending"] = combat.pending
	result["step"] = combat.next_step
	return result


func _armed() -> Combat:
	var combat := Combat.new(1)
	combat.state.guard = 8
	combat.state.ap = 6
	combat.state.ward = 5
	return combat


func _run() -> void:
	for phase: int in State.Phase.values():
		if phase in [State.Phase.PLAYER_INPUT, State.Phase.POST_MATCH]:
			continue
		var combat := _armed()
		combat.state.phase = phase
		var before: Dictionary = _snapshot(combat)
		_check(not combat.can_shield_bash(), "Ability forbidden outside player ability windows")
		_check(not combat.activate_shield_bash().valid, "Forbidden phase rejects activation")
		_check(before == _snapshot(combat), "Invalid phase activation changes no combat state or board/RNG")
	for guard_value: int in [0, 8]:
		for ap: int in [0, 1, 2, 3]:
			if guard_value > 0 and ap >= 3:
				continue
			var combat := _armed()
			combat.state.guard = guard_value
			combat.state.ap = ap
			var before: Dictionary = _snapshot(combat)
			_check(not combat.can_shield_bash() and not combat.activate_shield_bash().valid, "Zero Guard or insufficient AP unavailable")
			_check(before == _snapshot(combat), "Invalid resource activation changes no combat state")
	var combat := _armed()
	var report: Dictionary = combat.activate_shield_bash()
	_check(report.valid and report.damage == 8 and report.guard_consumed == 8 and combat.state.enemy_hp == 32, "8 Guard deals 8 physical damage")
	_check(combat.state.guard == 0 and combat.state.ward == 5 and combat.state.ap == 3, "Consumes all Guard and exactly 3 AP, leaves Ward intact")
	_check(combat.state.phase == State.Phase.PLAYER_INPUT and combat.state.valid_swaps == 0 and combat.state.enemy_actions == 0, "Pre-swap ability does not spend a swap/turn")
	combat.state.guard = 6
	report = combat.activate_shield_bash()
	_check(report.valid and combat.state.ap == 0 and combat.state.enemy_hp == 26, "No once-per-turn restriction when Guard is regained")
	combat = _armed()
	combat.state.enemy_armor = 3
	report = combat.activate_shield_bash()
	_check(report.damage == 5 and combat.state.enemy_hp == 35, "Physical damage uses existing armor mitigation without penetration or bonuses")
	combat = _armed()
	combat.activate_shield_bash()
	var move: Vector4i = combat.board.legal_moves()[0]
	var swap := combat.begin_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w))
	_check(swap.valid and combat.state.valid_swaps == 1, "Swap still available after pre-swap Bash")
	var before: Dictionary = _snapshot(combat)
	_check(not combat.activate_shield_bash().valid and before == _snapshot(combat), "Bash cannot interrupt real board resolution")
	combat.finish_player_resolution()
	_check(combat.state.phase == State.Phase.RESOLVING_BOARD, "Cannot enter ability window before every cascade finishes")
	for step in swap.steps:
		combat.resolve_next_step()
	combat.finish_player_resolution()
	_check(combat.state.phase == State.Phase.POST_MATCH, "All cascades lead to a decision window")
	_check(combat.state.enemy_actions == 0 and combat.execute_enemy_action().is_empty(), "Enemy waits for End Turn")
	combat.state.guard = 8
	combat.state.ap = 3
	var ward_before: int = combat.state.ward
	before = _snapshot(combat)
	report = combat.activate_shield_bash()
	_check(report.valid and combat.state.ward == ward_before and combat.state.phase == State.Phase.POST_MATCH, "Post-swap Bash returns to same window and preserves Ward")
	_check(combat.state.valid_swaps == 1 and combat.state.enemy_actions == 0 and combat.state.turn == 1, "Post-swap Bash never advances a turn or grants a swap")
	_check(combat.board.cells == before.board and combat.board.rng.state == before.rng, "Ability leaves board and RNG untouched")
	_check(not combat.begin_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w)).valid, "Second swap forbidden after Bash")
	_check(combat.end_turn() and not combat.end_turn(), "End Turn advances once")
	_check(not combat.can_shield_bash(), "Enemy phase blocks abilities")
	combat.execute_enemy_action()
	_check(combat.state.enemy_actions == 1 and combat.state.turn == 2 and combat.state.phase == State.Phase.PLAYER_INPUT, "Explicit End Turn executes one enemy action and restores swap")
	_check(not combat.end_turn(), "Cannot skip the board swap")
	for phase: int in [State.Phase.PLAYER_INPUT, State.Phase.POST_MATCH]:
		combat = _armed()
		combat.state.phase = phase
		combat.state.enemy_hp = 4
		report = combat.activate_shield_bash()
		_check(report.valid and combat.state.enemy_hp == 0 and combat.state.phase == State.Phase.VICTORY, "Lethal Bash wins immediately in either window")
		_check(combat.execute_enemy_action().is_empty() and not combat.end_turn() and combat.state.enemy_actions == 0, "Lethal Bash never retaliates")
		_check(combat.state.ward == 0, "Existing end-of-combat Ward cleanup is preserved")
	await _ui_test()
	print("Shield Bash tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _ui_test() -> void:
	root.size = Vector2i(1280, 720)
	var screen = SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var combat: Combat = screen.combat
	_check(screen.shield_bash_button.disabled and screen.end_turn_button.disabled, "Initially unavailable ability and End Turn")
	_check(screen.shield_bash_button.tooltip_text == "Consume all Guard to deal equal physical damage. Costs 3 AP.", "Approved tooltip")
	screen.shield_bash_button.mouse_entered.emit()
	_check(screen.ap_meter.preview_cost == 3, "Hover highlights exactly three AP segments")
	screen.shield_bash_button.mouse_exited.emit()
	combat.state.guard = 8
	combat.state.ap = 6
	combat.state.ward = 5
	screen._sync_state()
	_check(not screen.shield_bash_button.disabled, "Live resources enable ability")
	screen.shield_bash_button.pressed.emit()
	_check(combat.state.enemy_hp == 32 and combat.state.ap == 3 and combat.state.ward == 5, "UI activation reaches rules")
	_check("8 Guard consumed" in screen.feedback.text and "8 physical damage" in screen.feedback.text, "Clear ability feedback")
	_check(not screen.tiles[0].disabled, "Pre-swap ability preserves board input")
	var move: Vector4i = combat.board.legal_moves()[0]
	screen.tiles[move.y * 7 + move.x].pressed.emit()
	screen.tiles[move.w * 7 + move.z].pressed.emit()
	_check(screen.shield_bash_button.disabled, "Ability disabled throughout visual swap/resolution")
	for tile: Button in screen.tiles:
		_check(tile.disabled, "Tiles disabled while resolving")
	while screen.resolving:
		await process_frame
	_check(combat.state.phase == State.Phase.POST_MATCH and not screen.end_turn_button.disabled, "UI exposes post-match End Turn")
	for tile: Button in screen.tiles:
		_check(tile.disabled, "Tiles remain disabled in post-match phase")
	var board_before: Array[int] = combat.board.cells.duplicate()
	screen.tiles[0].pressed.emit()
	screen.tiles[1].pressed.emit()
	_check(combat.board.cells == board_before and screen.selected == -1, "Input handler rejects second swap")
	await create_timer(0.6).timeout
	_check(combat.state.enemy_actions == 0 and combat.state.phase == State.Phase.POST_MATCH, "Decision window has no automatic timeout/retaliation")
	combat.state.guard = 8
	combat.state.ap = 3
	screen._sync_state()
	screen.shield_bash_button.pressed.emit()
	_check(combat.state.phase == State.Phase.POST_MATCH and combat.state.enemy_actions == 0, "UI post-match Bash leaves enemy waiting")
	screen.end_turn_button.pressed.emit()
	_check(screen.shield_bash_button.disabled and screen.end_turn_button.disabled, "Enemy action blocks ability and repeated End Turn")
	while screen.resolving:
		await process_frame
	_check(combat.state.turn == 2 and combat.state.enemy_actions == 1 and not screen.tiles[0].disabled, "End Turn restores normal player input after enemy action")
	combat.state.guard = 8
	combat.state.ap = 3
	combat.state.enemy_hp = 1
	screen._sync_state()
	screen.shield_bash_button.pressed.emit()
	_check("VICTORY" in screen.feedback.text and screen.enemy_hp_bar.value == 0, "Ability victory immediately updates UI")
	_check(screen.shield_bash_button.disabled and screen.end_turn_button.disabled and screen.tiles[0].disabled, "Ability victory locks every functional action")
	screen.queue_free()
	await process_frame
