# Ashen Oath — Final session handoff

## Checkpoint — 2026-11-14, approved-reference combat UI

Implementation baseline: `main`, `89296e7` — Forest Relic UI integration. The
reference rework began with only the supplied `docs/references/art/ui-reference.png`
untracked. Existing equipment/run, Shield Bash, Bandage, emergency crafting,
Match-3 and Debug Undo were already implemented and committed; none was rewritten.

The user has explicitly authorized this final handoff/roadmap update, thematic
commits and push to `origin/main`. Publication groups are reference/art audit,
hero/meters, enemy frames, belt/bag/crafting popup, shared integration, and final
roadmap/handoff. Use `git log`, `git status` and `origin/main` for final SHA/sync
state rather than an embedded self-referential commit hash.

Implementation commits in this publication:

- `defd710` — approved reference and art audit.
- `6b31f12` — framed hero and joined resource meters.
- `759f151` — separate enemy artwork/information frames.
- `1e62946` — consumable belt, inventory bag and crafting popup.
- `1855000` — shared combat layout, documentation and regression integration.

The following final documentation commit contains this handoff and the roadmap.

The functional layout is implemented and tested. **Final artwork and manual
player acceptance remain incomplete**; do not claim pixel-perfect reproduction.
No final art, installations, dependencies, gameplay rules or balance changes were
introduced. The reference PNG and existing source textures were preserved.

## Restore context and launch

Read AGENTS.md, GAME_DESIGN.md, ARCHITECTURE.md, ART_DIRECTION.md and
DEVELOPMENT_ROADMAP.md before extending the project. Current UI details live in
COMBAT_UI_REFERENCE_REWORK.md; asset inspection/gaps are in
UI_REFERENCE_ASSET_AUDIT.md. FOREST_RELIC_UI.md retains the earlier sprite
integration checkpoint and source crops; its older layout statements are
superseded by the reference rework.

Godot 4.7.2 / typed GDScript, Windows-first, GL Compatibility, nearest filtering.
F5 starts `scenes/run/run_entry.tscn`: three explicit repetitions of the existing
Hollow Sentinel encounter with deterministic separate board seeds. F6 on
`scenes/combat/combat_screen.tscn` starts one fresh standalone encounter. The
actual combat scene is in `scenes/combat/`, not `scenes/ui/`.

## Current playable project state

- One Warden, one combat enemy, exactly Sword/Shield/Herb/Action on the existing
  seeded 7x7 board. Adjacent swaps, invalid rollback, match groups, gravity/refill,
  cascades, stable generation and dead-board reshuffling are unchanged.
- Intersecting straight runs merge unique cells. Rank is the longest straight
  run, capped at Match-5+. No new T/L/cross policy or deferred special tiles.
- One valid swap per turn; invalid swaps spend nothing. All cascades/effects
  finish before POST_MATCH. Shield Bash, emergency craft and Bandage work in the
  existing pre-swap/post-match windows. Explicit End Turn permits the announced
  alternating 5/8 attack; lethal effects prevent retaliation.
- End Turn now sits at the central footer's bottom-right. The same button becomes
  Next Encounter after nonfinal victory or disabled Run Complete at final victory.
  No automatic transition, healing or preparation follows victory.
- Equipment has definitions, compatibility/loadout/snapshot contracts only.
  Loadout identity persists without bonuses, loot or equipment interactions.
- Existing actor visual definitions, optional queue/skip/cancel and one-turn Undo
  remain; no authored animations were added or wired into new turn waits.

## Approved-reference UI

The lead and four native Codex workers inspected the actual
`docs/references/art/ui-reference.png`. They used disjoint source ownership in
the shared workspace; no new worktrees were created for this UI task.

- Hero worker: new HeroPortrait wrapper with existing ActorView, dedicated
  supplied frame and bottom WARDEN / LVL 01 plaque. Standalone Ser Aldric/name
  label removed. `hero_class_label`/`hero_level` are configurable presentation
  inputs for the existing identity, not a new class/XP system. Guard/Ward and AP
  use joined full-width plates, fixed caps and one-pixel dividers.
