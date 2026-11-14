extends SceneTree
## Skin/layout checks plus real-render HP coverage. Does not change combat rules.
const SCREEN: PackedScene = preload("res://scenes/combat/combat_screen.tscn")
const SKIN = preload("res://scripts/ui/forest_relic_theme.gd")
var checks: int = 0
var failures: int = 0
var rendered: bool = false


func _initialize() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _settle() -> void:
	for index: int in range(5):
		await process_frame


func _frame() -> Image:
	RenderingServer.force_draw()
	return root.get_texture().get_image()


func _red_pixels(image: Image, bar: ProgressBar) -> int:
	var bounds: Rect2i = Rect2i(bar.get_global_rect())
	var red: int = 0
	for x: int in range(bounds.position.x + 4, bounds.end.x - 4):
		var color: Color = image.get_pixel(x, bounds.get_center().y)
		if color.r > color.g * 1.5 and color.r > color.b * 1.4 and color.r > 0.12:
			red += 1
	return red


func _end_pixels(image: Image, bar: ProgressBar) -> Array[Color]:
	var bounds: Rect2i = Rect2i(bar.get_global_rect())
	var colors: Array[Color] = []
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in [bounds.position.x, bounds.position.x + 1, bounds.end.x - 2, bounds.end.x - 1]:
			colors.append(image.get_pixel(x, y))
	return colors


