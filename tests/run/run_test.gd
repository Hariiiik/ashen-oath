extends SceneTree

const Run = preload("res://scripts/run/run_controller.gd")
const Encounter = preload("res://scripts/run/encounter_definition.gd")
const Result = preload("res://scripts/run/run_result.gd")
const Combat = preload("res://scripts/combat/combat_controller.gd")
const CombatState = preload("res://scripts/combat/combat_state.gd")
const Inventory = preload("res://scripts/combat/run_inventory.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func _win(combat: Combat) -> void:
	# Test fixture: lethal Guard and exactly the existing approved Bash AP cost.
	combat.state.guard = combat.state.enemy_hp
	combat.state.ap = 3
	_check(combat.activate_shield_bash().valid, "Existing Shield Bash wins test encounter")
	_check(combat.state.phase == CombatState.Phase.VICTORY, "CombatController owns victory")


func _run() -> void:
	_initial_and_invalid_transitions()
	_persistence_and_resets()
	_seed_independence()
	_undo_boundaries()
	_terminal_results()
	print("Run tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _initial_and_invalid_transitions() -> void:
	var run := Run.new()
	_check(not run.can_advance_encounter() and not run.advance_encounter() and run.get_result() == null, "Unstarted run cannot advance or finish")
	var invalid: Array[Encounter] = [null]
	_check(not run.start_run(1, invalid) and run.combat == null, "Null encounter rejects start without beginning combat")
	_check(run.start_run(1), "Default run starts")
	_check(run.state.encounters.size() == 3 and run.state.encounter_index == 0, "Prototype fixed sequence has three encounters")
	_check(run.state.inventory == run.combat.state.run_inventory, "Existing RunInventory is shared by identity")
	_check(run.state.inventory.herbs == 0 and run.state.inventory.bandages == 0, "New run starts fresh without meta inventory")
	_check(run.combat.state.player_hp == 100 and run.get_current_hp() == 100, "Initial HP uses existing prototype default")
	_check(run.combat.state.enemy_hp == 40 and run.combat.state.enemy_intent == 5, "Existing test enemy is reused unchanged")
	var current: Combat = run.combat
	_check(not run.start_run(99) and run.combat == current and run.state.seed == 1, "Start cannot silently discard an existing run")
	for phase: int in CombatState.Phase.values():
		if phase == CombatState.Phase.VICTORY:
			continue
		run.combat.state.phase = phase
		var rng_state: int = run.combat.board.rng.state
		_check(not run.can_advance_encounter() and not run.advance_encounter(), "Only victory permits transition, not phase %d" % phase)
		_check(run.combat == current and run.state.encounter_index == 0 and run.combat.board.rng.state == rng_state, "Rejected transition changes no owner, index or board RNG")
	_check(not run.is_class("Node") and not run.state.is_class("Node"), "Run model has no UI/Node dependency")


func _persistence_and_resets() -> void:
	var inventory := Inventory.new()
	inventory.herbs = 12
	inventory.bandages = 2
	var loadout := RefCounted.new()
	var first := Encounter.new()
	var second := Encounter.new()
	var sequence: Array[Encounter] = [first, second]
	var run := Run.new()
	_check(run.start_run(17, sequence, inventory, loadout), "Explicit sequence accepts run-owned inventory/loadout")
	sequence.clear()
	_check(run.state.encounters.size() == 2, "Caller sequence mutation cannot alter run length")
	run.combat.state.player_max_hp = 120
	run.combat.state.player_hp = 70
	run.combat.state.ap = 2
	_check(run.combat.emergency_craft_bandage().valid and run.combat.use_bandage().valid, "Existing emergency crafting and Bandage operate within run")
	_check(inventory.herbs == 6 and inventory.bandages == 2 and run.get_current_hp() == 82, "Run inventory and authoritative HP reflect crafting/healing")
	_check(run.state.player_hp == 100, "Checkpoint HP is not a second live combat source")
	run.combat.state.herb_budget = 0
	_win(run.combat)
	var retired: Combat = run.combat
	_check(run.can_advance_encounter() and run.get_result() == null, "Intermediate victory awaits explicit continuation, not run completion")
	_check(run.combat == retired and run.state.encounter_index == 0 and run.get_current_hp() == 82, "Victory does not auto advance or heal")
	# Any remaining encounter resources must reset even if a fixture retains them.
	retired.state.guard = 9
	retired.state.ward = 11
	retired.state.ap = 6
	_check(run.advance_encounter(), "Explicit continuation accepts victory")
	_check(run.combat != retired and run.state.encounter_index == 1, "Continuation creates a fresh combat only once")
	_check(run.combat.state.player_hp == 82 and run.combat.state.player_max_hp == 120, "Current HP and max HP carry without restoration")
	_check(run.state.player_hp == 82 and run.state.player_max_hp == 120, "HP checkpoint updates at accepted transition")
	_check(run.combat.state.guard == 0 and run.combat.state.ward == 0 and run.combat.state.ap == 0, "Guard/Ward and provisional AP reset per encounter")
	_check(run.combat.state.herb_budget == 10 and run.combat.state.turn == 1 and run.combat.state.enemy_actions == 0, "Encounter budget and turn/action counters reset")
	_check(run.combat.state.enemy_hp == 40 and run.combat.state.enemy_intent == 5, "Fresh existing enemy begins with announced 5 damage")
	_check(run.state.inventory == inventory and run.combat.state.run_inventory == inventory and inventory.herbs == 6 and inventory.bandages == 2, "Same Herb/Bandage stacks persist through transition")
	_check(run.state.equipment_loadout == loadout, "Optional loadout retains identity without applying bonuses")
	_check(not run.combat.can_debug_undo() and not retired.can_debug_undo() and not retired.debug_undo_last_turn(), "Old and new controllers cannot Undo across encounter boundary")
	_check(not run.advance_encounter() and run.state.encounter_index == 1, "Repeated continue cannot skip a new battle")
	var independent := Run.new()
	independent.start_run(17)
	_check(independent.state.inventory != inventory and independent.state.inventory.herbs == 0, "Separate new run has independent inventory")


func _seed_independence() -> void:
	var first := Run.new()
	var second := Run.new()
	first.start_run(987654)
	second.start_run(987654)
	_check(first.state.encounter_seeds == second.state.encounter_seeds and first.combat.board.cells == second.combat.board.cells, "Seeded run generates reproducible encounter boards")
	var original_seeds: Array[int] = first.state.encounter_seeds.duplicate()
	for index: int in range(30):
		first.combat.board.rng.randi()
	_check(first.state.encounter_seeds == original_seeds, "Extra board RNG draws cannot change future encounter seeds")
	for index: int in range(3):
		_check(first.combat.board.rng.seed == first.state.encounter_seeds[index], "Current board uses its assigned encounter seed")
		_win(first.combat)
		_win(second.combat)
		if index < 2:
			_check(first.advance_encounter() and second.advance_encounter(), "Both seeded runs accept same transition")
			_check(first.combat.board.cells == second.combat.board.cells and first.combat.board.rng.state == second.combat.board.rng.state, "Next board is reproducible regardless of prior board RNG consumption")
	var other := Run.new()
	other.start_run(987655)
	_check(other.state.encounter_seeds != original_seeds, "Different run seed changes encounter seed sequence")


func _undo_boundaries() -> void:
	var run := Run.new()
	run.start_run(51)
	run.combat.state.player_hp = 63
	run.combat.state.run_inventory.herbs = 12
	run.combat.state.ap = 3
	run.combat.state.guard = 40
	var board_before: Array[int] = run.combat.board.cells.duplicate()
	var rng_before: int = run.combat.board.rng.state
	run.combat.emergency_craft_bandage()
	run.combat.activate_shield_bash()
	_check(run.can_advance_encounter() and run.combat.can_debug_undo(), "Victory offers explicit continuation and current encounter Undo")
	_check(run.combat.debug_undo_last_turn(), "Existing Undo can revoke intermediate victory")
	_check(not run.can_advance_encounter() and not run.advance_encounter() and run.get_result() == null, "Revoked victory cannot advance or yield a result")
	_check(run.get_current_hp() == 63 and run.state.inventory.herbs == 12 and run.state.inventory.bandages == 0, "Undo restores authoritative HP and shared inventory without stale run synchronization")
	_check(run.combat.board.cells == board_before and run.combat.board.rng.state == rng_before and run.state.encounter_index == 0, "Undo leaves run index/seeds intact and restores board RNG")
	run.combat.activate_shield_bash()
	_check(run.advance_encounter() and run.get_current_hp() == 63, "Replay victory captures restored current HP at explicit transition")
	# Defeat result is also derived; Undo must reopen the same encounter, not a room.
	var defeated := Run.new()
	defeated.start_run(2)
	defeated.combat.state.player_hp = 1
	defeated.combat.state.run_inventory.herbs = 6
	defeated.combat.emergency_craft_bandage()
	defeated.combat.state.phase = CombatState.Phase.POST_MATCH
	defeated.combat.end_turn()
	defeated.combat.execute_enemy_action()
	_check(defeated.get_result() != null and defeated.get_result().outcome == Result.Outcome.DEFEAT and not defeated.can_advance_encounter(), "Defeat stops the run without another encounter")
	_check(defeated.combat.debug_undo_last_turn() and defeated.get_result() == null, "Undo revokes derived defeat result")
	_check(defeated.get_current_hp() == 1 and defeated.state.inventory.herbs == 6 and defeated.state.inventory.bandages == 0 and defeated.state.encounter_index == 0, "Undo after defeat restores current room resources, not run progression")


func _terminal_results() -> void:
	var only: Array[Encounter] = [Encounter.new()]
	var run := Run.new()
	run.start_run(72, only)
	run.combat.state.player_hp = 47
	run.state.inventory.herbs = 4
	run.state.inventory.bandages = 2
	_win(run.combat)
	var result: Result = run.get_result()
	_check(result != null and result.outcome == Result.Outcome.VICTORY and result.seed == 72, "Last victory yields run result")
	_check(result.encounters_completed == 1 and result.encounters_total == 1 and result.player_hp == 47 and result.player_max_hp == 100, "Result records completion and remaining HP without healing")
	_check(result.herbs == 4 and result.bandages == 2, "Result records final in-memory stacks")
	_check(not run.can_advance_encounter() and not run.advance_encounter(), "Final victory cannot create an unplanned encounter")
	result.herbs = 999
	_check(run.get_result().herbs == 4 and run.state.inventory.herbs == 4, "Result is a fresh value summary, not inventory alias")
	_check(run.combat.debug_undo_last_turn() and run.get_result() == null, "Final victory remains undoable until leaving the run")
	var failed := Run.new()
	failed.start_run(3)
	_win(failed.combat)
	failed.advance_encounter()
	failed.combat.state.player_hp = 0
	failed.combat.state.phase = CombatState.Phase.DEFEAT
	_check(failed.get_result().encounters_completed == 1 and failed.get_result().encounters_total == 3, "Defeat result counts only earlier completed encounters")
