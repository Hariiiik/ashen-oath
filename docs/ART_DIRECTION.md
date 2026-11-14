# Ashen Oath — Forest / Rust / Iron

Status: approved overall visual direction and starting palette. Individual hero,
enemy, combat tile and UI designs still require separate approval. This document
is the primary art direction specification and supersedes conflicting visual
guidance in the earlier `ART_STYLE_GUIDE.md` draft. It changes no gameplay rules.

## Primary reference

**Current combat UI composition source of truth:**
[`ui-reference.png`](references/art/ui-reference.png), supplied and approved for
the combat UI rework. Its framed portrait/plaque, joined meters, separate enemy
art/info, board/footer, belt and bag hierarchy supersedes earlier UI composition
measurements. Mockup resource numbers and illustrated items add no game rules.
The character illustrations are not separate production sprite assets. See
[COMBAT_UI_REFERENCE_REWORK.md](COMBAT_UI_REFERENCE_REWORK.md) for implementation
and remaining art gaps; the earlier sheet below remains the overall material guide.

Intended reference location: `docs/references/art/forest_rust_iron_reference.png`.
That exact filename was absent when this document was prepared. The supplied
sheet inspected in the project is
[`2b4f6a9f-1478-4991-b860-9fb40c006a7f.png`](references/art/2b4f6a9f-1478-4991-b860-9fb40c006a7f.png).
It depicts the described detailed Forest / Rust / Iron concept: a Warden,
forest enemy, four tiles, palette, iron panels and parchment UI samples. The
image has not been moved, renamed or modified by this documentation task.

Use this first detailed concept sheet as the primary reference for palette
relationships, pixel density, material treatment, directional light and overall
atmosphere. Later coarse-pixel experiments are not the target. The sheet's
overlapping steel plates, broken rust patches, worn leather straps, mossy ruin
silhouettes and localized edge highlights illustrate the intended material
language. Do not treat its individual faces, costumes, creatures, tile symbols,
frames or typography as approved production assets.

Concept labels are not gameplay specifications: the Herb caption “Heal / Recover”
does not authorize automatic healing. Herb tiles generate crafting materials;
Action tiles generate shared AP and do not grant extra swaps. Heart-like health
indicators in the sheet are UI examples, not an additional board tile type.
The written GDD and approved combat rules govern mechanics.

## Visual identity

- Grimdark medieval fantasy with detailed, handcrafted pixel-art character.
- Dark forests, abandoned ruins and decaying medieval environments. Age, exposure
  and practical use should be evident in surfaces, clothing and architecture.
- Stoneshard-like pixel-art craftsmanship is a quality reference for deliberate
  clusters, material definition and readable detail. Ashen Oath must retain an
  original identity rather than reproduce another game's characters or assets.
- Earthy, natural, moderately desaturated color relationships: forest greens,
  rust browns and cool iron, supported by charcoal and dirty parchment.
- Grounded proportions and restrained ornament. Threat and atmosphere come from
  silhouette, posture, texture and light rather than exaggerated faces or anatomy.

Avoid cartoon proportions, oversized pixels, excessively simplified sprites,
smooth digital painting disguised as pixel art, neon or pastel palettes, glossy
mobile-game finishes, excessive outlines, decorative golden borders and detail
that competes with combat information.

## Approved starting palette

These named starting colors are approved. Material-specific shading variations
and supporting colors are allowed when they preserve the reference's color
relationships and readability. This is not an absolute color-count restriction.
Use the written hex values below if image labels or sampled pixels differ.

### Dark foundations

| Color | Hex |
| --- | --- |
| Charcoal Black | `#161515` |
| Ash Brown | `#26211E` |
| Deep Iron | `#2F3438` |
| Soot Grey | `#44484A` |

### Forest

| Color | Hex |
| --- | --- |
| Bog Green | `#2F4A34` |
| Moss Green | `#4E6A42` |
| Muted Olive | `#6D7A4B` |
| Rotting Leaf | `#8B8A52` |

### Rust and blood

| Color | Hex |
| --- | --- |
| Dried Blood | `#6A2E2A` |
| Rust Red | `#8A4A32` |
| Burnt Umber | `#7A5237` |
| Old Copper | `#A1693D` |

### Iron

| Color | Hex |
| --- | --- |
| Cold Steel | `#53606A` |
| Iron Blue Grey | `#6A7680` |
| Worn Steel | `#87919A` |
| Edge Highlight | `#B4BCC1` |

### Highlights

| Color | Hex |
| --- | --- |
| Bone | `#C8B89A` |
| Old Parchment | `#A8926E` |
| Dust Beige | `#8E7D62` |

## Pixel-art rendering guidelines

- Match the moderately detailed density of the first reference. Use deliberate
  pixel clusters to describe form, wear and material; avoid both coarse blocks
  and indiscriminate single-pixel speckling.
- Preserve crisp pixel edges with nearest-neighbor filtering. Review at intended
  in-game display scale, not only enlarged in an art editor. Avoid blurred scaling,
  soft airbrushing and smoothed resampling.
- Maintain compatible apparent pixel density between tiles, characters, enemies
  and UI. Do not enlarge a coarse sprite to imitate the reference's detail level.
- Establish silhouette and major value masses first; add texture where it explains
  form or material. Small details must survive the gameplay readability check.
- Use selective contour contrast where needed to separate overlapping forms.
  Avoid thick uniform outlines around every object.
- No fixed sprite resolutions, tile dimensions, animation frame counts, universal
  pixel grid or asset-specific camera specifications are approved here. Determine
  production specifications through later asset review without changing the
  existing 1280x720 screen layout or board interaction geometry in this task.

## Materials and lighting

