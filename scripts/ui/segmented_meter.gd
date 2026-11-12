extends Control
## Read-only presentation. Iron plates are decoration, never an Armor resource.
@export var defense: bool = false
var amount: int = 0
var capacity: int = 6
var preview_cost: int = 0
var guard: int = 0
var ward: int = 0


func _ready() -> void:
	custom_minimum_size.y = 40 if defense else 26
	mouse_filter = Control.MOUSE_FILTER_PASS
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
		draw_rect(rect, Color("2F3438"))
		draw_rect(rect, Color("53606A"), false, 1.0)
		if defense:
			# Worn iron base, Guard chain patches, then translucent Ward veil.
			draw_line(rect.position + Vector2(3, 5), rect.end - Vector2(4, 6), Color("44484A"), 1.0)
			if i < ceili(guard / 6.0):
				for y: int in range(6, int(size.y) - 5, 6):
					for x: int in range(3, int(width) - 2, 6):
						draw_rect(Rect2(rect.position + Vector2(x, y), Vector2(3, 3)), Color("87919A"), false)
			if i < ceili(ward / 6.0):
				draw_rect(rect.grow(-2), Color(0.42, 0.46, 0.50, 0.65))
				draw_rect(rect.grow(-2), Color("B4BCC1"), false)
		else:
			if i < amount:
				draw_rect(rect.grow(-2), Color("8B8A52"))
				draw_highlight(rect)
			if i < preview_cost:
				var color := Color("C8B89A") if i < amount else Color("8A4A32")
				draw_rect(rect, color, false, 2.0)
				if i >= amount:
					draw_line(rect.position + Vector2(3, 3), rect.end - Vector2(3, 3), color, 2.0)


func draw_highlight(rect: Rect2) -> void:
	draw_line(rect.position + Vector2(3, 3), rect.position + Vector2(rect.size.x - 3, 3), Color("C8B89A"), 1.0)
