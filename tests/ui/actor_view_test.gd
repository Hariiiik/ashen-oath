extends SceneTree
## Presentation-only tests: no combat model is needed to exercise actor playback.
const View = preload("res://scripts/ui/actor_view.gd")
const Definition = preload("res://scripts/ui/actor_visual_definition.gd")
const Queue = preload("res://scripts/ui/combat_visual_queue.gd")
const Stage = preload("res://scripts/ui/enemy_stage.gd")
const ActorScene = preload("res://scenes/ui/actor_view.tscn")
const CombatTheme = preload("res://scenes/ui/combat_theme.tres")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	create_timer(10.0).timeout.connect(func() -> void: push_error("Actor test timeout"); quit(1))
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _settle() -> void:
	for index: int in range(3):
		await process_frame


func _definition() -> Definition:
	var definition := Definition.new()
	var image := Image.create(8, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color("87919A"))
	definition.texture = ImageTexture.create_from_image(image)
	definition.sprite_frames = SpriteFrames.new()
	definition.sprite_frames.add_animation(&"hit")
	definition.sprite_frames.set_animation_loop(&"hit", false)
	definition.sprite_frames.set_animation_speed(&"hit", 60.0)
	definition.sprite_frames.add_frame(&"hit", definition.texture)
	definition.sprite_frames.add_frame(&"hit", definition.texture)
	definition.sprite_frames.add_animation(&"ambient")
	definition.sprite_frames.set_animation_loop(&"ambient", true)
	definition.sprite_frames.add_frame(&"ambient", definition.texture)
	definition.clips[&"damage"] = &"hit"
	return definition


func _run() -> void:
	var view: View = ActorScene.instantiate() as View
	view.size = Vector2(80, 80)
	root.add_child(view)
	await _settle()
	_check(view.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Actor ignores board input")
	_check(view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Actor nearest filtering")
	_check(view.get_node("Placeholder").visible, "Missing definition uses placeholder")
	_check(not view.get_node("Texture").visible and not view.get_node("Animation").visible, "No empty asset view")
	var reports: Array[Dictionary] = []
	view.clip_finished.connect(func(clip: StringName, cancelled: bool) -> void: reports.append({"clip": clip, "cancelled": cancelled}))
	_check(not view.play_clip(&"missing"), "Missing clip reports unavailable")
	await _settle()
	_check(reports.size() == 1 and not reports[0].cancelled, "Missing clip completes without waiting")
	_check(not view.is_playing_clip(), "Missing clip releases playback")
	var definition: Definition = _definition()
	view.visual_definition = definition
	_check(view.get_node("Texture").visible, "Static art without idle clip")
	_check(not view.get_node("Placeholder").visible, "Static art replaces placeholder")
	_check(view.get_node("Texture").stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Texture preserves source proportions")
	_check(definition.has_clip(&"damage") and not definition.has_clip(&"absent"), "Optional clip mapping")
	_check(view.play_clip(&"damage"), "Known clip plays")
	var sprite: AnimatedSprite2D = view.get_node("Animation")
	_check(sprite.scale.x == sprite.scale.y and sprite.scale.x == 5.0, "Animation fits without stretching and uses integer upscale")
	_check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Animation nearest filtering")
	await create_timer(0.15).timeout
	_check(reports.size() == 2 and reports[-1].clip == &"damage" and not reports[-1].cancelled, "One completion for authored clip")
	_check(not view.is_playing_clip(), "Authored clip releases playback")
	_check(view.get_node("Texture").visible, "Resting image restored after clip")
	view.play_clip(&"damage")
	view.cancel_playback()
	await _settle()
	_check(reports.size() == 3 and reports[-1].cancelled, "Cancel completes exactly once")
	view.play_clip(&"damage")
	view.skip_playback()
	await _settle()
	_check(reports.size() == 4 and not reports[-1].cancelled, "Skip completes exactly once")
	view.play_clip(&"missing")
	view.play_clip(&"damage")
	await create_timer(0.15).timeout
	_check(reports.size() == 6 and reports[-2].cancelled and not reports[-1].cancelled, "Replaced missing deferred clip cannot finish newer clip")
	view.play_clip(&"ambient")
	await _settle()
	_check(reports.size() == 7 and not view.is_playing_clip(), "Looping clips cannot block queue")
	definition.idle_clip = &"ambient"
	view.visual_definition = definition
	_check(sprite.visible and sprite.animation == &"ambient" and sprite.is_playing(), "Optional idle animation is ambient only")
	_check(not view.is_playing_clip(), "Ambient idle does not hold action playback")
	view.enemy = true
	_check(view.get_node("Placeholder").enemy, "Fallback role changes without gameplay")
	var queue := Queue.new()
	root.add_child(queue)
	var queue_results: Array[bool] = []
	var completions: Array[StringName] = []
	queue.queue_finished.connect(func(cancelled: bool) -> void: queue_results.append(cancelled))
	queue.clip_completed.connect(func(clip: StringName, _cancelled: bool) -> void: completions.append(clip))
	queue.enqueue(view, &"damage")
	queue.enqueue(view, &"absent")
	await create_timer(0.2).timeout
	_check(completions == [&"damage", &"absent"], "Queue preserves presentation order")
	_check(queue_results == [false] and not queue.is_playing(), "Queue drains once")
	queue.enqueue(view, &"damage")
	queue.enqueue(view, &"damage")
	await process_frame
	queue.cancel()
	var after_cancel: int = completions.size()
	await create_timer(0.15).timeout
	_check(queue_results == [false, true], "Queue cancellation reports once")
	_check(completions.size() == after_cancel and not queue.is_playing(), "Cancelled callbacks cannot advance discarded queue")
	queue.enqueue(view, &"damage")
	await process_frame
	queue.skip_current()
	await _settle()
	_check(queue_results == [false, true, false], "Queue can restart and skip after cancellation")
	var temporary := View.new()
	temporary.visual_definition = definition
	root.add_child(temporary)
	queue.enqueue(temporary, &"damage")
	await process_frame
	temporary.queue_free()
	await _settle()
	_check(not queue.is_playing(), "Freed actor cannot strand queue")
	var detached := View.new()
	queue.enqueue(detached, &"damage")
	detached.free()
	queue.enqueue(view, &"missing")
	await _settle()
	_check(not queue.is_playing(), "Missing queued actor and clip both drain safely")
	var stage := Stage.new()
	root.add_child(stage)
	for count: int in [1, 2, 3]:
		stage.set_enemy_count(count)
		_check(stage.cards.size() == count and stage.actor_views.size() == count, "Reusable stage actor capacity")
		_check(is_instance_valid(stage.primary_hp_label) and is_instance_valid(stage.primary_hp_bar) and is_instance_valid(stage.primary_intent), "Existing stage bindings preserved")
		for actor: View in stage.actor_views:
			_check(actor.enemy and actor.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Preview enemy is decorative")
	_check(CombatTheme.get_color("font_color", "Label").is_equal_approx(Color("C8B89A")), "Reusable theme uses approved Bone")
	queue.free()
	stage.free()
	view.free()
	await _settle()
	print("Actor presentation tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
