extends SceneTree
## Approved-reference layout plus functional nonmodal crafting across turn windows.
const ENTRY: PackedScene = preload("res://scenes/run/run_entry.tscn")
const State = preload("res://scripts/combat/combat_state.gd")
const Rules = preload("res://scripts/combat/combat_rules.gd")
var checks: int = 0
var failures: int = 0
var rendered: bool = false


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


func _capture(path: String) -> void:
	if not rendered:
		return
	await create_timer(0.1).timeout
	RenderingServer.force_draw()
	await _settle()
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(path)


func _labels(node: Node) -> Array[Label]:
	var result: Array[Label] = []
	if node is Label:
		result.append(node as Label)
	for child: Node in node.get_children():
		result.append_array(_labels(child))
	return result


func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	root.content_scale_size = Vector2i.ZERO
	DirAccess.make_dir_recursive_absolute("res://build/screenshots")
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		var entry = ENTRY.instantiate()
		entry.debug_match_logging = false
		root.add_child(entry)
		await _settle()
		var screen = entry.screen
		var combat = screen.combat
		var inventory = combat.state.run_inventory
		var viewport := Rect2(Vector2.ZERO, Vector2(resolution))
		var board_rect: Rect2 = screen.board_grid.get_global_rect()
		_check(viewport.encloses(board_rect), "Board fits reference layout")
		_check(screen.tiles[0].size == Vector2.ONE * (52 if resolution.x == 1280 else 94), "Original tile sizing retained")
		_check(screen.hero_frame.caption.text == "%s  /  LVL %02d" % [screen.hero_class_label.to_upper(), screen.hero_level], "Class/level supplied to portrait plaque")
		_check(screen.hero_frame.get_global_rect().encloses(screen.hero_portrait.get_global_rect()), "Actor fits framed portrait")
		for label: Label in _labels(screen):
			_check(label.text != "Ser Aldric", "Standalone hero name removed")
		var footer: Rect2 = screen.combat_footer.get_global_rect()
		var end_button: Rect2 = screen.end_turn_button.get_global_rect()
		_check(end_button.position.y >= board_rect.end.y and end_button.get_center().x > board_rect.get_center().x, "End Turn below board at right")
		_check(viewport.encloses(footer) and footer.encloses(end_button), "Footer remains readable inside viewport")
		_check(viewport.encloses(screen.feedback.get_global_rect()) and viewport.encloses(screen.budget_label.get_global_rect()), "Feedback and bag totals fit")
		for meter: Control in [screen.ap_meter, screen.defense_meter]:
			for index: int in range(5):
				_check(is_equal_approx(meter.segment_rect(index + 1).position.x - meter.segment_rect(index).end.x, 1), "Meter plates are joined by one-pixel dividers")
		var stage = screen.enemy_stage
		_check(not stage.art_frames[0].get_global_rect().intersects(stage.info_panels[0].get_global_rect()), "Separate enemy art and information frames")
		_check(stage.actor_views[0].get_global_rect().end.y > stage.art_frames[0].get_global_rect().end.y, "Enemy art may overhang frame")
		_check(stage.actor_views[0].get_global_rect().end.y < board_rect.position.y, "Artwork clearance protects board")
		_check(stage.actor_views[0].mouse_filter == Control.MOUSE_FILTER_IGNORE, "Enemy art ignores board input")
		_check(screen.inventory.get_parent().get_parent() == screen.inventory_bag, "Inventory belongs to shared bag surface")
		_check(screen.use_bandage_button == screen.consumables_belt.use_button and screen.craft_bandage_button == screen.crafting_popup.craft_button, "Existing handlers use one belt/popup action instance")
		await _capture("res://build/screenshots/ui_reference_%dx%d.png" % [resolution.x, resolution.y])
		screen.consumables_belt.hammer_button.pressed.emit()
		await _settle()
		var popup = screen.crafting_popup
		_check(popup.visible and screen.craft_bandage_button.disabled, "Hammer opens nonmodal popup even without materials")
		var allowed: Rect2 = (screen.loadout_column.get_parent() as Control).get_global_rect()
		_check(allowed.encloses(popup.get_global_rect()) and not popup.get_global_rect().intersects(board_rect), "Crafting popup stays entirely in right column")
		_check(not popup.get_global_rect().intersects(screen.shield_bash_button.get_global_rect()) and not popup.get_global_rect().intersects(screen.debug_undo_button.get_global_rect()), "Open popup leaves Bash and Undo accessible")
		# Actual pointer dispatch is deterministic headless; native OS pointer events
		# are kept out of the rendered-capture verification.
		if not rendered:
			for tile: Button in screen.tiles:
				var motion := InputEventMouseMotion.new()
				motion.position = tile.get_global_rect().get_center()
				root.push_input(motion)
				await process_frame
				_check(root.gui_get_hovered_control() == tile, "Open crafting never intercepts any board tile")
		combat.state.player_hp = 70
		combat.state.ap = 4
		combat.state.guard = 9
		combat.state.ward = 7
		inventory.herbs = 12
		inventory.bandages = 1
		screen._sync_state()
		await _capture("res://build/screenshots/ui_reference_crafting_%dx%d.png" % [resolution.x, resolution.y])
		screen.craft_bandage_button.pressed.emit()
		_check(inventory.herbs == 6 and inventory.bandages == 2 and combat.state.ap == 4, "Popup crafts exactly one Bandage for existing 6-Herb cost and no AP")
		screen.use_bandage_button.mouse_entered.emit()
		_check(screen.ap_meter.preview_cost == Rules.BANDAGE_AP_COST, "Belt previews existing AP cost")
		screen.use_bandage_button.pressed.emit()
		_check(inventory.bandages == 1 and combat.state.ap == 2 and combat.state.player_hp == 82, "Belt uses existing manual Bandage effect")
		_check(combat.state.valid_swaps == 0 and combat.state.enemy_actions == 0 and popup.visible, "Actions preserve pre-swap window and open popup")
		screen.debug_undo_button.pressed.emit()
		_check(inventory.herbs == 12 and inventory.bandages == 1 and combat.state.player_hp == 70 and combat.state.ap == 4 and popup.visible, "Undo restores resources without closing popup or repeating actions")
		combat.state.enemy_hp = 1000
		var invalid: Vector4i
		var found: bool = false
		for y: int in range(7):
			for x: int in range(6):
				if not found and not combat.board.is_valid_swap(Vector2i(x, y), Vector2i(x + 1, y)):
					invalid = Vector4i(x, y, x + 1, y)
					found = true
		screen.tiles[invalid.y * 7 + invalid.x].pressed.emit()
		screen.tiles[invalid.w * 7 + invalid.z].pressed.emit()
		_check(screen.resolving and screen.craft_bandage_button.disabled, "Crafting locks during swap preview")
		screen.craft_bandage_button.pressed.emit()
		_check(inventory.herbs == 12, "Handler rejects craft during presentation lock")
		while screen.resolving:
			await process_frame
		_check(combat.state.valid_swaps == 0 and popup.visible, "Invalid swap spends nothing and leaves popup open")
		var move: Vector4i = combat.board.legal_moves()[0]
		screen.tiles[move.y * 7 + move.x].pressed.emit()
		screen.tiles[move.w * 7 + move.z].pressed.emit()
		while screen.resolving:
			await process_frame
		_check(combat.state.phase == State.Phase.POST_MATCH and combat.state.enemy_actions == 0 and popup.visible, "Post-match decision window preserves popup and awaits End Turn")
		var herbs_before: int = inventory.herbs
		var ap_before: int = combat.state.ap
		screen.craft_bandage_button.pressed.emit()
		_check(inventory.herbs == herbs_before - Rules.BANDAGE_EMERGENCY_HERBS and combat.state.ap == ap_before and combat.state.valid_swaps == 1, "Post-match crafting preserves AP and single swap allowance")
		screen.end_turn_button.pressed.emit()
		_check(screen.craft_bandage_button.disabled and popup.visible, "Enemy action disables crafting while keeping popup open")
		while screen.resolving:
			await process_frame
		_check(combat.state.enemy_actions == 1 and combat.state.turn == 2 and popup.visible, "Relocated End Turn performs existing enemy action once")
		combat.state.enemy_hp = 1
		combat.state.guard = 1
		combat.state.ap = 3
		screen._sync_state()
		screen.shield_bash_button.pressed.emit()
		_check(combat.state.phase == State.Phase.VICTORY and popup.visible and screen.craft_bandage_button.disabled, "Victory keeps popup readable but crafting unavailable")
		_check(screen.end_turn_button.text == "Next Encounter", "Run progression retains relocated action button")
		popup.close_button.pressed.emit()
		_check(not popup.visible, "Popup remains closable after combat")
		print("Reference layout %s: board=%s, portrait=%s, EndTurn=%s" % [resolution, board_rect, screen.hero_frame.size, end_button])
		entry.queue_free()
		await _settle()
	print("Reference UI tests: %d checks, %d failures; rendered=%s" % [checks, failures, rendered])
	quit(0 if failures == 0 else 1)
