# Technical Architecture — Ashen Oath
Version 0.1 — foundation, Godot 4 / typed GDScript wherever practical.

## Goals
Readable single-player code, fast iteration, deterministic battle logic, editable content without deep rewrites, no unnecessary dependencies.

## Layers and boundaries
1. **Domain (pure logic):** board arrays, match discovery, swap validation, damage calculations, turn transitions, inventory rules. No Node paths or UI dependencies in testable calculations.
2. **Application (orchestration):** `CombatController`, `RunController` coordinate domain logic and send presentation events.
3. **Presentation:** Godot scenes, panels, animations, pixel-art sprites. These may request actions but cannot become the source of truth for HP, tile content or equipment effects.
4. **Content:** typed Godot `Resource` definitions (`.tres`) for character, enemy, item and ability data when implemented. JSON only where suitable for external fixtures.

## Planned flow
`PlayerInput -> CombatController -> BoardModel -> MatchResolver -> CombatEffects -> TurnController -> CombatState -> UI updates`.
Use signals for significant state changes and direct function calls for clear local dependencies. Avoid a universal event bus for every call.

### Implemented combat slice
`scripts/board/board_model.gd` is a seeded, node-independent `RefCounted` model
covering generation, swaps, grouped matches, gravity/refill, cascades and dead-board
reshuffling. `try_swap()` returns structured per-cascade snapshots and deduplicated
match groups. The board engine remains independent from combat.

`scripts/combat/combat_controller.gd` owns the board and combat state, accepts swaps
only during `PLAYER_INPUT`, advances one cascade step at a time and gates enemy
actions. After all steps, `finish_player_resolution()` enters `POST_MATCH`;
only explicit `end_turn()` opens `ENEMY_ACTION`. No timer advances the decision
phase. `combat_rules.gd` applies prototype tile effects, Shield Bash and damage absorption;
`combat_state.gd` owns encounter HP, Guard/Ward, AP, herb budget, phase, turn and
intent. `run_inventory.gd` stores stackable Herbs and Bandages in memory; passing the same inventory to
another controller retains them without a run system or persistence service.

Groups resolve in row-major order by their first cell. Each deduplicated group
receives one effect using its longest straight run. All groups within a step
resolve before checking victory; a lethal step prevents later cascade effects
and enemy retaliation. The existing board engine precomputes refill snapshots;
unused snapshots after victory have no combat effects. Guard absorbs before Ward,
then HP; remaining Guard expires after an enemy action, and Ward clears on either
combat outcome. Enemy intent alternates 5/8, starting at 5.

`scripts/ui/combat_screen.gd` requests swaps and step progression, presents live
state, locks input during playback/enemy actions and permanently disables the
board on victory/defeat. `board_resolved(result)` remains a presentation-completion
signal and must not be used to apply the effects a second time. It now completes
board playback before the post-match decision, not the whole combat turn.
Shield Bash, emergency Bandage crafting/use and End Turn are functional action
buttons. No standard/between-battle crafting, other items/abilities, equipment
modifiers or full run controller are implemented.
Prototype constants and launch/test commands are in `COMBAT_UI_PROTOTYPE.md`;
these testing values do not finalize the GDD's open balance decisions.

## Suggested future files (do not generate empty scripts for all of these)
```
scenes/combat/combat_screen.tscn
scripts/board/board_model.gd
scripts/board/match_detector.gd
scripts/board/board_resolver.gd
scripts/combat/combat_controller.gd
scripts/combat/combat_state.gd
scripts/combat/combat_rules.gd
scripts/combat/enemy_intent.gd
scripts/items/item_definition.gd
scripts/characters/class_definition.gd
```

## Core models
- `BoardModel`: 7x7 grid, exactly Sword/Shield/Herb/Action base tile ids and seedable RNG, no Godot UI references. Match-4/5 effects resolve immediately, without deferred special tiles.
- `CombatState`: hero HP/stats, temporary Guard (expires after the next enemy action), finite Ward pool (until consumed or combat ends), shared consumable/ability AP, enemy HP/stats/intent, turn phase, board state and remaining encounter herb budget. AP never grants additional swaps.
- `CombatRules`: integer formulas, effect order, damage/healing/Guard/Ward caps. Herb matches collect materials within the encounter budget, never heal, and keep resolving without materials after exhaustion; Herb tiles stay on the board. Healing item activation is manual and costs AP. Unresolved balance and Herb/Action special rewards stay unspecified.
- `RunState` (later): seed, map progress, run-persistent herb materials, rewards, unlocks; no hub assumption.
- `ItemDefinition`/`AbilityDefinition` (later): static content definitions, with separate runtime state for cooldowns/uses.

