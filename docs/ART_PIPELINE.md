# Actor presentation and UI art pipeline

This implemented infrastructure follows [ART_DIRECTION.md](ART_DIRECTION.md):
Forest / Rust / Iron, crisp nearest-filtered presentation, restrained native
iron/rust styling. It adds no final artwork, new actors or gameplay rules.
The existing provisional tile PNGs and board presentation remain unchanged.

## Replaceable actor definitions

`scripts/ui/actor_visual_definition.gd` is a presentation-only `Resource`:

- `texture`: optional static `Texture2D`.
- `sprite_frames`: optional authored `SpriteFrames`.
- `idle_clip`: optional ambient animation name, default `idle`.
- `clips`: optional mapping of presentation clip names to authored animation names.

No asset dimensions, frame counts, durations or mandatory clip names are imposed.
Review those with each future asset. Definitions contain no HP, damage, equipment
bonuses, enemy AI, RNG or callbacks into combat rules. Source artwork and individual
designs still require approval; creating an empty definition does not approve art.

`scenes/ui/actor_view.tscn` / `scripts/ui/actor_view.gd` provide a reusable decorative
`Control`. Assign `visual_definition` and set `enemy` for the native fallback role.
Without usable assets it draws the existing geometric Warden/enemy placeholder.
At rest it prefers the optional idle clip, then static texture, then fallback.
Assets can be replaced at runtime; replacement cancels outstanding playback.
EnemyStage uses the view for its existing 1–3 **visual-only** slots and retains its
primary HP/intent API. There is still only one gameplay enemy and no targeting.

Textures preserve their source proportions and remain inside their allocated UI
area. SpriteFrames are uniformly fitted with integer upscaling when they fit at
native size; smaller spaces use nearest-filtered proportional reduction. All art
is nearest-filtered, clipped to its view and ignores mouse input. This does not
alter board hitboxes, the three zones or the reserved enemy-to-board clearance.

## Optional playback

`ActorView.play_clip(name) -> bool` starts a presentation request and reports whether
the clip exists and can play. Every request emits `clip_finished(name, cancelled)`
once, including absent/empty/zero-speed clips (deferred completion). A nonlooping
authored clip finishes naturally. Looping clips cannot hold a combat wait: their
request completes deferred and the view returns to its resting presentation.
Use `idle_clip` for persistent ambient loops.

`skip_playback()` completes the current request; `cancel_playback()` cancels it.
Both return to resting art. Replacement and tree exit also cancel safely. Stale
deferred completion from a replaced clip cannot finish its successor.

`CombatVisualQueue` is an optional Node for sequential `enqueue(view, clip)` calls.
It emits `clip_completed` and `queue_finished(cancelled)`; `skip_current()` skips
the active request and `cancel()` discards all pending work. A destroyed/detached
view is skipped safely. The queue can be reused after cancellation.
Use one queue/playback owner per view. Cancel it on Undo, screen replacement or
encounter transition before disposing views. No completion signal applies combat
effects or advances turns: CombatController remains authoritative and existing
input gates remain with the screen. The queue is infrastructure, not a new timing
rule or mandatory wait in the existing board resolver.

## Reusable native UI styling

`scenes/ui/combat_theme.tres` extracts the existing native panel/button/HP style:
charcoal, ash brown, deep iron, cold/worn steel, old copper, dried blood and bone.
It supplies no fonts or final artwork. A screen may use a duplicated Theme when
local overrides are needed. Layout dimensions and resource calculations remain
owned by their existing components.

## Future asset integration checklist

- Review the asset against the primary reference and approved palette.
- Record source/provenance; do not overwrite existing art before checking usage.
- Review silhouette, material contrast and apparent pixel density at gameplay size.
- Author a Resource pointing to approved textures/SpriteFrames, optionally mapping
  clip names; keep all gameplay values outside that Resource.
- Verify missing-art fallback and missing-clip completion.
- Verify cancellation on Undo/transition, no duplicate effects or stuck input.
- Verify nearest filtering, proportional fit and unobstructed input at 1280x720
  and a larger 16:9 size. No fixed production sprite size is approved here.

## Verification

`godot --headless --path . --script tests/ui/actor_view_test.gd` covers fallback,
asset replacement, static/animated fit, clip mapping/completion, cancellation,
skip/reuse, looping and absent clips, disposed views and stage binding compatibility.
Run `tests/presentation_smoke.gd` for the existing 1280x720 / 1920x1080 layout and
board pointer-target checks after integration. New authored animation content,
manual visual acceptance and final assets remain pending.
