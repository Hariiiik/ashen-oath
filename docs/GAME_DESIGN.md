# Ashen Oath — Game Design Document (GDD)
Version: 0.4 (approved combat tiles, Shield Bash and emergency Bandage crafting). Status: **rules below are approved where marked; unresolved balance values and future ideas remain provisional.** This document specifies intended behavior, not implemented gameplay.

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
- Art: detailed, handcrafted pixel-art direction — **Forest / Rust / Iron**. See [ART_DIRECTION.md](ART_DIRECTION.md) for the approved visual identity, starting palette and primary concept reference. Individual asset designs require separate approval; any AI-assisted source requires manual correction and review.
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
2. Player may activate allowed skills, emergency-craft or use Bandage, then perform a tile swap/move.
3. Resolve matches, effects, falls and cascades in deterministic order; play queued animations.
4. Resolve win condition. If the enemy survives, enter a post-match action window: no further board swap; Shield Bash, emergency crafting and Bandage use may be activated if available. The player explicitly selects **End Turn**; there is no decision timer or automatic enemy action.
5. Execute the announced enemy action only after End Turn. Resolve loss condition, expire remaining Guard, update intent and return control to the player.
6. During resolution/animations, disable board and action inputs.

**Approved turn timing (Milestone 4A):** One valid matching swap consumes the player's board move for the turn. Invalid swaps revert and do not consume it. Cascades remain part of the same turn. Shield Bash is available before that swap and after all cascades, before End Turn; it neither consumes nor grants a board swap. Other ability timings/costs remain open.

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
- Stackable Herbs and Bandages persist between encounters throughout the current run, in a run-owned inventory. No meta-inventory or disk persistence is implied.
- Each encounter has a finite herb collection budget. Once exhausted, herb matches still resolve normally but produce no more materials. Herb tiles remain on the board.
- Standard Bandage crafting costs **4 Herbs**, but is not automatically available between regular combat encounters. Preparation is intended **between runs**, not after every room/victory. Special crafting/safe rooms are future ideas only. Do not implement between-battle crafting, a Preparation Screen, Hub, safe rooms or meta-inventory in the current slice.
- Emergency combat crafting costs **6 Herbs per Bandage** and has **no AP cost**. It creates one stacked Bandage, without healing automatically or resetting the encounter collection budget.
- Healing items are activated manually and consume AP. Herb matches never heal automatically.
- The only implemented healing item is **Bandage**. Manually using one consumes **1 Bandage and a provisional 2 AP**, restoring **a provisional 12 HP**, capped at max HP. The current prototype rejects full-HP use to avoid wasting the item; this is an implementation guard, not a new healing effect.
- Crafting and Bandage use are allowed in the pre-swap and post-match action windows only. They preserve the current phase and neither consume nor grant a board swap, advance the enemy action or create AP/Guard/Ward. Block them during resolution, enemy actions and victory/defeat. Emergency crafting can occur at zero AP if materials suffice.
- Herb budget size, material yield and Match-4/5 rewards for Herb and Action remain unresolved. Do not invent these rewards.

### Match rules (provisional)
- Match 3+ horizontally or vertically; swap must create at least one match.
- Match-3 and immediate Match-4/5 effects follow the approved rules above. Additional cascade bonuses remain a future idea.
- Initial board should not start with accidental matches and should offer at least one legal move; reshuffle if stuck.
- Damage is integer based, with explicitly documented order of modifiers.
- Board state and random seed should be reproducible for tests.

## Classes
**Approved MVP:** Warden is the only playable class. Shield Bash below is the first approved active ability; no other ability or counterattack mechanic is approved by the class's defensive direction.

**Future ideas only:** Heretic (curses/life drain) and Reaver (bleed/risk and reward). Future classes do not authorize Skull/Occult tiles in the MVP. Keep class definitions extensible without implementing additional classes now.

### Shield Bash (approved — Milestone 4A)

- Warden active ability costing **3 AP**, base damage **0**. Store current Guard at activation, spend 3 AP, consume all Guard and deal that stored amount as physical damage (1:1 before existing physical mitigation). No bonus, critical strike, armor penetration or cooldown. The test enemy is unarmored.
- Ward contributes no damage and is not consumed by the ability. Existing combat-end cleanup still clears Ward if the hit wins the encounter.
- Requires Guard > 0 and AP >= 3. Valid only in pre-swap player input or the post-match decision phase; never during swap/cascade playback, enemy action or victory/defeat.
- Does not generate AP/Guard, consume the board swap, grant another swap or automatically advance the enemy turn. If the enemy survives, remain in the same player ability window.
- May be activated repeatedly if Guard is regained and sufficient AP remains; no once-per-turn limit.
- Check victory immediately after damage; a kill prevents retaliation. Invalid activation changes no combat state.
- The first ability slot is Shield Bash; the second stays locked. Post-match **End Turn** explicitly closes the ability window and permits the enemy action. End Turn is unavailable before the board move.

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
- Only emergency Bandage crafting/use is implemented in Milestone 4B. Standard/between-battle crafting, preparation, safe rooms, other recipes/consumables, loot, additional classes and a Hub remain outside this slice. Preserve architecture extension points only.
- Fatigue is not part of the MVP. It is a possible anti-stalling mechanic for later testing, not an approved rule.

## Open decisions
- Damage, critical multipliers, armor penetration balance, Guard/Ward amounts and absorption order, starting HP, enemy balance.
- Herb yields and encounter collection budgets; immediate Match-4/5 rewards for Herb and Action.
- AP generation/limits and future ability costs/timings (Shield Bash's 3 AP cost and swap-free timing are approved above); healing amount and activation AP cost for Bandage.
- Emergency crafting has no AP cost; Bandage's 2 AP/12 HP are provisional testing values. Other status effects and durations remain open; Guard/Ward expiry is approved above.
- Exact equipment slots and reward choices.
- Individual art designs and UI spacing; overall direction and starting palette are approved in [ART_DIRECTION.md](ART_DIRECTION.md).
All undecided items are proposals: seek approval before implementing major new mechanics.
