# Core combat prototype (Sprint 04)

Open `scenes/combat/combat_screen.tscn` in Godot 4 and press **F6**.
Alternatively: `godot --path . res://scenes/combat/combat_screen.tscn`.
F5 now starts `scenes/run/run_entry.tscn`: three repeats of the existing test
encounter, using this same combat view. **Next Encounter** replaces End Turn
after a nonfinal victory; continuation is explicit. HP and Herbs/Bandages persist
without automatic healing/crafting. Guard/Ward and provisionally AP reset.
The last victory shows **Run Complete**. Debug Undo remains available until
explicit continuation, then starts fresh for the next encounter. F6 on the
standalone combat scene still launches one fresh encounter.

## Emergency crafting and Bandage (Milestone 4B)

The Consumables area has **Craft Bandage / 6 Herbs** (no AP cost) and **Use Bandage
×N / 2 AP** (provisional healing: up to 12 HP). Both work before the board swap
and in the post-match decision window; neither changes swap allowance or starts
the enemy action. Resolution, enemy action and combat outcomes block both.
Use is disabled without a Bandage, with insufficient AP, or at full HP to avoid
wasting an item. Hover previews two AP segments, even when use is unavailable.

The inventory shows live Herb and Bandage stacks; Bandage's BND glyph is temporary
native UI rather than final art. The scene exposes `run_inventory` for the run
owner to inject before `_ready`; reuse it across encounters to preserve both
stacks. Launching a standalone scene without injection starts a fresh inventory.
No automatic encounter progression or preparation screen is added.

The standard recipe is 4 Herbs as a design reference only. Normal crafting is not
available after every room; preparation is intended between runs, with future
special crafting/safe rooms possible. Neither is implemented. Undo restores both
stacks along with HP and AP after crafting/usage.

Tests: `godot --headless --path . --script tests/bandage_test.gd`.

Debug builds also expose **DEBUG / Undo Last Turn**, restoring the pre-turn state
once, including after victory/defeat; it is disabled during resolution/playback.
`debug_match_logging` enables detailed group/cascade/effect traces in Godot Output.
See [DEBUG_COMBAT.md](DEBUG_COMBAT.md) for snapshot boundaries, the Shield-cross
investigation and a reproducible 12-Guard cascade. No T/L policy or balance changes
are introduced by these tools.

Headless layout/selection check:
`godot --headless --path . --script tests/combat_ui_smoke.gd`.

The screen uses the project's 1280×720 reference resolution with approximately 22/56/22
percent columns, a shared charcoal/crimson/bone/gold theme, reusable board
tiles, and geometric portrait placeholders. Select one tile, then an orthogonally
adjacent tile to swap. Re-click to deselect; a distant click selects a different
tile. Invalid swaps revert without spending a move. Valid swaps clear matches,
apply gravity/refill and resolve cascades with input locked. A valid swap consumes
one player board move; an invalid swap consumes none. After all surviving cascades,
the board locks and the player may use Shield Bash, then explicitly press **End
Turn** to let the enemy execute its displayed intent. There is no decision timer.
Victory prevents retaliation; victory and
defeat lock the board. Press F6 again in the editor to restart the encounter.
HP, Guard, Ward, AP, herbs, budget, turn and intent are live state. Equipment,
the second ability slot and status slots remain placeholders. Shield Bash is functional.

## Shield Bash and turn timing (Milestone 4A)

The first ability button is **Shield Bash / 3 AP** with the tooltip:
"Consume all Guard to deal equal physical damage. Costs 3 AP."
It is enabled only with positive Guard, at least 3 AP, and a player ability window
(before the board swap or after all cascades). It is disabled during playback,
enemy actions and terminal states. Hover still previews three AP segments when
unavailable; insufficient AP is clearly marked. The second ability is locked.

Activation consumes 3 AP and all stored Guard, applying that Guard amount as
physical damage with existing mitigation. Ward is untouched by the ability;
standard combat-end cleanup applies on victory. Feedback reports Guard consumed
and physical damage. No swap, AP/Guard generation, cooldown or automatic enemy
action is triggered. Reuse is allowed if Guard and AP become available again.

