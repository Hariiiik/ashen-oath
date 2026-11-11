extends SceneTree
## Run: godot --headless --path . --script tests/combat_ui_smoke.gd


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	root.size = Vector2i(1280, 720)
	var scene := load("res://scenes/combat/combat_screen.tscn") as PackedScene
	var screen := scene.instantiate() as Control
	root.add_child(screen)
	await process_frame
	await process_frame
	var tiles: Array[Node] = screen.find_children("*", "Button", true, false)
	var count: int = 0
	var enemy_stage := screen.get_child(2).get_child(0).get_child(1) as Control
	for node: Node in tiles:
		var button := node as Button
		if button.disabled:
			continue
		count += 1
		assert(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(button.get_global_rect()), "Tile outside viewport")
		# The structural boundary is independent of current mouse position.
		assert(button.mouse_filter == Control.MOUSE_FILTER_STOP)
		assert(button.get_global_rect().position.y > enemy_stage.get_global_rect().end.y, "Board overlaps enemy region")
		if count == 1:
			button.button_pressed = true
			button.pressed.emit()
			assert("selected" in screen.get("feedback").text)
	assert(count == 49, "Expected 49 selectable tiles")
	var feedback := screen.get("feedback") as Label
	assert(feedback.get_global_rect().end.y <= 720, "Feedback clipped")
	print("PASS: 49 tiles fit; board below enemy; selection feedback works.")
	screen.queue_free()
	quit()
