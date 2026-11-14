extends Control
## Read-only presentation. Iron plates are decoration, never an Armor resource.
const SKIN = preload("res://scripts/ui/forest_relic_theme.gd")
@export var defense: bool = false
var amount: int = 0
var capacity: int = 6
var preview_cost: int = 0
var guard: int = 0
var ward: int = 0


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
	var gap: float = 4.0
	var width: float = floorf((size.x - gap * (capacity - 1)) / capacity)
	for i: int in range(capacity):
		var rect := Rect2(Vector2(i * (width + gap), 2), Vector2(width, size.y - 4))
		var empty: Texture2D = SKIN.segment_texture("empty")
		var scale_factor: float = minf(rect.size.x / empty.get_width(), rect.size.y / empty.get_height())
		var icon_size: Vector2 = (empty.get_size() * scale_factor).floor()
		var icon_rect := Rect2((rect.position + (rect.size - icon_size) / 2.0).floor(), icon_size)
		draw_texture_rect(empty, icon_rect, false)
		if defense:
			# Worn base, Guard sprite, then the existing translucent Ward veil.
			if i < ceili(guard / 6.0):
				draw_texture_rect(SKIN.segment_texture("guard"), icon_rect, false)
			if i < ceili(ward / 6.0):
				draw_rect(icon_rect.grow(-2), Color(0.42, 0.46, 0.50, 0.65))
				draw_rect(icon_rect.grow(-2), Color("B4BCC1"), false)
		else:
			if i < amount:
				draw_texture_rect(SKIN.segment_texture("ap"), icon_rect, false)
			if i < preview_cost:
				var color := Color("C8B89A") if i < amount else Color("8A4A32")
				draw_rect(rect, color, false, 2.0)
				if i >= amount:
					draw_line(rect.position + Vector2(3, 3), rect.end - Vector2(3, 3), color, 2.0)
