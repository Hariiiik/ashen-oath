extends Resource
## Inert extension descriptor. No combat system interprets these fields yet.
@export var effect_id: StringName = &""
@export var parameters: Dictionary = {}


func is_valid() -> bool:
	return not String(effect_id).strip_edges().is_empty()
