extends SceneTree
const Hero = preload("res://scripts/ui/hero_portrait.gd")
const Meter = preload("res://scripts/ui/segmented_meter.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var hero := Hero.new()
	hero.set_identity("Warden", 1)
	root.add_child(hero)
	var meter := Meter.new()
	root.add_child(meter)
	for dimensions: Vector2 in [Vector2(250, 350), Vector2(375, 525)]:
		hero.size = dimensions
		meter.size = Vector2(dimensions.x, 30)
		await process_frame
		_check(hero.caption.text == "WARDEN  /  LVL 01", "Identity belongs on portrait plaque")
		_check(hero.actor_view.size.y > dimensions.y * 0.8, "Portrait fills frame height")
		_check(Rect2(Vector2.ZERO, hero.size).encloses(Rect2(hero.actor_view.position, hero.actor_view.size)), "Actor stays within frame")
		_check(hero.caption.position.y >= hero.actor_view.position.y + hero.actor_view.size.y - 10, "Plaque stays below portrait")
		_check(hero.mouse_filter == Control.MOUSE_FILTER_IGNORE and hero.caption.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Decoration ignores input")
		_check(not hero._frame.draw_center, "Frame cannot obscure actor")
		meter.show_ap(2, 6)
		meter.set_preview(3)
		_check(meter.amount == 2 and meter.capacity == 6 and meter.preview_cost == 3, "AP preview preserves live values")
		_check(meter.segment_rect(0).position.x == 0 and meter.segment_rect(5).end.x == meter.size.x, "Joined bar spans full width")
		_check(meter.segment_rect(1).position.x - meter.segment_rect(0).end.x == 1, "Plates have one pixel seam")
		meter.defense = true
		meter.show_defense(7, 13)
		_check(meter.guard == 7 and meter.ward == 13 and ceili(meter.guard / 6.0) == 2 and ceili(meter.ward / 6.0) == 3, "Defense keeps exact totals and six-point groups")
		_check(meter._segment_box("guard").texture_margin_left == 4, "Segment edges keep fixed cap width")
	hero.set_identity("Warden", 12)
	_check(hero.caption.text.ends_with("12"), "Identity updates after ready")
	hero.queue_free()
	meter.queue_free()
	await process_frame
	print("Hero panel: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