After a valid swap's playback, `POST_MATCH` enables **End Turn** while keeping the
board disabled. The player may activate Shield Bash or finish the turn. End Turn
is disabled before a swap and during playback/enemy action/outcomes. Its click
alone starts the existing short enemy-action presentation delay; the decision
window has no automatic delay/timeout. The next turn restores board input.

## Modular presentation layout

The screen follows `references/art/ui-reference.png` with approximately 22/56/22
hero/center/loadout zones. At the 1280x720 reference
size the board uses 52px square hitboxes (388px board including gaps), compared
with the earlier 40px tiles. At a logical 1920x1080 it uses 94px tiles (682px
board). These are responsive layout results, not asset production specifications.
The normal canvas-items stretch mode also supports scaling the reference layout
to larger 16:9 windows. Nearest filtering and the provisional PNG tile art remain.

- `scripts/ui/enemy_stage.gd`: a mouse-ignoring visual stage supports
  `set_enemy_count(1..3)`. Only its first card binds the existing enemy state;
  extra cards are explicitly previews, without combat actors or targeting. Slot
  changes rebind the live primary labels. A dedicated 80px clearance region
  separates the stage from the board. The artwork view may extend 32px below its
  frame into this clearance, without reaching interactive board cells. Artwork
  and info have separate frames; both remain pointer-transparent.
- Hero frame height is 350px at reference size (525px at logical 1080p), with an
  inset ActorView and an integrated class/level plaque. There is no standalone
  hero name. The silhouette remains temporary native art. Compact G/W/empty
  status badges expose descriptions and exact live counts through tooltips.
- `scripts/ui/segmented_meter.gd`: six muted yellow/olive AP segments use Rotting
  Leaf and Bone highlights from the approved palette. Plates form a continuous
  joined bar, with fixed source caps and one-pixel dividers. Shield Bash previews its
  approved **3 AP** cost; the second slot is locked. Hover or
  keyboard focus outlines required segments; unavailable segments receive rust
  crosses and an explicit insufficient-AP label. Hover spends nothing; a valid
  Shield Bash click spends 3 AP through the combat controller.
- The same component presents decorative worn iron plates with Guard texture
  and a translucent Ward overlay. Each active overlay segment represents
  up to six points, visually saturating above 36; exact Guard/Ward values remain
  in labels/tooltips. The backing plates are not Armor or another resource.
- Compact equipment slots have full-name hover tooltips; no equipment behavior
  is connected. Reserved ability and consumable areas remain visible.
- End Turn shares the central footer with turn/feedback, aligned bottom-right
  below the board. The run still reuses that same button for explicit continuation.
- `consumables_belt.gd` groups Bandage use and a crafting toggle on one temporary
  native leather surface. Its nonmodal `crafting_popup.gd` remains inside the
  right column, stays open through turns/Undo, and routes its only recipe button
  to the existing crafting handler. Availability follows the same phase/resource
  gates. `inventory_bag.gd` groups the existing scrollable grid and live totals.
- `scripts/ui/inventory_grid.gd`: scrollable three-column view accepts item
  dictionaries (`id`, `name`, `description`, `texture`, `quantity`) and updates
  stacks through `set_quantity()`. The herb bundle uses the provisional Herb PNG
  and live run count. A BND glyph displays the Bandage stack. Empty slots reserve
  future item types; only emergency Bandage crafting/use is implemented, with no loot
  or other recipes. Scrolling appears when the
  entries exceed available space.
- Combat feedback and turn labels stay below the board. Long feedback is clipped
  to preserve the layout, with the full report on hover after resolution.

The layout refactor was presentation-only. Milestone 4A additionally connects
Shield Bash and the post-match phase to the controller/rules, preserving the
board engine and all existing tile/resource effects.

