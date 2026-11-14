extends Control
## Read-only presentation. Iron plates are decoration, never an Armor resource.
const SKIN = preload("res://scripts/ui/forest_relic_theme.gd")
@export var defense: bool = false
var amount: int = 0
var capacity: int = 6
var preview_cost: int = 0
var guard: int = 0
var ward: int = 0
var _segment_boxes: Dictionary[String, StyleBoxTexture] = {}


func _ready() -> void:
	custom_minimum_size.y = 40 if defense else 26
	mouse_filter = Control.MOUSE_FILTER_PASS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)


func show_ap(value: int, limit: int = 6) -> void:
	amount = value
	capacity = limit
	queue_redraw()


func show_defense(guard_value: int, ward_value: int) -> void:
	guard = guard_value
	ward = ward_value
	tooltip_text = "Guard: %d (expires after enemy action)\nWard: %d (until consumed or combat ends)\nIron backing is decorative; no Armor stat. Each overlay segment represents up to 6 points; exact totals appear above." % [guard, ward]
	queue_redraw()


func set_preview(cost: int) -> void:
	preview_cost = cost
	queue_redraw()


func _draw() -> void:
	if capacity <= 0:
		return
	# One trough with joined plates; fixed cap widths preserve the source edges.
	draw_rect(Rect2(Vector2(0, 2), Vector2(size.x, size.y - 4)), Color("161515"))
	for i: int in range(capacity):
		var rect: Rect2 = segment_rect(i)
		draw_style_box(_segment_box("empty"), rect)
		if defense:
			# Worn base, Guard sprite, then the existing translucent Ward veil.
			if i < ceili(guard / 6.0):
				draw_style_box(_segment_box("guard"), rect)
			if i < ceili(ward / 6.0):
				draw_rect(rect.grow(-4), Color(0.42, 0.46, 0.50, 0.65))
				draw_rect(rect.grow(-4), Color("B4BCC1"), false)
		else:
			if i < amount:
				draw_style_box(_segment_box("ap"), rect)
			if i < preview_cost:
				var color := Color("C8B89A") if i < amount else Color("8A4A32")
				draw_rect(rect, color, false, 2.0)
				if i >= amount:
					draw_line(rect.position + Vector2(3, 3), rect.end - Vector2(3, 3), color, 2.0)


func segment_rect(index: int) -> Rect2:
	var left: float = floorf(size.x * index / capacity)
	var right: float = floorf(size.x * (index + 1) / capacity)
	return Rect2(Vector2(left, 2), Vector2(right - left - (1 if index < capacity - 1 else 0), size.y - 4))


func _segment_box(kind: String) -> StyleBoxTexture:
	if not _segment_boxes.has(kind):
		var box := StyleBoxTexture.new()
		box.texture = SKIN.segment_texture(kind)
		box.texture_margin_left = 4
		box.texture_margin_right = 4
		box.texture_margin_top = 4
		box.texture_margin_bottom = 4
		_segment_boxes[kind] = box
	return _segment_boxes[kind]
