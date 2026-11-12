# Ashen Oath — Session handoff

## Interim update — 2026-11-13

This update is the current checkpoint. The 2026-11-11 snapshot below is retained
as historical context; its Git checkpoint, geometric-only tile description and
pending roadmap audit are superseded by this update.

### Repository checkpoint and scope of this update

- Current HEAD: `dcf3a4e` — `grafics: art implementation + resolution channges`.
  Previous checkpoints: `0e1dbdc` (Forest / Rust / Iron documentation), `092e948`
  (core combat), `16af194` (playable board).
- Working tree was clean at the start of this review. The recent art integration
  and UI presentation refactor are already committed; they are not pending changes.
- This task changes only `docs/DEVELOPMENT_ROADMAP.md` and this handoff. No code,
  assets, scenes, settings, other documentation or commits are changed.
- Git status/diff and implementation files were reviewed locally. No fetch,
  remote visibility check or network operation was performed.

### Current state and milestone review

| Milestone | Status | Remaining boundary |
| --- | --- | --- |
| 0 — Foundation | Project foundation complete | Private remote visibility/push setup and local login not independently verified |
| 1 — Board prototype | Implemented and tested | Prototype visuals remain replaceable |
| 2 — Complete battle | Minimal encounter implemented and tested | Final balance and some special rewards remain open |
| 3 — Combat UI | Static/presentation slice implemented and validated | Manual acceptance, final assets and animation/polish pending |
| 4 — Light RPG | Not implemented | Abilities, equipment effects and data-driven RPG content need separate tasks |
| 5 — Simple run | Not implemented | No rooms, rewards, run orchestration or saves |

The roadmap now has explicit status/checklist entries. It distinguishes
implemented prototype behavior from final design approval and unverified setup.

### Completed since the original handoff

- Established the approved Forest / Rust / Iron overall direction and starting
  palette in `docs/ART_DIRECTION.md`; the GDD references it and the earlier art
  guide defers to it. Individual assets remain unapproved/provisional.
- Inspected the supplied detailed concept sheet at
  `docs/references/art/2b4f6a9f-1478-4991-b860-9fb40c006a7f.png`. The art direction
  document records the intended canonical filename and the supplied filename;
  reference-image captions do not override gameplay rules.
- Integrated `assets/tiles/sword.png`, `shield.png`, `herb.png`, `action.png`
  through exported texture assignments in `scenes/ui/board_tile.tscn`.
  Nearest filtering, square sizing, selection and empty-cell rendering are kept.
- Refactored static combat presentation without changing board/combat algorithms:
  three 20/60/20 zones; enlarged hero portrait; compact status/equipment tooltips;
  reserved ability and consumable areas; scrollable inventory with live herbs.
- Added a reusable EnemyStage for 1–3 visual slots. Only its primary slot binds
  the existing single enemy. There are no extra combat actors or targeting rules.
- Reserved 80px between the enemy stage and board. Tiles measure 52px at logical
  1280x720 (388px board) and 94px at logical 1920x1080 (682px board). Hero portrait
  height is 320px/480px respectively. These are layout results, not asset specs.
- Added segmented AP presentation: muted yellow/olive palette, required-segment
  highlights and explicit insufficient-AP feedback. Reserved button costs of
  2/4 AP are UI-only examples, not implemented abilities or approved costs.
- Added decorative iron defense plates, Guard chain patches and translucent Ward
  overlays. No Armor resource exists. Overlay segments each represent up to six
  points and saturate visually above 36; exact values remain in labels/tooltips.
- Inventory accepts view dictionaries and updates stack counts. This provides
  future item presentation without implementing loot, crafting or item usage.

### Latest recorded verification

These results are from the preceding implementation work, not rerun for this
documentation-only audit, which must leave all other files untouched:

- Board: **1,151 checks, 0 failures**.
- Combat: **582 checks, 0 failures**; default test encounter won in four legal
  swaps with 100 HP using a test-only move search. This is not balance approval.
- Presentation: **354 checks, 0 failures** at 1280x720 and 1920x1080, including
  all 49 unobstructed pointer targets, stage capacity, AP previews, defense,
  inventory scrolling and quantities.
- Combat UI smoke test passed swaps/rollback, phase input locks, state bindings,
  retaliation, victory and defeat.
- Godot 4.7.2 editor validation and OpenGL rendered capture runs passed. Rendered
  captures were produced at both resolutions; the reference-size capture was
  visually inspected after the final spacing adjustment. Full manual player
  playtesting remains outstanding. Captures are ignored `.godot/ui_*.png` files.
- Documentation audit: `git diff --check` is the appropriate check; no Godot
  invocation is required for these two Markdown changes.

Test commands remain those below, with the additional UI suite:
`godot --headless --path . --script tests/presentation_smoke.gd`.

### Important recent files

- `scripts/ui/combat_screen.gd`: presentation composition, responsive sizing and
  existing live state adapter; combat turn-resolution behavior is preserved.
- `scripts/ui/enemy_stage.gd`, `segmented_meter.gd`, `inventory_grid.gd`: modular,
  read-only presentation components with companion UID files.
- `scripts/ui/placeholder_portrait.gd`: scalable native silhouette placeholder.
- `scripts/ui/board_tile.gd`, `scenes/ui/board_tile.tscn`: replaceable PNG rendering.
- `assets/tiles/*.png` and import sidecars: provisional supplied tile art.
- `tests/presentation_smoke.gd`, `tests/combat_ui_smoke.gd`: presentation and
  combat integration coverage. Existing board/combat tests remain in place.
- `docs/COMBAT_UI_PROTOTYPE.md`: current layout/components, caveats and commands.
- `docs/ART_DIRECTION.md`, `docs/ART_STYLE_GUIDE.md`, `docs/GAME_DESIGN.md`:
  visual direction and distinction between approved rules and prototype values.

### Decisions, pending work and next action

All approved rules and Sprint 04 prototype constants recorded below remain in
effect. No mechanics were added by the art/UI work. In particular, herbs never
heal automatically, AP never buys board swaps, and Ward is finite absorption.

1. Manually playtest the combat scene with **F6** at 1280x720 and a larger 16:9
   window. Check selection, AP hover/focus clarity, tooltips, scrolling, live herb
   stacks, enemy/board separation, feedback and victory/defeat input locks.
2. Record concrete findings and agree on a narrowly scoped next implementation
   task. Do not infer permission for abilities or multi-enemy combat from slots.
3. The next planned art task is individual design/approval of the four tiles,
   followed by set consistency review. Existing PNGs are provisional integration
   assets, not final designs. Character/enemy/UI art, typography, production asset
   specifications and animation requirements still need approval.
4. Final balance remains open, particularly Herb/Action special rewards, hero HP,
   budget, AP limits, damage and future item/ability costs. The GDD's open decisions
   must not be silently finalized from implementation constants.
5. AP/herbs cannot yet be spent. There is no in-game restart, save system or full
   run flow. A shared inventory object can retain herbs across future encounters,
   but current scene restart creates a fresh inventory. Equipment/consumable slots
   and additional enemy cards are presentation only. Fatigue/Hub stay outside MVP.
6. README foundation text remains stale; it was deliberately left unchanged under
   this task's two-file scope. Remote privacy/login verification is optional setup
   follow-up and was not claimed complete from local Git references alone.

No commits are made by this handoff. At completion, only the roadmap and handoff
should be uncommitted changes; preserve that boundary before the next task.

## Historical snapshot — 2026-11-11, after Sprint 04

The sections below preserve the earlier context and prototype decisions. For
current implementation, verification and next steps, use the interim update above.

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
