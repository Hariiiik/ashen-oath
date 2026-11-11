extends Control
## Geometric silhouettes replace external art. Always ignore pointer input.

@export var enemy: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var center: Vector2 = Vector2(floorf(size.x / 2.0), 0)
	var ink := Color("56545b") if enemy else Color("686970")
	var gold := Color("98825c")
	var width: float = 72.0 if enemy else 48.0
	draw_rect(Rect2(center + Vector2(-width, 66), Vector2(width * 2, size.y - 74)), Color("303038"))
	draw_rect(Rect2(center + Vector2(-32, 27), Vector2(64, 68)), ink)
	draw_rect(Rect2(center + Vector2(-37, 20), Vector2(74, 16)), gold)
	if enemy:
		for side: int in [-1, 1]:
			draw_rect(Rect2(center + Vector2(side * 48 - 8, 5), Vector2(16, 54)), gold)
			draw_rect(Rect2(center + Vector2(side * 22 - 6, 49), Vector2(12, 5)), Color("ad535d"))
	else:
		draw_rect(Rect2(center + Vector2(-22, 48), Vector2(44, 6)), Color("17181e"))
		draw_rect(Rect2(center + Vector2(-4, 54), Vector2(8, 34)), gold)
