extends ScrollContainer
## Data-driven inventory view; entries are supplied by UI adapters, not loot logic.
var grid: GridContainer
var cells: Dictionary = {}


func _ready() -> void:
	name = "Inventory"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	custom_minimum_size.y = 120
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	add_child(grid)


func set_entries(entries: Array[Dictionary]) -> void:
	for child: Node in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	cells.clear()
	for entry: Dictionary in entries:
		var cell := _cell()
		cell.tooltip_text = entry.get("description", entry.get("name", "Item"))
		var content := Control.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(content)
		var icon := TextureRect.new()
		icon.texture = entry.get("texture") as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if icon.texture == null:
			var glyph := Label.new()
			glyph.text = entry.get("glyph", "?")
			glyph.add_theme_font_size_override("font_size", 12)
			glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(glyph)
			glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var count := Label.new()
		count.add_theme_font_size_override("font_size", 14)
		count.add_theme_color_override("font_color", Color("C8B89A"))
		count.add_theme_color_override("font_outline_color", Color("161515"))
		count.add_theme_constant_override("outline_size", 4)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(count)
		count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cells[entry.id] = count
		set_quantity(entry.id, int(entry.get("quantity", 0)))
	# Empty slots reserve future item types and make the inventory scrollable.
	for index: int in range(maxi(0, 15 - entries.size())):
		var cell := _cell()
		cell.tooltip_text = "Empty inventory slot"
		var label := Label.new()
		label.text = "·"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(label)


func _cell() -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(58, 58)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(cell)
	return cell


func set_quantity(id: String, quantity: int) -> void:
	if cells.has(id):
		(cells[id] as Label).text = "×%d" % quantity
