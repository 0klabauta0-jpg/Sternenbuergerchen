class_name TerrainMarkerCatalog
extends RefCounted

const CONTEXT_EDITOR_ONLY: String = "editor_only"
const CONTEXT_MISSION_PLAYER: String = "mission_player"

const SYMBOL_CIRCLE: String = "circle"
const SYMBOL_SQUARE: String = "square"
const SYMBOL_CROSS: String = "cross"
const SYMBOL_DIAMOND: String = "diamond"
const SYMBOL_TRIANGLE: String = "triangle"
const SYMBOL_FLAG: String = "flag"
const SYMBOL_CHEVRON: String = "chevron"

const TYPE_CUSTOM: String = "custom"

const _TYPE_ORDER: PackedStringArray = [
	TYPE_CUSTOM,
	"spawn_alpha",
	"spawn_bravo",
	"objective_point",
	"rally_point",
	"danger_zone",
	"loot_cache",
	"recon_note",
	"move",
	"defend",
	"engage",
	"flank",
	"take",
]

const _TYPE_DEFINITIONS: Dictionary = {
	TYPE_CUSTOM: {
		"display_name": "Custom Marker",
		"default_name": "Custom Marker",
		"color": Color(0.86, 0.88, 0.92, 0.96),
		"symbol": SYMBOL_CIRCLE,
		"placement_context": CONTEXT_EDITOR_ONLY,
		"single_instance": false,
		"user_visible": false,
	},
	"spawn_alpha": {
		"display_name": "Spawn Alpha",
		"default_name": "Spawn Alpha",
		"color": Color(0.38, 0.78, 1.0, 0.98),
		"symbol": SYMBOL_DIAMOND,
		"placement_context": CONTEXT_EDITOR_ONLY,
		"single_instance": true,
	},
	"spawn_bravo": {
		"display_name": "Spawn Bravo",
		"default_name": "Spawn Bravo",
		"color": Color(1.0, 0.56, 0.42, 0.98),
		"symbol": SYMBOL_DIAMOND,
		"placement_context": CONTEXT_EDITOR_ONLY,
		"single_instance": true,
	},
	"objective_point": {
		"display_name": "Objective",
		"default_name": "Objective",
		"color": Color(1.0, 0.86, 0.24, 0.98),
		"symbol": SYMBOL_FLAG,
		"placement_context": CONTEXT_EDITOR_ONLY,
		"single_instance": true,
	},
	"rally_point": {
		"display_name": "Rally Point",
		"default_name": "Rally Point",
		"color": Color(0.48, 0.9, 1.0, 0.98),
		"symbol": SYMBOL_CIRCLE,
		"placement_context": CONTEXT_EDITOR_ONLY,
		"single_instance": false,
	},
	"danger_zone": {
		"display_name": "Danger Zone",
		"default_name": "Danger Zone",
		"color": Color(0.98, 0.35, 0.29, 0.98),
		"symbol": SYMBOL_TRIANGLE,
		"placement_context": CONTEXT_EDITOR_ONLY,
		"single_instance": false,
	},
	"loot_cache": {
		"display_name": "Loot Cache",
		"default_name": "Loot Cache",
		"color": Color(0.98, 0.82, 0.32, 0.98),
		"symbol": SYMBOL_SQUARE,
		"placement_context": CONTEXT_EDITOR_ONLY,
		"single_instance": false,
	},
	"recon_note": {
		"display_name": "Recon Note",
		"default_name": "Recon Note",
		"color": Color(0.86, 0.68, 1.0, 0.98),
		"symbol": SYMBOL_CROSS,
		"placement_context": CONTEXT_EDITOR_ONLY,
		"single_instance": false,
	},
	"move": {
		"display_name": "Move",
		"default_name": "Move",
		"color": Color(0.72, 0.9, 1.0, 0.95),
		"symbol": SYMBOL_CIRCLE,
		"placement_context": CONTEXT_MISSION_PLAYER,
		"single_instance": false,
	},
	"defend": {
		"display_name": "Defend",
		"default_name": "Defend",
		"color": Color(0.66, 0.94, 0.78, 0.95),
		"symbol": SYMBOL_SQUARE,
		"placement_context": CONTEXT_MISSION_PLAYER,
		"single_instance": false,
	},
	"engage": {
		"display_name": "Engage",
		"default_name": "Engage",
		"color": Color(1.0, 0.68, 0.58, 0.95),
		"symbol": SYMBOL_CROSS,
		"placement_context": CONTEXT_MISSION_PLAYER,
		"single_instance": false,
	},
	"flank": {
		"display_name": "Flank",
		"default_name": "Flank",
		"color": Color(0.95, 0.84, 0.48, 0.95),
		"symbol": SYMBOL_DIAMOND,
		"placement_context": CONTEXT_MISSION_PLAYER,
		"single_instance": false,
	},
	"take": {
		"display_name": "Take",
		"default_name": "Take",
		"color": Color(1.0, 0.95, 0.8, 0.95),
		"symbol": SYMBOL_FLAG,
		"placement_context": CONTEXT_MISSION_PLAYER,
		"single_instance": false,
	},
}


static func has_type(marker_type_id: String) -> bool:
	return _TYPE_DEFINITIONS.has(marker_type_id.strip_edges().to_lower())


