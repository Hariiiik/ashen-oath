extends PanelContainer
## Nonmodal, right-column-only presentation. Availability belongs to the screen.
var craft_button: Button
var close_button: Button
var quantities_label: Label


func _ready() -> void:
	name = "EmergencyCrafting"
	visible = false
	z_index = 20
	custom_minimum_size = Vector2(210, 136)
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("26211E")
	surface.border_color = Color("72553B")
	surface.set_border_width_all(2)
	surface.set_content_margin_all(8)
	add_theme_stylebox_override("panel", surface)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := Label.new()
	title.text = "Emergency crafting"
	title.add_theme_font_size_override("font_size", 14)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	close_button = Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Close crafting"
	close_button.custom_minimum_size = Vector2(28, 28)
	close_button.theme_type_variation = "CompactButton"
	heading.add_child(close_button)
	close_button.pressed.connect(close)
	quantities_label = Label.new()
	quantities_label.add_theme_font_size_override("font_size", 13)
	column.add_child(quantities_label)
	craft_button = Button.new()
	craft_button.text = "Craft Bandage / 6 Herbs"
	craft_button.tooltip_text = "Emergency crafting: consume 6 Herbs to make 1 Bandage. No AP cost."
	craft_button.custom_minimum_size.y = 36
	craft_button.add_theme_font_size_override("font_size", 13)
	craft_button.theme_type_variation = "CompactButton"
	column.add_child(craft_button)
	set_quantities(0, 0)


func toggle_open() -> void:
	visible = not visible


func close() -> void:
	hide()


func set_quantities(herbs: int, bandages: int) -> void:
	quantities_label.text = "Herbs %d / Bandages %d" % [herbs, bandages]


func place_near_belt(belt_rect: Rect2, allowed_rect: Rect2) -> void:
	var popup_size := Vector2(maxf(210, allowed_rect.size.x - 16), 136)
	popup_size = popup_size.min(allowed_rect.size)
	size = popup_size
	# Prefer the read-only bag area, leaving abilities, Undo and the belt usable.
	var below: float = belt_rect.end.y + 4
	var popup_y: float = below if below + size.y <= allowed_rect.end.y else belt_rect.position.y - size.y - 4
	var desired := Vector2(belt_rect.position.x, popup_y)
	desired.x = clampf(desired.x, allowed_rect.position.x, allowed_rect.end.x - size.x)
	desired.y = clampf(desired.y, allowed_rect.position.y, allowed_rect.end.y - size.y)
	global_position = desired
