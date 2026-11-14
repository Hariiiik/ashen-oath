# Forest Relic v2 combat skin

This records the original sprite integration checkpoint. The subsequent approved
`ui-reference.png` rework supersedes its 20/60/20 layout, floating inventory slots
and unused-portrait-frame statements. Current composition, component mapping and
remaining art requirements are in [COMBAT_UI_REFERENCE_REWORK.md](COMBAT_UI_REFERENCE_REWORK.md).
Source crops/reductions below remain relevant to reused assets.

Presentation integration only. No board textures, algorithms, combat calculations,
actor art/animation, equipment effects, crafting or encounter progression changed.
The supplied pack was found at `res://assets/ui/{panels,buttons,slots,meters}/`,
not the requested `assets/ui/forest_relic/`. Files were used in place without
renaming, moving, regenerating or modifying any source PNG.
The existing combat scene is `scenes/combat/combat_screen.tscn` (not `scenes/ui/`).

## Implementation and mapping

`scenes/ui/combat_theme.tres` instantiates the editor/runtime Theme script
`scripts/ui/forest_relic_theme.gd`. Its named type variations style the dynamically
created controls. `combat_screen.gd` assigns panel/equipment/compact variations;
`inventory_grid.gd` assigns the inventory variation. `segmented_meter.gd` changes
only drawing, using the same amounts, capacity, Guard/Ward grouping and AP preview.

| Asset relative to `assets/ui/` | Control |
| --- | --- |
| `panels/hero_panel.png` | Left column, RelicHeroPanel |
| `panels/center_panel.png` | Central column, RelicCenterPanel |
| `panels/loadout_panel.png` | Right column, RelicLoadoutPanel |
| `buttons/button_{normal,hover,pressed,disabled}.png` | Normal-sized action buttons through the shared Button theme |
| `slots/equipment_slot.png` | Six compact equipment buttons; labels/tooltips unchanged |
| `slots/inventory_slot.png` | Item/empty cells; icons, stack labels and tooltips unchanged |
| `meters/health_trough.png` | Both existing ProgressBars, including recreated EnemyStage slots |
| `meters/health_fill.png` | Red interior only, driven by native ProgressBar value/max |
| `meters/segment_empty.png` | Empty AP/defense segment |
| `meters/segment_ap.png` | Filled AP segment |
| `meters/segment_guard.png` | Guard overlay segment |

There is **no Ward texture**. The existing translucent veil and outline remain
above Guard/empty sprites. Worn backing is decoration, never an Armor resource.
`portrait_frame.png` and `label_plate.png` are intentionally unused: adding them
would create unrequested nested frames or change the existing portrait/layout.
Small status badges and board buttons retain compact native styles; decorative
action-button borders are not forced onto 34px badges or Match-3 tiles.

## Source preparation and nine-slice values

Source rectangles are `(x, y, width, height)` in **original PNG pixels**.
Margins below are `(left, top, right, bottom)` in the **reduced texture pixels**
actually passed to StyleBoxTexture; multiply by the reduction divisor to obtain
the approximate source-pixel equivalent. Rounding occurs only at whole pixels.
Source texture dimensions and crops were inspected separately for every asset.

All crops/reductions happen once in memory, using `Image.INTERPOLATE_NEAREST` and
a texture cache. No derived art is written into the asset folder. Corners retain
their uniformly reduced proportions. Horizontal/vertical middle strips use
`AXIS_STRETCH_MODE_TILE`, not full-image stretching or TILE_FIT rescaling.

| Asset | Original | Source region | Divisor | Nine-slice L/T/R/B |
| --- | --- | --- | --- | --- |
| Hero panel | 184×421 | 3,3,178,415 | 2 | 24 / 36 / 14 / 32 |
| Center panel | 499×289 | 3,3,494,283 | 2 | 48 / 32 / 48 / 32 |
| Loadout panel | 159×417 | 3,3,153,411 | 2 | 12 / 28 / 18 / 26 |
| Button normal | 302×116 | 3,3,296,110 | 3 | 10 / 10 / 10 / 10 |
| Button hover | 306×116 | 3,3,300,110 | 3 | 11 / 10 / 11 / 10 |
| Button pressed | 300×111 | 3,3,294,105 | 3 | 10 / 9 / 10 / 9 |
| Button disabled | 302×116 | 3,3,296,110 | 3 | 10 / 10 / 10 / 10 |
| Equipment slot | 184×182 | 3,3,178,177 | 4 | 6 / 6 / 6 / 6 |
| Inventory slot | 185×185 | 3,3,179,180 | 4 | 8 / 10 / 8 / 8 |
| Health trough | 326×71 | 3,3,320,65 | 5 | 4 / 3 / 4 / 3 |
| Health fill | 326×69 | 20,18,286,33 | 5 | 0 / 0 / 0 / 0 |