static func get_type_definition(marker_type_id: String) -> Dictionary:
	var normalized_type_id: String = marker_type_id.strip_edges().to_lower()
	if not _TYPE_DEFINITIONS.has(normalized_type_id):
		normalized_type_id = TYPE_CUSTOM
	return Dictionary(_TYPE_DEFINITIONS.get(normalized_type_id, {})).duplicate(true)


static func get_display_name(marker_type_id: String) -> String:
	var definition: Dictionary = get_type_definition(marker_type_id)
	return String(definition.get("display_name", marker_type_id)).strip_edges()


static func get_default_name(marker_type_id: String, fallback_marker_id: String = "") -> String:
	var definition: Dictionary = get_type_definition(marker_type_id)
	var default_name: String = String(definition.get("default_name", "")).strip_edges()
	if not default_name.is_empty():
		return default_name
	if not fallback_marker_id.is_empty():
		return fallback_marker_id
	return get_display_name(marker_type_id)


static func get_symbol(marker_type_id: String) -> String:
	var definition: Dictionary = get_type_definition(marker_type_id)
	return String(definition.get("symbol", SYMBOL_CIRCLE)).strip_edges().to_lower()


static func get_context(marker_type_id: String) -> String:
	var definition: Dictionary = get_type_definition(marker_type_id)
	return String(definition.get("placement_context", CONTEXT_EDITOR_ONLY)).strip_edges().to_lower()


static func get_color(marker_type_id: String) -> Color:
	var definition: Dictionary = get_type_definition(marker_type_id)
	return normalize_color(definition.get("color", Color(0.9, 0.9, 0.9, 1.0)), Color(0.9, 0.9, 0.9, 1.0))


static func is_single_instance(marker_type_id: String) -> bool:
	var definition: Dictionary = get_type_definition(marker_type_id)
	return bool(definition.get("single_instance", false))


static func is_user_visible(marker_type_id: String) -> bool:
	var definition: Dictionary = get_type_definition(marker_type_id)
	return bool(definition.get("user_visible", true))


static func get_type_ids_for_context(placement_context: String, include_hidden: bool = false) -> PackedStringArray:
	var normalized_context: String = placement_context.strip_edges().to_lower()
	var result: PackedStringArray = []
	for marker_type_id in _TYPE_ORDER:
		var definition: Dictionary = get_type_definition(marker_type_id)
		if String(definition.get("placement_context", CONTEXT_EDITOR_ONLY)) != normalized_context:
			continue
		if not include_hidden and not bool(definition.get("user_visible", true)):
			continue
		result.append(marker_type_id)
	return result


static func build_marker_id(marker_type_id: String, existing_marker_ids: PackedStringArray = PackedStringArray()) -> String:
	var normalized_type_id: String = marker_type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		normalized_type_id = TYPE_CUSTOM
	if is_single_instance(normalized_type_id):
		return normalized_type_id
	var existing_lookup: Dictionary = {}
	for marker_id in existing_marker_ids:
		existing_lookup[String(marker_id).strip_edges()] = true
	var suffix: int = 1
	while true:
		var candidate: String = "%s_%02d" % [normalized_type_id, suffix]
		if not existing_lookup.has(candidate):
			return candidate
		suffix += 1
	return normalized_type_id


static func build_marker_record(marker_id: String, marker_type_id: String, world_position: Vector2, overrides: Dictionary = {}) -> Dictionary:
	var normalized_marker_id: String = marker_id.strip_edges()
	var normalized_type_id: String = marker_type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		normalized_type_id = normalized_marker_id.to_lower() if has_type(normalized_marker_id) else TYPE_CUSTOM
	if not has_type(normalized_type_id):
		normalized_type_id = TYPE_CUSTOM

	var default_color: Color = get_color(normalized_type_id)
	var marker_name: String = String(overrides.get("name", get_default_name(normalized_type_id, normalized_marker_id))).strip_edges()
	if marker_name.is_empty():
		marker_name = get_default_name(normalized_type_id, normalized_marker_id)

	return {
		"marker_id": normalized_marker_id,
		"marker_type_id": normalized_type_id,
		"name": marker_name,
		"placement_context": String(overrides.get("placement_context", get_context(normalized_type_id))).strip_edges().to_lower(),
		"symbol": String(overrides.get("symbol", get_symbol(normalized_type_id))).strip_edges().to_lower(),
		"color": normalize_color(overrides.get("color", default_color), default_color),
		"position": normalize_position(overrides.get("position", world_position)),
	}


static func normalize_color(value: Variant, fallback: Color = Color(0.9, 0.9, 0.9, 1.0)) -> Color:
	if value is Color:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		var color_dict: Dictionary = value
		return Color(
			clampf(float(color_dict.get("r", fallback.r)), 0.0, 1.0),
			clampf(float(color_dict.get("g", fallback.g)), 0.0, 1.0),
			clampf(float(color_dict.get("b", fallback.b)), 0.0, 1.0),
			clampf(float(color_dict.get("a", fallback.a)), 0.0, 1.0)
		)
	return fallback


static func serialize_color(color: Color) -> Dictionary:
	return {
		"r": snappedf(color.r, 0.001),
		"g": snappedf(color.g, 0.001),
		"b": snappedf(color.b, 0.001),
		"a": snappedf(color.a, 0.001),
	}


static func normalize_position(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		var vector2i_value := value as Vector2i
		return Vector2(vector2i_value.x, vector2i_value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		if value_dict.has("position"):
			return normalize_position(value_dict.get("position"))
		return Vector2(float(value_dict.get("x", 0.0)), float(value_dict.get("y", 0.0)))
	return Vector2.ZERO
