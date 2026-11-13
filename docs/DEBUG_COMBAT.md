# Combat diagnostics and developer Undo

These tools change no match classification, T/L/cross rules, tile effects or
balance. They are available only when the controller's developer tools are
enabled (defaults to `OS.is_debug_build()`). Release play has no Undo button,
checkpoint creation or diagnostic output.

## Shield cross investigation

The reported shape was a vertical Shield Match-3 plus two horizontally connected
Shield tiles. No original board/RNG snapshot or turn log was supplied, so its
exact history cannot be identified retrospectively.

An isolated cross whose horizontal arm also forms Match-3 was reproduced at
zero-based `(column, row)` positions `(3,2), (2,3), (3,3), (4,3), (3,4)`:

- Raw detection: one horizontal length-3 run and one vertical length-3 run.
- Their shared center is merged: **one group, five unique cells**, longest straight
  run 3, rank 3. The output groups contain no duplicated cells.
- Existing Shield effect: **+6 Guard, zero Ward**, once. Five cells in the union
  do not currently classify the shape as Match-5.
- Nonmatching adjacent tiles do not join a group merely by touching it. Only
  intersecting detected runs are merged. Separate matched groups receive separate
  effects; later cascades receive effects again for newly fallen/refilled tiles.

Verified sources of a displayed total of 12 Guard include two separate Shield
Match-3 groups, two Shield Match-3 cascade steps, or six existing Guard plus one
new Match-3 effect. The isolated cross alone does not produce 12 in the regression
fixture. There is no independent Armor contribution or Ward-to-Guard conversion.

### Real seeded 12-Guard example

Set `board_seed = 9` on `scenes/combat/combat_screen.tscn` and run with F6. Swap
`(5,0)` with `(6,0)` (first row, sixth and seventh columns). Before End Turn:

| Cascade index | Match | Effect |
| --- | --- | --- |
| 0 | Vertical Shield Match-3 at `(5,0), (5,1), (5,2)` | Guard 0 -> 6 |
| 1 | New/refilled Shield Match-3 at the same coordinates | Guard 6 -> 12 |
| 2 | Sword Match-3 | Enemy HP 40 -> 34 |
| 3 | Herb Match-3 | Herbs 0 -> 1; budget 10 -> 9 |

Identical coordinates in different steps are different tile occupancies after
clear/refill, not duplicate processing of a shared center. This example proves a
cascade explanation is possible; it is not a reconstruction of the reported cross.

## Diagnostic output

`debug_match_logging` on the combat screen defaults to true. Disable it in the
Inspector to suppress output. Controller-only callers may set
`diagnostics_enabled = true`. Logs are prefixed `[COMBAT DEBUG]` in Godot Output
and the standard engine log; no repository log file is created by gameplay code.

Events identify:

- `swap_requested`: board contents, swap coordinates, seed/RNG state and initial
  resources. Tile ids are Sword=0, Shield=1, Herb=2, Action=3; empty is -1.
- `cascade`: zero-based cascade index, group ids (first row-major cell index),
  tile kind, raw run orientations/lengths/positions, longest run, rank, unique
  positions and counts. `shared_run_cells` describes raw overlap;
  `duplicate_group_cells` detects overlap left between output groups. Cleared and
  refilled row-major snapshots distinguish occupancy across steps.
- `effect`: the group and applied amount, with HP, Guard, Ward, AP, herbs and
  budget before/after. Each group is processed once per step in row-major order.
- `shield_bash`, `enemy_action`, `combat_ended`, `undo`: other state changes that
  could explain a displayed total or terminal cleanup.

Logging does not consume RNG, invoke actions or change the resulting board.
`MatchGroup.runs` is observational metadata; the resolver and effect rank remain
unchanged. Test-only manually constructed groups may have no raw-run metadata.

## Proposed deterministic shape policy — awaiting approval

Formalize the current behavior before adding shape bonuses:

1. Detect maximal horizontal/vertical runs of at least three within one step.
2. Merge runs only through shared cells, transitively; touching disjoint runs
   remain separate groups.
3. Remove each unique cell once. Apply one effect per merged group, using the
   longest straight run capped at Match-5+, not the union's size.
4. Process groups by first row-major cell, then cascades in increasing order.
   Later steps may reward the same coordinates after refill.

Under this proposal, a 3+3 T/L/cross with five unique cells remains one Match-3
effect. Classifying that union as Match-5, or adding a separate shape bonus, would
be a different policy requiring explicit approval. None is implemented here.

## DEBUG / Undo Last Turn

The developer-only button restores the state before the current/previous turn's
first successful action, including a Shield Bash used before the swap:

- Board contents, RNG seed and RNG state.
- Every scalar combat/ability state field: player/enemy HP and maxima, enemy armor,
  Guard, Ward, AP, herb budget, phase, turn, valid-swap count, enemy action count
  and announced intent.
- Run herb quantity, restoring the existing inventory object rather than replacing
  it. The current ability has no independent cooldown/use flag; its availability
  is derived from restored resources and phase.
- Controller step cursor. Pending resolution is cleared because a pre-turn
  checkpoint is always a stable `PLAYER_INPUT` boundary.

A successful pre-swap ability or valid swap lazily captures the checkpoint before
mutation. Further actions in that same turn never overwrite it. Invalid actions
create no checkpoint. After the enemy action it remains available until the next
turn's first successful action replaces it. Undo consumes the one checkpoint;
there is no history stack or redo. Replaying creates a new checkpoint normally.

Undo is allowed during stable player windows and after victory/defeat. It is
blocked during board/effect resolution and enemy action. The UI also blocks it
during visual preview/playback before the model phase changes, preventing stale
timer callbacks from modifying a restored state.

UI restoration clears tile selection/AP hover preview, redraws tiles and live
meters/counts, resets the displayed move counter and refreshes action availability
without emitting action signals or triggering combat effects. This is an in-memory
developer aid, not a save/load or player rewind mechanic. Future compound state
requires explicitly extending `turn_snapshot.gd`; new scalar state is captured
automatically with an assertion protecting against omitted compound values.

## Verification

```powershell
godot --headless --path . --script tests/debug_turn_test.gd
```

The harness covers isolated cross grouping, separate effects, a real seeded
12-Guard cascade, diagnostic noninterference, complete restoration, 20 seeded
replays including Shield Bash/refills/enemy actions, herb budget exhaustion,
one-checkpoint replacement, invalid actions, terminal outcomes, release gating
and UI restoration/input locks. Run the existing board, combat, Shield Bash,
combat UI and presentation suites for regression coverage.
