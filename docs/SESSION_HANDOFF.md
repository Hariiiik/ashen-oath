# Ashen Oath — Session handoff

## Interim checkpoint — 2026-11-13, after Milestone 4B

This replaces the earlier interim snapshot. It describes the current working tree,
including uncommitted Emergency Crafting & Bandage work. Approved design lives in
`GAME_DESIGN.md`; implemented boundaries and commands are in `ARCHITECTURE.md`,
`COMBAT_UI_PROTOTYPE.md` and `DEBUG_COMBAT.md`.

## Repository and handoff scope

- Branch: `main`; HEAD: `b7f9727` — `docs: rebalance milestone`.
- Earlier checkpoints: `ff4417b` (debug rollback), `c1af8c9` (Shield Bash and End
  Turn), `dcf3a4e` (art integration/presentation), `0e1dbdc` (art direction),
  `092e948` (core combat), `16af194` (playable board).
- The tree was already dirty when this handoff began. Bandage implementation,
  tests and relevant design/technical docs are uncommitted. The roadmap also has
  an existing staged change moving balancing after Milestone 5; its newer working
  copy includes Bandage and this review. Do not assume the staged roadmap matches
  the working copy or overwrite/unstage it without authorization.
- This handoff task modifies only `docs/DEVELOPMENT_ROADMAP.md` and this file.
  Other existing changes are preserved. No features, tests, commits, pushes or
  network operations are performed by the documentation review.

## Current project state

Godot 4 / typed GDScript, Windows-first, GL Compatibility, 1280x720 reference
resolution and nearest filtering. Last validation used Godot 4.7.2.

Open `scenes/combat/combat_screen.tscn` and press **F6**. F5 still opens the
foundation title scene. A standalone combat scene has one Warden and one Hollow
Sentinel; there is no automatic encounter progression or post-victory screen.

The seeded 7x7 board uses exactly Sword, Shield, Herb and Action. It supports
adjacent swaps, invalid rollback, match detection, gravity/refill, cascades,
stable initial generation and dead-board reshuffling. Raw intersecting runs
merge into one unique-cell group whose rank is the longest straight run, capped
at Match-5+. Board/combat calculations are independent of UI nodes.

Three 20/60/20 zones remain: hero, enemy stage/board, loadout/inventory. The enemy
stage accommodates 1–3 visual cards, but only one real enemy exists and there is
no targeting. The board has 52px tiles at logical 1280x720 and 94px at 1920x1080;
hero portrait heights are 320px/480px, with 80px stage-to-board clearance.
These are layout measurements, not final asset production specifications.

## Milestone status

| Milestone | Current status | Remaining work |
| --- | --- | --- |
| 0 — Foundation | Project foundation complete | Private remote visibility/setup and local login not independently verified |
| 1 — Board prototype | Implemented and tested | Provisional tile assets remain replaceable |
| 2 — Complete battle | Minimal encounter implemented and tested | Final balance and some tile special rewards remain open |
| 3 — Combat UI | Static presentation implemented and validated | Manual acceptance, final artwork and animation/polish |
| 4 — Light RPG | Partially implemented | Equipment effects and broader data-driven RPG content |
| 4A — Shield Bash | Implemented, committed and tested | Manual ability/End Turn acceptance |
| 4B — Emergency Crafting & Bandage | Implemented in the uncommitted working tree and tested | Manual resource/healing/persistence acceptance |
| 5 — Simple run | Not implemented | Rooms, rewards, encounter progression, replay/save/run orchestration |
| 6 — Combat Balance & Playtesting | PLANNED / NOT STARTED, after Milestone 5 | Core RPG, crafting, equipment interactions and basic run loop must be playable first |

The former balance milestone's 4B identifier now belongs to the explicitly
requested Bandage slice; balancing is Milestone 6. Its analytics/tooling scope
is retained. Until its prerequisites are ready, address only critical balance
issues and obvious exploits, not routine tuning or comprehensive rebalancing.

## Implemented actions and approved boundaries

### Turn timing and Shield Bash

- `PLAYER_INPUT` accepts the single board move and available actions. Invalid
  swaps consume nothing. All cascades/effects finish before `POST_MATCH`.
- In `POST_MATCH`, the board is locked but Shield Bash, emergency crafting and
  Bandage use may be activated if available. Only explicit **End Turn** starts
  the announced enemy action; no decision timer or automatic action exists.
