extends SceneTree
## Cross-stream regression: real screen actions, run transitions and shared data.
const ENTRY: PackedScene = preload("res://scenes/run/run_entry.tscn")
const State = preload("res://scripts/combat/combat_state.gd")
const Loadout = preload("res://scripts/equipment/equipment_loadout.gd")
const Definition = preload("res://scripts/equipment/equipment_definition.gd")
const Slots = preload("res://scripts/equipment/equipment_slots.gd")
const ActorView = preload("res://scripts/ui/actor_view.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	create_timer(45).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _settle() -> void:
	for index: int in range(5):
		await process_frame


func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		var entry = ENTRY.instantiate()
		entry.debug_match_logging = false
		root.add_child(entry)
		await _settle()
		if "--capture" in OS.get_cmdline_user_args():
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://.godot/run_%dx%d.png" % [resolution.x, resolution.y])
		var screen = entry.screen
		var run = entry.run
		var combat = run.combat
		var inventory = run.state.inventory
		var loadout: Loadout = run.state.equipment_loadout
		_check(screen.combat == combat and screen.board == combat.board, "View uses run-owned controller/board")
		_check(screen.run_inventory == inventory and combat.state.run_inventory == inventory, "No duplicate inventory")
		_check(loadout != null, "Entry owns actual equipment contract")
		_check(screen.hero_portrait is ActorView and screen.enemy_stage.actor_views[0] is ActorView, "Both actors use reusable views")
		_check(screen.hero_portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Hero artwork ignores input")
		_check(screen.hero_portrait.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Actor art remains crisp")
		_check(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(screen.board_grid.get_global_rect()), "Run board fits viewport")
		_check(screen.tiles.size() == 49, "Unchanged 7x7 board")
		var item := Definition.new()
		item.item_id = &"integration_fixture"
		item.compatible_slots = [Slots.ARMOR]
		_check(loadout.equip(Slots.ARMOR, item), "Test-only loadout fixture")
		combat.state.player_hp = 77
		inventory.herbs = 12
		inventory.bandages = 1
		combat.state.ap = 5
		combat.state.guard = 8
		combat.state.ward = 9
		screen._sync_state()
		screen.craft_bandage_button.pressed.emit()
		screen.use_bandage_button.pressed.emit()
		_check(inventory.herbs == 6 and inventory.bandages == 1 and combat.state.player_hp == 89 and combat.state.ap == 3, "Existing emergency craft/use remain functional")
		screen.shield_bash_button.pressed.emit()
		_check(combat.state.enemy_hp == 32 and combat.state.guard == 0 and combat.state.ward == 9, "Bash unchanged by equipment/run/presentation")
		_check(combat.state.valid_swaps == 0 and combat.state.enemy_actions == 0, "Actions preserve pre-swap window")
		screen.visual_queue.enqueue(screen.hero_portrait, &"missing")
		screen.debug_undo_button.pressed.emit()
		_check(not screen.visual_queue.is_playing(), "Undo cancels pending presentation before restoring state")
		_check(combat.state.player_hp == 77 and combat.state.guard == 8 and combat.state.ward == 9 and combat.state.ap == 5, "UI Undo restores combat resources")
		_check(inventory.herbs == 12 and inventory.bandages == 1 and combat.state.enemy_hp == 40, "UI Undo restores shared inventory")
		# Exercise the real existing board playback, not a replacement resolver.
		combat.state.enemy_hp = 1000
		var move: Vector4i = combat.board.legal_moves()[0]
		screen.tiles[move.y * 7 + move.x].pressed.emit()
		screen.tiles[move.w * 7 + move.z].pressed.emit()
		_check(screen.resolving and screen.end_turn_button.disabled, "No transition during board playback")
		while screen.resolving:
			await process_frame
		_check(combat.state.phase == State.Phase.POST_MATCH and combat.state.enemy_actions == 0, "Cascades finish before explicit enemy action")
		_check(screen.tiles[0].disabled and not screen.end_turn_button.disabled, "Post-match board locked, End Turn available")
		screen.end_turn_button.pressed.emit()
		while screen.resolving:
			await process_frame
		_check(combat.state.turn == 2 and combat.state.enemy_actions == 1, "Existing enemy turn executes once")
		# A terminal ability action opens the explicit encounter transition.
		combat.state.player_hp = 63
		combat.state.guard = 8
		combat.state.ward = 11
		combat.state.ap = 6
		combat.state.enemy_hp = 8
		inventory.herbs = 7
		inventory.bandages = 2
		screen.shield_bash_button.pressed.emit()
		_check(combat.state.phase == State.Phase.VICTORY and run.state.encounter_index == 0, "Victory never auto-advances")
		_check(screen.end_turn_button.text == "Next Encounter" and not screen.end_turn_button.disabled, "Victory enables explicit next encounter")
		# Queue advancement then Undo in the same frame: deferred transition revalidates.
		screen.end_turn_button.pressed.emit()
		screen.debug_undo_button.pressed.emit()
		await _settle()
		_check(run.state.encounter_index == 0 and entry.screen == screen and not run.can_advance_encounter(), "Undo revokes pending transition")
		_check(screen.end_turn_button.text == "End Turn" and screen.end_turn_button.disabled, "Undo refreshes correct action window")
		# Win again and accept transition; the consumed turn snapshot cannot cross rooms.
		screen.shield_bash_button.pressed.emit()
		screen.end_turn_button.pressed.emit()
		await _settle()
		_check(run.state.encounter_index == 1 and entry.screen != screen, "Accepted transition replaces only encounter view/controller")
		_check(not combat.can_debug_undo(), "Retired controller cannot rewind shared inventory")
		screen = entry.screen
		combat = run.combat
		_check(combat.state.player_hp == 63 and combat.state.player_max_hp == 100, "No healing between encounters")
		_check(combat.state.ap == 0 and combat.state.guard == 0 and combat.state.ward == 0, "Encounter-local resources reset")
		_check(run.state.inventory == inventory and inventory.herbs == 7 and inventory.bandages == 2, "Both inventory stacks persist by identity")
		_check(run.state.equipment_loadout == loadout and loadout.get_item(Slots.ARMOR) == item, "Loadout persists without effects")
		_check(combat.state.herb_budget == 10 and combat.state.enemy_intent == 5, "Fresh encounter budget and existing intent")
		_check(not combat.can_debug_undo() and screen.hero_hp_bar.value == 63, "New encounter has no stale Undo and live HP binding")
		for tile: Button in screen.tiles:
			var motion := InputEventMouseMotion.new()
			motion.position = tile.get_global_rect().get_center()
			root.push_input(motion)
			await process_frame
			_check(root.gui_get_hovered_control() == tile, "Integrated actor views cannot block board input")
		# Remaining encounter transitions and derived final result.
		for index: int in range(2):
			combat = run.combat
			combat.state.guard = 40
			combat.state.ap = 3
			entry.screen.shield_bash_button.pressed.emit()
			if index == 0:
				entry.screen.end_turn_button.pressed.emit()
				await _settle()
		_check(run.get_result() != null and entry.screen.end_turn_button.text == "Run Complete", "Final victory exposes result without auto-transition")
		_check(entry.screen.end_turn_button.disabled, "No transition past final encounter")
		entry.screen.debug_undo_button.pressed.emit()
		_check(run.get_result() == null and run.combat.state.phase == State.Phase.PLAYER_INPUT, "Final victory Undo revokes run result")
		entry.queue_free()
		await _settle()
	print("Parallel integration tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
