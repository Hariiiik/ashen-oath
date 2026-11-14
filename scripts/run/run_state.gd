extends RefCounted
## Run-owned data; HP checkpoints update only when an encounter is accepted.
## During combat, CombatState is the authoritative source of current HP.
const Inventory = preload("res://scripts/combat/run_inventory.gd")
const Encounter = preload("res://scripts/run/encounter_definition.gd")

var seed: int = 1
var encounter_index: int = 0
var encounters: Array[Encounter] = []
var encounter_seeds: Array[int] = []
var player_hp: int = 100
var player_max_hp: int = 100
var inventory: Inventory = Inventory.new()
# Optional independent model contract; no modifiers are evaluated by the run.
var equipment_loadout: RefCounted
