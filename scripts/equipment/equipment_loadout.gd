extends RefCounted
## Run-owned slot assignments only. No bonuses, inventory transfer, or combat effects.
const Slots = preload("res://scripts/equipment/equipment_slots.gd")
const Definition = preload("res://scripts/equipment/equipment_definition.gd")

var _items: Dictionary = {}


func get_item(slot: StringName) -> Definition:
	return _items.get(slot) as Definition


func equip(slot: StringName, definition: Definition) -> bool:
	if not Slots.is_valid(slot) or definition == null or not definition.is_valid() or not definition.supports_slot(slot):
		return false
	_items[slot] = definition
	return true


func unequip(slot: StringName) -> Definition:
	var previous: Definition = get_item(slot)
	_items.erase(slot)
	return previous


func snapshot() -> Dictionary:
	# Only runtime assignments are copied; static Resource references remain shared.
	return _items.duplicate()


func restore(values: Dictionary) -> bool:
	# Validate the entire mapping before mutation; malformed snapshots are atomic no-ops.
	for key: Variant in values:
		if not key is StringName or not Slots.is_valid(key):
			return false
		if not values[key] is Definition:
			return false
		var definition: Definition = values[key] as Definition
		if definition == null or not definition.is_valid() or not definition.supports_slot(key):
			return false
	_items = values.duplicate()
	return true
