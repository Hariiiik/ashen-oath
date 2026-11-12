# Ashen Oath — Repository Instructions for Codex

## Project
Godot 4, GDScript, Windows-first, 2D grimdark Match-3 roguelite. **Current state: playable Match-3 and minimal single-encounter combat prototype.** Inspect existing implementations before extending them; do not assume future RPG/run systems exist. Read `docs/SESSION_HANDOFF.md` for the latest session context and pending work.

## Read before editing
1. `docs/GAME_DESIGN.md`
2. `docs/ARCHITECTURE.md`
3. `docs/DEVELOPMENT_ROADMAP.md`
4. Relevant specialist briefing in `agents/` if the task fits.

## Working contract
- Follow the user's task exactly; do not implement adjacent future milestones.
- Make small incremental changes. Read relevant existing files before editing.
- Keep game logic independent from UI nodes/animation as much as practical.
- Use typed GDScript where it improves clarity; Godot 4 APIs only.
- No external add-ons/dependencies without approval.
- Never overwrite existing art, scenes or data without checking usage.
- Do not create hundreds of placeholder files.
- Do not introduce a Hub yet; only preserve an architecture extension point.
- Treat unresolved design choices in GDD as proposals, not permission to invent mechanics.
- When writing user-facing UI copy, use English.

## Task execution
1. State a focused implementation plan for work changing multiple systems.
2. Determine file ownership and avoid conflicting simultaneous edits.
3. Implement the smallest complete change with tests where feasible.
4. Run Godot headless/editor checks when available, otherwise report that testing was not possible.
5. Report changed files, behavior, tests, unresolved issues, and suggested next step.

## Specialist modes
Roles in `agents/*.md` are **reference briefings**. They are not automatically executable subagents. The lead may consult a role file to work in that mode; use actual Codex delegation only if supported and explicitly requested.

## Safety
- No commits, pushes, destructive Git operations, installations, network calls or API charges without user approval.
- Never store credentials in the repository.