func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	root.content_scale_size = Vector2i.ZERO
	DirAccess.make_dir_recursive_absolute("res://build/screenshots")
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		var screen = SCREEN.instantiate()
		screen.debug_match_logging = false
		root.add_child(screen)
		await _settle()
		var viewport := Rect2(Vector2.ZERO, Vector2(resolution))
		var panels: Array[PanelContainer] = []
		for child: Node in screen.get_children():
			if child is PanelContainer and child.theme_type_variation in ["RelicHeroPanel", "RelicCenterPanel", "RelicLoadoutPanel"]:
				panels.append(child)
		_check(panels.size() == 3, "Exactly three main panel frames")
		for index: int in range(3):
			var panel: PanelContainer = panels[index]
			_check(panel.get_theme_stylebox("panel") is StyleBoxTexture, "Main panel uses supplied texture")
			_check(panel.offset_left == 8 and panel.offset_right == -8 and panel.offset_top == 12 and panel.offset_bottom == -12, "Original outer margins")
			_check(viewport.encloses(panel.get_global_rect()), "Panel remains in viewport")
		_check(is_equal_approx(panels[0].anchor_right, 0.21875) and is_equal_approx(panels[1].anchor_left, 0.21875) and is_equal_approx(panels[1].anchor_right, 0.78125) and is_equal_approx(panels[2].anchor_left, 0.78125), "Reference side columns and centered board")
		_check(screen.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Skin inherits nearest filtering")
		_check(screen.tiles[0].get_theme_stylebox("normal") is StyleBoxFlat, "No decorative button border on board tiles")
		for badge: Button in screen.status_icons:
			_check(badge.get_theme_stylebox("normal") is StyleBoxFlat and badge.size.y <= 34, "Compact badges keep compact borders")
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			var style: StyleBox = screen.shield_bash_button.get_theme_stylebox(state)
			_check(style is StyleBoxTexture and style.get_content_margin(SIDE_TOP) == 8 and style.get_content_margin(SIDE_BOTTOM) == 8, "Button state shares content geometry")
		_check(screen.end_turn_button.disabled and screen.shield_bash_button.disabled, "Initial action availability preserved")
		screen.shield_bash_button.mouse_entered.emit()
		_check(screen.ap_meter.preview_cost == 3 and "insufficient" in screen.ap_label.text, "Unavailable ability still previews AP cost")
		screen.shield_bash_button.mouse_exited.emit()
		for cell: Node in screen.inventory.grid.get_children():
			_check((cell as PanelContainer).get_theme_stylebox("panel") is StyleBoxFlat and screen.inventory.grid.get_theme_constant("h_separation") == 0, "Inventory cells share joined leather surface")
		_check(screen.inventory.cells.herb.text == "×0" and screen.inventory.cells.bandage.text == "×0", "Stack counts remain visible")
		_check(viewport.encloses(screen.budget_label.get_global_rect()) and viewport.encloses(screen.feedback.get_global_rect()), "Footer and combat feedback fit")
		_check(SKIN.segment_texture("empty").get_width() == 32 and SKIN.segment_texture("empty").get_height() == 32, "Empty segment excludes atlas strip and uses square padding")
		var original_hp: int = screen.combat.state.player_hp
		var original_enemy_hp: int = screen.combat.state.enemy_hp
		if rendered:
			# Allow font-atlas uploads to finish before the presentation capture.
			await create_timer(0.1).timeout
			_frame()
			await _settle()
			_frame().save_png("res://build/screenshots/forest_relic_%dx%d.png" % [resolution.x, resolution.y])
			if resolution.x == 1280:
				await _capture_button_states(screen)
		var previous_red: Array[int] = [-1, -1]
		var end_pixels: Array = [[], []]
		for percent: int in [0, 25, 50, 75, 100]:
			var bars: Array[ProgressBar] = [screen.hero_hp_bar, screen.enemy_hp_bar]
			for bar: ProgressBar in bars:
				bar.max_value = 100
				bar.value = percent
			screen.hero_hp_label.text = "HP %d / 100" % percent
			screen.enemy_hp_label.text = "HP %d / 100" % percent
			await _settle()
			var image: Image = _frame() if rendered else null
			for index: int in range(bars.size()):
				var bar: ProgressBar = bars[index]
				_check(bar.value == percent and bar.max_value == 100, "HP bar accepts 0/25/50/75/100 percent")
				if rendered:
					var red: int = _red_pixels(image, bar)
					_check(red > previous_red[index] and (percent != 0 or red == 0), "Rendered HP red coverage increases with value")
					previous_red[index] = red
					if percent == 0:
						end_pixels[index] = _end_pixels(image, bar)
					else:
						_check(_end_pixels(image, bar) == end_pixels[index], "HP decorative end caps remain stationary")
			if rendered and resolution.x == 1280:
				image.save_png("res://build/screenshots/forest_relic_hp_%03d.png" % percent)
		screen.ap_meter.show_ap(4)
		screen.ap_meter.set_preview(3)
		screen.defense_meter.show_defense(9, 7)
		_check(screen.combat.state.ap == 0 and screen.combat.state.guard == 0 and screen.combat.state.ward == 0, "Meter rendering never grants resources")
		_check(screen.combat.state.player_hp == original_hp and screen.combat.state.enemy_hp == original_enemy_hp, "Bar presentation never changes combat HP")
		screen._sync_state()
		_check(screen.hero_hp_bar.value == original_hp and screen.enemy_hp_bar.value == original_enemy_hp, "Live HP binding restores view")
		if rendered and resolution.x == 1280:
			# Screenshot fixture with matching live labels; no production seed/resources change.
			screen.combat.state.ap = 4
			screen.combat.state.guard = 9
			screen.combat.state.ward = 7
			screen._sync_state()
			screen._preview_ap(3)
			await _settle()
			_frame().save_png("res://build/screenshots/forest_relic_meter_preview.png")
		screen.queue_free()
		await _settle()
	print("Forest Relic skin tests: %d checks, %d failures; rendered=%s" % [checks, failures, rendered])
	quit(0 if failures == 0 else 1)


func _capture_button_states(screen: Control) -> void:
	# Test-only state swatches in the reserved clearance; never part of game UI.
	var gallery := Control.new()
	gallery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gallery.position = Vector2(320, 185)
	gallery.size = Vector2(640, 60)
	screen.add_child(gallery)
	var states: Array[String] = ["normal", "hover", "pressed", "disabled"]
	gallery.draw.connect(func() -> void:
		for index: int in range(states.size()):
			gallery.draw_style_box(screen.theme.get_stylebox(states[index], "Button"), Rect2(index * 160, 0, 152, 38))
	)
	for index: int in range(states.size()):
		var label := Label.new()
		label.text = states[index].capitalize()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(index * 160, 0)
		label.size = Vector2(152, 38)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gallery.add_child(label)
	await _settle()
	_frame().save_png("res://build/screenshots/forest_relic_button_states.png")
	gallery.queue_free()
	await _settle()
