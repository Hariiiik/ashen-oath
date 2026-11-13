extends Control
## Combat presentation only. Rules and turn transitions belong to the controller.

const TILE_SCENE: PackedScene = preload("res://scenes/ui/board_tile.tscn")
const PORTRAIT = preload("res://scripts/ui/placeholder_portrait.gd")
const BOARD = preload("res://scripts/board/board_model.gd")
const COMBAT = preload("res://scripts/combat/combat_controller.gd")
const STATE = preload("res://scripts/combat/combat_state.gd")
const RULES = preload("res://scripts/combat/combat_rules.gd")
const ENEMY_STAGE = preload("res://scripts/ui/enemy_stage.gd")
const METER = preload("res://scripts/ui/segmented_meter.gd")
const INVENTORY = preload("res://scripts/ui/inventory_grid.gd")
signal board_resolved(result: BOARD.SwapResult)
@export var board_seed: int = 1
@export var debug_match_logging: bool = true
var feedback: Label
var turn_label: Label
var board: BOARD
var combat: COMBAT
var hero_hp_label: Label
var hero_hp_bar: ProgressBar
var enemy_hp_label: Label
var enemy_hp_bar: ProgressBar
var defense_label: Label
var intent_label: Label
var ap_label: Label
var herbs_label: Label
var budget_label: Label
var tiles: Array[Button] = []
var selected: int = -1
var resolving: bool = false
var moves: int = 0
var enemy_stage: ENEMY_STAGE
var ap_meter: METER
var defense_meter: METER
var inventory: INVENTORY
var hero_portrait: Control
var board_grid: GridContainer
var board_frame: CenterContainer
var art_clearance: Control
var center_column: VBoxContainer
var ability_previews: Array[Button] = []
var status_icons: Array[Button] = []
var shield_bash_button: Button
var end_turn_button: Button
var debug_undo_button: Button


func _ready() -> void:
	combat = COMBAT.new(board_seed)
	combat.diagnostics_enabled = debug_match_logging
	board = combat.board
	theme = _make_theme()
	var background := ColorRect.new()
	background.color = Color("101116")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_build_hero(_column(0.0, 0.2))
	_build_center(_column(0.2, 0.8))
	_build_loadout(_column(0.8, 1.0))
	_sync_state()
	resized.connect(_resize_presentation)
	_resize_presentation.call_deferred()


func _style(fill: String, border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill)
	style.border_color = Color(border)
	style.set_border_width_all(2)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_color("font_color", "Label", Color("C8B89A"))
	result.set_stylebox("panel", "PanelContainer", _style("161515", "44484A"))
	result.set_stylebox("normal", "Button", _style("26211E", "53606A"))
	result.set_stylebox("hover", "Button", _style("2F3438", "A1693D"))
	result.set_stylebox("pressed", "Button", _style("2F4A34", "87919A"))
	result.set_stylebox("disabled", "Button", _style("26211E", "44484A"))
	result.set_color("font_disabled_color", "Button", Color("8E7D62"))
	result.set_stylebox("background", "ProgressBar", _style("161515", "44484A"))
	result.set_stylebox("fill", "ProgressBar", _style("6A2E2A", "8A4A32"))
	return result


