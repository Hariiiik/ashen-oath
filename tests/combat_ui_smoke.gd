extends SceneTree
## Run: godot --headless --path . --script tests/combat_ui_smoke.gd
const Board = preload("res://scripts/board/board_model.gd")
const Combat = preload("res://scripts/combat/combat_controller.gd")
const State = preload("res://scripts/combat/combat_state.gd")


func _initialize() -> void:
	create_timer(15.0).timeout.connect(func() -> void: quit(1))
	call_deferred("_verify")


func _verify() -> void:
	root.size = Vector2i(1280, 720)
	var scene := load("res://scenes/combat/combat_screen.tscn") as PackedScene
	var screen := scene.instantiate() as Control
	root.add_child(screen)
	await process_frame
	await process_frame
	var tiles: Array = screen.get("tiles")
	var count: int = 0
	var enemy_stage := screen.get("enemy_stage") as Control
	for node: Node in tiles:
		var button := node as Button
		if button.disabled:
			continue
		count += 1
		assert(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(button.get_global_rect()), "Tile outside viewport")
		# The structural boundary is independent of current mouse position.
		assert(button.mouse_filter == Control.MOUSE_FILTER_STOP)
		assert(button.get_global_rect().position.y > enemy_stage.get_global_rect().end.y, "Board overlaps enemy region")
		if count == 1:
			button.button_pressed = true
			button.pressed.emit()
			assert("selected" in screen.get("feedback").text)
	assert(count == 49, "Expected 49 selectable tiles")
	var feedback := screen.get("feedback") as Label
	assert(feedback.get_global_rect().end.y <= 720, "Feedback clipped")
	var model: Board = screen.get("board")
	var buttons: Array = screen.get("tiles")
	var old: Array[int] = model.cells.duplicate()
	# Re-click deselects; distant click changes selection without a swap.
	buttons[0].pressed.emit()
	assert(screen.get("selected") == -1)
	buttons[0].pressed.emit()
	buttons[48].pressed.emit()
	assert(screen.get("selected") == 48 and model.cells == old)
	buttons[48].pressed.emit()
	var invalid: Vector4i
	var found: bool = false
	for y: int in range(7):
		for x: int in range(6):
			if not found and not model.is_valid_swap(Vector2i(x, y), Vector2i(x + 1, y)):
				invalid = Vector4i(x, y, x + 1, y)
				found = true
	buttons[invalid.y * 7 + invalid.x].pressed.emit()
	buttons[invalid.w * 7 + invalid.z].pressed.emit()
	assert(screen.get("resolving"))
	while screen.get("resolving"):
		await process_frame
	assert(model.cells == old and screen.get("moves") == 0, "Invalid swap spends no move")
	var move: Vector4i = model.legal_moves()[0]
	buttons[move.y * 7 + move.x].pressed.emit()
	buttons[move.w * 7 + move.z].pressed.emit()
	assert(screen.get("resolving"))
	for button: Button in buttons:
		assert(button.disabled, "All tiles disabled during resolution")
	buttons[0].pressed.emit()
	assert(screen.get("selected") == -1, "Handler also rejects input while resolving")
	while screen.get("resolving"):
		await process_frame
	assert(screen.get("moves") == 1, "Valid move counted once including cascades")
	assert(model.find_matches().is_empty() and model.has_legal_move())
	for i: int in range(49):
		assert(buttons[i].disabled and buttons[i].get("tile_kind") == model.cells[i])
	var combat: Combat = screen.get("combat")
	assert(combat.state.phase == State.Phase.POST_MATCH and combat.state.enemy_actions == 0)
	assert(not screen.get("end_turn_button").disabled)
	screen.get("end_turn_button").pressed.emit()
	while screen.get("resolving"):
		await process_frame
	assert(combat.state.turn == 2 and combat.state.enemy_actions == 1 and combat.state.enemy_intent == 8)
	assert(screen.get("hero_hp_bar").value == combat.state.player_hp)
	assert(screen.get("enemy_hp_bar").value == combat.state.enemy_hp)
	assert("8 damage" in screen.get("intent_label").text)
	assert(str(combat.state.ap) in screen.get("ap_label").text)
	# Guaranteed Sword swap for victory; all terminal input remains disabled.
	for y: int in range(7):
		for x: int in range(7):
			model.cells[y * 7 + x] = (x + y) % 4
	model.cells[2] = 0
	model.cells[8] = 0
	screen.call("_refresh", model.cells)
	combat.state.enemy_hp = 1
	buttons[1].pressed.emit()
	buttons[8].pressed.emit()
	while screen.get("resolving"):
		await process_frame
	assert(combat.state.phase == State.Phase.VICTORY and combat.state.enemy_actions == 1)
	assert("VICTORY" in feedback.text and screen.get("enemy_hp_bar").value == 0)
	for button: Button in buttons:
		assert(button.disabled)
	buttons[0].pressed.emit()
	assert(screen.get("selected") == -1)
	screen.queue_free()
	await process_frame
	# Separate encounter exercises the actual UI enemy action -> defeat path.
	screen = scene.instantiate() as Control
	root.add_child(screen)
	await process_frame
	combat = screen.get("combat")
	combat.state.player_hp = 1
	combat.state.enemy_hp = 1000
	combat.state.enemy_max_hp = 1000
	combat.state.enemy_intent = 1000
	buttons = screen.get("tiles")
	move = combat.board.legal_moves()[0]
	buttons[move.y * 7 + move.x].pressed.emit()
	buttons[move.w * 7 + move.z].pressed.emit()
	while screen.get("resolving"):
		await process_frame
	assert(combat.state.phase == State.Phase.POST_MATCH and combat.state.player_hp == 1)
	screen.get("end_turn_button").pressed.emit()
	while screen.get("resolving"):
		await process_frame
	assert(combat.state.phase == State.Phase.DEFEAT)
	assert("DEFEAT" in screen.get("feedback").text and screen.get("hero_hp_bar").value == 0)
	for button: Button in buttons:
		assert(button.disabled)
	buttons[0].pressed.emit()
	assert(screen.get("selected") == -1)
	print("PASS: layout, swaps, input lock, live combat UI, retaliation, victory and defeat.")
	screen.queue_free()
	quit()
