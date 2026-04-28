class_name MovementLayer
extends RefCounted

const MOVEMENT_LAYER_GROUND: String = "ground"
const MOVEMENT_LAYER_AIR: String = "air"
const DEFAULT_ALTITUDE_BAND: int = 0
const MAX_ALTITUDE_BAND: int = 8
const ALLOWED_MOVEMENT_LAYERS: PackedStringArray = [
	MOVEMENT_LAYER_GROUND,
	MOVEMENT_LAYER_AIR,
]


static func normalize_layer(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	if ALLOWED_MOVEMENT_LAYERS.has(normalized_value):
		return normalized_value
	return MOVEMENT_LAYER_GROUND


static func is_valid_layer(value: String) -> bool:
	return ALLOWED_MOVEMENT_LAYERS.has(value.strip_edges().to_lower())


static func normalize_altitude_band(value: Variant) -> int:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return DEFAULT_ALTITUDE_BAND
	return clampi(int(value), DEFAULT_ALTITUDE_BAND, MAX_ALTITUDE_BAND)


static func is_air_layer(value: String) -> bool:
	return normalize_layer(value) == MOVEMENT_LAYER_AIR