| Material | Treatment |
| --- | --- |
| Rusted iron | Dark iron base with irregular reddish-brown oxidation, pitting and exposed edges; avoid a uniform orange coating |
| Worn steel | Cool grey planes, scratches and selective bright edges; damage interrupts reflections rather than becoming glitter |
| Aged leather | Muted brown, matte surface, creases at bends, worn seams and practical straps |
| Moss and vegetation | Layered bog/moss/olive greens with dark recesses; group foliage into readable forms rather than scattered noise |
| Weathered stone | Heavy muted masses, chipped edges, cracks and localized moss; keep background texture subordinate to actors |
| Dirty parchment | Uneven warm beige, stains and frayed edges; preserve a calm, legible area behind text |

Use strong directional lighting with a coherent source within each asset or
scene. Separate lit planes from shadow masses; concentrate highlights on steel
edges, raised stone and other surfaces that justify them. Leather and moss should
remain comparatively matte. Do not impose a universal light angle before asset
reviews establish the intended scene context.

Keep silhouettes readable against dark forests and iron panels through value
separation and controlled highlights. Darkness must not obscure tile identity,
enemy intent, health or selection. Avoid glossy gradients, bloom-like halos and
bright edge accents applied equally to every material.

## Hero direction

Warden is the first and only MVP playable class. Use grounded medieval armor,
worn steel and iron, aged leather and practical equipment with believable weight
and construction. Keep anatomy and facial proportions realistic. Wear should
describe use and history without hiding the pose or armor structure.

The sheet's portrait is a style example. Face, hair, helmet, armor arrangement,
cloak, insignia, weapon and final silhouette are not approved character designs.
Do not treat these visuals as permission to add equipment stats or abilities.

## Enemy direction

Dark fantasy creatures should have threatening silhouettes, readable posture and
distinctive material textures: hide, rough cloth, rusted metal, bark or other
materials appropriate to the eventual approved creature. Keep each creature's
major forms distinct from the environment and from the Warden.

Avoid comic expressions, cute proportions and exaggerated cartoon monster
features. The forest enemy on the sheet is a mood/material example, not approval
of that enemy design, species, equipment or an additional gameplay enemy.

## Combat tile guidelines

Exactly four base tiles: Sword, Shield, Herb and Action. Each needs a distinct
silhouette and value structure, identifiable without relying on color alone.
Keep detail, apparent pixel density, lighting and framing consistent across the
set. Texture and borders support the central symbol rather than compete with it.

| Tile | Direction for individual design review |
| --- | --- |
| Sword | A clearly readable medieval weapon form in worn steel/iron, with restrained rust or leather cues; exact weapon design and orientation remain open |
| Shield | A distinct defensive silhouette with grounded construction and worn metal/material texture; exact shield shape and markings remain open |
| Herb | A recognizable plant silhouette using natural forest greens; visually communicate collected plant material, not instant healing; no separate herb/flower variants |
| Action | A distinct symbol for shared action resources that belongs to the medieval material language; exact motif remains open, and the sheet's parchment symbol is only an example |

The four concepts in the sheet are not individually approved tiles. Do not lock
their backgrounds, icon angles, border shapes, emblems or decorative details yet.
Evaluate candidates together on the board for distinction, especially Sword versus
Shield and Herb versus Action. Selection and interaction feedback must remain
clear without introducing new tile types or deferred special tiles.

## UI visual language

- Dark iron panels, weathered borders and restrained rust/bronze accents. Use
  modest ornament where it supports hierarchy; avoid decorative golden frames.
- Dirty parchment may support lore or text surfaces, with wear kept away from
  essential text. Use the current approved UI reference for composition; the
  earlier concept sheet is a material guide, not a technical screen specification.
- Readable typography and functional indicators take precedence over historical
  styling. Font choice and specific frame designs remain unapproved. Render
  user-facing copy in English through the game UI rather than baking text into art.
- Distinguish HP, Guard, Ward, AP, herbs, budget, intent and turn feedback through
  clear labels, values and visual hierarchy. Their exact icon designs remain open.
- Preserve the three combat zones and 7x7 board. Enemy art may overlap decoration
  only; it must not obscure interactive tiles, buttons, text or essential indicators,
  and decorative overlays must not intercept board input.
- Keep surfaces behind labels and tile symbols quiet. Scratches, rivets and moss
  should not compete with hover, selection, disabled or outcome states.

## Asset consistency checklist

- [ ] Matches the first detailed Forest / Rust / Iron reference, not later coarse experiments.
- [ ] Uses the approved palette relationships; any variations serve material or lighting needs.
- [ ] Has deliberate, crisp clusters and compatible apparent pixel density at gameplay scale.
- [ ] Has a readable silhouette and value hierarchy, without excessive outlining or noise.
- [ ] Differentiates rust, steel, leather, vegetation, stone and parchment where present.
- [ ] Uses coherent directional lighting and restrained, material-appropriate highlights.
- [ ] Keeps anatomy grounded and avoids cartoonish faces or proportions.
- [ ] Remains legible alongside other assets and live combat information.
- [ ] Preserves interaction boundaries and approved mechanics; reference captions add no rules.
- [ ] Has been individually reviewed; approval of this direction alone does not approve the asset.
- [ ] Records provenance for future generated/third-party source material; any generated source receives manual cleanup and review before production use.

## Remaining approvals and next art task

Next: **design and approve Sword, Shield, Herb and Action tiles individually**,
then review them as a coherent set. This document does not generate or implement
those assets.

Still open: the four final tile designs (especially the Action symbol), the Warden's
specific appearance, enemy designs, UI frames/indicators, font choice, production
asset specifications and animation requirements. Any reference-file rename to
the intended canonical path remains separate from this documentation change.
