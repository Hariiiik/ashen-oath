extends RefCounted

const Inventory = preload("res://scripts/combat/run_inventory.gd")
enum Phase { PLAYER_INPUT, RESOLVING_BOARD, RESOLVING_EFFECTS, ENEMY_ACTION, VICTORY, DEFEAT }

# Prototype defaults, not approved final balance.
var player_max_hp: int = 100
var player_hp: int = 100
var enemy_max_hp: int = 40
var enemy_hp: int = 40
var enemy_armor: int = 0
var guard: int = 0
var ward: int = 0
var ap: int = 0
var herb_budget: int = 10
var run_inventory: Inventory
var phase: Phase = Phase.PLAYER_INPUT
var turn: int = 1
var valid_swaps: int = 0
var enemy_actions: int = 0
var enemy_intent: int = 5


func _init(inventory: Inventory = null) -> void:
	run_inventory = inventory if inventory != null else Inventory.new()


func is_finished() -> bool:
	return phase == Phase.VICTORY or phase == Phase.DEFEAT
