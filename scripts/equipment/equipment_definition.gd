extends Resource
## Static content; share definitions as read-only data, never as item instance state.
const Slots = preload("res://scripts/equipment/equipment_slots.gd")
const Modifier = preload("res://scripts/equipment/equipment_modifier.gd")

@export var item_id: StringName = &""
@export var display_name: String = ""
@export var compatible_slots: Array[StringName] = []
@export var modifiers: Array[Modifier] = []


func is_valid() -> bool:
	if String(item_id).strip_edges().is_empty() or compatible_slots.is_empty():
		return false
	var seen: Array[StringName] = []
	for slot: StringName in compatible_slots:
		if not Slots.is_valid(slot) or slot in seen:
			return false
		seen.append(slot)
	for modifier: Modifier in modifiers:
		if modifier == null or not modifier.is_valid():
			return false
	return true


func supports_slot(slot: StringName) -> bool:
	return Slots.is_valid(slot) and slot in compatible_slots
