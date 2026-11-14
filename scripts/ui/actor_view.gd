extends Control
## Decorative, replaceable actor art. Completion never applies gameplay effects.
const Definition = preload("res://scripts/ui/actor_visual_definition.gd")
const Portrait = preload("res://scripts/ui/placeholder_portrait.gd")

signal clip_finished(clip: StringName, cancelled: bool)

@export var visual_definition: Definition:
	set(value):
		visual_definition = value
		if is_node_ready():
			_refresh_visual()
@export var enemy: bool = false:
	set(value):
		enemy = value
		if is_instance_valid(_fallback):
			_fallback.set("enemy", enemy)
			_fallback.queue_redraw()

var _fallback: Control
var _image: TextureRect
var _sprite: AnimatedSprite2D
var _playing: bool = false
var _current_clip: StringName
var _playback_id: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	_fallback = Portrait.new()
	_fallback.name = "Placeholder"
	_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fallback.set("enemy", enemy)
	add_child(_fallback)
	_image = TextureRect.new()
	_image.name = "Texture"
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_image)
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Animation"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.frame_changed.connect(_fit_sprite)
	resized.connect(_fit_sprite)
	_refresh_visual()


func _exit_tree() -> void:
	cancel_playback()


func _refresh_visual() -> void:
	cancel_playback()
	_sprite.stop()
	_sprite.sprite_frames = visual_definition.sprite_frames if visual_definition != null else null
	_image.texture = visual_definition.texture if visual_definition != null else null
	_show_resting_visual()


func _show_resting_visual() -> void:
	var has_idle: bool = visual_definition != null and visual_definition.has_clip(visual_definition.idle_clip)
	_sprite.visible = has_idle
	_image.visible = not has_idle and _image.texture != null
	_fallback.visible = not _sprite.visible and not _image.visible
	if has_idle:
		_sprite.play(visual_definition.animation_for(visual_definition.idle_clip))
		_fit_sprite()


func is_playing_clip() -> bool:
	return _playing


func play_clip(clip: StringName) -> bool:
	cancel_playback()
	_playback_id += 1
	_current_clip = clip
	_playing = true
	var available: bool = is_node_ready() and visual_definition != null and visual_definition.has_clip(clip)
	if not available:
		_finish_missing.call_deferred(_playback_id)
		return false
	var animation: StringName = visual_definition.animation_for(clip)
	# Looping clips are ambient presentation, never an unbounded queue wait.
	if visual_definition.sprite_frames.get_animation_loop(animation):
		_sprite.play(animation)
		_finish_missing.call_deferred(_playback_id)
	else:
		_sprite.stop()
		_sprite.play(animation)
	_sprite.visible = true
	_image.visible = false
	_fallback.visible = false
	_fit_sprite()
	return true


func _finish_missing(playback_id: int) -> void:
	if _playing and playback_id == _playback_id:
		_finish(false)


func _on_animation_finished() -> void:
	if _playing:
		_finish(false)


func skip_playback() -> void:
	if _playing:
		_finish(false)


func cancel_playback() -> void:
	if _playing:
		_finish(true)


func _finish(cancelled: bool) -> void:
	var completed: StringName = _current_clip
	_playing = false
	_playback_id += 1
	if is_instance_valid(_sprite):
		_sprite.stop()
		_show_resting_visual()
	clip_finished.emit(completed, cancelled)


func _fit_sprite() -> void:
	if not is_instance_valid(_sprite) or _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(_sprite.animation) or _sprite.sprite_frames.get_frame_count(_sprite.animation) == 0:
		return
	var frame_texture: Texture2D = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if frame_texture == null:
		return
	var dimensions: Vector2 = frame_texture.get_size()
	if dimensions.x <= 0 or dimensions.y <= 0:
		return
	var factor: float = minf(size.x / dimensions.x, size.y / dimensions.y)
	if factor >= 1.0:
		factor = floorf(factor)
	_sprite.scale = Vector2.ONE * factor
	_sprite.position = (size / 2.0).floor()
