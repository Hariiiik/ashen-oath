extends PanelContainer
## Presentation-only quick slots. The screen connects all action callbacks.
var use_button: Button
var hammer_button: Button


func _ready() -> void:
	name = "ConsumablesBelt"
	custom_minimum_size.y = 68
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("3A2B21")
	surface.border_color = Color("72553B")
	surface.set_border_width_all(2)
	surface.content_margin_left = 5
	surface.content_margin_right = 5
	surface.content_margin_top = 14
	surface.content_margin_bottom = 14
	add_theme_stylebox_override("panel", surface)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	add_child(row)
	use_button = _button(row, "", 108)
	use_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	use_button.tooltip_text = "Use 1 Bandage to restore up to 12 HP. Costs 2 AP. Unavailable at full HP."
	for index: int in range(2):
		var slot := _button(row, "-", 29)
		slot.disabled = true
		slot.tooltip_text = "Locked consumable slot"
	hammer_button = _button(row, "Craft", 45)
	# Use an installed symbol font when available; keep English fallback portable.
	var symbol_font := SystemFont.new()
	symbol_font.font_names = PackedStringArray(["Segoe UI Symbol"])
	if symbol_font.has_char(0x2692):
		hammer_button.text = String.chr(0x2692)
		hammer_button.add_theme_font_override("font", symbol_font)
		hammer_button.add_theme_font_size_override("font_size", 20)
	hammer_button.tooltip_text = "Open or close emergency crafting"
	set_quantity(0)


func _button(row: HBoxContainer, text: String, width: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 36)
	button.add_theme_font_size_override("font_size", 12)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("30251E") if state != "hover" else Color("51402D")
		style.border_color = Color("72553B") if state != "focus" else Color("C8B89A")
		style.set_border_width_all(1)
		style.content_margin_left = 3
		style.content_margin_right = 3
		button.add_theme_stylebox_override(state, style)
	row.add_child(button)
	return button


func set_quantity(quantity: int, ap_cost: int = 2) -> void:
	use_button.text = "BND ×%d / %d AP" % [quantity, ap_cost]