- Enemy worker: separate artwork and name/HP/intent frames, preserving legacy
  primary bindings and 1–3 visual-only preview slots. ActorView may extend 32px
  below its frame into the 80px clearance. All decoration ignores pointer input;
  no artwork reaches board cells. No goblin or multi-enemy mechanics were added.
- Inventory worker: same grid/API/data/58px minimum cells/scrolling, now grouped
  in a shared temporary native leather bag. A matching belt contains Bandage and
  two inert future slots. Its tool button toggles contextual crafting.
- Art worker: all sixteen UI PNGs inspected; reusable frames, source limitations,
  state hierarchy and final art requirements documented.
- Lead: approximately 22/56/22 columns, portrait and meter bindings, footer action,
  unified components, Theme focus/footer styles, actual run-scene integration
  tests and native visual QA. Original board sizes and positions are retained.

| Measurement | 1280x720 | 1920x1080 |
| --- | --- | --- |
| Board position/size | (446,260), 388x388 | (619,324), 682x682 |
| Tile hitbox | 52x52 | 94x94 |
| Hero frame | 248x350 | 388x525 |
| End Turn position/size | (824,657), 160x40 | (1324,1015), 160x40 |

CraftingPopup is a **nonmodal Control**, not a paused scene or fullscreen input
catcher. It stays in the right column, preferring the read-only bag area below
the belt so Bash, Undo and belt controls stay accessible. Above is a limited-space
fallback. It may remain open through swaps, enemy actions, Undo and outcomes;
gameplay buttons still obey normal availability. Close/toggle remains usable.

The screen aliases its single craft button to the existing craft handler. There
is no duplicate recipe or resource mutation path. UI cost strings come from
CombatRules. Existing Bandage use remains the single active belt consumable.

## Rules and persistence to preserve

HP/max HP persist between encounters without victory healing. Herbs/Bandages use
the same RunInventory instance; equipment retains the same loadout reference.
Guard/Ward reset each encounter. **AP resets to zero provisionally**, not as a
permanent approved design rule. Budget, turn, intent and enemy HP reset normally.
CombatState is authoritative during combat; RunState HP is a transition checkpoint.

Shield Bash remains approved at 3 AP, consuming all Guard for equal physical base
damage. No Ward contribution, swap cost, cooldown, bonus or arbitrary per-turn cap.
Guard absorbs before Ward before HP; remaining Guard expires after enemy action.

Emergency crafting remains 6 Herbs -> 1 Bandage with zero crafting AP. Manual use
costs provisional 2 AP for provisional up-to-12 HP, capped at max; full-HP use is
blocked. The standard 4-Herb recipe is design-only. Preparation is intended between
runs, not automatically after rooms. No Hub, safe rooms, meta-inventory, standard/
between-battle crafting, additional items or recipes exist.

Unchanged prototype values: Sword 6/12/18; Shield 6 Guard/8 Ward/12 Ward; Herb
1/2/3 capped by encounter budget; Action 2/3/5 capped at 6 AP. Hero 100 HP, enemy
40 HP, herb budget 10. These do not finalize balance or open GDD special rewards.

Developer-only Debug Undo restores one pre-turn board/RNG/scalar-state/inventory
checkpoint without replaying effects. It is blocked during resolution, allowed
after victory/defeat, and cancels presentation first. It cannot cross encounters;
accepted continuation retires the old controller's debug tools. Derived run results
and continuation availability immediately follow actual phase after Undo.

## Executed verification

All sixteen headless suites rerun for publication: **3,629 counted checks,
zero failures**, plus combat UI smoke PASS.

