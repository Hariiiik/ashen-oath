extends Button
## Presentation only. Tile identity is supplied by the board model.

const NAMES: Array[String] = ["Sword", "Shield", "Herb", "Action"]
# Provisional art is assigned in board_tile.tscn; replacement needs no logic edits.
@export var sword_texture: Texture2D
@export var shield_texture: Texture2D
@export var herb_texture: Texture2D
@export var action_texture: Texture2D
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
	var texture: Texture2D = [sword_texture, shield_texture, herb_texture, action_texture][tile_kind]
	if texture != null:
		# Fit inside the existing square hitbox, leaving the selection border visible.
		var side: float = maxf(0.0, minf(size.x, size.y) - 8.0)
		var source_size: Vector2 = texture.get_size()
		var ratio: float = side / maxf(source_size.x, source_size.y)
		var draw_size: Vector2 = (source_size * ratio).floor()
		draw_texture_rect(texture, Rect2(((size - draw_size) / 2.0).floor(), draw_size), false)
	if button_pressed:
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("c0a66d"), false, 2.0)
