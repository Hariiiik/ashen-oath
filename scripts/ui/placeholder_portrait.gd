extends Control
## Geometric silhouettes replace external art. Always ignore pointer input.

@export var enemy: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var reference := Vector2(160, 120) if enemy else Vector2(160, 240)
	var factor: float = minf(size.x / reference.x, size.y / reference.y)
	draw_set_transform(((size - reference * factor) / 2.0).floor(), 0, Vector2.ONE * factor)
	var center := Vector2(80, 0)
	var ink := Color("53606A")
	var accent := Color("7A5237")
	draw_rect(Rect2(center + Vector2(-66, 60), Vector2(132, reference.y - 64)), Color("2F3438"))
	draw_rect(Rect2(center + Vector2(-29, 24), Vector2(58, 62)), ink)
	draw_rect(Rect2(center + Vector2(-34, 18), Vector2(68, 12)), accent)
	if enemy:
		for side: int in [-1, 1]:
			draw_rect(Rect2(center + Vector2(side * 48 - 8, 2), Vector2(16, 54)), accent)
			draw_rect(Rect2(center + Vector2(side * 20 - 6, 44), Vector2(12, 5)), Color("8A4A32"))
	else:
		draw_rect(Rect2(center + Vector2(-22, 45), Vector2(44, 6)), Color("161515"))
		draw_rect(Rect2(center + Vector2(-4, 51), Vector2(8, 34)), Color("87919A"))
		for y: int in range(100, 220, 28):
			draw_rect(Rect2(24, y, 112, 20), ink)
			draw_line(Vector2(26, y), Vector2(132, y), Color("87919A"), 1)
			draw_rect(Rect2(78, y, 4, 20), accent)
