# Combat UI prototype

Open `scenes/combat/combat_screen.tscn` in Godot 4 and press **F6**.
Alternatively: `godot --path . res://scenes/combat/combat_screen.tscn`.
The existing foundation boot scene remains available through F5.

Headless layout/selection check:
`godot --headless --path . --script tests/combat_ui_smoke.gd`.

The screen uses the project's 1280×720 reference resolution with 20/60/20
percent columns, a shared charcoal/crimson/bone/gold theme, reusable board
tiles, and geometric portrait placeholders. Tile selection updates feedback;
it does not swap tiles, advance turns, or resolve matches. All displayed stats,
intent, equipment slots, ability slots, and resources are illustrative fixtures.

Presentation lives in `scripts/ui/`; no domain or application systems are added.
The enemy portrait can draw above its decorative frame using an explicit
z-index. Its stage and artwork ignore mouse input and occupy a separate layout
region above the board. Replace its geometry with nearest-filtered art later,
preserving that input boundary. The board uses four provisional GDD tile icons.
Its deterministic static pattern is not a playable board generator.

Remaining work: approved pixel art, visual review in a window, and later binding
to domain/application state when combat mechanics are implemented. Equipment,
abilities, resources, balance, and Match-3 rules remain outside this prototype.
