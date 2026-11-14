# Approved-reference combat UI rework

The actual image `references/art/ui-reference.png` was inspected by the lead and
all four specialized workers. It is the current UI composition source of truth,
as distinct from a technical pixel specification or approval of mockup values.
This is a working presentation/layout implementation; final illustration is not
complete. No new gameplay system, rule, resource calculation or artwork was added.

## Baseline and ownership

Started from HEAD `89296e7` (Forest Relic integration already committed). The only
initial untracked file was the supplied reference PNG; it was preserved. Native
Codex workers audited in parallel, then implemented disjoint files in the shared
workspace. No new worktree was needed. The implementation checkpoint was left
uncommitted; the user's follow-up explicitly authorizes final handoff/roadmap
updates, thematic commits and push.

| Worker | Owned work |
| --- | --- |
| Hero/meters | `hero_portrait.gd`, `segmented_meter.gd`, `hero_panel_test.gd` |
| Enemy center | `enemy_stage.gd`, `enemy_stage_test.gd` |
| Inventory/belt/crafting | `inventory_grid.gd`, `inventory_bag.gd`, `consumables_belt.gd`, `crafting_popup.gd`, `loadout_components_test.gd` |
| Art/style audit | `UI_REFERENCE_ASSET_AUDIT.md`; viewed all 16 UI source PNGs |
| Lead | `combat_screen.gd`, shared Theme script, integration/layout tests and directly relevant documentation |

## Composition and integration

- Left: THE OATHBOUND, dominant framed portrait, bottom WARDEN / LVL 01 plaque,
  live HP, joined Guard/Ward and AP meters, existing G/W/empty status tooltips.
  The separate hero-name label is removed. `hero_class_label`/`hero_level` expose
  the existing prototype identity as presentation inputs; no class/level gameplay
  model currently exists. Mockup HP 92 and other example values are not copied.
- Center: live encounter heading; separate enemy art and information frames;
  actual HP/intent; reserved 80px clearance; unchanged 7x7 board and playback.
  Turn/feedback and End Turn share one footer, with the button at bottom-right.
  The run owner continues to use this same button for Next Encounter/Run Complete.
- Right: compact equipment, existing Shield Bash and locked second ability,
  developer-only Undo, shared consumable belt, and shared native leather inventory
  bag. Two belt slots remain inert placeholders. Bandage is the only consumable.

Side anchors are `0.21875`/`0.78125` (approximately 22/56/22), giving whole-pixel
column starts at both verified sizes. Outer margins remain 8px horizontal/12px
vertical; source panel frames stay frame-only. No gameplay component is made
smaller to accommodate ornament.

| Measurement | 1280x720 | 1920x1080 |
| --- | --- | --- |
| Board position | 446,260 | 619,324 |
| Board size | 388x388 | 682x682 |
| Tile hitbox | 52x52 | 94x94 |
| Hero frame | 248x350 | 388x525 |
| End Turn position | 824,657 | 1324,1015 |
| End Turn size | 160x40 | 160x40 |

The hero ActorView is inset inside the new wrapper; its clipping, placeholder,
visual definitions and animation APIs are unchanged. EnemyStage preserves its
legacy public binding/preview APIs and adds `art_frames`, `info_panels` and
`primary_name_label`. ActorView bounds can extend 32px below its frame into the
clearance. Stage/card/frame ancestors do not clip this overhang. All enemy/hero
decoration ignores pointer input, and the actor still ends above the board.
Only one enemy has combat state; extra slots remain previews without targeting.

Meters retain their public values and callbacks. Full-width nine-slice plates
have fixed 4px caps and one-pixel dividers instead of floating square icons. The
existing Guard/Ward display grouping (up to six points per plate), AP preview,
insufficient-resource crosses and native translucent Ward overlay remain.

## Nonmodal crafting and existing actions

The belt exposes `use_button` and `hammer_button`; the screen aliases the former
as the existing `use_bandage_button`. The hammer toggles a normal Control panel,
not a modal window, paused game, timer or fullscreen input catcher. The popup is
clamped near the belt inside the right-column bounds, so it cannot cover board
cells. It prefers the read-only bag area below the belt, keeping Shield Bash,
Undo and belt buttons accessible; above is a fallback if space is insufficient.
It remains open through swaps, cascades, enemy actions, Undo and outcomes.
Close/toggle remains usable; gameplay buttons follow existing restrictions.

