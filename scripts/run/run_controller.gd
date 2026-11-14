extends RefCounted
## Explicit encounter orchestration. Existing CombatController remains unchanged.
const Combat = preload("res://scripts/combat/combat_controller.gd")
const CombatState = preload("res://scripts/combat/combat_state.gd")
const Inventory = preload("res://scripts/combat/run_inventory.gd")
const State = preload("res://scripts/run/run_state.gd")
const Encounter = preload("res://scripts/run/encounter_definition.gd")
const Result = preload("res://scripts/run/run_result.gd")

# A small fixed test sequence, not approved production run length/content.
const PROTOTYPE_ENCOUNTER_COUNT: int = 3

var state: State = State.new()
var combat: Combat


func start_run(seed_value: int = 1, encounters: Array[Encounter] = [], inventory: Inventory = null, loadout: RefCounted = null) -> bool:
	# Restarting uses a new run owner; never discard an active run implicitly.
	if combat != null:
		return false
	for encounter: Encounter in encounters:
		if encounter == null:
			return false
	state = State.new()
	state.seed = seed_value
	if inventory != null:
		state.inventory = inventory
	state.equipment_loadout = loadout
	state.encounters.assign(encounters)
	if state.encounters.is_empty():
		for index: int in range(PROTOTYPE_ENCOUNTER_COUNT):
			state.encounters.append(Encounter.new())
	# Precompute from an independent RNG: board play/refill/Undo never draws here.
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.seed = seed_value
	for encounter: Encounter in state.encounters:
		state.encounter_seeds.append(seed_rng.randi())
	_begin_encounter()
	return true


func can_advance_encounter() -> bool:
	# Read the actual live phase, including any developer Undo, on every request.
	return combat != null and combat.state.phase == CombatState.Phase.VICTORY and state.encounter_index + 1 < state.encounters.size()


func advance_encounter() -> bool:
	if not can_advance_encounter():
		return false
	state.player_hp = combat.state.player_hp
	state.player_max_hp = combat.state.player_max_hp
	# A retained UI/test reference must not rewind the shared inventory across rooms.
	combat.developer_tools_enabled = false
	state.encounter_index += 1
	_begin_encounter()
	return true


func get_current_hp() -> int:
	return combat.state.player_hp if combat != null else state.player_hp


func get_result() -> Result:
	# Derived instead of cached so Undo after victory/defeat immediately revokes it.
	if combat == null:
		return null
	var defeat: bool = combat.state.phase == CombatState.Phase.DEFEAT
	var completed: bool = combat.state.phase == CombatState.Phase.VICTORY and state.encounter_index == state.encounters.size() - 1
	if not defeat and not completed:
		return null
	var result := Result.new()
	result.outcome = Result.Outcome.DEFEAT if defeat else Result.Outcome.VICTORY
	result.seed = state.seed
	result.encounters_completed = state.encounter_index if defeat else state.encounters.size()
	result.encounters_total = state.encounters.size()
	result.player_hp = combat.state.player_hp
	result.player_max_hp = combat.state.player_max_hp
	result.herbs = state.inventory.herbs
	result.bandages = state.inventory.bandages
	return result


func _begin_encounter() -> void:
	combat = Combat.new(state.encounter_seeds[state.encounter_index], state.inventory)
	combat.state.player_max_hp = state.player_max_hp
	combat.state.player_hp = state.player_hp
	combat.state.guard = 0
	combat.state.ward = 0
	# Provisional implementation rule, not permanent approved AP carry-over design.
	combat.state.ap = 0
