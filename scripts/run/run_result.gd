extends RefCounted
## Fresh in-memory terminal summary, not a save, reward, or unlock service.
enum Outcome { VICTORY, DEFEAT }

var outcome: Outcome = Outcome.VICTORY
var seed: int = 1
var encounters_completed: int = 0
var encounters_total: int = 0
var player_hp: int = 0
var player_max_hp: int = 100
var herbs: int = 0
var bandages: int = 0
