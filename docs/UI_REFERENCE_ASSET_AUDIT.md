# UI reference and asset audit

Reviewed 2026-11-14. Presentation guidance only; no new mechanics or final art
approval. Inspected `references/art/ui-reference.png` at its actual resolution
and all sixteen individual PNGs in `assets/ui/`. The supplied pack lives directly
under `assets/ui/`, not a `forest_relic` subdirectory. Existing tile PNGs remain
outside this audit and must not be regenerated for the layout change.

## Composition to preserve

The reference depends on three unequal vertical zones and large material masses,
rather than numerous nested cards. The left is a tall portrait between substantial
stone uprights, followed by quiet HP, defense and AP blocks. Its short label
plates separate sections without repeating an entire ornate panel around each.
The center gives the enemy the left side of a shallow ruins stage and puts its
name, HP and explicit intent on the right. A broad stone ledge separates this
from the square board. Turn feedback and End Turn share the bottom strip. The
right places compact equipment and abilities above a horizontal consumable belt
and a recognizable hanging leather bag.

Reproduce that hierarchy with existing controls. The reference's illustrated
Warden, goblin, scenery and bag are composition targets, not supplied separate
production assets. Reference captions, item arrangements and illustrated numbers
do not authorize gameplay changes. Enemy overlap belongs above decoration only;
all 49 board cells, essential labels and buttons need unobstructed hit targets.

For a 1260 x 696 usable layout inside the baseline window, reserve 388px for the
7 x 7 board (52px cells plus 24px existing aggregate spacing), about 58px for the
footer, and 22-30px for vertical gaps. The complete top stack must fit about
220px, including its title and stage padding. Do not independently add a tall
enemy scene, header and clearance on top of that budget. Give the enemy roughly
the left 40% of the stage and the text the remainder; use proportional actor fit.
Use approximately 240-250px side columns, 10-12px column gaps and the remaining
width for the center. These are layout recommendations, not revised board rules.

## Individually inspected source assets

| Source | Observed fit and limitation |
| --- | --- |
| `panels/hero_panel.png` | Thin stone frame, heavy upper-left foliage, dark painted interior. Suitable outer frame; does not supply the reference's thick portrait columns. |
| `panels/center_panel.png` | Wide frame with broad corner masses and lower-right foliage. Use outer center boundary; do not repeat its nonseamless interior. |
| `panels/loadout_panel.png` | Narrow upright frame with side metal tabs. Useful right-column boundary, not a leather bag. |
| `panels/portrait_frame.png` | Substantial near-square stone surround with opaque dark interior. A full-image overlay hides the actor. Use frame-only rendering, or keep unused. |
| `panels/label_plate.png` | Shallow pointed stone plate with quiet center. Useful section/title accent when proportionate; excessive repetition adds visual noise. |
| `buttons/button_normal.png` | Matte cracked stone with subdued iron edge; appropriate primary action surface. |
| `buttons/button_hover.png` | Warmer rust/copper edges; useful hover signal without luminous glow. Its dimensions differ from normal. |
| `buttons/button_pressed.png` | Darker recessed interior with a different source height. Preserve fixed control bounds and content padding across states. |
| `buttons/button_disabled.png` | Low-contrast grey surface. Pair with muted readable text and actual disabled input. |
| `slots/inventory_slot.png` | Square with extra upper-left foliage; quiet interior, suitable item cell. Repeating this frame at every small cell can become busy. |
| `slots/equipment_slot.png` | Quieter square frame, appropriate compact equipment surface. Does not contain equipment silhouettes. |
| `meters/health_trough.png` | Long quiet dark recess with fixed metal caps. Owns the stationary outer HP frame. |
| `meters/health_fill.png` | Red stone-like fill already enclosed by metal. Crop to red interior so shrinking HP does not move or duplicate end caps. |
| `meters/segment_empty.png` | Actual square segment is near the bottom; unrelated atlas strip and large blank region above it must be excluded. |
| `meters/segment_ap.png` | Muted ochre segment with metal rim; suitable existing AP meter. |
| `meters/segment_guard.png` | Cool steel segment with scratches; suitable Guard. There is no dedicated Ward asset. |

