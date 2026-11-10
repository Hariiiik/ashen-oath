# Pixel Art Direction — Draft v0.1

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

## Planned specs (not locked)
- Item icons: logical 64x64 source canvas.
- Hero portrait: vertical composition.
- Monster art: flexible resolution with consistent apparent pixel size.
- First pass: placeholders, then one approved enemy and one approved hero portrait before generating batches.
