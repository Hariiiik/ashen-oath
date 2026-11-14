# Ashen Oath — Session handoff

## Current checkpoint — 2026-11-14, approved parallel integration

Baseline: `main`, HEAD `81e649f453cdf0b9f43201a7b5ae9c1b26546ef8`.
The baseline was clean. Shield Bash, Bandage, emergency crafting, RunInventory,
Match-3 and DEBUG Undo were already implemented/committed; none was reimplemented.
The previous handoff's `b7f9727`/uncommitted-Bandage description was stale.

The equipment/run/presentation integration and relevant documentation are
**implemented and tested**. The implementation checkpoint was uncommitted;
the user's subsequent request explicitly authorizes thematic commits and a push
to GitHub. Publication groups: equipment contracts, run architecture, actor
presentation infrastructure, shared integration and project documentation.
Use `git log`, `git status` and `origin/main` for the current publication state.
No installations or final art generation were performed.

## Playable state and launch

Godot 4.7.2, GL Compatibility, Windows-first, nearest filtering, baseline 1280x720.
F5 now opens `scenes/run/run_entry.tscn`: three explicit repeats of the existing
Hollow Sentinel test encounter. F6 on `scenes/combat/combat_screen.tscn` still
starts one fresh standalone encounter. The old foundation title scene remains
in the repository, but is no longer the configured main scene.

- One Warden, exactly Sword/Shield/Herb/Action on the existing seeded 7x7 board.
- Adjacent swaps, invalid rollback, matches, gravity/refill, cascades and dead-board
  reshuffling remain unchanged. Intersecting straight runs merge unique cells;
  rank is their longest straight run, capped at Match-5+. No new T/L policy.
- One valid swap per turn. After cascades, the board locks in POST_MATCH. Existing
  Shield Bash, emergency craft and Bandage actions work before/after the swap;
  explicit End Turn permits the announced alternating 5/8 enemy attack.
- No deferred special tiles, new enemy logic, balance changes or extra abilities.
- Three combat zones, 80px artwork clearance, 52px tiles at 1280x720 and 94px at
  1920x1080 remain. Warden/enemy visuals are replaceable native placeholders;
  provisional tile PNGs were not edited.

## Completed work by worker and lead

Native Codex workers A/B/C ran in isolated detached worktrees, all created from
the same clean baseline. Their source ownership did not overlap. Lead reviewed
and integrated **A → B → C**, then changed shared presentation/entry/docs only.

- **A — Equipment:** static Resource definitions, six prototype slot identifiers,
  compatibility checks, run-owned loadout assignments, copied mapping snapshots
  and atomic restore. Inert future modifier descriptors only. No item catalog,
  actual bonuses, modifier evaluator, loot or equipment interaction UI.
- **B — Run:** node-independent state/controller/encounter metadata/result;
  explicit continuation, independent seeded encounter boards, persistent HP and
  shared inventory/loadout, outcome/Undo safeguards. No new combat engine.
- **C — UI/art:** ActorVisualDefinition, ActorView scene, texture/SpriteFrames
  fallback, nearest proportional fit, optional clip queue/skip/cancel, shared
  Forest / Rust / Iron Theme; EnemyStage retains its public live-state API.
- **Lead integration:** actual equipment loadout injected into run; existing
  CombatController injected into CombatScreen; End Turn becomes Next Encounter
  only after nonfinal victory, or disabled Run Complete at final victory. A
  deferred transition rechecks live phase so Undo can revoke a queued request.
  Queue cancellation precedes UI Undo. No new mandatory animation wait.

## Approved boundaries and provisional values

Current HP/max HP persist without victory healing. Herbs/Bandages keep the same
existing RunInventory object; loadout identity persists without effects. Guard
and Ward reset at every new encounter. **AP resets to zero provisionally**, not
as a permanent approved design rule. Encounter budget/turn/intent reset through
the existing combat defaults.

CombatState owns live HP; RunState HP is a transition checkpoint only. Do not
mirror live HP into another authority or cache terminal results: Undo can revoke
victory/defeat. RunResult is derived from the current actual phase. Advancing
disables debug tools on the retired controller; old snapshots cannot restore
shared inventory across encounters. Current-encounter Undo remains usable after
victory/defeat until explicit advance. There is one checkpoint, no redo/history.

Shield Bash stays approved at 3 AP, consuming all Guard for equal physical base
damage, no Ward contribution, swap cost, cooldown or new bonuses. Guard absorbs
before Ward before HP; remaining Guard expires after enemy action.

Emergency crafting stays 6 Herbs → 1 Bandage, zero crafting AP. Manual use costs
provisional 2 AP for provisional up-to-12 HP; full-HP use is blocked. The standard
4-Herb recipe remains design-only. Preparation is intended between runs, not
automatically after rooms. No preparation screen, Hub, safe rooms, meta-inventory,
standard/between-battle crafting or additional consumables were added.

Tile testing values are unchanged: Sword 6/12/18; Shield 6 Guard/8 Ward/12 Ward;
Herb 1/2/3 capped by encounter budget; Action 2/3/5 capped at 6 AP. Prototype hero
100 HP, enemy 40 HP, herb budget 10. These do not finalize GDD balance/rewards.
Three repeated encounters are test content, not approved final run length.

