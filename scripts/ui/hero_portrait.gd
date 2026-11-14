extends Control
## Presentation wrapper; class and level are supplied by the owning screen.
const Actor = preload("res://scripts/ui/actor_view.gd")
const SKIN = preload("res://scripts/ui/forest_relic_theme.gd")
var actor_view: Actor = Actor.new()
var caption: Label = Label.new()
var _frame: StyleBoxTexture
var _plaque: StyleBoxTexture


func _init() -> void:
	custom_minimum_size = Vector2(220, 270)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor_view.name = "ActorView"
	add_child(actor_view)
	caption.name = "Caption"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 16)
	caption.add_theme_color_override("font_color", Color("C8B89A"))
	add_child(caption)
	set_identity("Warden", 1)


func _ready() -> void:
	_frame = _make_box(SKIN.texture("panels/portrait_frame.png", Rect2i(0, 0, 235, 246), 2), Vector4(14, 16, 14, 16))
	_frame.draw_center = false
	_plaque = _make_box(SKIN.texture("panels/label_plate.png", Rect2i(0, 0, 327, 87), 2), Vector4(20, 10, 20, 10))
	resized.connect(_layout)
	_layout()


func set_identity(class_label: String, level: int) -> void:
	caption.text = "%s  /  LVL %02d" % [class_label.to_upper(), level]


func _make_box(texture: Texture2D, margins: Vector4) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = margins.x
	box.texture_margin_top = margins.y
	box.texture_margin_right = margins.z
	box.texture_margin_bottom = margins.w
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return box


func _layout() -> void:
	actor_view.position = Vector2(14, 16)
	actor_view.size = Vector2(maxf(0, size.x - 28), maxf(0, size.y - 60))
	caption.position = Vector2(12, size.y - 40)
	caption.size = Vector2(maxf(0, size.x - 24), 34)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(10, 12), size - Vector2(20, 24)), Color("161515"))
	if _frame != null:
		draw_style_box(_frame, Rect2(Vector2.ZERO, size - Vector2(0, 10)))
	if _plaque != null:
		draw_style_box(_plaque, Rect2(Vector2(0, size.y - 44), Vector2(size.x, 44)))
