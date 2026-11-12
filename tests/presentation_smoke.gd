extends SceneTree
## Layout/component checks without changing any combat state or board algorithms.
const SCREEN = preload("res://scenes/combat/combat_screen.tscn")
const INVENTORY = preload("res://scripts/ui/inventory_grid.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	create_timer(20).timeout.connect(func() -> void: quit(1))
	call_deferred("_verify")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _settle() -> void:
	for i: int in range(5):
		await process_frame


func _verify() -> void:
	root.content_scale_size = Vector2i.ZERO
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		var screen = SCREEN.instantiate()
		root.add_child(screen)
		await _settle()
		if "--capture" in OS.get_cmdline_user_args():
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://.godot/ui_%dx%d.png" % [resolution.x, resolution.y])
		var viewport := Rect2(Vector2.ZERO, Vector2(resolution))
		var bounds: Rect2 = screen.board_grid.get_global_rect()
		_check(viewport.encloses(bounds), "Board fits viewport %s" % resolution)
		_check(bounds.position.y >= screen.enemy_stage.get_global_rect().end.y + 80, "Looming art clearance")
		_check(screen.tiles[0].size.x > 40 and screen.tiles[0].size.x == screen.tiles[0].size.y, "Enlarged square tiles")
		_check(screen.hero_portrait.size.y >= 320, "Substantially enlarged portrait")
		_check(viewport.encloses(screen.feedback.get_global_rect()), "Combat feedback visible")
		_check(viewport.encloses(screen.budget_label.get_global_rect()), "Inventory footer visible")
		for tile: Button in screen.tiles:
			_check(viewport.encloses(tile.get_global_rect()), "All tiles in viewport")
			_check(tile.mouse_filter == Control.MOUSE_FILTER_STOP, "Board owns input")
			# Real pointer dispatch verifies decoration cannot swallow tile clicks.
			var move := InputEventMouseMotion.new()
			move.position = tile.get_global_rect().get_center()
			root.push_input(move)
			await process_frame
			_check(root.gui_get_hovered_control() == tile, "Board hit target unobstructed")
		for count: int in [1, 2, 3]:
			screen.enemy_stage.set_enemy_count(count)
			await _settle()
			_check(screen.enemy_stage.cards.size() == count, "EnemyStage visual capacity")
			for card: Control in screen.enemy_stage.cards:
				_check(screen.enemy_stage.get_global_rect().encloses(card.get_global_rect()), "Enemy card fits stage")
			_check(screen.combat.state.enemy_hp == 40, "Visual slots add no combat enemies")
		screen.inventory.set_quantity("herb", 17)
		_check(screen.inventory.cells.herb.text == "×17", "Live stack display")
		_check(screen.combat.state.run_inventory.herbs == 0, "Inventory view cannot mutate domain")
		var entries: Array[Dictionary] = []
		for index: int in range(60):
			entries.append({"id": "preview_%d" % index, "name": "Future item", "quantity": index, "texture": preload("res://assets/tiles/herb.png")})
		screen.inventory.set_entries(entries)
		await _settle()
		_check(screen.inventory.get_v_scroll_bar().max_value > screen.inventory.size.y, "Inventory scrolls when entries exceed available space")
		var initial_ap: int = screen.combat.state.ap
		screen.ability_previews[0].mouse_entered.emit()
		_check(screen.ap_meter.preview_cost == 3 and "insufficient" in screen.ap_label.text, "Insufficient AP preview")
		screen.ability_previews[0].pressed.emit()
		_check(screen.combat.state.ap == initial_ap, "Hover/click preview spends no AP")
		screen.ability_previews[0].mouse_exited.emit()
		_check(screen.ap_meter.preview_cost == 0, "AP preview clears")
		screen.ap_meter.show_ap(6)
		screen.ap_meter.set_preview(4)
		_check(screen.ap_meter.amount >= screen.ap_meter.preview_cost, "Affordable AP preview")
		screen.defense_meter.show_defense(7, 13)
		_check(screen.defense_meter.guard == 7 and screen.defense_meter.ward == 13, "Layered defense state")
		_check(screen.combat.state.guard == 0 and screen.combat.state.ward == 0, "Defense view cannot grant resources")
		for status: Button in screen.status_icons:
			_check(not status.tooltip_text.is_empty() and status.size.y <= 34, "Compact status tooltips")
		print("Layout %s: tile %s, board %s, portrait %s" % [resolution, screen.tiles[0].size, bounds, screen.hero_portrait.size])
		screen.queue_free()
		await process_frame
	print("Presentation tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
