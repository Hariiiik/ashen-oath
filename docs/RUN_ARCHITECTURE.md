# Minimal run architecture

The first run prototype is an explicit sequence of encounters. The default test
sequence repeats the existing Hollow Sentinel three times with distinct seeded
boards; this is not final run length, new enemy content or procedural generation.
The existing Match-3 engine, combat rules, Shield Bash, Bandage, emergency crafting,
RunInventory and one-turn Debug Undo are reused unchanged.

## Ownership and API

- `scripts/run/encounter_definition.gd`: Resource with sequence ID/display metadata
  only. It does not supply enemy stats, combat effects or rewards.
- `run_state.gd`: run seed, copied sequence, predetermined board seeds, zero-based
  encounter index, checkpoint HP/max HP, shared RunInventory and optional independent
  equipment-loadout model reference. No equipment effects are evaluated.
- `run_controller.gd`: RefCounted application owner of `state` and active `combat`.
  `start_run(seed, encounters = [], inventory = null, loadout = null)` starts once;
  a new run needs a new controller. Empty sequence selects the prototype sequence;
  null definitions reject startup. `can_advance_encounter()` and
  `advance_encounter()` accept only an actual nonfinal victory. There is no timer
  or automatic continuation. The presentation must additionally gate playback.
- `run_result.gd`: fresh value summary returned by `get_result()` for current
  defeat or final victory. Includes outcome, seed, completed/total encounters,
  remaining HP/max HP and Herb/Bandage counts. No save/unlock/reward service exists.

All models are independent of Nodes and UI. The combat screen is given the
run-owned CombatController, rather than creating another controller or copying
inventory. Definitions are shared static Resources; runtime sequence arrays are
copied. Optional loadout identity persists without affecting combat calculations.

## Persistence contract

Current HP and max HP carry to the next encounter without automatic healing.
While fighting, **CombatState is authoritative**; RunState HP fields are only
checkpoints. `get_current_hp()` reads the live combat. Checkpoints are updated
only by an accepted explicit advance, so Undo cannot leave a stale copied HP value.

Herbs and Bandages retain the same existing RunInventory instance throughout the
run. Equipment retains the supplied loadout model reference. Every accepted advance
creates a fresh CombatController, resetting Guard, Ward, turn/action counters,
enemy HP/intent and the finite encounter herb budget to existing defaults.
**AP also resets to zero; this is a provisional implementation rule, not a
permanent approved game-design decision.** No combat values are rebalanced.

Victory itself neither advances the sequence nor restores HP. No automatic crafting
or preparation is offered between encounters. Standard 4-Herb crafting remains
unimplemented; emergency 6-Herb crafting and provisional 2-AP/12-HP Bandage use
remain available only through existing combat action windows. There is no Hub,
safe room, room selection, loot generation, boss, save or meta-inventory.

## Determinism and Debug Undo

Startup precomputes encounter seeds from a dedicated seeded RandomNumberGenerator.
Board refill, move choices, visual playback and combat Undo never consume this
source. Same run seed and sequence produce the same initial boards per encounter
under the same Godot version; this is not a cross-version save guarantee.

Undo operates on the current encounter until explicit advance. Advance replaces
the active controller with a fresh one and disables debug tools on the retired
controller, preventing a retained reference from restoring old shared inventory.
No checkpoint crosses encounters. Terminal results and advance availability are
derived from the live phase on every query, so Undo after victory/defeat revokes
them immediately rather than leaving a stale completed/failed run state.

## Verification

Run `godot --headless --path . --script tests/run/run_test.gd`.
The suite covers invalid starts/transitions, explicit continuation, HP/max-HP and
inventory/loadout persistence, Guard/Ward/AP/budget resets, unchanged enemy,
independent deterministic seeds, unchanged crafting/Bandage/Bash integration,
Undo after victory/defeat, rejected cross-encounter Undo and terminal summaries.
Existing combat, Bandage, Shield Bash, board and UI suites remain regression gates.
