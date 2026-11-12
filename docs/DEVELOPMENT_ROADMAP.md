# Development Roadmap

Reviewed: 2026-11-13 against the implementation at `dcf3a4e` and the latest
recorded validation. Checked items describe implemented/verified work; prototype
completion does not approve final balance or production artwork. Unverified setup
items remain unchecked. See `SESSION_HANDOFF.md` for the current checkpoint.

## Milestone 0 — Foundation (this archive)
Status: project foundation complete; some account/repository setup details unverified.

- [x] Godot project and simple boot scene
- [x] Git hygiene / ignore rules
- [x] GDD, architecture, Codex repository instructions
- [x] Specialist agent role guides
- [x] Import and run locally in Godot (headless validation and rendered UI checks in Godot 4.7.2)
- [x] Create local Git repository and first commit (existing history verified)
- [ ] Verify private GitHub repository visibility and initial push status; local `origin/main` exists, but remote visibility was not checked
- [ ] Confirm local Codex login/setup if still needed; not independently verified during this review

## Milestone 1 — Board prototype
Status: complete as a playable prototype.

- [x] 7x7 generated board with exactly Sword, Shield, Herb and Action tiles; seedable RNG, tile swap, legal moves, match discovery, gravity and refill, cascades, dead-board reshuffle. No Skull/Occult tiles or multiple herb/flower variants.
- [x] Tests for algorithms (1,151 checks passed in the latest recorded run).
- [x] Provisional PNG tile visuals with nearest filtering and replaceable scene texture assignments.

## Milestone 2 — Complete battle
Status: complete as a minimal single-encounter prototype; balance remains provisional.

- [x] Single Warden (the only MVP class), single enemy, immediate Match-3/4/5+ effects, HP, Guard/Ward, AP, encounter herb collection budget, enemy intent, phase transitions, victory/death. No deferred special tiles.
- [x] Invalid swaps spend no turn; cascades resolve before retaliation; victory prevents retaliation; terminal states lock input.
- [x] Combat rules/controller tests (582 checks passed) and combat UI smoke coverage.
- [ ] Approve final balance and Herb/Action special rewards. Sprint 04 explicitly authorized experimental rewards for testing; these are implemented without treating them as finalized GDD decisions.

## Milestone 3 — Combat UI
Status: static/presentation slice implemented and validated; animation/polish and manual acceptance remain pending.

- [x] Three zones: enlarged hero portrait, central enemy stage and board, compact equipment/ability/consumable/inventory areas.
- [x] Extensible EnemyStage with 1–3 visual slots; only one combat enemy, no targeting or multi-enemy logic.
- [x] Safe artwork clearance, enlarged square board, compact status tooltips, segmented AP hover previews and layered Guard/Ward presentation without an Armor mechanic.
- [x] Scrollable inventory view with live herb icon/quantity; no loot or item-use systems.
- [x] Forest / Rust / Iron direction documented; temporary native UI and provisional PNG tiles integrated.
- [x] Layout and rendered checks at 1280x720 and 1920x1080; 354 presentation checks passed, including all 49 unobstructed board pointer targets.
- [ ] Manual player acceptance/playtest of readability, hover behavior, pacing and outcome feedback.
- [ ] Individual final asset approval; tile/hero/enemy/UI artwork remains provisional.
- [ ] Animation/polish that never blocks interaction. No new animation work was authorized in the presentation refactor; current clear/refill snapshot playback remains.

## Milestone 4 — Light RPG
Status: partially implemented through Milestone 4A; equipment effects and broader RPG content remain outside the current slice. The inventory view is not a loot or item-use system.

### Milestone 4A — Shield Bash

- [x] One functional Warden active ability: 3 AP, all current Guard converted to physical damage, no Ward contribution or consumption, no swap cost, bonus or cooldown.
- [x] Pre-swap and post-match activation windows; explicit End Turn before enemy action, no second board swap or automatic decision timeout.
- [x] Live first-slot button, approved tooltip, unavailable state, 3-segment AP hover preview and activation feedback. Second ability slot remains locked.
- [x] Automated rules/controller/UI tests and regressions for the new ability and timing. See `tests/shield_bash_test.gd`.
- [ ] Manual acceptance/playtest of the ability windows and End Turn at both supported UI sizes.

This working-tree slice implements only the expressly approved Shield Bash rules;
it does not complete the whole Light RPG milestone or approve another ability.

- [ ] 1-2 abilities, early gear modifiers, data-driven content (requires separately scoped design/implementation work).
- Later crafting/consumable work follows the GDD: run-persistent herbs, normal between-battle crafting, increased-cost emergency crafting, manual healing item activation using shared ability/consumable AP. Bandage material costs are 4/6 herbs; healing and activation AP amounts remain provisional. Crafting AP cost is an unapproved proposal. No implementation is requested now.

## Milestone 5 — Simple run
Status: not implemented. The shared in-memory herb inventory is only an extension point, not a run loop.

- [ ] Handful of rooms, rewards, failure, replay and basic seed/saves. Hub later.

## Next review gate

Manually playtest the current combat scene at 1280x720 and a larger 16:9 window,
record concrete readability/interaction/balance findings, and scope the next task.
The next planned art task remains individual design/approval of Sword, Shield,
Herb and Action tiles; current PNG integration does not finalize those designs.
Do not begin Milestone 4 or multi-enemy combat solely because UI placeholders exist.

Each milestone must be independently runnable and committed before expansion.

Fatigue remains outside the MVP and may only be considered in later anti-stalling tests. Keep extension points for future classes, loot, crafting and a Hub without building those systems in the current documentation/UI work.
