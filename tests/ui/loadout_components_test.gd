extends SceneTree
const Bag = preload("res://scripts/ui/inventory_bag.gd")
const Belt = preload("res://scripts/ui/consumables_belt.gd")
const Crafting = preload("res://scripts/ui/crafting_popup.gd")
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
	var bag := Bag.new()
	bag.position = Vector2(1000, 400)
	bag.size = Vector2(250, 260)
	root.add_child(bag)
	bag.inventory.set_entries([
		{"id": "herb", "glyph": "H", "quantity": 0},
		{"id": "bandage", "glyph": "BND", "quantity": 0}])
	bag.set_summary(9, 2, 7)
	var belt := Belt.new()
	belt.position = Vector2(1000, 300)
	belt.size = Vector2(250, 68)
	root.add_child(belt)
	var popup := Crafting.new()
	root.add_child(popup)
	await process_frame
	await process_frame
	_check(bag.inventory.grid.get_child_count() == 15, "Inventory retains fifteen slots")
	_check(bag.inventory.cells.herb.text == "×9" and bag.inventory.cells.bandage.text == "×2", "Both stacks stay live")
	_check(bag.inventory.custom_minimum_size.y == 120, "Inventory retains viewport minimum")
	_check(bag.inventory.get_v_scroll_bar().max_value > bag.inventory.size.y, "Inventory still scrolls")
	for cell: Control in bag.inventory.grid.get_children():
		_check(cell.size.x >= 58 and cell.size.y >= 58, "Inventory hitbox minimum retained")
	belt.set_quantity(3)
	_check(belt.use_button.text.contains("×3"), "Belt quantity supplied by adapter")
	_check(belt.size.y <= 72, "Belt height stays compact")
	_check(not popup.visible, "Crafting starts closed")
	popup.toggle_open()
	popup.set_quantities(4, 3)
	popup.craft_button.disabled = true
	_check(popup.visible and not popup.close_button.disabled and not belt.hammer_button.disabled, "Unavailable crafting remains open and closable")
	var allowed := Rect2(992, 100, 270, 580)
	popup.place_near_belt(belt.get_global_rect(), allowed)
	await process_frame
	_check(allowed.encloses(popup.get_global_rect()), "Crafting stays in right-column bounds")
	_check(popup.get_global_rect().position.y >= belt.get_global_rect().end.y, "Crafting prefers bag area without covering the belt")
	popup.close_button.pressed.emit()
	_check(not popup.visible, "Close button closes crafting")
	bag.queue_free()
	belt.queue_free()
	popup.queue_free()
	await process_frame
	print("Loadout components: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
