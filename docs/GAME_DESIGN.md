# Ashen Oath — Game Design Document (GDD)
Version: 0.1 (foundation). Status: **direction approved; individual combat numbers are provisional.**

## High concept
A single-player Windows PC grimdark pixel-art roguelite. The player fights monstrous enemies with a turn-based hybrid Match-3 board, class abilities and equipment. Runs are self-contained; future unlocks and a hub may be added later, without being part of the initial MVP.

## Design pillars
1. **Tactical clarity:** enemy intent is always readable; a player's move has explainable consequences.
2. **Build variety:** tile matches interact meaningfully with class, skills and gear.
3. **Oppressive atmosphere:** large gothic enemies visually loom above the board, sometimes overlapping *noninteractive* decoration.
4. **Small playable slices:** prioritize a complete, enjoyable single battle before long-term systems.

## Platform, presentation, audience
- Platform: Windows PC, keyboard/mouse (mouse-first for the board).
- Engine: Godot 4, GDScript.
- Art: AI-assisted pixel art with a consistent style guide and manual correction.
- Resolution target: 1280x720 baseline; responsive layout for 16:9 at larger resolutions.
- Core mode: single-player, offline, turn-based.

## Combat screen layout (approved)
- **Top-center:** large enemy artwork, HP and next-action intent. Enemy may overlap *decorative* UI borders, never interactive board tiles/buttons/text.
- **Center-below-enemy:** Match-3 board; initially 7 columns x 7 rows.
- **Left:** hero portrait, current/max HP, attack/defense, statuses, run level.
- **Right:** equipment summary, equipped slots and active ability buttons/resources.
- Bottom edge: turn/feedback and controls as needed.

## Turn model (approved)
1. Show enemy intent before player acts.
2. Player may activate allowed skills, then perform a tile swap/move.
3. Resolve matches, effects, falls and cascades in deterministic order; play queued animations.
4. Resolve win condition. If enemy survives, execute its announced action.
5. Resolve loss condition, update intent and return control to the player.
6. During resolution/animations, disable board and action inputs.

**Provisional design decision:** One valid matching swap consumes one player turn. Invalid swaps revert and do not consume a turn. Cascades remain part of the same turn. Explicit ability costs and whether a skill consumes an action remain to be designed. This is a proposal, not a final game rule.

## Tile types (provisional MVP set)
| Tile | Draft effect | Notes |
| --- | --- | --- |
| Sword | Physical damage | Class and equipment modifiers apply |
| Shield | Block | Used against the announced enemy attack |
| Skull | Occult damage | Can interact with curses later |
| Heart | Restore HP | Never exceed max HP |

**Later candidates:** Blood and Rune resource tiles. Do not include them in the first prototype without a balance reason.

### Match rules (provisional)
- Match 3+ horizontally or vertically; swap must create at least one match.
- Four/five matches and chain cascades can gain bonuses, after basic combat is fun.
- Initial board should not start with accidental matches and should offer at least one legal move; reshuffle if stuck.
- Damage is integer based, with explicitly documented order of modifiers.
- Board state and random seed should be reproducible for tests.

## Classes (future after the first combat slice)
- **Warden** — defense, shields, counterattacks; first playable class.
- **Heretic** — skulls, curses, life drain.
- **Reaver** — swords, bleed and risk/reward.
Implement only Warden in the first vertical slice.

## Equipment (future)
- Potential slots: weapon, armor, helmet, amulet, two rings.
- Gear modifies tile effects, stats and later triggers synergies.
- Item effects must be resolved by game logic, never by UI scripts.
- Rarity and curses are concepts, not final balance specifications.

## Run loop (later milestone)
Choose class → enter run → select room → battle/event/reward → next room/boss → death/completion → unlocks → new run.

## Scope boundaries
### First playable slice
- One hero (Warden), one enemy, a 7x7 board.
- Four base tiles, legal swap, match resolution, fall/refill, cascades.
- HP, block, enemy intent, alternating turns, win/lose.
- Placeholder sprites are acceptable until combat loop is fun.

### Explicitly out of scope initially
- Hub UI and NPCs, crafting, multiplayer, procedural overworld, multiple bosses, loot sets, complex meta-progression, elaborate skill trees.

## Open decisions
- Damage/block values, starting HP, enemy balance.
- Whether special matches create power tiles.
- Skill timings/costs; status effects and durations.
- Exact equipment slots and reward choices.
- Pixel-art palette and UI spacing after first visual mockup.
All undecided items are proposals: seek approval before implementing major new mechanics.
