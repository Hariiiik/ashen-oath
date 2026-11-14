@tool
extends Theme
## Presentation adapter. Source PNGs remain unchanged; see FOREST_RELIC_UI.md.
const ROOT: String = "res://assets/ui/"
static var _textures: Dictionary[String, Texture2D] = {}


static func texture(path: String, region: Rect2i, divisor: int) -> Texture2D:
	var key: String = "%s:%s:%d" % [path, region, divisor]
	if not _textures.has(key):
		var source := load(ROOT + path) as Texture2D
		var image: Image = source.get_image().get_region(region)
		# Uniform nearest reduction, cached once. No writes to source artwork.
		image.resize(maxi(1, roundi(float(region.size.x) / divisor)), maxi(1, roundi(float(region.size.y) / divisor)), Image.INTERPOLATE_NEAREST)
		_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]


static func segment_texture(kind: String) -> Texture2D:
	var key: String = "segment:%s" % kind
	if _textures.has(key):
		return _textures[key]
	var source: Texture2D
	match kind:
		"ap":
			source = texture("meters/segment_ap.png", Rect2i(3, 3, 90, 92), 3)
		"guard":
			source = texture("meters/segment_guard.png", Rect2i(3, 3, 92, 92), 3)
		_:
			# Exclude the unrelated atlas strip above the actual empty segment.
			source = texture("meters/segment_empty.png", Rect2i(35, 77, 95, 92), 3)
	# Pad to a common square without stretching any segment's frame.
	var image: Image = source.get_image()
	var canvas := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	canvas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), (Vector2i(32, 32) - image.get_size()) / 2)
	_textures[key] = ImageTexture.create_from_image(canvas)
	return _textures[key]


func _box(path: String, region: Rect2i, divisor: int, margins: Vector4, content: float = 8.0) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture(path, region, divisor)
	box.texture_margin_left = margins.x
	box.texture_margin_top = margins.y
	box.texture_margin_right = margins.z
	box.texture_margin_bottom = margins.w
	# Repeat grain/rivets instead of stretching full illustrations or borders.
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.content_margin_left = content
	box.content_margin_top = content
	box.content_margin_right = content
	box.content_margin_bottom = content
	return box


func _compact(fill: String, border: String) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill)
	box.border_color = Color(border)
	box.set_border_width_all(2)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


func _init() -> void:
	default_font_size = 16
	set_color("font_color", "Label", Color("C8B89A"))
	set_color("font_disabled_color", "Button", Color("8E7D62"))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		set_color(state, "Button", Color("C8B89A"))
	set_color("font_outline_color", "Button", Color("161515"))
	set_constant("outline_size", "Button", 2)
	set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	for variant: String in ["RelicHeroPanel", "RelicCenterPanel", "RelicLoadoutPanel", "RelicInventorySlot"]:
		set_type_variation(variant, "PanelContainer")
	set_stylebox("panel", "RelicHeroPanel", _box("panels/hero_panel.png", Rect2i(3, 3, 178, 415), 2, Vector4(24, 36, 14, 32)))
	set_stylebox("panel", "RelicCenterPanel", _box("panels/center_panel.png", Rect2i(3, 3, 494, 283), 2, Vector4(48, 32, 48, 32)))
	set_stylebox("panel", "RelicLoadoutPanel", _box("panels/loadout_panel.png", Rect2i(3, 3, 153, 411), 2, Vector4(12, 28, 18, 26)))
	# The painted interiors are not seamless. Use the supplied frame only instead
	# of distorting/repeating the full illustrations behind gameplay information.
	for variant: String in ["RelicHeroPanel", "RelicCenterPanel", "RelicLoadoutPanel"]:
		var frame: StyleBoxTexture = get_stylebox("panel", variant) as StyleBoxTexture
		frame.draw_center = false
	# Quiet text backplates keep bottom foliage away from footer glyphs without
	# increasing column minimum height or shifting existing gameplay components.
	set_type_variation("RelicFooter", "Label")
	var footer := StyleBoxFlat.new()
	footer.bg_color = Color("161515")
	set_stylebox("normal", "RelicFooter", footer)
	set_type_variation("RelicCombatFooter", "PanelContainer")
	var combat_footer := StyleBoxFlat.new()
	combat_footer.bg_color = Color("161515")
	combat_footer.border_color = Color("53606A")
	combat_footer.border_width_top = 1
	combat_footer.content_margin_top = 2
	set_stylebox("panel", "RelicCombatFooter", combat_footer)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("C8B89A")
	focus.set_border_width_all(1)
	set_stylebox("focus", "Button", focus)
	set_stylebox("panel", "RelicInventorySlot", _box("slots/inventory_slot.png", Rect2i(3, 3, 179, 180), 4, Vector4(8, 10, 8, 8)))
	set_type_variation("RelicEquipmentSlot", "Button")
	set_type_variation("CompactButton", "Button")
	set_type_variation("BoardTileButton", "CompactButton")
	var states: Array[String] = ["normal", "hover", "pressed", "disabled"]
	var regions: Array[Rect2i] = [Rect2i(3, 3, 296, 110), Rect2i(3, 3, 300, 110), Rect2i(3, 3, 294, 105), Rect2i(3, 3, 296, 110)]
	var margins: Array[Vector4] = [Vector4(10, 10, 10, 10), Vector4(11, 10, 11, 10), Vector4(10, 9, 10, 9), Vector4(10, 10, 10, 10)]
	var fills: Array[String] = ["26211E", "2F3438", "2F4A34", "26211E"]
	var borders: Array[String] = ["53606A", "A1693D", "87919A", "44484A"]
	for index: int in range(states.size()):
		var state: String = states[index]
		set_stylebox(state, "Button", _box("buttons/button_%s.png" % state, regions[index], 3, margins[index]))
		var slot: StyleBoxTexture = _box("slots/equipment_slot.png", Rect2i(3, 3, 178, 177), 4, Vector4(6, 6, 6, 6))
		if state == "hover":
			slot.modulate_color = Color(1.18, 1.12, 1.02)
		elif state == "pressed":
			slot.modulate_color = Color(0.8, 0.8, 0.8)
		elif state == "disabled":
			slot.modulate_color = Color(0.65, 0.65, 0.65)
		set_stylebox(state, "RelicEquipmentSlot", slot)
		set_stylebox(state, "CompactButton", _compact(fills[index], borders[index]))
	set_stylebox("background", "ProgressBar", _box("meters/health_trough.png", Rect2i(3, 3, 320, 65), 5, Vector4(4, 3, 4, 3), 0))
	# Red interior only. The trough owns the stationary decorative end caps.
	var health: StyleBoxTexture = _box("meters/health_fill.png", Rect2i(20, 18, 286, 33), 5, Vector4.ZERO, 0)
	health.expand_margin_left = -3
	health.expand_margin_right = -3
	health.expand_margin_top = -3
	health.expand_margin_bottom = -3
	set_stylebox("fill", "ProgressBar", health)
