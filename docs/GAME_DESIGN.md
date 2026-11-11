# Ashen Oath — Game Design Document (GDD)
Version: 0.2 (approved combat tile design). Status: **rules below are approved where marked; unresolved balance values and future ideas remain provisional.** This document specifies intended behavior, not implemented gameplay.

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

## Combat tiles (approved MVP rules)
The board is 7x7 with exactly four base tile types: **Sword, Shield, Herb, Action**. Skull/Occult and Heart tiles are excluded from the MVP. Do not introduce multiple herb/flower variants or additional base tiles.

Match-3 activates the basic tile effect. Match-4/5 activates an immediate special effect; it never creates a special tile requiring another move to activate.

| Tile | Match-3 basic effect | Match-4 | Match-5 |
| --- | --- | --- | --- |
| Sword | Physical damage | Immediate critical strike | Immediate critical strike with additional armor penetration; balance provisional |
| Shield | Temporary Guard | Ward | Ward |
| Herb | Generate crafting materials, never automatic healing | Immediate special reward not yet finalized | Immediate special reward not yet finalized |
| Action | Generate Action Points (AP) | Immediate special reward not yet finalized | Immediate special reward not yet finalized |

**Guard and Ward (approved):** Guard expires after the next enemy action. Ward persists until consumed or combat ends. Ward is a finite pool of absorbable damage, not permanent defense. Amounts and the order in which Guard and Ward absorb damage remain balance decisions.

**Action Points (approved):** AP is a shared resource for consumables and class abilities. AP does not grant additional board swaps. AP generation amounts, limits and action costs remain provisional.

### Herb collection, crafting and healing (approved rules)
- Herb materials persist throughout the current run.
- Each encounter has a finite herb collection budget. Once exhausted, herb matches still resolve normally but produce no more materials. Herb tiles remain on the board.
- Craft primarily between battles at normal material cost. Emergency crafting is allowed in combat at increased material cost.
- Healing items are activated manually and consume AP. Herb matches never heal automatically.
- The intended first healing item is **Bandage**: craft for **4 herbs between battles** or **6 herbs during battle**. These are the approved starting recipe costs; healing amount and activation AP cost remain provisional.
- An additional AP cost for emergency crafting is only a balance proposal, not approved. Do not confuse it with the approved AP cost for manually activating a healing item.
- Herb budget size, material yield and Match-4/5 rewards for Herb and Action remain unresolved. Do not invent these rewards.

### Match rules (provisional)
- Match 3+ horizontally or vertically; swap must create at least one match.
- Match-3 and immediate Match-4/5 effects follow the approved rules above. Additional cascade bonuses remain a future idea.
- Initial board should not start with accidental matches and should offer at least one legal move; reshuffle if stuck.
- Damage is integer based, with explicitly documented order of modifiers.
- Board state and random seed should be reproducible for tests.

## Classes
**Approved MVP:** Warden is the only playable class. Its defensive direction does not approve specific abilities or counterattack mechanics.

**Future ideas only:** Heretic (curses/life drain) and Reaver (bleed/risk and reward). Future classes do not authorize Skull/Occult tiles in the MVP. Keep class definitions extensible without implementing additional classes now.

## Equipment (future)
- Potential slots: weapon, armor, helmet, amulet, two rings.
- Gear modifies tile effects, stats and later triggers synergies.
- Item effects must be resolved by game logic, never by UI scripts.
- Rarity and curses are concepts, not final balance specifications.

## Run loop (later milestone)
Enter run as Warden → select room → battle/event/reward → next room/boss → death/completion → unlocks → new run. Class selection is a future extension when additional classes are approved.

## Scope boundaries
### First playable slice
- One hero (Warden), one enemy, a 7x7 board.
- Exactly Sword, Shield, Herb and Action tiles; legal swap, match resolution, fall/refill, cascades.
- HP, Guard/Ward, AP, enemy intent, alternating turns, win/lose; tile effects follow the approved rules above, with unresolved balance left open.
- Placeholder sprites are acceptable until combat loop is fun.

### Explicitly out of scope initially
- Hub UI and NPCs, additional classes, multiplayer, procedural overworld, multiple bosses, loot sets, complex meta-progression, elaborate skill trees.
- Crafting rules above are approved design for later implementation; do not build crafting, loot, additional classes or a Hub in the current documentation/UI work. Preserve architecture extension points only.
- Fatigue is not part of the MVP. It is a possible anti-stalling mechanic for later testing, not an approved rule.

## Open decisions
- Damage, critical multipliers, armor penetration balance, Guard/Ward amounts and absorption order, starting HP, enemy balance.
- Herb yields and encounter collection budgets; immediate Match-4/5 rewards for Herb and Action.
- AP generation/limits, ability costs/timings and whether a skill consumes an action; healing amount and activation AP cost for Bandage.
- Additional AP cost for emergency crafting is a proposal only. Other status effects and durations remain open; Guard/Ward expiry is approved above.
- Exact equipment slots and reward choices.
- Pixel-art palette and UI spacing after first visual mockup.
All undecided items are proposals: seek approval before implementing major new mechanics.
