# Ashen Oath — Session handoff

Prepared: 2026-11-11, after Sprint 04 (core combat).

## Current project state

- Godot 4 / typed GDScript, Windows-first, 1280x720 reference resolution,
  GL Compatibility renderer and nearest texture filtering. Current project
  configuration declares Godot 4.7; last validation used Godot 4.7.2.
- A playable single encounter exists: one Warden versus the Hollow Sentinel.
  Open `scenes/combat/combat_screen.tscn` and press **F6**. F5 still launches
  the foundation title scene; combat is not connected to that boot screen.
- Left hero, center enemy/board and right loadout/resource zones remain 20/60/20.
  Artwork is geometric placeholder art. Enemy visuals ignore mouse input and
  remain outside board interaction space.
- Board and combat logic are node-independent `RefCounted` objects. The UI
  requests actions and displays state rather than calculating combat effects.
- No crafting, consumables, abilities, equipment modifiers, additional classes,
  additional enemies, Hub, procedural dungeon, full run flow or disk saves.

## Completed work

1. Combat UI prototype with reusable tiles, silhouettes, shared styling and
   disabled loadout placeholders.
2. Design documentation aligned with Sword, Shield, Herb and Action tiles.
3. Seeded 7x7 Match-3: selection, adjacent swaps, validation/rollback, horizontal
   and vertical matches, removal, gravity/refill, cascades, stable initial boards,
   legal-move detection and dead-board reshuffling.
4. Structured match groups and per-cascade snapshots. Intersecting runs are
   deduplicated; a group's rank uses its longest straight run, capped at 5+.
5. Sprint 04 combat: live HP, Guard, Ward, AP, run herb inventory, encounter herb
   budget, phases, turn counter and alternating enemy intent. Valid swaps spend
   one turn; invalid swaps do not. Cascades precede retaliation. Victory and
   defeat stop input, and victory prevents retaliation.
6. Headless algorithm, combat and UI integration tests.

## Approved decisions and scope

The GDD remains the design reference; prototype constants are not final balance.

- Warden is the only MVP playable class. Exactly four base tiles on a 7x7 board:
  Sword, Shield, Herb, Action. No Skull/Occult, Heart, Cursed or extra herb variants.
- Match-3 gives the basic effect; Match-4/5 gives an immediate special effect.
  No special tiles waiting for a future move. Sword specials are critical strikes,
  with additional armor penetration at Match-5 (balance provisional).
- Match-3 Shield produces temporary Guard, expiring after the next enemy action.
  Match-4/5 produces Ward, a finite damage pool lasting until consumed/combat end.
- Herb matches collect materials, never automatically heal. Materials persist
  within the run. A finite encounter collection budget limits gains, not matching:
  Herb tiles remain and continue resolving when the budget is exhausted.
- AP is shared by future consumables and class abilities; it never buys swaps.
  Healing items require manual activation and AP.
- Crafting is primarily between battles, with increased material cost for emergency
  combat crafting. Intended Bandage recipe: 4 herbs between battles, 6 in combat.
  Healing amount and activation AP cost remain provisional. Additional crafting
  AP cost is a proposal, not approved. None of these item systems is implemented.
- Fatigue is outside the MVP; later anti-stalling experiments only. Preserve
  extension points for future classes, loot, crafting and a Hub without building
  them before an authorized task.

### Sprint 04 prototype configuration

| Tile | Match-3 | Match-4 | Match-5+ |
| --- | --- | --- | --- |
| Sword | 6 physical damage | 12 critical damage | 18 damage ignoring armor |
| Shield | 6 Guard | 8 Ward | 12 Ward |
| Herb | 1 herb | 2 herbs | 3 herbs |
| Action | 2 AP | 3 AP | 5 AP |

- AP cap: 6. Warden: 100/100 HP. Encounter herb budget: 10. Guard/Ward/AP/herbs
  initially zero for a fresh run inventory. Enemy: 40 HP, zero armor, attacks
  alternating 5 and 8, starting at 5. All numbers are testing values.
- Guard -> Ward -> HP is the Sprint 04 absorption order. Remaining Guard expires
  after the enemy action; combat end clears Ward and Guard.
- Groups resolve in row-major order by first cell. Every group in a cascade step
  resolves before checking victory. A lethal step stops later cascade effects and
  retaliation. The board engine precomputes all refill snapshots; unused snapshots
  after victory do not grant combat rewards.
- The GDD still marks some turn details, absorption order and Herb/Action special
  rewards as open. Sprint 04 explicitly authorized the current test behavior;
  do not silently promote it to final balance/design approval.