Keep definitions extensible for future classes, loot and crafting; the MVP has only Warden. The only implemented recipe is emergency Bandage crafting for 6 Herbs and no AP. Standard recipe cost is 4 Herbs, but its availability is future preparation between runs or special crafting/safe rooms, not automatic between-battle access. No preparation, safe-room or Hub system is implemented. See the GDD for approved rules and provisional balance. Fatigue is outside the MVP.

### Emergency Bandage slice

`CombatRules` validates player action phases and resources before mutating stacks.
`emergency_craft_bandage()` consumes 6 Herbs and adds one Bandage without AP or
healing. `use_bandage()` consumes one Bandage and a provisional 2 AP, restores
up to a provisional 12 HP and rejects use at full HP. The controller wraps both
actions with pre-turn Undo capture and diagnostics, leaving board/RNG, phase,
swap count, Guard/Ward and enemy action unchanged. The UI additionally locks
both actions throughout visual playback. Tile herb collection remains unchanged.

Encounter persistence uses explicit ownership, not a global/meta store:
construct controllers with `Combat.new(seed, shared_inventory)`, or assign
`combat_screen.run_inventory` before adding the scene to the tree. Each encounter
uses that same `RunInventory` object; a new standalone scene without injection
creates a fresh one. `RunInventory` owns no encounter phase, HP or AP. No automatic
encounter transition or post-victory screen is introduced. Inventory adapters
display both live quantities; Bandage uses a native BND placeholder glyph.

## State and input safety
States: `PLAYER_INPUT`, `RESOLVING_BOARD`, `RESOLVING_EFFECTS`, `POST_MATCH`, `ENEMY_ACTION`, `VICTORY`, `DEFEAT`. Board swaps are accepted only during `PLAYER_INPUT`. Shield Bash is accepted during `PLAYER_INPUT` or `POST_MATCH`, with Guard > 0 and at least 3 AP. All input actions validate phase; do not allow animation callbacks to create extra turns. Mark transitions explicitly.

`CombatRules.can_shield_bash()` and `shield_bash()` validate before mutation,
capture Guard, spend exactly 3 AP, clear Guard, then apply physical damage using
the existing armor subtraction (no penetration). The controller's
`activate_shield_bash()` checks victory immediately, otherwise retaining the
current phase. No board/RNG, intent, swap count, Ward or run inventory is changed
by the ability; standard combat-end cleanup remains in force on lethal damage.
There is no cooldown or once-per-turn flag. The UI additionally blocks activation
throughout visual playback, including the brief swap preview before model resolution.

## Determinism and testing

Developer-only diagnostics and one-turn Undo are described in
`DEBUG_COMBAT.md`. `turn_snapshot.gd` captures the stable state before the first
successful action of a turn, including pre-swap Shield Bash, and restores board,
RNG, scalar combat/ability fields and both run inventory stacks without replaying effects. Undo
is forbidden during resolution/enemy action but allowed after victory/defeat;
the UI additionally gates visual playback. These are debug facilities, not combat
rules or player rewind mechanics. Raw match-run metadata supports diagnosis
without changing grouping/ranking or balance.

- Seed board generation for replayable tests.
- When gameplay is implemented, test match detection, cascades, dead boards, invalid swaps, basic Match-3 and immediate Match-4/5 effects, intent, HP, Guard expiry, Ward consumption/end-of-combat clearing, manual healing/AP use, and herb budget exhaustion without tile removal. Verify run-persistent herbs and that AP cannot buy swaps. Do not encode unresolved rewards or balance as approved behavior.
- The first automated test suite may use lightweight Godot headless test scripts; add a test framework only if its maintenance is justified.
- UI smoke test in Godot editor after changes; report explicitly if Godot is not installed.

## Pixel-art rendering
Use nearest-neighbor filtering; design at baseline 1280x720 and keep logical board hitboxes independent of monster visuals. Do not intercept board input with decorative overlays (`mouse_filter = IGNORE` on appropriate Control overlays). Manage visual stacking via `CanvasLayer` or canvas `z_index` with explicit layering, without obscuring interaction.

## Git and change workflow
- Small atomic commits, status checks, readable diffs.
- No unrequested refactors or mass reformatting.
- Every PR/task report includes changed files, tests run, and limitations.
- Do not put secrets or generated Godot cache into Git.

## Future hub extension point
`RunController` should end with a `RunResult` data structure and save/unlock service interface. Build no hub screens or NPC systems now.
