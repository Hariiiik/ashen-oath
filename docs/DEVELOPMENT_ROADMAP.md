# Development Roadmap

Reviewed: 2026-11-14 against clean baseline `81e649f` and the verified
parallel equipment/run/presentation integration, grouped into thematic commits
for user-authorized publication. Bandage and emergency crafting
were already committed at that baseline. Checked items describe implemented/verified work; prototype
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
- [x] Combat rules/controller tests (583 checks passed) and combat UI smoke coverage, including explicit post-match End Turn.
- [ ] Approve final balance and Herb/Action special rewards. Sprint 04 explicitly authorized experimental rewards for testing; these are implemented without treating them as finalized GDD decisions.

### Developer diagnostics (supporting tools)

- [x] Match/cascade/effect logs identify raw runs, merged groups, unique positions and resource changes without changing T/L/cross rules.
- [x] DEBUG Undo restores one complete pre-turn snapshot, including board/RNG, combat state and both run inventory stacks; blocked during resolution, allowed after victory/defeat.
- [x] Diagnostics/Undo regression coverage (157 checks passed). These tools are not the planned full combat analytics/balancing milestone.

## Milestone 3 — Combat UI
Status: presentation slice and reusable actor infrastructure implemented and validated; authored animations/polish and manual acceptance remain pending.

- [x] Three zones: enlarged hero portrait, central enemy stage and board, compact equipment/ability/consumable/inventory areas.
- [x] Extensible EnemyStage with 1–3 visual slots; only one combat enemy, no targeting or multi-enemy logic.
- [x] Safe artwork clearance, enlarged square board, compact status tooltips, segmented AP hover previews and layered Guard/Ward presentation without an Armor mechanic.
- [x] Scrollable inventory view with live Herb/Bandage stacks; Bandage is the only implemented consumable. No loot system.
- [x] Forest / Rust / Iron direction documented; temporary native UI and provisional PNG tiles integrated.
- [x] Layout and rendered checks at 1280x720 and 1920x1080; 354 presentation checks passed, including all 49 unobstructed board pointer targets.
- [ ] Manual player acceptance/playtest of readability, hover behavior, pacing and outcome feedback.
- [ ] Individual final asset approval; tile/hero/enemy/UI artwork remains provisional.
- [x] Reusable ActorView/visual Resource, native fallback, shared theme and optional animation queue with skip/cancel/missing-clip safety; actor suite 44 checks passed.
- [ ] Authored animation content/polish and its future timing integration. Current board clear/refill playback remains unchanged; infrastructure does not apply effects or advance turns.

## Milestone 4 — Light RPG
Status: partially implemented through Milestones 4A and 4B and equipment data contracts; equipment effects and broader RPG content remain outside the current slice. Only Bandage item use is implemented; there is no loot system.

### Milestone 4A — Shield Bash

- [x] One functional Warden active ability: 3 AP, all current Guard converted to physical damage, no Ward contribution or consumption, no swap cost, bonus or cooldown.
- [x] Pre-swap and post-match activation windows; explicit End Turn before enemy action, no second board swap or automatic decision timeout.
- [x] Live first-slot button, approved tooltip, unavailable state, 3-segment AP hover preview and activation feedback. Second ability slot remains locked.
- [x] Automated rules/controller/UI tests and regressions for the new ability and timing (167 checks passed). See `tests/shield_bash_test.gd`.
- [ ] Manual acceptance/playtest of the ability windows and End Turn at both supported UI sizes.

The Shield Bash slice implements only the expressly approved ability rules;
it does not complete the whole Light RPG milestone or approve another ability.

### Milestone 4B — Emergency Crafting & Bandage

- [x] Existing Bandage: emergency recipe 6 Herbs, zero crafting AP; manual use consumes one Bandage and provisional 2 AP for up to provisional 12 HP.
- [x] Shared RunInventory Herb/Bandage stacks, action-window gates, AP preview and Undo restoration; Bandage suite 62 checks passed.
- [ ] Manual acceptance of resource economy, full-HP rejection and action-window usability.

The standard 4-Herb recipe is a design reference only. Preparation is intended
between runs, not automatically between rooms. No standard/between-battle crafting,
Preparation Screen, Hub, safe rooms or meta-inventory has been implemented.

### Equipment data contracts — approved parallel slice

- [x] Static definitions and inert future modifier descriptors, prototype slot compatibility, runtime loadout and atomic in-memory snapshot/restore; equipment suite 52 checks passed.
- [x] Actual loadout object persists across the integrated run without affecting combat calculations.
- [ ] Final equipment slots/content/bonuses, effect interpretation and equipment interaction UI require separately approved work. No loot or additional active ability is implemented.

