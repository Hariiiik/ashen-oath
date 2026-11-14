extends SceneTree
## Enemy slots remain decorative and expose stable live-state binding points.
const Stage = preload("res://scripts/ui/enemy_stage.gd")
const CombatTheme = preload("res://scenes/ui/combat_theme.tres")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _settle() -> void:
	for index: int in range(4):
		await process_frame


func _ignore_tree(node: Node) -> void:
	if node is Control:
		_check((node as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "All enemy decoration ignores input")
	for child: Node in node.get_children():
		_ignore_tree(child)


func _run() -> void:
	var stage := Stage.new()
	stage.theme = CombatTheme
	root.add_child(stage)
	var emissions: Array[int] = [0]
	stage.slots_changed.connect(func() -> void: emissions[0] += 1)
	for dimensions: Vector2 in [Vector2(680, 128), Vector2(1020, 192)]:
		stage.size = dimensions
		for requested: int in [0, 1, 2, 3, 4]:
			stage.set_enemy_count(requested)
			await _settle()
			var count: int = clampi(requested, 1, 3)
			_check(stage.cards.size() == count and stage.actor_views.size() == count, "Clamped visual capacity")
			_check(stage.art_frames.size() == count and stage.info_panels.size() == count, "Public frame bounds available")
			_check(not stage.clip_contents, "Stage allows lower artwork overhang")
			stage.primary_name_label.text = "HOLLOW SENTINEL"
			stage.primary_hp_label.text = "HP 21 / 40"
			stage.primary_hp_bar.max_value = 40
			stage.primary_hp_bar.value = 21
			stage.primary_intent.text = "Attack for 8 damage"
			_check(stage.primary_hp_bar.value == 21 and stage.primary_intent.text == "Attack for 8 damage", "Live binding targets remain writable")
			for index: int in range(count):
				var card: Control = stage.cards[index]
				var frame: Rect2 = stage.art_frames[index].get_global_rect()
				var info: Rect2 = stage.info_panels[index].get_global_rect()
				var actor: Rect2 = stage.actor_views[index].get_global_rect()
				_check(stage.get_global_rect().encloses(card.get_global_rect()), "Slot stays inside stage")
				_check(card.get_global_rect().encloses(frame) and card.get_global_rect().encloses(info), "Separate art frame and info stay inside slot")
				_check(frame.end.x <= info.position.x and actor.end.x <= info.position.x, "Art cannot cover live information")
				_check(is_equal_approx(actor.end.y, card.get_global_rect().end.y + 32), "Actor reserves exactly 32px lower bleed")
				_check(actor.end.y < stage.get_global_rect().end.y + 80, "Artwork leaves clearance before board")
				_check(stage.actor_views[index].clip_contents and not card.clip_contents, "Actor clips inside its larger safe bounds")
				if index > 0:
					_check((stage.info_panels[index].get_child(0).get_child(1) as Label).text == "Preview only", "Additional slots stay preview-only")
			_ignore_tree(stage)
	_check(emissions[0] == 10, "Every rebuild emits binding refresh")
	stage.queue_free()
	await process_frame
	print("Enemy stage: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
