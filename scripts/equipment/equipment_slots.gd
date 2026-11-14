extends RefCounted
## Prototype identifiers matching the six existing visual slots, not final slot design.
const WEAPON: StringName = &"weapon"
const ARMOR: StringName = &"armor"
const HELMET: StringName = &"helmet"
const AMULET: StringName = &"amulet"
const RING_I: StringName = &"ring_i"
const RING_II: StringName = &"ring_ii"


static func all() -> Array[StringName]:
	return [WEAPON, ARMOR, HELMET, AMULET, RING_I, RING_II]


static func is_valid(slot: StringName) -> bool:
	return slot in all()
