# Core combat prototype (Sprint 04)

Open `scenes/combat/combat_screen.tscn` in Godot 4 and press **F6**.
Alternatively: `godot --path . res://scenes/combat/combat_screen.tscn`.
The existing foundation boot scene remains available through F5.

Headless layout/selection check:
`godot --headless --path . --script tests/combat_ui_smoke.gd`.

The screen uses the project's 1280×720 reference resolution with 20/60/20
percent columns, a shared charcoal/crimson/bone/gold theme, reusable board
tiles, and geometric portrait placeholders. Select one tile, then an orthogonally
adjacent tile to swap. Re-click to deselect; a distant click selects a different
tile. Invalid swaps revert without spending a move. Valid swaps clear matches,
apply gravity/refill and resolve cascades with input locked. A valid swap consumes
one player turn; an invalid swap consumes none. After all surviving cascades, the
enemy executes its displayed intent. Victory prevents retaliation; victory and
defeat lock the board. Press F6 again in the editor to restart the encounter.
HP, Guard, Ward, AP, herbs, budget, turn and intent are live state. Equipment,
ability slots and status slots remain placeholders.

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
The UI smoke test above also exercises rollback, valid swaps, input locking,
live HP/resources, enemy retaliation, terminal input locks, and victory/defeat.

Remaining work: balance testing, approved pixel art and visual review in a window.
Crafting, item usage, abilities, equipment stats, additional classes/enemies,
Hub and procedural dungeon remain outside this sprint. AP and herbs accumulate
but cannot yet be spent. Visual playback uses brief clear/refill steps rather
than sliding tile animations. There is no in-game restart or save system.
