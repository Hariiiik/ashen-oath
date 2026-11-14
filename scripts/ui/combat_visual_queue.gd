extends Node
## Optional sequential presentation only. The caller owns all combat resolution.
const ActorView = preload("res://scripts/ui/actor_view.gd")

signal queue_finished(cancelled: bool)
signal clip_completed(clip: StringName, cancelled: bool)

var _pending: Array[Dictionary] = []
var _active: ActorView
var _active_clip: StringName
var _running: bool = false


func is_playing() -> bool:
	return _running


func enqueue(view: ActorView, clip: StringName) -> void:
	_pending.append({"view": weakref(view), "clip": clip})
	if not _running:
		_running = true
		_pump.call_deferred()


func _pump() -> void:
	if not _running or is_instance_valid(_active):
		return
	while not _pending.is_empty():
		var entry: Dictionary = _pending.pop_front()
		var view: ActorView = entry.view.get_ref() as ActorView
		if not is_instance_valid(view) or not view.is_inside_tree():
			clip_completed.emit(entry.clip, true)
			continue
		view.cancel_playback()
		_active = view
		_active_clip = entry.clip
		view.clip_finished.connect(_on_clip_finished)
		view.tree_exiting.connect(_on_view_exiting)
		view.play_clip(_active_clip)
		return
	_running = false
	queue_finished.emit(false)


func _disconnect_active() -> void:
	if is_instance_valid(_active):
		if _active.clip_finished.is_connected(_on_clip_finished):
			_active.clip_finished.disconnect(_on_clip_finished)
		if _active.tree_exiting.is_connected(_on_view_exiting):
			_active.tree_exiting.disconnect(_on_view_exiting)
	_active = null


func _on_clip_finished(clip: StringName, cancelled: bool) -> void:
	_disconnect_active()
	clip_completed.emit(clip, cancelled)
	_pump.call_deferred()


func _on_view_exiting() -> void:
	var clip: StringName = _active_clip
	_disconnect_active()
	clip_completed.emit(clip, true)
	_pump.call_deferred()


func skip_current() -> void:
	if is_instance_valid(_active):
		_active.skip_playback()


func cancel() -> void:
	var was_running: bool = _running
	var previous: ActorView = _active
	_disconnect_active()
	_pending.clear()
	_running = false
	if is_instance_valid(previous):
		previous.cancel_playback()
	if was_running:
		queue_finished.emit(true)


func _exit_tree() -> void:
	cancel()
