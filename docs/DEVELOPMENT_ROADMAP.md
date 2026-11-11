# Development Roadmap

## Milestone 0 — Foundation (this archive)
- [x] Godot project and simple boot scene
- [x] Git hygiene / ignore rules
- [x] GDD, architecture, Codex repository instructions
- [x] Specialist agent role guides
- [ ] Import and run locally in Godot
- [ ] Create local Git repository and first commit
- [ ] Create private GitHub repository and push
- [ ] Log in to Codex locally

## Milestone 1 — Board prototype
- 7x7 generated board with exactly Sword, Shield, Herb and Action tiles; seedable RNG, tile swap, legal moves, match discovery, gravity and refill, cascades, dead-board reshuffle. No Skull/Occult tiles or multiple herb/flower variants.
- Tests for algorithms; placeholder tile visuals.

## Milestone 2 — Complete battle
- Single Warden (the only MVP class), single enemy, approved basic Match-3 and immediate Match-4/5 effects, HP, Guard/Ward, AP, encounter herb collection budget, enemy intent, phase transitions, victory/death. No deferred special tiles; Herb/Action special rewards need design approval before implementation.

## Milestone 3 — Combat UI
- Left hero panel, large looming top enemy, board center, right skill/equipment panel; animations that never block interaction.

## Milestone 4 — Light RPG
- 1-2 abilities, early gear modifiers, data-driven content.
- Later crafting/consumable work follows the GDD: run-persistent herbs, normal between-battle crafting, increased-cost emergency crafting, manual healing item activation using shared ability/consumable AP. Bandage material costs are 4/6 herbs; healing and activation AP amounts remain provisional. Crafting AP cost is an unapproved proposal. No implementation is requested now.

## Milestone 5 — Simple run
- Handful of rooms, rewards, failure, replay and basic seed/saves. Hub later.

Each milestone must be independently runnable and committed before expansion.

Fatigue remains outside the MVP and may only be considered in later anti-stalling tests. Keep extension points for future classes, loot, crafting and a Hub without building those systems in the current documentation/UI work.
