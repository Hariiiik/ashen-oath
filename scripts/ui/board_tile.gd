extends Button
## Presentation only: selection never swaps tiles or changes combat state.

const NAMES: Array[String] = ["Sword", "Shield", "Skull", "Heart"]
const COLORS: Array[Color] = [Color("c3bba5"), Color("8c9b99"), Color("b4a786"), Color("a65c61")]
var tile_kind: int = 0


func _ready() -> void:
	tooltip_text = NAMES[tile_kind] + " — placeholder"
	toggled.connect(_on_toggled)


func _on_toggled(_selected: bool) -> void:
	queue_redraw()


func _draw() -> void:
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
			draw_rect(Rect2(p + Vector2(-12, -12), Vector2(24, 21)), c)
			draw_rect(Rect2(p + Vector2(-8, 9), Vector2(16, 6)), c)
			for x: int in [-8, 3]:
				draw_rect(Rect2(p + Vector2(x, -5), Vector2(6, 6)), Color("242126"))
		3:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -9), p + Vector2(-6, -14), p + Vector2(0, -7), p + Vector2(6, -14), p + Vector2(14, -9), p + Vector2(14, 0), p + Vector2(0, 15), p + Vector2(-14, 0)]), c)
	if button_pressed:
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("c0a66d"), false, 2.0)
