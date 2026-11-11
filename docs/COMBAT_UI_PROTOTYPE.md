# Combat UI and playable board prototype

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
apply gravity/refill and resolve cascades with input locked. The board move
counter counts valid swaps only; it does not implement enemy turns. All displayed stats,
intent, equipment slots, ability slots, and resources are illustrative fixtures.

Presentation lives in `scripts/ui/`; pure board logic lives in
`scripts/board/board_model.gd` and has no UI/node dependencies. No combat effects
or combat controller are implemented.
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
reward for combined shapes. No special tiles or combat rewards are created.
The UI emits `board_resolved(result)` after playback for future integration.

Board algorithm tests:
`godot --headless --path . --script tests/board_model_test.gd`.
The UI smoke test above also exercises rollback, valid swaps, input locking,
and synchronization between the model and visible tiles.

Remaining work: approved pixel art, visual review in a window, and later binding
to domain/application state when combat mechanics are implemented. Equipment,
abilities, damage, Guard/Ward, herb inventory, AP and item usage remain outside
this prototype. Visual playback uses brief clear/refill steps rather than sliding
tile animations. A windowed visual review remains recommended.
