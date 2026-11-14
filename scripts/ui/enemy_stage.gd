extends HBoxContainer
## Visual slots only: no targeting, enemy list, or additional combat state.
const ACTOR_VIEW = preload("res://scripts/ui/actor_view.gd")
const RELIC = preload("res://scripts/ui/forest_relic_theme.gd")
const ART_BLEED: float = 32.0
signal slots_changed
var cards: Array[Control] = []
var actor_views: Array[ACTOR_VIEW] = []
var art_frames: Array[Control] = []
var info_panels: Array[Control] = []
var primary_name_label: Label
var primary_hp_label: Label
var primary_hp_bar: ProgressBar
var primary_intent: Label


func _ready() -> void:
	name = "EnemyStage"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	add_theme_constant_override("separation", 12)
	resized.connect(_layout_cards)
	set_enemy_count(1)


func set_enemy_count(count: int) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	cards.clear()
	actor_views.clear()
	art_frames.clear()
	info_panels.clear()
	for index: int in range(clampi(count, 1, 3)):
		var card := Control.new()
		card.name = "EnemySlot%d" % (index + 1)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.resized.connect(_layout_cards)
		add_child(card)
		cards.append(card)
		var frame := Panel.new()
		frame.name = "ArtFrame"
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_theme_stylebox_override("panel", _frame_style(true))
		card.add_child(frame)
		art_frames.append(frame)
		var art := ACTOR_VIEW.new()
		art.name = "EnemyArtwork"
		art.enemy = true
		actor_views.append(art)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(art)
		var panel := PanelContainer.new()
		panel.name = "EnemyInformation"
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", _frame_style(false))
		card.add_child(panel)
		info_panels.append(panel)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(info)
		var caption := Label.new()
		caption.text = "HOLLOW SENTINEL" if index == 0 else "Enemy slot %d" % (index + 1)
		caption.tooltip_text = caption.text
		caption.add_theme_font_size_override("font_size", 18 if clampi(count, 1, 3) == 1 else 14)
		caption.clip_text = true
		info.add_child(caption)
		var hp := Label.new()
		hp.add_theme_font_size_override("font_size", 14)
		info.add_child(hp)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(40, 14)
		bar.show_percentage = false
		info.add_child(bar)
		var intent := Label.new()
		intent.add_theme_font_size_override("font_size", 14 if clampi(count, 1, 3) == 1 else 13)
		intent.clip_text = true
		info.add_child(intent)
		for node: Node in info.get_children():
			(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		if index == 0:
			primary_name_label = caption
			primary_hp_label = hp
			primary_hp_bar = bar
			primary_intent = intent
		else:
			hp.text = "Preview only"
			bar.value = 0
			intent.text = "No combat actor"
	_layout_cards()
	slots_changed.emit()


func _layout_cards() -> void:
	for index: int in range(cards.size()):
		var card: Control = cards[index]
		var art_width: float = floorf(card.size.x * 0.38)
		var gap: float = 8.0 if cards.size() == 1 else 5.0
		art_frames[index].position = Vector2.ZERO
		art_frames[index].size = Vector2(art_width, maxf(0, card.size.y - 12))
		# ActorView clips its own artwork. Its larger bounds reserve a lower leg /
		# weapon overhang beyond the frame, inside the screen's artwork clearance.
		actor_views[index].position = Vector2(6, 6)
		actor_views[index].size = Vector2(maxf(0, art_width - 12), card.size.y + ART_BLEED - 6)
		info_panels[index].position = Vector2(art_width + gap, 6)
		info_panels[index].size = Vector2(maxf(0, card.size.x - art_width - gap), maxf(0, card.size.y - 12))


func _frame_style(art: bool) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = RELIC.texture("panels/portrait_frame.png", Rect2i(3, 3, 229, 240), 2) if art else RELIC.texture("panels/center_panel.png", Rect2i(3, 3, 494, 283), 2)
	box.texture_margin_left = 12
	box.texture_margin_top = 12
	box.texture_margin_right = 12
	box.texture_margin_bottom = 12
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.draw_center = false
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box