## Verification recorded before this handoff

Latest implementation checks in this session, before the documentation-only
handoff (not rerun while preparing this file):

- `tests/board_model_test.gd`: **1,151 checks, 0 failures**.
- `tests/combat_test.gd`: **582 checks, 0 failures**. Includes a full default
  encounter won in 4 legal swaps with 100 HP remaining using a test-only move
  search; this is a regression check, not a claim of balanced difficulty.
- `tests/combat_ui_smoke.gd`: passed layout, selection, swaps, rollback, input
  locking, live combat UI, retaliation, victory and defeat checks.
- Godot 4.7.2 headless editor validation passed without reported errors.
- Windowed visual/manual playtesting has not been performed by the agent.
- Initial sandboxed Godot runs could not write standard user logs/cache; approved
  retries passed. Use the normal approval mechanism if that recurs.

Commands from the repository root (substitute the executable if not on PATH):

```powershell
godot --headless --path . --script tests/board_model_test.gd
godot --headless --path . --script tests/combat_test.gd
godot --headless --path . --script tests/combat_ui_smoke.gd
godot --headless --path . --editor --quit
```

Executable found locally:
`C:\Users\Hariiik\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.

## Important files and Git checkpoint

At handoff start, `main` was clean and up to date with the locally recorded
`origin/main` at **092e948 — combat draft**. No fetch/network operation was used.
The earlier playable board is in **16af194**; approved tile documentation is in
**d356e71**. Existing implementation work is committed, not pending in the diff.

| Files | Responsibility / recent change |
| --- | --- |
| `scripts/board/board_model.gd` | Existing seeded board engine; preserved during Sprint 04 |
| `scripts/combat/combat_state.gd` | New encounter state and prototype defaults |
| `scripts/combat/combat_rules.gd` | New tile effects, caps and absorption rules |
| `scripts/combat/combat_controller.gd` | New input/phase gates, cascade effects and enemy actions |
| `scripts/combat/run_inventory.gd` | New in-memory herbs; share the instance between future encounters |
| `scripts/ui/combat_screen.gd` | Live state bindings, staged playback, outcome feedback and input locks |
| `scenes/combat/combat_screen.tscn` | Directly runnable combat scene |
| `scripts/ui/board_tile.gd`, `scenes/ui/board_tile.tscn` | Reusable placeholder tile presentation |
| `tests/board_model_test.gd` | Board regression suite |
| `tests/combat_test.gd`, `tests/combat_ui_smoke.gd` | Combat rules/controller and UI regression coverage |
| `docs/GAME_DESIGN.md` | Approved direction and explicitly open design questions |
| `docs/ARCHITECTURE.md`, `docs/COMBAT_UI_PROTOTYPE.md` | Implemented boundaries, prototype values and launch instructions |

New combat scripts have companion `.gd.uid` files. The handoff task itself only
changes this new document and corrects the stale foundation-only status in
`AGENTS.md`. No source, scenes, project settings or existing commits are changed.

## Pending tasks and open questions

- Perform a windowed playtest at 1280x720: selection readability, live resources,
  intent, cascade pacing, terminal feedback and enemy/board interaction boundary.
- Review prototype balance across seeds. Hero starting HP, collection budget,
  rewards, AP cap and damage values remain provisional, particularly Herb/Action
  Match-4/5 special rewards. Do not invent resource spending systems to fill gaps.
- AP and herbs can accumulate but cannot yet be spent. Herbs are memory-only;
  the current UI creates a fresh inventory on scene restart, and there is no run
  traversal to demonstrate inventory carry-over between encounters.
- There is no in-game restart; rerun the scene in the editor. Playback uses brief
  cleared/refilled snapshots rather than sliding tile animations.
- Dead-board reshuffling tries 256 permutations, then regenerates if necessary
  for pathological tile distributions. Final art and animation polish are pending.
- README foundation status and roadmap setup checkboxes are stale. The GDD and
  architecture include future/planned sections alongside implemented behavior;
  distinguish those when planning the next task. This handoff did not rewrite
  those documents or mark milestones complete without review.
- Crafting, items/abilities, equipment, future classes, loot and Hub need separate
  scoped work. Bandage healing/AP cost and emergency crafting AP cost remain open.

## Next recommended action

Open the combat scene and perform a manual windowed playtest before expanding
systems. Record concrete UI or balance findings, then agree on a narrowly scoped
next sprint. If code changes follow, run all three test scripts and editor
validation. Preserve the committed Sprint 04 checkpoint and request explicit
authorization before any commit/push; this handoff makes neither.
