extends RefCounted
## Combat calculations and ability validation, independent from UI/animation.
const Board = preload("res://scripts/board/board_model.gd")
const State = preload("res://scripts/combat/combat_state.gd")
const AP_CAP: int = 6
const SHIELD_BASH_AP_COST: int = 3
# Standard recipe is a design reference only; no out-of-combat crafting API.
const BANDAGE_STANDARD_HERBS: int = 4
const BANDAGE_EMERGENCY_HERBS: int = 6
# Provisional prototype values, not final balance.
const BANDAGE_AP_COST: int = 2
const BANDAGE_HEAL: int = 12
const SWORD: Array[int] = [6, 12, 18]
const SHIELD: Array[int] = [6, 8, 12]
const HERB: Array[int] = [1, 2, 3]
const ACTION: Array[int] = [2, 3, 5]


static func can_emergency_craft_bandage(state: State) -> bool:
	return state.phase in [State.Phase.PLAYER_INPUT, State.Phase.POST_MATCH] and state.run_inventory.herbs >= BANDAGE_EMERGENCY_HERBS


static func emergency_craft_bandage(state: State) -> Dictionary:
	if not can_emergency_craft_bandage(state):
		return {"valid": false}
	state.run_inventory.herbs -= BANDAGE_EMERGENCY_HERBS
	state.run_inventory.bandages += 1
	return {"valid": true, "herbs_spent": BANDAGE_EMERGENCY_HERBS, "bandages_added": 1}


static func can_use_bandage(state: State) -> bool:
	return state.phase in [State.Phase.PLAYER_INPUT, State.Phase.POST_MATCH] and state.run_inventory.bandages > 0 and state.ap >= BANDAGE_AP_COST and state.player_hp < state.player_max_hp


static func use_bandage(state: State) -> Dictionary:
	if not can_use_bandage(state):
		return {"valid": false}
	var healed: int = mini(BANDAGE_HEAL, state.player_max_hp - state.player_hp)
	state.run_inventory.bandages -= 1
	state.ap -= BANDAGE_AP_COST
	state.player_hp += healed
	return {"valid": true, "healed": healed, "ap_spent": BANDAGE_AP_COST, "bandages_used": 1}


static func can_shield_bash(state: State) -> bool:
	return state.phase in [State.Phase.PLAYER_INPUT, State.Phase.POST_MATCH] and state.guard > 0 and state.ap >= SHIELD_BASH_AP_COST


static func shield_bash(state: State) -> Dictionary:
	if not can_shield_bash(state):
		return {"valid": false}
	var consumed: int = state.guard
	state.ap -= SHIELD_BASH_AP_COST
	state.guard = 0
	# Same physical mitigation as ordinary Sword damage; no armor penetration.
	var damage: int = maxi(0, consumed - state.enemy_armor)
	var hp_lost: int = mini(state.enemy_hp, damage)
	state.enemy_hp -= hp_lost
	return {"valid": true, "guard_consumed": consumed, "damage": damage, "hp_lost": hp_lost}


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