| Suite | Checks/result |
| --- | --- |
| board_model_test | 1,151 / 0 failures |
| combat_test | 583 / 0 |
| shield_bash_test | 167 / 0 |
| debug_turn_test | 157 / 0 |
| bandage_test | 62 / 0 |
| equipment/equipment_test | 52 / 0 |
| run/run_test | 85 / 0 |
| ui/actor_view_test | 44 / 0 |
| presentation_smoke | 354 / 0, both resolutions/all 49 pointer targets |
| combat_ui_smoke | PASS: actions, layout, input locks, enemy action/outcomes |
| integration/parallel_streams_test | 166 / 0 |
| ui/forest_relic_smoke | 106 / 0 headless |
| ui/hero_panel_test | 23 / 0 |
| ui/enemy_stage_test | 401 / 0 |
| ui/loadout_components_test | 26 / 0 |
| ui/reference_layout_smoke | 252 / 0 |

Latest native visual QA from the implementation: reference UI **154 / 0** and HP
rendering **142 / 0**, with captures viewed at both sizes. HP checks cover
0/25/50/75/100% and fixed end-cap pixels. Editor validation passed with no new
project errors/warnings. The reference integration uses actual F5 RunEntry and
checks open-popup board input, existing craft/use costs, Undo, cascades, post-match
actions, relocated End Turn and victory/continuation. Native capture mode excludes
OS-window pointer dispatch; deterministic headless input covers all board cells.

Commands: `godot --headless --path . --editor --quit` and
`godot --headless --path . --script tests/<suite>.gd`.
Local executable:
`C:\Users\Hariiik\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
Normal sandbox approval may be required for engine logs/certificate-store access;
approved runs used separate logs without those environment errors.

Ignored artifacts: `build/handoff_*.log`, `build/reference_*.log`, and
`build/screenshots/ui_reference_{1280x720,1920x1080}.png` plus
`ui_reference_crafting_{1280x720,1920x1080}.png`. Captures/logs are local artifacts,
not committed final art; rerun the native reference harness to recreate them.

## Important files and remaining work

New UI scripts: hero_portrait.gd, consumables_belt.gd, crafting_popup.gd,
inventory_bag.gd and UIDs. Modified: combat_screen.gd, enemy_stage.gd,
segmented_meter.gd, inventory_grid.gd, forest_relic_theme.gd. New component/reference
tests are under tests/ui/; existing presentation and skin assertions were updated
to the newly approved layout. Shared design/architecture/art/UI docs reflect the
new composition; detailed ownership/mapping is in COMBAT_UI_REFERENCE_REWORK.md.
Board/combat/run/core scripts, tile textures and source UI artwork were preserved.

Milestone 3 is functionally implemented/verified, not final-art or manual-acceptance
complete. 4A/4B remain implemented; equipment is data-only. Milestone 5 has the
tested sequential slice, not room/reward/procedural/save content. Milestone 6
stays PLANNED / NOT STARTED after 5, gated on playable core RPG/crafting/equipment
interactions/basic run loop. Until then fix only critical balance issues/exploits.

Next recommended action: manually play F5 through all three encounters at both
sizes with the popup open. Verify natural resource collection/craft/use, Bash,
Undo, footer/Next Encounter, defeat/final victory, and HP/stack persistence. Record
usability defects. Then scope approved art requirements separately.

Missing final art: Warden/enemy illustrations, ruins backdrop, thick stone
columns/ledge, authored leather bag/belt/buckle, pixel hammer, Ward treatment and
typography. Current silhouettes, thin supplied frames and matte leather are
explicit placeholders. The tool glyph uses Segoe UI Symbol when available, with
English Craft fallback; no font files are shipped. Individual tile approval,
final equipment content/effects, run content/length/rewards, authored clip timing
and permanent AP carry-over/balance decisions remain future approvals.

Earlier linked worktrees under `build/parallel/agent-{a,b,c}` remain detached at
`81e649f`, holding historical worker artifacts. They are ignored, not additional
pending main-branch work, and must not be published. Do not delete their parent
without proper Git worktree cleanup when authorized. No cleanup was performed.