## Milestone 5 — Simple Run

Status: **minimal sequential run prototype implemented and tested; broader run milestone incomplete**.

- [x] Explicit three-encounter test sequence reusing the existing Sentinel and combat engine; independent deterministic encounter seeds.
- [x] Persistent current HP/max HP, same RunInventory and equipment-loadout identity; no victory healing. Fresh Guard/Ward and provisional AP reset per encounter.
- [x] F5 run entry, explicit Next Encounter after victory, derived final victory/defeat result; no automatic crafting or preparation.
- [x] Current-encounter Undo until accepted advance, no cross-encounter Undo; run suite 85 checks passed and integrated UI regression passed at both supported sizes.
- [ ] Manual acceptance of the complete three-fight loop, defeat, final victory and Undo.
- [ ] Room selection/content, rewards, boss, procedural progression and disk saving remain future scoped work; this prototype does not approve or implement them.

The three repeats are verification content, not final run length or enemy variety.
There is no Hub, safe room, meta-inventory or automatic after-fight Preparation Screen.

## Milestone 6 — Combat Balance & Playtesting

Status: **PLANNED / NOT STARTED**. Full balancing begins only after core RPG
mechanics, crafting, equipment interactions and the basic run loop are playable.
The equipment data model alone does not satisfy these prerequisites. Until then,
address only critical balance problems and obvious gameplay exploits during development.
Positioned after Milestone 5; existing numbering is preserved. This plan authorizes no implementation or
balance changes now; all work below remains pending.

### Combat analytics

- [ ] Record average turns per battle and player damage taken per encounter.
- [ ] Separate Sword damage from Shield Bash damage and measure Shield Bash usage frequency.
- [ ] Track Guard generated, consumed (including absorption and Shield Bash) and expired unused.
- [ ] Track Ward generated and consumed.
- [ ] Track AP generated, spent and wasted; distinguish cap overflow from AP left unspent at combat end.
- [ ] Measure herb collection efficiency against the encounter collection budget, distinguishing collected materials from matches after exhaustion.

### Balance testing

- [ ] Compare offensive and defensive playstyles under reproducible encounter conditions.
- [ ] Evaluate Shield Bash effectiveness and its current approved 3 AP cost without treating evaluation as approval to change it.
- [ ] Evaluate the Sword, Shield, Herb and Action tile economy, Match-3/4/5 rewards and cascade effects.
- [ ] Identify dominant strategies and ineffective mechanics from measured results.
- [ ] Test encounters against different enemy attack patterns in future scoped test scenarios; do not implement new enemies or patterns as part of this documentation task.

### Balance tools

- [ ] Add developer-only combat statistics when this milestone is explicitly started.
- [ ] Use fixed random seeds for reproducible tests and comparisons.
- [ ] Integrate the existing Debug Undo where available, restoring pre-turn board/RNG/resources for replay; distinguish replayed attempts from independent encounters in analytics.
- [ ] Make prototype balance values configurable for controlled experiments, without changing current values now or silently overriding approved rules.

### Balance iteration

- [ ] Collect playtesting results and identify specific balance problems.
- [ ] Propose numerical adjustments with supporting evidence; preserve approved mechanics unless explicitly changed by the user.
- [ ] After the appropriate approval, compare before/after results using the same seeds and scenarios, and document conclusions.

No analytics, statistics UI, configurable balance tools, new tests or Shield Bash
rebalance are implemented by adding this milestone. Current combat values and
the approved 3 AP Shield Bash cost remain unchanged.

## Next review gate

Manually playtest the F5 run and standalone F6 combat scene at 1280x720 and a larger 16:9 window:
Shield Bash, emergency Bandage crafting/use, live stacks/AP previews, post-match
End Turn and DEBUG Undo. Verify naturally collected Herbs/AP and resource limits.
Record usability findings, critical balance issues or obvious exploits, then scope
the next task; defer routine tuning/full balancing to Milestone 6.
The next planned art task remains individual design/approval of Sword, Shield,
Herb and Action tiles; current PNG integration does not finalize those designs.
Verify explicit continuation, persistent HP/stacks, provisional AP reset, final
result and current-encounter Undo. Do not add equipment bonuses, new enemies or
other future systems solely because their data/UI extension points now exist.

Each slice must be independently runnable and verified. The user has authorized
thematic commits and push for this integration; later publication still requires
authorization.

Fatigue remains outside the MVP and may only be considered in later anti-stalling tests. Keep extension points for future classes, loot, crafting and a Hub without building those systems in the current documentation/UI work.