Presentation lives in `scripts/ui/`; pure board logic lives in
`scripts/board/board_model.gd` and has no UI/node dependencies. Combat state,
prototype rules and phase orchestration live in `scripts/combat/`, independent
from UI nodes. Herb inventory is in-memory run data, not saved to disk.
The enemy portrait can draw above its decorative frame using an explicit
z-index. Its stage and artwork ignore mouse input and occupy a separate layout
region above the board. Replace its geometry with nearest-filtered art later,
preserving that input boundary. The board uses exactly Sword, Shield, Herb and
Action placeholder icons. Change `board_seed` on the combat screen root in the
Inspector to reproduce a different starting board. Equal seeds and swaps produce
equal refills and cascades. Generation avoids starting matches and ensures a
legal move. Dead boards reshuffle without automatic matches; after 256 failed
permutations a pathological tile distribution is regenerated.

`try_swap()` returns a structured `SwapResult`: validity, swapped snapshot,
ordered `CascadeStep` records (matches, unique removed indices, cleared/refilled
snapshots), reshuffle flag and final board. Each match records tile type, unique
cells, longest straight run and rank 3/4/5 (5 means 5+). Intersecting runs merge
so a tile belongs to one group; rank uses the longest run, without inventing a
reward for combined shapes. No special tiles are created. Combat effects are
immediate per cascade step, not deferred to a later move. The UI emits
`board_resolved(result)` after playback; effects have already been processed.

## Prototype testing values (not approved final balance)

| Tile | Match-3 | Match-4 | Match-5+ |
| --- | --- | --- | --- |
| Sword | 6 physical damage | 12 critical physical damage | 18 physical damage, ignores armor |
| Shield | 6 Guard | 8 Ward | 12 Ward |
| Herb | 1 herb | 2 herbs | 3 herbs |
| Action | 2 AP | 3 AP | 5 AP |

AP caps at 6 and cannot grant additional swaps. Herb gains cap at the remaining
encounter budget; exhausted Herb matches still clear/refill without collecting
materials or healing. Herb/Action special amounts are experimental Sprint 04
values, not finalized design decisions. Matches longer than five use Match-5.

The test Warden starts at 100/100 HP with zero Guard, Ward, AP and herbs.
The encounter budget starts at 10 herbs. These two unspecified starting values
(hero HP and budget) are isolated prototype defaults. The unarmored test enemy
has 40 HP and alternating 5/8 attacks. Guard absorbs first, then Ward, then HP.
Unused Guard expires after the enemy action; Ward persists until consumed or
combat ends. No enemy armor changes or equipment stats are exposed in gameplay.
All simultaneous groups resolve before checking victory; later cascades do not
grant combat rewards after the lethal step. The board engine still computes a
stable final board, including unused visual snapshots after victory.

## Verification

Board algorithm tests:
`godot --headless --path . --script tests/board_model_test.gd`.
Combat rules and controller tests:
`godot --headless --path . --script tests/combat_test.gd`.
Shield Bash rules, timing and UI tests:
`godot --headless --path . --script tests/shield_bash_test.gd`.
Presentation component and responsive layout tests:
`godot --headless --path . --script tests/presentation_smoke.gd`.
This validates 1280x720 and 1920x1080, all 49 pointer hit targets, stage capacity,
art clearance, AP hover previews, read-only defense, inventory scrolling and stack
counts. To capture rendered previews, run the presentation test without
`--headless` and append `-- --capture`; captures go to ignored `.godot/ui_*.png`.
The UI smoke test above also exercises rollback, valid swaps, input locking,
live HP/resources, enemy retaliation, terminal input locks, and victory/defeat.

Remaining work: balance testing, approved pixel art and visual review in a window.
Standard/between-battle crafting, preparation, safe rooms, other item usage/abilities,
equipment stats, additional classes/enemies, Hub and procedural dungeon remain
outside this slice. AP can be spent on Shield Bash or Bandage use, and Herbs on
emergency Bandage crafting. Visual playback uses brief clear/refill steps rather
than sliding tile animations. There is no in-game restart or save system.