func _column(left: float, right: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	add_child(panel)
	panel.anchor_left = left
	panel.anchor_right = right
	panel.anchor_bottom = 1.0
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = 12
	panel.offset_bottom = -12
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	return column


func _label(parent: Node, copy: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _health(parent: Node) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 18
	bar.show_percentage = false
	parent.add_child(bar)
	return bar


func _portrait(parent: Node, is_enemy: bool, height: float) -> Control:
	var portrait := Control.new()
	portrait.set_script(PORTRAIT)
	portrait.set("enemy", is_enemy)
	portrait.custom_minimum_size = Vector2(0, height)
	parent.add_child(portrait)
	return portrait


func _placeholder(parent: Node, copy: String) -> void:
	var button := Button.new()
	button.text = copy
	button.disabled = true
	button.custom_minimum_size.y = 38
	button.tooltip_text = "Visual placeholder — not implemented"
	parent.add_child(button)


func _build_hero(column: VBoxContainer) -> void:
	_label(column, "THE OATHBOUND", 18)
	hero_portrait = _portrait(column, false, 320)
	_label(column, "Ser Aldric", 24)
	_label(column, "WARDEN  /  LEVEL 01")
	hero_hp_label = _label(column, "")
	hero_hp_bar = _health(column)
	defense_label = _label(column, "", 15)
	defense_meter = METER.new()
	defense_meter.defense = true
	column.add_child(defense_meter)
	var statuses := HBoxContainer.new()
	statuses.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(statuses)
	for caption: String in ["G", "W", "—"]:
		var badge := Button.new()
		badge.text = caption
		badge.add_theme_font_size_override("font_size", 12)
		badge.custom_minimum_size = Vector2(34, 30)
		badge.tooltip_text = "No additional status effects" if caption == "—" else caption
		statuses.add_child(badge)
		status_icons.append(badge)
	ap_label = _label(column, "", 14)
	ap_meter = METER.new()
	column.add_child(ap_meter)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	_label(column, "Prototype balance", 13)


func _build_center(column: VBoxContainer) -> void:
	center_column = column
	column.add_theme_constant_override("separation", 2)
	_label(column, "ASHEN OATH  /  THE HOLLOW CRYPT", 18)
	enemy_stage = ENEMY_STAGE.new()
	enemy_stage.custom_minimum_size.y = 128
	column.add_child(enemy_stage)
	enemy_stage.slots_changed.connect(_on_enemy_slots_changed)
	_bind_primary_enemy()
	art_clearance = Control.new()
	art_clearance.name = "ArtworkClearance"
	art_clearance.custom_minimum_size.y = 80
	art_clearance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(art_clearance)
	board_frame = CenterContainer.new()
	column.add_child(board_frame)
	board_grid = GridContainer.new()
	board_grid.columns = 7
	board_grid.add_theme_constant_override("h_separation", 4)
	board_grid.add_theme_constant_override("v_separation", 4)
	board_frame.add_child(board_grid)
	for row: int in range(7):
		for col: int in range(7):
			var tile := TILE_SCENE.instantiate() as Button
			tile.set("tile_kind", board.cells[row * 7 + col])
			tiles.append(tile)
			board_grid.add_child(tile)
			tile.pressed.connect(_on_tile_pressed.bind(row * 7 + col))
	turn_label = _label(column, "BOARD MOVE 00  /  SELECT TWO ADJACENT TILES", 16)
	feedback = _label(column, "Sword / Shield / Herb / Action  •  Seed %d" % board_seed, 14)
	# Long cascade reports must not push the three columns beyond the viewport.
	feedback.clip_text = true
	feedback.custom_minimum_size.y = 26
	feedback.mouse_filter = Control.MOUSE_FILTER_PASS


func _bind_primary_enemy() -> void:
	enemy_hp_label = enemy_stage.primary_hp_label
	enemy_hp_bar = enemy_stage.primary_hp_bar
	intent_label = enemy_stage.primary_intent


func _on_enemy_slots_changed() -> void:
	_bind_primary_enemy()
	_sync_state()


func _resize_presentation() -> void:
	if not is_instance_valid(board_grid):
		return
	# Allocate the remaining central height to an integer-sized square board.
	enemy_stage.custom_minimum_size.y = floorf(maxf(128, size.y * 0.178))
	hero_portrait.custom_minimum_size.y = floorf(maxf(320, size.y * 0.445))
	var available_height: float = size.y - 24 - 16 - 22 - enemy_stage.custom_minimum_size.y - art_clearance.custom_minimum_size.y - 26 - 23 - 12
	var available_width: float = size.x * 0.6 - 32
	var side: float = floorf((minf(available_height, available_width) - 24) / 7.0)
	for tile: Button in tiles:
		tile.custom_minimum_size = Vector2.ONE * maxf(40, side)


func _preview_ap(cost: int) -> void:
	ap_meter.set_preview(cost)
	ap_label.text = "AP %d / 6" % combat.state.ap
	if cost > 0:
		if combat.state.ap < cost:
			ap_label.text += " / insufficient (%d)" % cost
		else:
			ap_label.text += " / cost %d" % cost
	ap_label.modulate = Color("A1693D") if cost > combat.state.ap else Color.WHITE
	ap_meter.tooltip_text = "Insufficient AP: need %d, have %d." % [cost, combat.state.ap] if cost > combat.state.ap else "Shared AP for abilities and future items."


func _on_tile_pressed(index: int) -> void:
	if resolving or combat.state.phase != STATE.Phase.PLAYER_INPUT:
		return
	if selected == index:
		selected = -1
		feedback.text = "Selection cleared."
		_refresh(board.cells)
		return
	if selected < 0:
		selected = index
		feedback.text = "%s selected. Choose an adjacent tile." % tiles[index].tooltip_text
		_refresh(board.cells)
		return
	var a := Vector2i(selected % 7, floori(selected / 7.0))
	var b := Vector2i(index % 7, floori(index / 7.0))
	if absi(a.x - b.x) + absi(a.y - b.y) != 1:
		selected = index
		feedback.text = "Choose a tile directly beside the selected tile."
		_refresh(board.cells)
		return
	selected = -1
	resolving = true
	_sync_action_availability()
	for tile: Button in tiles:
		tile.disabled = true
	var before: Array[int] = board.cells.duplicate()
	var preview: Array[int] = before.duplicate()
	preview[a.y * 7 + a.x] = before[index]
	preview[index] = before[a.y * 7 + a.x]
	_refresh(preview)
	await get_tree().create_timer(0.15).timeout
	var result: BOARD.SwapResult = combat.begin_swap(a, b)
	if not result.valid:
		feedback.text = "No match. Swap reverted; no move spent."
	else:
		moves = combat.state.valid_swaps
		for step: BOARD.CascadeStep in result.steps:
			var reports: Array[Dictionary] = combat.resolve_next_step()
			var effects: PackedStringArray = []
			for report: Dictionary in reports:
				var effect: String = ["damage", "Guard" if report.rank == 3 else "Ward", "herbs", "AP"][report.tile]
				effects.append("M%d: +%d %s" % [report.rank, report.amount, effect])
			feedback.text = "Cascade %d / %s" % [step.index + 1, ", ".join(effects)]
			feedback.tooltip_text = feedback.text
			_sync_state()
			_refresh(step.cleared)
			if combat.state.is_finished():
				break
			await get_tree().create_timer(0.22).timeout
			_refresh(step.refilled)
			await get_tree().create_timer(0.22).timeout
		if result.reshuffled and not combat.state.is_finished():
			feedback.text = "No legal moves remained. Board reshuffled."
		combat.finish_player_resolution()
		if combat.state.phase == STATE.Phase.POST_MATCH:
			feedback.text = "Swap complete. Use Shield Bash or End Turn."
	_refresh(result.final_cells)
	for tile: Button in tiles:
		tile.disabled = combat.state.phase != STATE.Phase.PLAYER_INPUT
	resolving = false
	_sync_state()
	if combat.state.phase == STATE.Phase.VICTORY:
		feedback.text = "VICTORY — The Hollow Sentinel has fallen. F6 to play again."
	elif combat.state.phase == STATE.Phase.DEFEAT:
		feedback.text = "DEFEAT — Your oath ends here. F6 to try again."
	feedback.tooltip_text = feedback.text
	board_resolved.emit(result)


func _on_shield_bash_pressed() -> void:
	if resolving:
		return
	var report: Dictionary = combat.activate_shield_bash()
	if not report.valid:
		return
	selected = -1
	_refresh(board.cells)
	feedback.text = "Shield Bash: %d Guard consumed / %d physical damage." % [report.guard_consumed, report.damage]
	if combat.state.phase == STATE.Phase.VICTORY:
		feedback.text += " VICTORY — no retaliation."
	feedback.tooltip_text = feedback.text
	_sync_state()


func _on_end_turn_pressed() -> void:
	if resolving or not combat.end_turn():
		return
	resolving = true
	_sync_state()
	feedback.text = "Enemy attacks for %d." % combat.state.enemy_intent
	await get_tree().create_timer(0.35).timeout
	var attack: Dictionary = combat.execute_enemy_action()
	feedback.text = "Enemy: %d damage / Guard %d / Ward %d / HP -%d" % [attack.damage, attack.guard, attack.ward, attack.hp]
	if combat.state.phase == STATE.Phase.DEFEAT:
		feedback.text = "DEFEAT — Your oath ends here. F6 to try again."
	resolving = false
	feedback.tooltip_text = feedback.text
	_sync_state()


func _sync_action_availability() -> void:
	for tile: Button in tiles:
		tile.disabled = resolving or combat.state.phase != STATE.Phase.PLAYER_INPUT
	shield_bash_button.disabled = resolving or not combat.can_shield_bash()
	end_turn_button.disabled = resolving or combat.state.phase != STATE.Phase.POST_MATCH
	if is_instance_valid(debug_undo_button):
		debug_undo_button.disabled = resolving or not combat.can_debug_undo()


func _on_debug_undo_pressed() -> void:
	if resolving or not combat.debug_undo_last_turn():
		return
	selected = -1
	moves = combat.state.valid_swaps
	ap_meter.set_preview(0)
	_refresh(board.cells)
	_sync_state()
	feedback.text = "DEBUG: Previous turn restored. Replay uses the same RNG."
	feedback.tooltip_text = feedback.text


func _sync_state() -> void:
	var state: STATE = combat.state
	hero_hp_label.text = "HP  %d / %d" % [state.player_hp, state.player_max_hp]
	hero_hp_bar.max_value = state.player_max_hp
	hero_hp_bar.value = state.player_hp
	enemy_hp_label.text = "HP %d / %d" % [state.enemy_hp, state.enemy_max_hp]
	enemy_hp_bar.max_value = state.enemy_max_hp
	enemy_hp_bar.value = state.enemy_hp
	defense_label.text = "GUARD %d   /   WARD %d" % [state.guard, state.ward]
	ap_meter.show_ap(state.ap)
	_preview_ap(ap_meter.preview_cost)
	defense_meter.show_defense(state.guard, state.ward)
	status_icons[0].tooltip_text = "Guard: %d. Absorbs first; expires after the next enemy action." % state.guard
	status_icons[1].tooltip_text = "Ward: %d. Persists until consumed or combat ends." % state.ward
	status_icons[0].modulate = Color.WHITE if state.guard > 0 else Color("53606A")
	status_icons[1].modulate = Color.WHITE if state.ward > 0 else Color("53606A")
	herbs_label.text = "Run herbs  %d" % state.run_inventory.herbs
	budget_label.text = "Herb budget left  %d" % state.herb_budget
	inventory.set_quantity("herb", state.run_inventory.herbs)
	intent_label.text = "Attack for %d damage" % state.enemy_intent if not state.is_finished() else "Combat ended"
	intent_label.tooltip_text = intent_label.text
	turn_label.text = "TURN %02d / %s" % [state.turn, STATE.Phase.keys()[state.phase].replace("_", " ")]
	_sync_action_availability()


func _refresh(values: Array[int]) -> void:
	for i: int in range(tiles.size()):
		tiles[i].set("tile_kind", values[i])
		tiles[i].set_pressed_no_signal(i == selected)
		tiles[i].queue_redraw()


func _build_loadout(column: VBoxContainer) -> void:
	_label(column, "EQUIPMENT", 18)
	var equipment := GridContainer.new()
	equipment.columns = 3
	column.add_child(equipment)
	for slot: String in ["Weapon", "Armor", "Helmet", "Amulet", "Ring I", "Ring II"]:
		var button := Button.new()
		button.text = {"Weapon": "Wpn", "Armor": "Arm", "Helmet": "Hel", "Amulet": "Amu", "Ring I": "R1", "Ring II": "R2"}[slot]
		button.custom_minimum_size = Vector2(62, 34)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = slot + " — empty equipment slot"
		equipment.add_child(button)
	_label(column, "ABILITIES", 16)
	shield_bash_button = Button.new()
	shield_bash_button.text = "Shield Bash / 3 AP"
	shield_bash_button.custom_minimum_size.y = 32
	shield_bash_button.tooltip_text = "Consume all Guard to deal equal physical damage. Costs 3 AP."
	shield_bash_button.mouse_entered.connect(_preview_ap.bind(RULES.SHIELD_BASH_AP_COST))
	shield_bash_button.mouse_exited.connect(_preview_ap.bind(0))
	shield_bash_button.focus_entered.connect(_preview_ap.bind(RULES.SHIELD_BASH_AP_COST))
	shield_bash_button.focus_exited.connect(_preview_ap.bind(0))
	shield_bash_button.pressed.connect(_on_shield_bash_pressed)
	column.add_child(shield_bash_button)
	ability_previews.append(shield_bash_button)
	_placeholder(column, "Ability II / Locked")
	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.tooltip_text = "After your swap, finish the turn and let the enemy act."
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	column.add_child(end_turn_button)
	if combat.developer_tools_enabled:
		debug_undo_button = Button.new()
		debug_undo_button.text = "DEBUG / Undo Last Turn"
		debug_undo_button.add_theme_font_size_override("font_size", 13)
		debug_undo_button.tooltip_text = "Developer only. Restore the state before the last turn's first valid action. One checkpoint; no redo."
		debug_undo_button.pressed.connect(_on_debug_undo_pressed)
		column.add_child(debug_undo_button)
	_label(column, "CONSUMABLES", 16)
	_placeholder(column, "Reserved / —")
	_label(column, "INVENTORY", 16)
	inventory = INVENTORY.new()
	column.add_child(inventory)
	inventory.set_entries([{"id": "herb", "name": "Herb bundle", "description": "Collected herbs. Materials only; no automatic healing.", "texture": preload("res://assets/tiles/herb.png"), "quantity": 0}])
	herbs_label = _label(column, "")
	budget_label = _label(column, "", 14)