- Shield Bash: approved **3 AP**, consumes all current Guard for equal physical
  base damage, applying existing physical mitigation. No bonus, critical strike,
  penetration, cooldown or once-per-turn limit. Ward is not consumed by the ability.
- A lethal match/Bash wins without retaliation; standard combat-end cleanup clears
  Guard/Ward. Otherwise Guard absorbs before Ward, then HP. Remaining Guard expires
  after the enemy action. AP never grants another swap.
- All actions are blocked during resolution/playback, enemy action and outcomes.
  Debug Undo is the deliberate exception after victory/defeat.

### Emergency crafting and Bandage

- Exactly one recipe/item: **6 Herbs -> 1 Bandage** in combat, with **zero AP**
  crafting cost. Creating a Bandage does not automatically heal.
- Manual use consumes **1 Bandage + provisional 2 AP**, restoring **provisional
  12 HP**, capped at maximum HP. The prototype rejects full-HP use to avoid waste.
- Craft/use preserve the current player action window, board/RNG, swap allowance,
  Guard/Ward, enemy intent and encounter herb budget. No automatic enemy action.
- The standard **4-Herb** recipe is a design reference, not an available action.
  Standard crafting is not automatically offered between regular encounters.
  Preparation is intended between runs; special crafting/safe rooms are future
  ideas. No between-battle crafting, Preparation Screen after victory, Hub,
  safe rooms or meta-inventory is implemented.
- `RunInventory` owns stackable `herbs` and `bandages`. Pass the same object to
  `Combat.new(seed, shared_inventory)` or assign `screen.run_inventory` before
  adding a combat scene to the tree. Both stacks persist across those encounters.
- Persistence is explicit shared in-memory ownership, not a run loop or disk save.
  Standalone F6 without injection creates a fresh inventory. HP/AP carry-over
  rules and automatic room transitions were not introduced.
- UI has craft/use buttons, live stack counts and a 2-segment AP hover preview.
  Bandage uses a temporary native BND glyph; final art is not approved.

### Existing prototype testing values

| Tile | Match-3 | Match-4 | Match-5+ |
| --- | --- | --- | --- |
| Sword | 6 physical damage | 12 critical damage | 18 damage ignoring armor |
| Shield | 6 Guard | 8 Ward | 12 Ward |
| Herb | 1 herb | 2 herbs | 3 herbs |
| Action | 2 AP | 3 AP | 5 AP |

These tile numbers are provisional, as are the AP cap 6, Warden 100 HP and
encounter herb budget 10. Test enemy: 40 HP, unarmored, alternating 5/8 attacks,
starting at 5. Herb collection is budget-limited; exhausted Herb matches still
clear/refill without producing materials or automatically healing. Current
implementation values do not finalize the GDD's open balance decisions.

### Art and presentation

Forest / Rust / Iron overall direction and starting palette are approved in
`ART_DIRECTION.md`. Individual tiles, character/enemy/UI designs, typography,
asset specifications and animations remain subject to approval. The four PNGs
in `assets/tiles/` are provisional, exported through `board_tile.tscn` for easy
replacement. Compact status/equipment tooltips, segmented AP, decorative iron
with Guard patches/Ward overlay, and scrollable inventory are present. There is
no independent Armor mechanic, equipment effect, second ability or loot system.

## Diagnostics and Undo

- `debug_match_logging` enables `[COMBAT DEBUG]` events in Godot Output and the
  standard engine log. Reports include seed/RNG, board, raw run orientations,
  merged groups, unique positions, cascades/refill, effects and resource deltas,
  including crafting/Bandage usage. See `DEBUG_COMBAT.md`.
- An isolated five-cell Shield cross is one rank-3 group and gives **6 Guard**,
  not two effects. A real 12-Guard replay uses seed **9**, swap **(5,0) <-> (6,0)**:
  two Shield Match-3 effects in cascade indices 0/1 each grant 6. Coordinate reuse
  after refill is not a duplicated shared cell. The original reported board was
  unavailable, so its exact history is not proven. T/L/cross rules were not changed;
  a deterministic policy proposal is documented, awaiting approval.
- **DEBUG / Undo Last Turn** is debug-build-only and stores one stable checkpoint
  before the turn's first successful action, including pre-swap Bash or crafting.
  It restores board, seed/RNG, all scalar combat fields, both item stacks, phase,
  counters and derived ability availability without emitting gameplay actions.