The screen aliases the popup's single craft button as `craft_bandage_button` and
connects it once to the existing `_on_craft_bandage_pressed()` handler. There is
no second crafting calculation, recipe or inventory mutation path. UI cost strings
come from existing CombatRules constants. Existing emergency crafting stays
6 Herbs / zero crafting AP; manual Bandage use stays provisional 2 AP / up to
12 HP. Pre-swap/post-match timing and the single board swap remain unchanged.
During visual resolution, enemy actions and outcomes, craft/use stay disabled.
No preparation, between-battle crafting, new recipe or consumable is introduced.

InventoryBag wraps the same InventoryGrid and exposes its existing quantity/footer
labels. Grid public APIs, three columns, 58px minimum cells, 15 placeholder slots,
entries, quantities, tooltips and vertical scrolling remain. Shared flat leather
recesses and joined dividers replace isolated ornamental inventory frames.

## Reused assets and missing final artwork

The source pack remains under `assets/ui/`, not `assets/ui/forest_relic/`.
No source PNG was edited, generated or extracted from the approved reference.

| Supplied resource | Use |
| --- | --- |
| `panels/hero_panel.png`, `center_panel.png`, `loadout_panel.png` | Outer columns, existing fixed-density borders |
| `panels/portrait_frame.png` | Hero portrait surround and enemy art frame, center disabled |
| `panels/label_plate.png` | Hero class/level plaque |
| `panels/center_panel.png` | Separate enemy info border, quiet frame-only interior |
| `buttons/button_*.png` | Existing ability and relocated turn action states |
| `slots/equipment_slot.png` | Existing equipment summary cells |
| `meters/health_*.png` | Existing native ProgressBars and fixed end caps |
| `meters/segment_*.png` | Joined AP/defense plates; contaminated empty crop still excluded |
| Native matte brown surfaces | Temporary bag, belt and popup; no generated leather art |

Final gaps: illustrated Warden, goblin/enemy, forest ruins stage, thick stone
portrait columns/ledge, authored bag silhouette and belt/buckle, final pixel hammer
icon, dedicated Ward art and final typography. The existing actor placeholders do
not reproduce the reference's seated goblin or hanging leg; the layout supports
overhang for a future approved sprite. Thin supplied frames do not reproduce its
thick masonry. Native leather grouping is functional, not finished texture work.
The crafting toggle uses a temporary monochrome system-font tool glyph when
available, otherwise the English label Craft; no font files/dependencies are added.
See `UI_REFERENCE_ASSET_AUDIT.md` for source-specific inspection and requirements.

## Verification and artifacts

Component suites cover hero/plaque/joined meters, enemy frame geometry/overhang/
input transparency, bag scrolling/quantities and popup placement/toggle behavior.
`tests/ui/reference_layout_smoke.gd` uses the actual F5 run entry and verifies:

- Reference hierarchy, original board dimensions, relocated footer and all bounds.
- Live class/HP/intent, meter geometry and data ownership.
- Popup open while all 49 board hit targets remain reachable at both sizes.
- Exact existing craft/use resources, AP preview and Undo without duplicate actions.
- Invalid/valid swap, cascades, post-match crafting, explicit End Turn, victory and
  run continuation availability while the popup stays open.

The headless reference suite passed 252 checks; native OpenGL capture mode passed
154 checks (OS-window pointer dispatch intentionally excluded from native mode).
All sixteen headless suites passed (3,629 counted checks plus combat UI smoke
PASS); Godot editor validation and native HP percentage/end-cap checks also passed.
Fixtures used to display popup
resources exist only in tests, never in production defaults.

Screenshots under ignored `build/screenshots/`:
`ui_reference_1280x720.png`, `ui_reference_1920x1080.png`, and
`ui_reference_crafting_1280x720.png` / `ui_reference_crafting_1920x1080.png`.
They show the working layout with explicit placeholder-art differences, not
pixel-perfect completion. Publication was subsequently authorized by the user;
see `SESSION_HANDOFF.md` and Git history/status for the final checkpoint.