## Verification on the integrated root

| Suite | Result |
| --- | --- |
| board_model_test | 1,151 checks, 0 failures |
| combat_test | 583 checks, 0 failures |
| shield_bash_test | 167 checks, 0 failures |
| debug_turn_test | 157 checks, 0 failures |
| bandage_test | 62 checks, 0 failures |
| equipment/equipment_test | 52 checks, 0 failures |
| run/run_test | 85 checks, 0 failures |
| ui/actor_view_test | 44 checks, 0 failures |
| presentation_smoke | 354 checks, 0 failures at 1280x720 and 1920x1080 |
| combat_ui_smoke | PASS: layout, input, swaps, actions, retaliation, victory/defeat |
| integration/parallel_streams_test | 166 checks, 0 failures at both sizes |
| Godot headless editor | exit 0, no project errors |
| Configured F5 main scene, headless launch | exit 0, no project errors |

Integration additionally checks real UI crafting/use/Bash, HP/resources/Undo,
loadout persistence, no automatic enemy action or encounter progression, no
cross-room Undo, Undo revoking a queued advance/final result, presentation queue
cancellation and all 49 board pointer targets in both sizes.

A native OpenGL Compatibility integration run passed 164 checks before the final
two queue-cancellation assertions were added; final headless integration passed
166. Captures `.godot/run_1280x720.png` and `.godot/run_1920x1080.png` were viewed.
Final code changed only standalone/run victory wording after that native capture;
no layout or render change. Manual player acceptance is still pending.

Early sandbox runs reported unavailable user log/certificate-store access; normal
approved reruns used separate logs and passed without these errors. Logs live in
ignored `build/parallel/*.log`; screenshots/cache remain ignored. This is not the
future analytics/balancing system.

Commands: `godot --headless --path . --editor --quit` and
`godot --headless --path . --script tests/<suite>.gd`.
Local executable:
`C:\Users\Hariiik\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
The integration harness also accepts `-- --capture` in a native-rendered run.

## Important files and ownership

- A: `scripts/equipment/{equipment_slots,equipment_definition,equipment_modifier,equipment_loadout}.gd`,
  their UIDs, `tests/equipment/equipment_test.gd`, `docs/EQUIPMENT_SYSTEM.md`.
- B: `scripts/run/{encounter_definition,run_state,run_result,run_controller}.gd`,
  their UIDs, `tests/run/run_test.gd`, `docs/RUN_ARCHITECTURE.md`.
- C: `scripts/ui/{actor_visual_definition,actor_view,combat_visual_queue}.gd`,
  their UIDs, `scenes/ui/{actor_view.tscn,combat_theme.tres}`,
  `tests/ui/actor_view_test.gd`, `docs/ART_PIPELINE.md`;
  existing `enemy_stage.gd` and `placeholder_portrait.gd` changed.
- Lead: `scripts/core/run_entry.gd` + UID, `scenes/run/run_entry.tscn`,
  `tests/integration/parallel_streams_test.gd`, `scripts/ui/combat_screen.gd`,
  `project.godot`, GDD/ARCHITECTURE/ROADMAP/COMBAT_UI_PROTOTYPE and this handoff.
- Board algorithms, combat controller/rules/state, RunInventory, TurnSnapshot,
  tile/enemy art, AGENTS.md and inventory/equipment UI behavior were preserved.

Worktrees remain for review at `build/parallel/agent-a`, `agent-b`, `agent-c`,
detached at `81e649f`. `build/` is already ignored; parent `.gdignore` prevents
Godot scanning these copies. Only owned source paths were copied into root;
generated import/cache churn was excluded. Do not treat worktrees as commits or
pushable branches. Do not delete the parent while registered worktrees remain;
cleanup must use the normal explicit Git workflow when authorized.

## Roadmap, limitations and next action

4A/4B remain implemented. Milestone 4 now includes equipment data contracts only;
gear effects/content are still future. Milestone 5 has a tested sequential slice,
not complete room/reward/procedural/save content. Milestone 6 is PLANNED / NOT
STARTED **after Milestone 5**, with full balancing gated on playable core RPG,
crafting, equipment interactions and basic run loop. Until then address only
critical balance problems and obvious exploits. No analytics were implemented.

Next: manually play F5 through all three encounters at both sizes. Verify HP and
stack carry-over, no healing/preparation between fights, resource resets, final
outcome, defeat and Undo before/after victory. Record usability defects.

Further approval is needed for final equipment slots/items/effects, final run
content/length/rewards, final art and authored clips/timing, and permanent AP
carry-over/balance decisions. The next art approval task remains the four tiles
individually. No new design decision blocks the delivered prototype.

Equipment snapshots intentionally retain read-only static Resource references;
they are not deep backups or disk saves. Any future in-combat equipment mutation
must explicitly extend Undo. Optional actor playback is infrastructure only;
clips are not yet used to gate existing combat resolution. Use one playback owner
per actor view. No save/resume, Hub, loot or procedural run system exists.
