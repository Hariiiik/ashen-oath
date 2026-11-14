extends SceneTree

const Slots = preload("res://scripts/equipment/equipment_slots.gd")
const Definition = preload("res://scripts/equipment/equipment_definition.gd")
const Modifier = preload("res://scripts/equipment/equipment_modifier.gd")
const Loadout = preload("res://scripts/equipment/equipment_loadout.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run()
	print("Equipment tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func _fixture(id: StringName, slots: Array[StringName]) -> Definition:
	var definition := Definition.new()
	definition.item_id = id
	definition.display_name = "Test fixture"
	definition.compatible_slots = slots
	return definition


func _run() -> void:
	var slots: Array[StringName] = Slots.all()
	_check(slots.size() == 6, "Six prototype slots match existing visual layout")
	for slot: StringName in slots:
		_check(Slots.is_valid(slot), "Known slot has stable identity")
	slots.clear()
	_check(Slots.all().size() == 6 and not Slots.is_valid(&"unknown"), "Caller cannot mutate slot registry")
	var weapon := _fixture(&"test_weapon", [Slots.WEAPON])
	var replacement := _fixture(&"test_replacement", [Slots.WEAPON])
	var ring := _fixture(&"test_ring", [Slots.RING_I, Slots.RING_II])
	var loadout := Loadout.new()
	_check(loadout.snapshot().is_empty() and loadout.get_item(Slots.WEAPON) == null, "New loadout is empty")
	_check(weapon is Resource and loadout is RefCounted, "Definitions and runtime assignments have independent data-only lifetimes")
	_check(weapon.is_valid() and weapon.supports_slot(Slots.WEAPON) and not weapon.supports_slot(Slots.ARMOR), "Definition declares compatible slots")
	_check(loadout.equip(Slots.WEAPON, weapon) and loadout.get_item(Slots.WEAPON) == weapon, "Compatible equipment assigned by reference")
	var before: Dictionary = loadout.snapshot()
	_check(not loadout.equip(Slots.ARMOR, weapon), "Incompatible equipment rejected")
	_check(not loadout.equip(&"unknown", weapon) and not loadout.equip(Slots.WEAPON, null), "Unknown slot and null definition rejected")
	_check(loadout.snapshot() == before, "Rejected equips do not alter assignments")
	_check(loadout.equip(Slots.WEAPON, replacement) and loadout.get_item(Slots.WEAPON) == replacement, "Replacement affects only selected slot")
	_check(loadout.equip(Slots.RING_I, ring) and loadout.equip(Slots.RING_II, ring), "A static ring definition supports both prototype ring slots")
	_check(loadout.unequip(Slots.WEAPON) == replacement and loadout.get_item(Slots.WEAPON) == null, "Unequip returns prior assignment")
	_check(loadout.unequip(Slots.WEAPON) == null and loadout.unequip(&"unknown") == null, "Unequip absent or unknown slot is safe")
	var another := Loadout.new()
	_check(another.snapshot().is_empty(), "Runtime loadouts do not share assignments")
	_check(another.restore(before) and another.get_item(Slots.WEAPON) == weapon, "Snapshot transfers slot mapping while preserving static definition identity")
	before.clear()
	_check(another.get_item(Slots.WEAPON) == weapon, "Restore copies the caller's mapping")
	var saved: Dictionary = loadout.snapshot()
	saved.erase(Slots.RING_I)
	_check(loadout.get_item(Slots.RING_I) == ring, "Snapshot editing does not change live slots")
	var invalid_definitions: Array[Definition] = [Definition.new(), _fixture(&"", [Slots.WEAPON]), _fixture(&"test_empty", []), _fixture(&"test_unknown", [&"unknown"]), _fixture(&"test_repeat", [Slots.WEAPON, Slots.WEAPON])]
	for definition: Definition in invalid_definitions:
		before = loadout.snapshot()
		_check(not definition.is_valid() and not loadout.equip(Slots.WEAPON, definition), "Malformed static definition rejected")
		_check(loadout.snapshot() == before, "Invalid definition leaves assignments intact")
	var invalid_snapshots: Array[Dictionary] = [
		{Slots.WEAPON: weapon, &"unknown": ring},
		{Slots.WEAPON: null},
		{Slots.WEAPON: 42},
		{Slots.WEAPON: Resource.new()},
		{Slots.ARMOR: weapon},
		{"weapon": weapon},
		{Slots.WEAPON: Definition.new()}
	]
	for invalid: Dictionary in invalid_snapshots:
		before = loadout.snapshot()
		_check(not loadout.restore(invalid), "Malformed snapshot rejected")
		_check(loadout.snapshot() == before, "Restore validates entire snapshot before changing slots")
	_check(loadout.restore({}) and loadout.snapshot().is_empty(), "Empty snapshot clears assignments")
	var modifier := Modifier.new()
	_check(not modifier.is_valid(), "Empty future modifier identifier rejected")
	modifier.effect_id = &"test_descriptor_only"
	modifier.parameters = {"fixture": 7}
	weapon.modifiers.append(modifier)
	_check(modifier.is_valid() and weapon.is_valid() and another.get_item(Slots.WEAPON).modifiers[0] == modifier, "Static inert descriptors remain attached without evaluation")
	weapon.modifiers.append(null)
	_check(not weapon.is_valid(), "Null descriptor invalidates definition")
	weapon.modifiers.pop_back()
	modifier.effect_id = &""
	_check(not weapon.is_valid(), "Invalid descriptor invalidates definition")
