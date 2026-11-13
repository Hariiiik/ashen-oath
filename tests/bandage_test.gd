extends SceneTree

const Combat = preload("res://scripts/combat/combat_controller.gd")
const State = preload("res://scripts/combat/combat_state.gd")
const Inventory = preload("res://scripts/combat/run_inventory.gd")
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


func _values(combat: Combat) -> Dictionary:
	var values: Dictionary = {}
	for property: Dictionary in combat.state.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			values[property.name] = combat.state.get(property.name)
	values["herbs"] = combat.state.run_inventory.herbs
	values["bandages"] = combat.state.run_inventory.bandages
	values["board"] = combat.board.cells.duplicate()
	values["rng"] = combat.board.rng.state
	return values


func _ready_combat() -> Combat:
	var combat := Combat.new(1)
	combat.state.run_inventory.herbs = 12
	combat.state.run_inventory.bandages = 2
	combat.state.player_hp = 70
	combat.state.ap = 5
	combat.state.guard = 8
	combat.state.ward = 9
	return combat


func _run() -> void:
	for phase: int in State.Phase.values():
		var combat := _ready_combat()
		combat.state.phase = phase
		if phase in [State.Phase.PLAYER_INPUT, State.Phase.POST_MATCH]:
			var before := _values(combat)
			var report := combat.emergency_craft_bandage()
			_check(report.valid and combat.state.run_inventory.herbs == 6 and combat.state.run_inventory.bandages == 3, "Emergency recipe consumes 6 herbs and stacks one bandage")
			_check(combat.state.ap == 5 and combat.state.herb_budget == before.herb_budget, "Crafting has no AP cost and does not reset herb budget")
			combat.emergency_craft_bandage()
			_check(combat.state.run_inventory.herbs == 0 and combat.state.run_inventory.bandages == 4, "Repeated crafting with enough herbs")
			report = combat.use_bandage()
			_check(report.valid and report.healed == 12 and combat.state.player_hp == 82 and combat.state.ap == 3 and combat.state.run_inventory.bandages == 3, "Use consumes one bandage, 2 AP, restores 12 HP")
			_check(combat.state.phase == phase and combat.state.turn == 1 and combat.state.valid_swaps == 0 and combat.state.enemy_actions == 0, "Actions preserve player window and do not grant or spend board swaps")
			_check(combat.board.cells == before.board and combat.board.rng.state == before.rng and combat.state.guard == 8 and combat.state.ward == 9, "Craft/use preserve board, RNG, Guard and Ward")
		else:
			var before := _values(combat)
			_check(not combat.can_emergency_craft_bandage() and not combat.emergency_craft_bandage().valid, "Crafting denied outside action windows")
			_check(not combat.can_use_bandage() and not combat.use_bandage().valid, "Bandage denied outside action windows")
			_check(before == _values(combat), "Invalid phase actions have no side effects")
	for herbs: int in [0, 3, 4, 5]:
		var combat := _ready_combat()
		combat.state.run_inventory.herbs = herbs
		var before := _values(combat)
		_check(not combat.emergency_craft_bandage().valid and before == _values(combat), "No standard 4-herb recipe exposed in combat; insufficient materials change nothing")
	var combat := _ready_combat()
	combat.state.ap = 0
	_check(combat.emergency_craft_bandage().valid and combat.state.ap == 0, "Emergency crafting allowed at zero AP")
	for ap: int in [0, 1]:
		combat = _ready_combat()
		combat.state.ap = ap
		var before := _values(combat)
		_check(not combat.use_bandage().valid and before == _values(combat), "Insufficient AP preserves inventory and HP")
	combat = _ready_combat()
	combat.state.run_inventory.bandages = 0
	var before := _values(combat)
	_check(not combat.use_bandage().valid and before == _values(combat), "Missing bandage cannot heal or spend AP")
	for hp: int in [89, 95, 99, 100]:
		combat = _ready_combat()
		combat.state.player_hp = hp
		before = _values(combat)
		var report := combat.use_bandage()
		if hp == 100:
			_check(not report.valid and before == _values(combat), "Full-HP use is disabled to avoid wasting an item")
		else:
			_check(report.valid and combat.state.player_hp == 100 and report.healed == 100 - hp and combat.state.ap == 3, "Healing clamps to max HP with normal AP cost")
	# Shared inventory survives separate encounter controllers; encounter state resets.
	var run_inventory := Inventory.new()
	run_inventory.herbs = 12
	run_inventory.bandages = 1
	combat = Combat.new(1, run_inventory)
	combat.emergency_craft_bandage()
	var next_encounter := Combat.new(2, run_inventory)
	_check(next_encounter.state.run_inventory == run_inventory and next_encounter.state.run_inventory.herbs == 6 and next_encounter.state.run_inventory.bandages == 2, "Herbs and bandages persist between encounters of the same run")
	_check(next_encounter.state.herb_budget == 10 and next_encounter.state.ap == 0 and next_encounter.state.player_hp == 100, "No run-progression or other state-carry rules introduced")
	var fresh := Combat.new(3)
	_check(fresh.state.run_inventory.herbs == 0 and fresh.state.run_inventory.bandages == 0, "New run inventory is independent; no meta-inventory")
	combat = _ready_combat()
	combat.use_bandage()
	_check(combat.can_shield_bash() and combat.state.ap == 3, "Bandage and Shield Bash share the same AP pool")
	combat.activate_shield_bash()
	_check(combat.state.ap == 0 and combat.state.enemy_hp == 32 and combat.state.ward == 9, "Shield Bash still spends 3 AP and only Guard after Bandage")
	# Undo captures crafting as the first action, including both item stacks.
	combat = _ready_combat()
	before = _values(combat)
	combat.emergency_craft_bandage()
	combat.use_bandage()
	_check(combat.debug_undo_last_turn() and _values(combat) == before, "Undo restores crafting, healing, AP and both stacks")
	# Real swap/cascades still determine the sole board move.
	combat = _ready_combat()
	combat.emergency_craft_bandage()
	combat.use_bandage()
	var move: Vector4i = combat.board.legal_moves()[0]
	var result := combat.begin_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w))
	_check(result.valid and combat.state.valid_swaps == 1, "Pre-swap craft/use do not consume swap")
	for step in result.steps:
		combat.resolve_next_step()
	combat.finish_player_resolution()
	combat.state.ap = 2
	combat.state.player_hp = 60
	_check(combat.use_bandage().valid and combat.state.phase == State.Phase.POST_MATCH, "Post-match item use supported")
	_check(not combat.begin_swap(Vector2i(move.x, move.y), Vector2i(move.z, move.w)).valid and combat.state.valid_swaps == 1, "Post-match item grants no extra swap")
	_check(combat.state.enemy_actions == 0 and combat.execute_enemy_action().is_empty(), "Item does not advance enemy turn")
	combat.end_turn()
	combat.execute_enemy_action()
	_check(combat.state.turn == 2 and combat.state.enemy_actions == 1 and combat.state.guard == 0, "End Turn and Guard expiration preserved")
	await _ui_test()
	print("Bandage tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _ui_test() -> void:
	root.size = Vector2i(1280, 720)
	var shared := Inventory.new()
	shared.herbs = 12
	var screen = SCREEN.instantiate()
	screen.run_inventory = shared
	screen.debug_match_logging = false
	root.add_child(screen)
	await process_frame
	await process_frame
	_check(not screen.craft_bandage_button.disabled and screen.use_bandage_button.disabled, "Initial item buttons reflect material and item availability")
	screen.craft_bandage_button.pressed.emit()
	_check(shared.herbs == 6 and shared.bandages == 1 and screen.inventory.cells.bandage.text == "×1" and screen.inventory.cells.herb.text == "×6", "Craft updates both visible stack counts")
	screen.combat.state.ap = 2
	screen.combat.state.player_hp = 95
	screen._sync_state()
	_check(screen.combat.can_shield_bash() == false, "UI item setup does not grant Guard or abilities")
	screen.use_bandage_button.mouse_entered.emit()
	_check(screen.ap_meter.preview_cost == 2 and not screen.use_bandage_button.disabled, "Bandage hover previews 2 AP")
	screen.use_bandage_button.pressed.emit()
	_check(screen.hero_hp_bar.value == 100 and shared.bandages == 0 and screen.ap_meter.amount == 0 and screen.inventory.cells.bandage.text == "×0", "Use updates live HP/AP and inventory")
	_check("+5 HP" in screen.feedback.text, "Feedback reports actual clamped healing")
	screen.use_bandage_button.mouse_exited.emit()
	_check(screen.ap_meter.preview_cost == 0, "Item AP preview clears")
	var move: Vector4i = screen.board.legal_moves()[0]
	screen.tiles[move.y * 7 + move.x].pressed.emit()
	screen.tiles[move.w * 7 + move.z].pressed.emit()
	_check(screen.craft_bandage_button.disabled and screen.use_bandage_button.disabled, "Craft/use locked throughout swap preview and resolution")
	screen.craft_bandage_button.pressed.emit()
	_check(shared.herbs == 6, "UI handler rejects crafting during preview")
	while screen.resolving:
		await process_frame
	_check(screen.combat.state.phase == State.Phase.POST_MATCH and not screen.craft_bandage_button.disabled, "Crafting remains available after cascades")
	screen.craft_bandage_button.pressed.emit()
	_check(shared.herbs == 0 and shared.bandages == 1 and screen.tiles[0].disabled, "Post-match crafting changes only resources, not swap availability")
	screen.queue_free()
	await process_frame
	screen = SCREEN.instantiate()
	screen.run_inventory = shared
	screen.debug_match_logging = false
	root.add_child(screen)
	await process_frame
	_check(screen.combat.state.run_inventory == shared and screen.inventory.cells.bandage.text == "×1", "A new encounter scene binds the existing run inventory")
	screen.queue_free()
	await process_frame
