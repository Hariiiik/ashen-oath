extends Control
## Board interaction and presentation; combat stats and loadout remain fixtures.

const TILE_SCENE: PackedScene = preload("res://scenes/ui/board_tile.tscn")
const PORTRAIT = preload("res://scripts/ui/placeholder_portrait.gd")
const BOARD = preload("res://scripts/board/board_model.gd")
signal board_resolved(result: BOARD.SwapResult)
@export var board_seed: int = 1
var feedback: Label
var turn_label: Label
var board: BOARD
var tiles: Array[Button] = []
var selected: int = -1
var resolving: bool = false
var moves: int = 0


func _ready() -> void:
	board = BOARD.new(board_seed)
	theme = _make_theme()
	var background := ColorRect.new()
	background.color = Color("101116")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_build_hero(_column(0.0, 0.2))
	_build_center(_column(0.2, 0.8))
	_build_loadout(_column(0.8, 1.0))


func _style(fill: String, border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill)
	style.border_color = Color(border)
	style.set_border_width_all(2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_color("font_color", "Label", Color("dbd3c0"))
	result.set_stylebox("panel", "PanelContainer", _style("1b1c23", "51493e"))
	result.set_stylebox("normal", "Button", _style("262830", "514d48"))
	result.set_stylebox("hover", "Button", _style("36343a", "b39a66"))
	result.set_stylebox("pressed", "Button", _style("41343a", "b39a66"))
	result.set_stylebox("disabled", "Button", _style("202127", "3e3a36"))
	result.set_color("font_disabled_color", "Button", Color("a49d90"))
	result.set_stylebox("background", "ProgressBar", _style("101116", "51493e"))
	result.set_stylebox("fill", "ProgressBar", _style("803f4b", "803f4b"))
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
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	return column


func _label(parent: Node, copy: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _health(parent: Node, caption: String, amount: float) -> void:
	_label(parent, caption)
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 18
	bar.value = amount
	bar.show_percentage = false
	parent.add_child(bar)


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
	_label(column, "THE OATHBOUND", 20)
	_portrait(column, false, 172)
	_label(column, "Ser Aldric", 24)
	_label(column, "WARDEN  /  LEVEL 01")
	_health(column, "HP  80 / 100", 80)
	_label(column, "ATK  12     DEF  08", 18)
	column.add_child(HSeparator.new())
	_label(column, "STATUS EFFECTS")
	_placeholder(column, "—   —   —")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	_label(column, "Combat UI prototype", 14)
	_label(column, "All values are illustrative", 13)


func _build_center(column: VBoxContainer) -> void:
	column.add_theme_constant_override("separation", 2)
	_label(column, "ASHEN OATH  /  THE HOLLOW CRYPT", 18)
	# Artwork extends above its decorative frame, in a separate region from the board.
	var stage := PanelContainer.new()
	stage.custom_minimum_size.y = 116
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(stage)
	var portrait := _portrait(stage, true, 100)
	portrait.z_index = 1
	_health(column, "THE HOLLOW SENTINEL   /   HP 120 / 120", 100)
	_label(column, "INTENT  /  Heavy strike  •  Preview only", 16)
	var center := CenterContainer.new()
	column.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	center.add_child(grid)
	for row: int in range(7):
		for col: int in range(7):
			var tile := TILE_SCENE.instantiate() as Button
			tile.set("tile_kind", board.cells[row * 7 + col])
			tiles.append(tile)
			grid.add_child(tile)
			tile.pressed.connect(_on_tile_pressed.bind(row * 7 + col))
	turn_label = _label(column, "BOARD MOVE 00  /  SELECT TWO ADJACENT TILES", 16)
	feedback = _label(column, "Sword / Shield / Herb / Action  •  Seed %d" % board_seed, 14)
	# Long cascade reports must not push the three columns beyond the viewport.
	feedback.clip_text = true


func _on_tile_pressed(index: int) -> void:
	if resolving:
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
	for tile: Button in tiles:
		tile.disabled = true
	var before: Array[int] = board.cells.duplicate()
	var preview: Array[int] = before.duplicate()
	preview[a.y * 7 + a.x] = before[index]
	preview[index] = before[a.y * 7 + a.x]
	_refresh(preview)
	await get_tree().create_timer(0.15).timeout
	var result: BOARD.SwapResult = board.try_swap(a, b)
	if not result.valid:
		feedback.text = "No match. Swap reverted; no move spent."
	else:
		moves += 1
		for step: BOARD.CascadeStep in result.steps:
			var ranks: PackedStringArray = []
			for group: BOARD.MatchGroup in step.matches:
				ranks.append("Match-%s" % ("5+" if group.rank == 5 else str(group.rank)))
			feedback.text = "Cascade %d  /  %s  /  %d tiles" % [step.index + 1, ", ".join(ranks), step.removed.size()]
			feedback.tooltip_text = feedback.text
			_refresh(step.cleared)
			await get_tree().create_timer(0.22).timeout
			_refresh(step.refilled)
			await get_tree().create_timer(0.22).timeout
		if result.reshuffled:
			feedback.text = "No legal moves remained. Board reshuffled."
		turn_label.text = "BOARD MOVE %02d  /  %d CASCADE STEPS" % [moves, result.steps.size()]
	_refresh(result.final_cells)
	for tile: Button in tiles:
		tile.disabled = false
	resolving = false
	board_resolved.emit(result)


func _refresh(values: Array[int]) -> void:
	for i: int in range(tiles.size()):
		tiles[i].set("tile_kind", values[i])
		tiles[i].set_pressed_no_signal(i == selected)
		tiles[i].queue_redraw()


func _build_loadout(column: VBoxContainer) -> void:
	_label(column, "EQUIPMENT", 20)
	for slot: String in ["Weapon", "Armor", "Helmet", "Amulet", "Ring I", "Ring II"]:
		_placeholder(column, slot + "   /   —")
	column.add_child(HSeparator.new())
	_label(column, "ACTIVE ABILITIES", 18)
	_placeholder(column, "Ability slot I   /   Locked")
	_placeholder(column, "Ability slot II   /   Locked")
	column.add_child(HSeparator.new())
	_label(column, "RESOURCES", 18)
	_label(column, "Gold   —     /     Charges   —")
	_label(column, "Loadout preview only", 14)
