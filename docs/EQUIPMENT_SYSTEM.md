# Equipment data contracts

Implemented scope: data model only. There are no equipment bonuses, combat
modifiers, item catalog, generated loot, equipment interactions or equip UI.
These contracts do not finalize equipment balance or the GDD's proposed slots.

## Static content and runtime state

- `equipment_slots.gd` exposes six prototype `StringName` identifiers matching
  existing visual slots: `weapon`, `armor`, `helmet`, `amulet`, `ring_i`,
  `ring_ii`. `all()` returns a fresh typed array; `is_valid(slot)` checks identity.
- `equipment_definition.gd` is an editor-friendly `Resource`: `item_id`,
  `display_name`, `compatible_slots` and `modifiers`. `is_valid()` checks a
  nonempty ID, nonempty unique known slots and valid modifier descriptors.
  `supports_slot(slot)` checks compatibility. Treat shared definitions as read-only
  static content once assigned; they are not unique inventory item instances.
- `equipment_modifier.gd` is an inert `Resource` containing an `effect_id` and
  generic `parameters`. Its only validation is a nonempty ID. No evaluator,
  stacking rules, operations, final effect IDs or numerical bonuses are defined.
- `equipment_loadout.gd` is a `RefCounted` runtime mapping owned by a run. It has
  no Node, UI, combat, RNG or inventory dependency. Passing the same loadout to
  subsequent encounters preserves equipment without any combat calculation.

## Loadout API

| Method | Contract |
| --- | --- |
| `get_item(slot)` | Returns the assigned definition or `null`. |
| `equip(slot, definition) -> bool` | Validates slot, definition and compatibility before replacing one assignment. Failure changes nothing. |
| `unequip(slot)` | Removes an assignment and returns its former definition, or `null`. |
| `snapshot() -> Dictionary` | Returns an independent mapping of populated `StringName` slots to static definition references. |
| `restore(snapshot) -> bool` | Validates the complete mapping, then replaces assignments atomically. Empty mapping clears the loadout. |

Snapshots copy assignments, not the referenced Resources: changing a snapshot's
keys never changes the live loadout, but editing a definition edits shared content.
This is an in-memory contract, not a disk-save format or a deep content backup.
Restore rejects unknown/non-StringName keys, null/wrong-type values and incompatible
or invalid definitions. No ownership transfer, quantity, uniqueness, inventory
removal or combat recalculation is implied by equip/unequip. Two assignments may
share a definition (for example, a future pair of identical rings); actual item
instance/quantity rules require future scoped design.

The run owns a loadout reference outside `CombatState`. Existing turn Undo does
not need to capture equipment because this slice provides no in-combat equipment
actions. Any later equipment mutation during combat must explicitly extend Undo
and the relevant combat contracts before it is implemented.

## Verification

Run `godot --headless --path . --script tests/equipment/equipment_test.gd`.
The harness uses transient test definitions only; no item assets or final bonuses
are added. It covers slot compatibility, invalid action atomicity, replacement,
independent loadouts, copied mapping snapshots, atomic restore and inert descriptors.
