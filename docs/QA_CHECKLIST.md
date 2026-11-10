# QA Checklist (Foundation)
- [ ] `project.godot` imports into installed Godot 4.
- [ ] Project launches placeholder screen without parse errors.
- [ ] No missing resources or dependencies reported.
- [ ] Generated `.godot/` cache is not committed.
- [ ] Git clean after initial commit.

## Later board tests
- [ ] Starting board has no accidental matches.
- [ ] Starting board has at least one legal move.
- [ ] Invalid swaps revert without advancing turn.
- [ ] Horizontal/vertical and cascading matches resolve deterministically.
- [ ] Player cannot interact during animations.
