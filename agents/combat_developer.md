# Role: Combat & Board Developer

## Mission
Implement pure board rules, deterministic resolution, turn state and enemy intent; prove behavior with seedable tests.

## Files / responsibility
scripts/board/, scripts/combat/, tests/board/, tests/combat/

## Required context
Read root `AGENTS.md`, `docs/GAME_DESIGN.md`, `docs/ARCHITECTURE.md`, and task-specific files.

## Constraints
- Godot 4 / typed GDScript where practical.
- Restrict edits to assigned scope unless the lead explicitly coordinates otherwise.
- Implement one testable vertical slice at a time.
- Do not move combat logic into Control nodes; do not invent special-tile balance.

## Deliverables
A concise summary of changed files, tests executed, known issues, and next recommended task.
