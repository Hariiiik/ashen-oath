extends PanelContainer
## Temporary native leather surface; no inventory ownership or item rules.
const Inventory = preload("res://scripts/ui/inventory_grid.gd")
var inventory: Inventory
var herbs_label: Label
var budget_label: Label


func _ready() -> void:
	name = "InventoryBag"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("3A2B21")
	surface.border_color = Color("72553B")
	surface.set_border_width_all(2)
	surface.content_margin_left = 10
	surface.content_margin_right = 10
	surface.content_margin_top = 10
	surface.content_margin_bottom = 8
	add_theme_stylebox_override("panel", surface)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	inventory = Inventory.new()
	column.add_child(inventory)
	herbs_label = Label.new()
	budget_label = Label.new()
	for label: Label in [herbs_label, budget_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	set_summary(0, 0, 0)


func set_summary(herbs: int, bandages: int, budget: int) -> void:
	herbs_label.text = "Herbs %d / Bandages %d" % [herbs, bandages]
	budget_label.text = "Herb budget left  %d" % budget
	inventory.set_quantity("herb", herbs)
	inventory.set_quantity("bandage", bandages)