- Undo is blocked during board/effect/enemy resolution and visual preview; it is
  allowed in stable player windows and after victory/defeat. It consumes its one
  checkpoint, with no history/redo. A next turn's first successful action replaces
  the old checkpoint; invalid actions do not. Future compound state must explicitly
  extend the snapshot implementation.

## Latest recorded verification

These results come from the preceding implementation, not rerun in this
strictly two-file documentation audit:

| Suite | Latest result |
| --- | --- |
| `tests/board_model_test.gd` | 1,151 checks, 0 failures |
| `tests/combat_test.gd` | 583 checks, 0 failures |
| `tests/shield_bash_test.gd` | 167 checks, 0 failures |
| `tests/debug_turn_test.gd` | 157 checks, 0 failures |
| `tests/bandage_test.gd` | 62 checks, 0 failures |
| `tests/presentation_smoke.gd` | 354 checks, 0 failures at 1280x720 and 1920x1080 |
| `tests/combat_ui_smoke.gd` | Passed swaps, rollback, timing, state/UI, victory/defeat |
| Godot 4.7.2 headless editor validation | Passed |

Bandage tests cover resource costs, healing limits, insufficient resources/AP,
shared AP with Shield Bash, stack persistence across controllers/scenes, action
windows and Undo restoration. The unchanged board/combat suites passed.

Earlier native-render captures were inspected for the presentation refactor.
The latest Bandage UI was checked by headless layout tests; manual player
acceptance and a fresh windowed visual review of that UI remain pending. The
recorded automated four-swap victory uses test-only move search and is not a
balance/difficulty assessment.

Run individual suites with `godot --headless --path . --script tests/<suite>.gd`;
editor validation is `godot --headless --path . --editor --quit`. Local executable:
`C:\Users\Hariiik\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
Sandboxed Godot logging/cache may require the normal approval flow; do not bypass it.

## Important implementation files and uncommitted work

- `scripts/board/board_model.gd`: existing engine and observational run metadata;
  no generation/rule changes in the Bandage slice.
- `scripts/combat/combat_rules.gd`, `combat_controller.gd`: Bandage validation,
  resource/healing effects, action gates and debug capture/logging.
- `scripts/combat/run_inventory.gd`, `turn_snapshot.gd`: new Bandage stack and
  restoration alongside Herbs. Shared inventory identity is preserved.
- `scripts/ui/combat_screen.gd`: craft/use controls, live counts/AP preview and
  explicit run-inventory injection. `inventory_grid.gd`: native fallback glyphs.
- `tests/bandage_test.gd`: new untracked test harness at this checkpoint; ensure
  it is included if/when the user authorizes committing the implementation.
- Updated implementation docs already pending before this handoff:
  `GAME_DESIGN.md`, `ARCHITECTURE.md`, `COMBAT_UI_PROTOTYPE.md`, `DEBUG_COMBAT.md`
  and `DEVELOPMENT_ROADMAP.md`. This audit additionally updates this handoff.

## Pending tasks and next recommended action

1. Manually playtest with F6 at 1280x720 and a larger 16:9 window. Collect Herbs/AP
   naturally, craft a Bandage, take damage and use it. Check disabled states,
   capped healing, live counts/AP previews, post-match actions/End Turn and Undo.
2. Verify the run-owner injection contract using two separately instantiated
   encounters sharing one `RunInventory`; do not add room/progression systems
   simply to demonstrate the already tested persistence API.
3. Record usability defects, critical balance issues and obvious exploits; scope
   the next authorized task. Full balancing remains Milestone 6 after the RPG,
   crafting, equipment and basic-run prerequisites are playable.
4. Next planned art task remains individual approval of Sword, Shield, Herb and
   Action tiles, followed by set review. Existing PNG integration is provisional.
5. Equipment interactions, other abilities/items/recipes, preparation, safe rooms,
   Hub, loot generation, run progression and saving are absent. Do not infer their
   approval from reserved UI slots or future roadmap sections. Fatigue is outside MVP.
6. README's old foundation-only status is stale; it was not changed under this
   task's two-file limit. Historical between-battle crafting statements must defer
   to GDD v0.4 and the latest explicit preparation-between-runs clarification.

No commits, staging changes or pushes are made by this audit. Preserve the
existing staged roadmap edit and all uncommitted implementation work.