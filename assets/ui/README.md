# Ashen Oath — Forest Relic UI Sprite Pack v2

All PNGs are individual, unconnected assets for Godot 4.

## Visual direction
Weathered stone, thin iron reinforcement, sparse dried autumn foliage, muted Forest / Rust / Iron palette, restrained relief and contrast. No existing Match-3 tile art is changed.

## Files

- `panels/hero_panel.png` — 184×421 RGBA
- `panels/center_panel.png` — 499×289 RGBA
- `panels/loadout_panel.png` — 159×417 RGBA
- `panels/portrait_frame.png` — 235×246 RGBA
- `buttons/button_normal.png` — 302×116 RGBA
- `buttons/button_hover.png` — 306×116 RGBA
- `buttons/button_pressed.png` — 300×111 RGBA
- `buttons/button_disabled.png` — 302×116 RGBA
- `slots/inventory_slot.png` — 185×185 RGBA
- `slots/equipment_slot.png` — 184×182 RGBA
- `meters/health_trough.png` — 326×71 RGBA
- `meters/health_fill.png` — 326×69 RGBA
- `meters/segment_empty.png` — 169×170 RGBA
- `meters/segment_ap.png` — 96×98 RGBA
- `meters/segment_guard.png` — 98×98 RGBA
- `panels/label_plate.png` — 327×87 RGBA

## Implementation notes (future only)

These are standalone illustrations extracted from a generated atlas. They are not wired into any scenes, scripts or themes. Validate 9-slice regions manually: decorative side details may deform if margins are too narrow. Consider downsampling once with nearest-neighbor if you want coarser actual game-pixel density. The transparency is reconstructed from the generated checkerboard image, so inspect alpha edges before shipping. Existing Sword/Shield/Herb/Action tiles were not regenerated.
