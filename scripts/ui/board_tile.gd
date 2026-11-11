extends Button
## Presentation only. Tile identity is supplied by the board model.

const NAMES: Array[String] = ["Sword", "Shield", "Herb", "Action"]
const COLORS: Array[Color] = [Color("c3bba5"), Color("8c9b99"), Color("85966d"), Color("b4a786")]
var tile_kind: int = 0:
	set(value):
		tile_kind = value
		tooltip_text = NAMES[value] if value >= 0 else "Empty"
		queue_redraw()


func _ready() -> void:
	tooltip_text = NAMES[tile_kind]
	toggled.connect(_on_toggled)


func _on_toggled(_selected: bool) -> void:
	queue_redraw()


func _draw() -> void:
	if tile_kind < 0:
		return
	var c: Color = COLORS[tile_kind]
	var p: Vector2 = (size / 2.0).floor()
	match tile_kind:
		0:
			draw_rect(Rect2(p + Vector2(-3, -15), Vector2(6, 23)), c)
			draw_rect(Rect2(p + Vector2(-10, 5), Vector2(20, 4)), c)
			draw_rect(Rect2(p + Vector2(-2, 9), Vector2(4, 7)), c)
		1:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-13, -13), p + Vector2(13, -13), p + Vector2(10, 6), p + Vector2(0, 16), p + Vector2(-10, 6)]), c)
			draw_rect(Rect2(p + Vector2(-2, -9), Vector2(4, 19)), Color("303638"))
		2:
			draw_rect(Rect2(p + Vector2(-2, -8), Vector2(4, 24)), c)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-1, 1), p + Vector2(-13, -3), p + Vector2(-13, -12), p + Vector2(-4, -10)]), c)
			draw_colored_polygon(PackedVector2Array([p + Vector2(1, -4), p + Vector2(4, -15), p + Vector2(14, -15), p + Vector2(12, -5)]), c)
		3:
			draw_colored_polygon(PackedVector2Array([p + Vector2(2, -16), p + Vector2(-12, 3), p + Vector2(-2, 3), p + Vector2(-5, 16), p + Vector2(13, -6), p + Vector2(3, -6)]), c)
	if button_pressed:
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("c0a66d"), false, 2.0)
