extends Control
## Scene adapter only: the run owns controllers; the combat view requests actions.
const Run = preload("res://scripts/run/run_controller.gd")
const Loadout = preload("res://scripts/equipment/equipment_loadout.gd")
const State = preload("res://scripts/combat/combat_state.gd")
const Screen = preload("res://scripts/ui/combat_screen.gd")
const SCREEN_SCENE: PackedScene = preload("res://scenes/combat/combat_screen.tscn")

@export var run_seed: int = 1
@export var debug_match_logging: bool = true
var run: Run
var screen: Screen
var _transition_requested: bool = false


func _ready() -> void:
	run = Run.new()
	if not run.start_run(run_seed, [], null, Loadout.new()):
		push_error("Unable to start the prototype run.")
		return
	_show_encounter()


func _show_encounter() -> void:
	if is_instance_valid(screen):
		remove_child(screen)
		screen.queue_free()
	screen = SCREEN_SCENE.instantiate() as Screen
	screen.combat = run.combat
	screen.board_seed = run.state.encounter_seeds[run.state.encounter_index]
	screen.run_managed = true
	screen.debug_match_logging = debug_match_logging
	screen.encounter_caption = "ASHEN OATH  /  ENCOUNTER %d OF %d" % [run.state.encounter_index + 1, run.state.encounters.size()]
	screen.state_presented.connect(_sync_run_controls)
	screen.next_encounter_requested.connect(_request_next_encounter)
	add_child(screen)
	_sync_run_controls()


func _sync_run_controls() -> void:
	var button: Button = screen.end_turn_button
	if run.combat.state.phase == State.Phase.VICTORY:
		var can_advance: bool = run.can_advance_encounter()
		button.text = "Next Encounter" if can_advance else "Run Complete"
		button.tooltip_text = "Continue with current HP and inventory. Guard, Ward and AP reset." if can_advance else "Prototype run complete. F6/F5 to start a fresh run; DEBUG Undo remains available."
		button.disabled = screen.resolving or not can_advance or _transition_requested
	else:
		button.text = "End Turn"
		button.tooltip_text = "After your swap, finish the turn and let the enemy act."
		button.disabled = screen.resolving or run.combat.state.phase != State.Phase.POST_MATCH


func _request_next_encounter() -> void:
	if _transition_requested or screen.resolving or not run.can_advance_encounter():
		return
	_transition_requested = true
	_sync_run_controls()
	# Never dispose the combat screen from inside its own button callback.
	_advance_encounter.call_deferred()


func _advance_encounter() -> void:
	# Revalidate actual combat phase: an Undo must revoke a pending victory.
	if not screen.resolving and run.advance_encounter():
		_show_encounter()
	_transition_requested = false
	_sync_run_controls()
