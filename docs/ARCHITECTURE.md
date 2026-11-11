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

These are planned boundaries, not instructions to implement systems now. Keep definitions extensible for future classes, loot and crafting; the MVP has only Warden. Future crafting should distinguish between-battle and emergency material costs (Bandage: 4/6 herbs respectively), with activation AP cost separate from any proposed crafting AP cost. No crafting AP cost is approved. See the GDD for approved rules and provisional balance. Fatigue is outside the MVP.

## State and input safety
States: `PLAYER_INPUT`, `RESOLVING_BOARD`, `RESOLVING_EFFECTS`, `ENEMY_ACTION`, `VICTORY`, `DEFEAT`. All input actions validate phase; do not allow animation callbacks to create extra turns. Mark transitions explicitly.

## Determinism and testing
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
