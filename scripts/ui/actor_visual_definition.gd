extends Resource
## Replaceable presentation data. No stats, combat events, or required asset sizes.

@export var texture: Texture2D
@export var sprite_frames: SpriteFrames
@export var idle_clip: StringName = &"idle"
## Optional presentation event -> authored SpriteFrames animation name.
@export var clips: Dictionary[StringName, StringName] = {}


func animation_for(clip: StringName) -> StringName:
	return clips.get(clip, clip)


func has_clip(clip: StringName) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(animation_for(clip)) and sprite_frames.get_frame_count(animation_for(clip)) > 0 and sprite_frames.get_animation_speed(animation_for(clip)) > 0.0
