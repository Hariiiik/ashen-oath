extends HBoxContainer
## Visual slots only: no targeting, enemy list, or additional combat state.
const ACTOR_VIEW = preload("res://scripts/ui/actor_view.gd")
signal slots_changed
var cards: Array[Control] = []
var actor_views: Array[ACTOR_VIEW] = []
var primary_hp_label: Label
var primary_hp_bar: ProgressBar
var primary_intent: Label


func _ready() -> void:
	name = "EnemyStage"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	add_theme_constant_override("separation", 12)
	set_enemy_count(1)


func set_enemy_count(count: int) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	cards.clear()
	actor_views.clear()
	for index: int in range(clampi(count, 1, 3)):
		var card := HBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(card)
		cards.append(card)
		var art := ACTOR_VIEW.new()
		art.enemy = true
		actor_views.append(art)
		art.custom_minimum_size.x = 86 if count > 1 else 170
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(art)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(info)
		var caption := Label.new()
		caption.text = "HOLLOW SENTINEL" if index == 0 else "Enemy slot %d" % (index + 1)
		caption.tooltip_text = caption.text
		caption.add_theme_font_size_override("font_size", 14)
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
		intent.add_theme_font_size_override("font_size", 13)
		intent.clip_text = true
		info.add_child(intent)
		for node: Node in info.get_children():
			(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		if index == 0:
			primary_hp_label = hp
			primary_hp_bar = bar
			primary_intent = intent
		else:
			hp.text = "Preview only"
			bar.value = 0
			intent.text = "No combat actor"
	slots_changed.emit()