Normal content padding remains **8px** for columns, buttons and slots. HP styles
have zero content padding. Health fill draws inset 3px on all sides, using negative
expand margins. Its source excludes the painted metal ends; the stationary trough
owns those caps, so neither cap moves or stretches as HP changes. Four button
states share content padding/minimum size and the same target control bounds.
Equipment uses the supplied slot for all states with restrained hover/press tint.

Segments use proportional square fitting, not nine-slice. Empty source region is
`(35,77,95,92)` in the 169×170 image, AP `(3,3,90,92)` in 96×98, Guard `(3,3,92,92)`
in 98×98. All reduce by 3 and receive transparent padding to a shared **32×32
in-memory canvas**; this is a rendering adapter, not an approved production asset
size. They fit the existing meter cells without changing their layout or values.

## Visual issues and handling

- The panels are painted illustrations, not seamless skins. Repeating their full
  interior produced visible rectangular seams; stretching would distort grain
  and detail. Therefore main panels use **frame-only `draw_center = false`** over
  native Charcoal Black `#161515`. Edge strips repeat at fixed pixel density, so
  foliage/rivets can recur; full illustrated backgrounds are not stretched.
- Source `segment_empty.png` contains a neighboring atlas fragment above the
  actual square segment. Its region excludes that fragment without editing PNGs.
- Extraction alpha is binary (0/255), with no partially transparent pixels in the
  supplied PNGs. Nearest reduction/filtering avoids introducing interpolated
  fringes. Rendered captures were inspected; no extra matte halo was observed.
  This remains provisional source art, not final production-art approval.
- Bottom foliage can intersect the original footer location. Quiet, borderless
  charcoal Label backplates keep footer copy readable without moving controls.
- Ward retains its existing native overlay because a dedicated asset is absent.

## Layout and verification

Original 20/60/20 anchors, outer margins (8px horizontal/12px vertical), 8px content
padding, portrait/EnemyStage sizes and 80px clearance remain. The board is exactly
`(446,260), 388×388` with 52px tiles at 1280×720 and `(619,324), 682×682` with 94px
tiles at 1920×1080. Baseline captures were made from an isolated archive of HEAD;
the source working tree was never reverted to obtain them.

Run `godot --headless --path . --script tests/ui/forest_relic_smoke.gd`:
106 checks cover panel/control bounds, state geometry, compact controls, inventory
counts, live HP bindings and unchanged combat state. Running the same harness
with GL Compatibility instead of headless performs 142 checks, including rendered
0/25/50/75/100% red coverage and unchanged decorative end-cap pixels for both bars
at both resolutions. It captures the finished UI, state swatches, HP percentages
and AP/Guard/Ward preview. Fixtures are test-only, not changed production values.

Also run existing `presentation_smoke.gd` (354 checks, including 49 board pointer
targets at both sizes), `combat_ui_smoke.gd`, and all board/combat/Bash/Bandage/Undo/
equipment/run/actor/integration suites. Native pointer smoke initially had four
hover failures on the unchanged baseline; headless pointer tests passed before
and after. Native render verification is separate from OS window-pointer events.

Artifacts (ignored; no source PNGs overwritten):

- `build/screenshots/forest_relic_1280x720.png`, `forest_relic_1920x1080.png`.
- `build/screenshots/forest_relic_button_states.png`, `forest_relic_meter_preview.png`.
- `build/screenshots/forest_relic_hp_{000,025,050,075,100}.png`.
- `build/forest_relic_before_1280x720.png`, `forest_relic_before_1920x1080.png`.
- `build/forest_relic_*.log`; isolated baseline copy under `build/ui_baseline/`.

Godot import sidecars are generated for the supplied PNGs. The pack and its
README/manifest were already untracked when this task began; they were preserved.
No commit or push is performed by this integration.
