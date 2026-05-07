class_name ComicBubbleVisualContract
extends RefCounted

const CATALOG_PATH: String = "res://data/comic_bubble_asset_catalog.json"
const DISPLAY_TYPE: String = "comic_bubble"
const DEFAULT_MAX_CANVAS_SIZE: Vector2i = Vector2i(220, 132)
const DEFAULT_MIN_CANVAS_SIZE: Vector2i = Vector2i(96, 56)
const DEFAULT_MAX_TEXT_LINES: int = 2
const DEFAULT_MAX_CHARS_PER_LINE: int = 26
const DEFAULT_Z_INDEX: int = 76
const DEFAULT_DURATION_SECONDS: float = 1.8
const MAX_DURATION_SECONDS: float = 3.0


static func load_catalog() -> Dictionary:
	var diagnostics: PackedStringArray = PackedStringArray()
	if not FileAccess.file_exists(CATALOG_PATH):
		return {"catalog": {}, "diagnostics": PackedStringArray(["missing_comic_bubble_catalog:%s" % CATALOG_PATH])}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {"catalog": {}, "diagnostics": PackedStringArray(["cannot_open_comic_bubble_catalog:%s" % CATALOG_PATH])}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"catalog": {}, "diagnostics": PackedStringArray(["invalid_comic_bubble_catalog_json:%s" % CATALOG_PATH])}
	var catalog: Dictionary = Dictionary(parsed).duplicate(true)
	var ids: Dictionary = {}
	var variants: Dictionary = {}
	for entry_variant in Array(catalog.get("bubbles", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			diagnostics.append("bubble_entry_not_dictionary")
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		for issue in validate_entry(entry, Dictionary(catalog.get("rules", {}))):
			diagnostics.append(issue)
		var bubble_id: String = String(entry.get("id", "")).strip_edges()
		if ids.has(bubble_id):
			diagnostics.append("duplicate_bubble_id:%s" % bubble_id)
		ids[bubble_id] = true
		var variant: int = int(entry.get("variant", 0))
		if variants.has(variant):
			diagnostics.append("duplicate_bubble_variant:%d" % variant)
		variants[variant] = true
	return {"catalog": catalog, "diagnostics": diagnostics}


static func get_contract_snapshot() -> Dictionary:
	var loaded: Dictionary = load_catalog()
	var catalog: Dictionary = Dictionary(loaded.get("catalog", {}))
	var rules: Dictionary = Dictionary(catalog.get("rules", {}))
	return {
		"catalog_path": CATALOG_PATH,
		"runtime_contract": String(rules.get("runtime_contract", "")),
		"max_canvas_size": _coerce_vector2i(rules.get("max_canvas_size", DEFAULT_MAX_CANVAS_SIZE), DEFAULT_MAX_CANVAS_SIZE),
		"min_canvas_size": _coerce_vector2i(rules.get("min_canvas_size", DEFAULT_MIN_CANVAS_SIZE), DEFAULT_MIN_CANVAS_SIZE),
		"text_lines_max": int(rules.get("text_lines_max", DEFAULT_MAX_TEXT_LINES)),
		"text_chars_per_line_max": int(rules.get("text_chars_per_line_max", DEFAULT_MAX_CHARS_PER_LINE)),
		"z_index": int(rules.get("z_index", DEFAULT_Z_INDEX)),
		"max_active_bubbles_total": int(rules.get("max_active_bubbles_total", 4)),
		"max_active_bubbles_per_unit": int(rules.get("max_active_bubbles_per_unit", 1)),
		"preview_runtime_bubble": bool(rules.get("preview_runtime_bubble", false)),
		"diagnostics": PackedStringArray(loaded.get("diagnostics", PackedStringArray())),
	}


static func get_runtime_bubble_ids() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in Array(Dictionary(load_catalog().get("catalog", {})).get("bubbles", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if not bool(entry.get("runtime_bubble", false)):
			continue
		var bubble_id: String = String(entry.get("id", "")).strip_edges()
		if not bubble_id.is_empty():
			result.append(bubble_id)
	return result


static func get_bubble_entry(bubble_id: String) -> Dictionary:
	var normalized_id: String = bubble_id.strip_edges()
	if normalized_id.is_empty():
		return {}
	for entry_variant in Array(Dictionary(load_catalog().get("catalog", {})).get("bubbles", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("id", "")).strip_edges() == normalized_id:
			return entry.duplicate(true)
	return {}


static func get_preview_entry() -> Dictionary:
	return Dictionary(Dictionary(load_catalog().get("catalog", {})).get("preview", {})).duplicate(true)


static func build_display_payload(
	bubble_id: String,
	text: String,
	anchor_position: Vector2,
	unit_id: String = "",
	overrides: Dictionary = {}
) -> Dictionary:
	var entry: Dictionary = get_bubble_entry(bubble_id)
	if entry.is_empty():
		return {
			"ok": false,
			"diagnostic": "missing_comic_bubble_id:%s" % bubble_id,
		}
	var rules: Dictionary = Dictionary(Dictionary(load_catalog().get("catalog", {})).get("rules", {}))
	var text_lines_max: int = min(int(entry.get("text_lines_max", DEFAULT_MAX_TEXT_LINES)), int(rules.get("text_lines_max", DEFAULT_MAX_TEXT_LINES)))
	var chars_per_line: int = min(int(entry.get("text_chars_per_line_max", DEFAULT_MAX_CHARS_PER_LINE)), int(rules.get("text_chars_per_line_max", DEFAULT_MAX_CHARS_PER_LINE)))
	var duration_seconds: float = clampf(float(overrides.get("duration_seconds", rules.get("default_duration_seconds", DEFAULT_DURATION_SECONDS))), 0.1, float(rules.get("max_duration_seconds", MAX_DURATION_SECONDS)))
	return {
		"ok": true,
		"display_type": DISPLAY_TYPE,
		"bubble_id": String(entry.get("id", "")),
		"path": String(entry.get("path", "")),
		"purpose": String(entry.get("purpose", "")),
		"tone": String(entry.get("tone", "")),
		"text": sanitize_text(text, text_lines_max, chars_per_line),
		"anchor": String(entry.get("anchor", "")),
		"anchor_position": anchor_position,
		"tail_offset": _coerce_vector2(entry.get("tail_offset", Vector2.ZERO), Vector2.ZERO),
		"text_inset": _coerce_inset(entry.get("text_inset", {})),
		"max_size": _coerce_vector2i(entry.get("max_size", DEFAULT_MAX_CANVAS_SIZE), DEFAULT_MAX_CANVAS_SIZE),
		"z_index": int(entry.get("z_index", rules.get("z_index", DEFAULT_Z_INDEX))),
		"duration_seconds": duration_seconds,
		"unit_id": unit_id.strip_edges(),
		"visual_only": true,
	}


static func sanitize_text(text: String, max_lines: int = DEFAULT_MAX_TEXT_LINES, max_chars_per_line: int = DEFAULT_MAX_CHARS_PER_LINE) -> String:
	var line_count: int = maxi(max_lines, 1)
	var char_count: int = maxi(max_chars_per_line, 4)
	var words: PackedStringArray = text.replace("\r", " ").replace("\n", " ").split(" ", false)
	var lines: PackedStringArray = PackedStringArray()
	var current_line: String = ""
	var truncated: bool = false
	for word_variant in words:
		var word: String = String(word_variant).strip_edges()
		if word.is_empty():
			continue
		if word.length() > char_count:
			word = word.left(char_count)
			truncated = true
		if current_line.is_empty():
			current_line = word
			continue
		if current_line.length() + 1 + word.length() <= char_count:
			current_line = "%s %s" % [current_line, word]
			continue
		lines.append(current_line)
		current_line = word
		if lines.size() >= line_count:
			truncated = true
			break
	if lines.size() < line_count and not current_line.is_empty():
		lines.append(current_line)
	if lines.size() > line_count:
		lines = PackedStringArray(Array(lines).slice(0, line_count))
		truncated = true
	if truncated and not lines.is_empty():
		var last_index: int = lines.size() - 1
		var suffix: String = "..."
		var base: String = String(lines[last_index])
		lines[last_index] = base.left(maxi(char_count - suffix.length(), 1)) + suffix
	return "\n".join(lines)


static func validate_entry(entry: Dictionary, rules: Dictionary = {}) -> PackedStringArray:
	var issues: PackedStringArray = PackedStringArray()
	var bubble_id: String = String(entry.get("id", "")).strip_edges()
	var path: String = String(entry.get("path", "")).strip_edges()
	var max_catalog_size: Vector2i = _coerce_vector2i(rules.get("max_canvas_size", DEFAULT_MAX_CANVAS_SIZE), DEFAULT_MAX_CANVAS_SIZE)
	var min_catalog_size: Vector2i = _coerce_vector2i(rules.get("min_canvas_size", DEFAULT_MIN_CANVAS_SIZE), DEFAULT_MIN_CANVAS_SIZE)
	var max_size: Vector2i = _coerce_vector2i(entry.get("max_size", Vector2i.ZERO), Vector2i.ZERO)
	var inset: Dictionary = _coerce_inset(entry.get("text_inset", {}))
	if bubble_id.is_empty():
		issues.append("missing_bubble_id")
	if not path.begins_with("res://Assets/Comic/"):
		issues.append("invalid_bubble_path:%s" % bubble_id)
	if path.get_extension().to_lower() != "png":
		issues.append("invalid_bubble_format:%s" % bubble_id)
	if not bool(entry.get("runtime_bubble", false)):
		issues.append("bubble_not_runtime:%s" % bubble_id)
	if int(entry.get("variant", 0)) < 1 or int(entry.get("variant", 0)) > 10:
		issues.append("invalid_bubble_variant:%s" % bubble_id)
	if max_size.x > max_catalog_size.x or max_size.y > max_catalog_size.y:
		issues.append("bubble_exceeds_max_canvas:%s" % bubble_id)
	if max_size.x < min_catalog_size.x or max_size.y < min_catalog_size.y:
		issues.append("bubble_below_min_canvas:%s" % bubble_id)
	if int(entry.get("text_lines_max", DEFAULT_MAX_TEXT_LINES)) > int(rules.get("text_lines_max", DEFAULT_MAX_TEXT_LINES)):
		issues.append("bubble_text_lines_exceed_contract:%s" % bubble_id)
	if int(entry.get("text_chars_per_line_max", DEFAULT_MAX_CHARS_PER_LINE)) > int(rules.get("text_chars_per_line_max", DEFAULT_MAX_CHARS_PER_LINE)):
		issues.append("bubble_text_chars_exceed_contract:%s" % bubble_id)
	if int(entry.get("z_index", DEFAULT_Z_INDEX)) < 0:
		issues.append("bubble_negative_z_index:%s" % bubble_id)
	var horizontal_inset: int = int(inset.get("left", 0)) + int(inset.get("right", 0))
	var vertical_inset: int = int(inset.get("top", 0)) + int(inset.get("bottom", 0))
	if max_size.x - horizontal_inset < 48 or max_size.y - vertical_inset < 24:
		issues.append("bubble_text_area_too_small:%s" % bubble_id)
	return issues


static func _coerce_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(roundi(value.x), roundi(value.y))
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2i(int(dict.get("x", fallback.x)), int(dict.get("y", fallback.y)))
	return fallback


static func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", fallback.x)), float(dict.get("y", fallback.y)))
	return fallback


static func _coerce_inset(value: Variant) -> Dictionary:
	var source: Dictionary = Dictionary(value) if typeof(value) == TYPE_DICTIONARY else {}
	return {
		"left": maxi(int(source.get("left", 0)), 0),
		"top": maxi(int(source.get("top", 0)), 0),
		"right": maxi(int(source.get("right", 0)), 0),
		"bottom": maxi(int(source.get("bottom", 0)), 0),
	}
