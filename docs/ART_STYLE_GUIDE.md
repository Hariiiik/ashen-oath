# Pixel Art Direction — Draft v0.1

This earlier draft is subordinate to [ART_DIRECTION.md](ART_DIRECTION.md), the
approved Forest / Rust / Iron specification. Use that document for visual
identity, palette, pixel density, materials, lighting and asset review criteria.

## Identity
Oppressive grimdark gothic fantasy: broken black iron, weathered stone, bone, ash, muted crimson and sickly highlights. Avoid glossy mobile-game art, cheerful saturation or mixed pixel densities.

## Rules
- AI art is source material, not automatically a game-ready sprite.
- Keep readable silhouettes at actual in-game display size.
- Use a controlled palette; test candidate colors in the actual Godot scene.
- Nearest-neighbor rendering; no blurred scaling or soft edges.
- Generate reusable assets separately: transparent enemy sprites, UI ornaments, inventory icons, backgrounds.
- Never depend on AI-generated text inside sprites; render text in Godot.
- Maintain provenance/rights for generated and third-party assets.

## Combat visual priority
Enemy artwork hangs over the board. Some body parts can bleed into ornamental borders; click/touch targets and vital indicators must stay legible and unobstructed.

## Production scope
- Fixed sprite resolutions, tile dimensions and animation frame counts are not approved.
- Individual characters, tiles and UI designs in the concept sheet require separate approval.
- Next art task: design and approve the four combat tiles individually before producing further asset batches.
