extends RefCounted
## Pure prototype calculations. No UI, animation, equipment or ability logic.
const Board = preload("res://scripts/board/board_model.gd")
const State = preload("res://scripts/combat/combat_state.gd")
const AP_CAP: int = 6
const SWORD: Array[int] = [6, 12, 18]
const SHIELD: Array[int] = [6, 8, 12]
const HERB: Array[int] = [1, 2, 3]
const ACTION: Array[int] = [2, 3, 5]


static func apply_match(state: State, group: Board.MatchGroup) -> Dictionary:
	var tier: int = clampi(group.rank, 3, 5) - 3
	var report: Dictionary = {"tile": group.tile, "rank": group.rank, "cells": group.cells.duplicate(), "amount": 0}
	match group.tile:
		Board.Tile.SWORD:
			var damage: int = SWORD[tier]
			if tier < 2:
				damage = maxi(0, damage - state.enemy_armor)
			report["amount"] = mini(state.enemy_hp, damage)
			report["critical"] = tier > 0
			report["ignores_armor"] = tier == 2
			state.enemy_hp = maxi(0, state.enemy_hp - damage)
		Board.Tile.SHIELD:
			report["amount"] = SHIELD[tier]
			if tier == 0:
				state.guard += SHIELD[tier]
			else:
				state.ward += SHIELD[tier]
		Board.Tile.HERB:
			var collected: int = mini(HERB[tier], state.herb_budget)
			state.herb_budget -= collected
			state.run_inventory.herbs += collected
			report["amount"] = collected
		Board.Tile.ACTION:
			var gained: int = mini(ACTION[tier], AP_CAP - state.ap)
			state.ap += gained
			report["amount"] = gained
	return report


static func enemy_attack(state: State) -> Dictionary:
	var remaining: int = state.enemy_intent
	var guard_used: int = mini(state.guard, remaining)
	remaining -= guard_used
	var ward_used: int = mini(state.ward, remaining)
	state.ward -= ward_used
	remaining -= ward_used
	var hp_lost: int = mini(state.player_hp, remaining)
	state.player_hp -= hp_lost
	state.guard = 0
	return {"damage": state.enemy_intent, "guard": guard_used, "ward": ward_used, "hp": hp_lost}
