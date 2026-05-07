class_name ContextualHelpService
extends RefCounted

const DEFAULT_CATALOG_PATH: String = "res://data/contextual_help_catalog.json"

const MODE_OFF: String = "off"
const MODE_COMPACT: String = "compact"
const MODE_EXPANDED: String = "expanded"
const LEVEL_NONE: String = "none"
const LEVEL_COMPACT: String = "compact"
const LEVEL_DETAIL: String = "detail"

const DEFAULT_COMPACT_DELAY_SECONDS: float = 0.45
const DEFAULT_DETAIL_DELAY_SECONDS: float = 3.5
const DEFAULT_COMPACT_MAX_WIDTH_PX: int = 360
const DEFAULT_DETAIL_MAX_WIDTH_PX: int = 460
const DEFAULT_MAX_VIEWPORT_HEIGHT_RATIO: float = 0.45

const VALID_MODES: PackedStringArray = [MODE_OFF, MODE_COMPACT, MODE_EXPANDED]

var _catalog_path: String = DEFAULT_CATALOG_PATH
var _catalog: Dictionary = {}
var _entries_by_id: Dictionary = {}
var _help_mode: String = MODE_COMPACT
var _global_help_active: bool = false
var _missing_id_count: int = 0
var _empty_text_count: int = 0
var _disabled_request_count: int = 0
var _registered_control_count: int = 0


func load_catalog(catalog_path: String = DEFAULT_CATALOG_PATH) -> Error:
	_catalog_path = catalog_path
	_catalog.clear()
	_entries_by_id.clear()
	if not FileAccess.file_exists(catalog_path):
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(catalog_path, FileAccess.READ)
	if file == null:
		return ERR_CANT_OPEN
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return ERR_PARSE_ERROR
	_catalog = Dictionary(parsed).duplicate(true)
	for entry_variant in Array(_catalog.get("entries", [])):
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		var help_id: String = String(entry.get("help_id", "")).strip_edges()
		if help_id.is_empty():
			continue
		_entries_by_id[help_id] = entry
	return OK


func set_help_mode(mode: String) -> void:
	_help_mode = normalize_help_mode(mode)
	if _help_mode == MODE_OFF:
		_global_help_active = false


func get_help_mode() -> String:
	return _help_mode


func set_global_help_active(active: bool) -> void:
	_global_help_active = active and _help_mode != MODE_OFF


func is_global_help_active() -> bool:
	return _global_help_active


func toggle_global_help_active() -> bool:
	set_global_help_active(not _global_help_active)
	return _global_help_active


func is_help_enabled() -> bool:
	return _help_mode != MODE_OFF


func get_catalog_snapshot() -> Dictionary:
	return _catalog.duplicate(true)


func get_entry(help_id: String) -> Dictionary:
	var normalized_id: String = help_id.strip_edges()
	if normalized_id.is_empty() or not _entries_by_id.has(normalized_id):
		_missing_id_count += 1
		return {}
	return Dictionary(_entries_by_id.get(normalized_id, {})).duplicate(true)


func get_help_payload(help_id: String, include_detail: bool = false) -> Dictionary:
	var entry: Dictionary = get_entry(help_id)
	if entry.is_empty():
		return {}
	var compact_lines: Array = Array(entry.get("compact_lines", []))
	var detail_lines: Array = Array(entry.get("detail_lines", []))
	if compact_lines.is_empty() or String(entry.get("title", "")).strip_edges().is_empty():
		_empty_text_count += 1
	return {
		"help_id": String(entry.get("help_id", "")),
		"screen_id": String(entry.get("screen_id", "")),
		"area_id": String(entry.get("area_id", "")),
		"title": String(entry.get("title", "")),
		"compact_lines": compact_lines.duplicate(true),
		"detail_lines": detail_lines.duplicate(true) if include_detail else [],
		"include_detail": include_detail,
		"status": String(entry.get("status", "")),
		"target_audience": String(entry.get("target_audience", "")),
	}


func request_help(help_id: String, hover_seconds: float = 0.0, pinned: bool = false) -> Dictionary:
	var level: String = resolve_help_level(hover_seconds, pinned)
	if level == LEVEL_NONE:
		_disabled_request_count += 1
		return {
			"level": LEVEL_NONE,
			"help_id": help_id,
			"disabled": _help_mode == MODE_OFF,
		}
	var payload: Dictionary = get_help_payload(help_id, level == LEVEL_DETAIL)
	payload["level"] = level
	payload["global_help_active"] = _global_help_active
	return payload


func resolve_help_level(hover_seconds: float, pinned: bool = false) -> String:
	if _help_mode == MODE_OFF:
		return LEVEL_NONE
	if pinned:
		return LEVEL_DETAIL
	if hover_seconds < DEFAULT_COMPACT_DELAY_SECONDS:
		return LEVEL_COMPACT if _global_help_active else LEVEL_NONE
	if _help_mode == MODE_EXPANDED and hover_seconds >= DEFAULT_DETAIL_DELAY_SECONDS:
		return LEVEL_DETAIL
	return LEVEL_COMPACT


func register_control(control: Control, help_id: String) -> void:
	if control == null:
		return
	var normalized_id: String = help_id.strip_edges()
	control.set_meta("help_id", normalized_id)
	control.tooltip_text = ""
	_registered_control_count += 1


func get_diagnostic_snapshot() -> Dictionary:
	return {
		"catalog_path": _catalog_path,
		"catalog_loaded": not _catalog.is_empty(),
		"entry_count": _entries_by_id.size(),
		"help_mode": _help_mode,
		"help_enabled": is_help_enabled(),
		"global_help_active": _global_help_active,
		"missing_id_count": _missing_id_count,
		"empty_text_count": _empty_text_count,
		"disabled_request_count": _disabled_request_count,
		"registered_control_count": _registered_control_count,
		"compact_delay_seconds": DEFAULT_COMPACT_DELAY_SECONDS,
		"detail_delay_seconds": DEFAULT_DETAIL_DELAY_SECONDS,
		"compact_max_width_px": DEFAULT_COMPACT_MAX_WIDTH_PX,
		"detail_max_width_px": DEFAULT_DETAIL_MAX_WIDTH_PX,
		"max_viewport_height_ratio": DEFAULT_MAX_VIEWPORT_HEIGHT_RATIO,
	}


static func normalize_help_mode(mode: String) -> String:
	var normalized_mode: String = mode.strip_edges().to_lower()
	if VALID_MODES.has(normalized_mode):
		return normalized_mode
	return MODE_COMPACT