## Central theme recommendations

Keep resource reuse in `forest_relic_theme.gd` and its shared Theme resource.
Recommended variations are outer hero/center/loadout frames; shallow section
plates; quiet stat blocks; a frame-only portrait surround; equipment/inventory
cells; normal action buttons; and a subdued temporary leather container.
Prefer borderless quiet stat blocks to another large ornate frame. Thick stone
columns require authored art; do not simulate them with exaggerated bevels,
cartoon rivets or stacks of painted rectangles.

The existing source crops and reductions documented in `FOREST_RELIC_UI.md` are
the inspected starting point. Retain panel `draw_center = false`. Painted panel
interiors are not seamless textures. Existing reduced nine-slice margins are
hero 24/36/14/32, center 48/32/48/32, loadout 12/28/18/26 (left/top/right/bottom).
These protect corner ornament, not text: independently use 8-12px content insets
and extra clearance where leaves intrude. A portrait candidate can use the same
nearest reduction by 2, with approximately 14/16/14/16 reduced-pixel margins,
`draw_center = false` and the actor behind the frame. Validate corners in a
rendered capture before adopting that candidate.

Normal/hover/pressed/disabled button margins remain approximately 10/10/10/10,
11/10/11/10, 10/9/10/9 and 10/10/10/10 after reduction by 3. Keep identical
content insets and minimum bounds for all four states so hover does not reflow
labels. Hover may use the supplied warmer art; pressed uses the recessed art;
disabled uses muted art/text. Compact cells can tint their existing frame
slightly for hover and darken for press/disabled. Avoid gloss, luminous outlines
and additional decorative bevels. Focus must remain visible independently of
hover. Use a quiet compact style for small badges and menu rows rather than
forcing large action-button corners into them.

Keep nearest-neighbor filtering and whole-pixel placement. Existing cached
nearest reductions are rendering adapters, not replacement production assets.
Never stretch the complete portrait, frame or segment nonuniformly to fill a
rectangle. Fit actors proportionally and crop/letterbox scenery intentionally.
The empty-segment crop `(35,77,95,92)` excludes its atlas contamination; preserve
that handling. Inspect at baseline size and 1920 x 1080, especially repeated
border seams, corner clipping, alpha edges and text crossing foliage.

## Missing final assets and honest fallbacks

| Needed final art | Current acceptable temporary treatment |
| --- | --- |
| Warden portrait with grounded face/armor | Existing replaceable native actor presentation; frame and labels may improve its layout, but it remains placeholder art. |
| Threatening goblin/enemy illustration | Existing native enemy presentation in a proportional slot; no invented cartoon creature drawing. |
| Forest ruin stage background | Quiet charcoal/forest backing; no crude programmatic ruined landscape. |
| Thick chipped-stone portrait columns and broad stage ledge | Existing supplied frame edges; do not claim thin frames reproduce reference architecture. |
| Authored leather inventory bag silhouette | Restrained matte brown native surface behind existing cells, explicitly temporary native leather, not final art. |
| Authored consumable belt and buckle | Quiet horizontal native leather backing around existing slots, explicitly temporary. |
| Hammer crafting icon | Readable English craft label or tooltip on the existing action; no improvised final hammer illustration. |
| Ward icon/segment treatment | Existing explicit Ward label and restrained separate overlay; steel Guard segment alone must not imply Ward is Guard or Armor. |

Bag and belt materials should stay Ash Brown/Burnt Umber with sparse low-contrast
edges, without decorative pseudo-stitching, rivets or gloss. Final hand-authored
or separately approved artwork is the next art task. No artwork was generated,
modified or approved by this audit.

## Verification

Read the project design, architecture, roadmap, handoff and art/UI briefings;
visually inspected the reference and each individual supplied UI PNG; compared
the current theme crops and documented integration. This change is documentation
only, so no Godot runtime test was needed. The integrated layout still requires
the lead's rendered checks and existing presentation/input smoke suite.
