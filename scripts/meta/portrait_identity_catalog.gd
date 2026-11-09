class_name PortraitIdentityCatalog
extends RefCounted

const CATALOG_PATH: String = "res://data/portrait_identity_catalog.json"
const MINIMUM_START_ROSTER_CANDIDATES: int = 30
const CHARACTER_SHEET_TARGET_SIZE := Vector2(96.0, 120.0)
const ROSTER_THUMBNAIL_SIZE := Vector2(64.0, 64.0)
const COMPACT_THUMBNAIL_SIZE := Vector2(38.0, 38.0)

static var _default_catalog_cache: Dictionary = {}


static func clear_cache_for_tests() -> void:
	_default_catalog_cache.clear()


static func load_catalog(catalog_path: String = CATALOG_PATH) -> Dictionary:
	# The shipped catalog is immutable for a process. Custom fixture paths always
	# read fresh; callers cannot mutate the shared snapshot through returned data.
	if catalog_path == CATALOG_PATH and not _default_catalog_cache.is_empty():
		return _default_catalog_cache.duplicate(true)
	var catalog: Dictionary = _load_json(catalog_path)
	var result: Dictionary = {
		"schema_version": int(catalog.get("schema_version", 0)),
		"catalog_id": String(catalog.get("catalog_id", "")),
		"source_root": String(catalog.get("source_root", "")),
		"source_inventory": Dictionary(catalog.get("source_inventory", {})).duplicate(true),
		"ui_contract": Dictionary(catalog.get("ui_contract", {})).duplicate(true),
		"fallback_portrait_id": String(catalog.get("fallback_portrait_id", "")),
		"entries": [],
		"entries_by_id": {},
		"entries_by_legacy_path": {},
		"candidate_count": 0,
		"loadable_count": 0,
		"large_source_count": 0,
		"diagnostics": PackedStringArray(),
	}
	if catalog.is_empty():
		_append_diagnostic(result, "missing_or_invalid_portrait_catalog:%s" % catalog_path)
		return result

	var entries: Array = []
	var entries_by_id: Dictionary = {}
	var entries_by_legacy_path: Dictionary = {}
	var seen_paths: Dictionary = {}
	for entry_variant in Array(catalog.get("entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			_append_diagnostic(result, "portrait_entry_not_dictionary")
			continue
		var entry: Dictionary = _normalize_entry(Dictionary(entry_variant))
		var id: String = String(entry.get("id", ""))
		var path: String = String(entry.get("path", ""))
		if id.is_empty():
			_append_diagnostic(result, "portrait_entry_without_id:%s" % path)
			continue
		if entries_by_id.has(id):
			_append_diagnostic(result, "duplicate_portrait_id:%s" % id)
			continue
		if path.is_empty() or not path.begins_with("res://"):
			_append_diagnostic(result, "portrait_entry_without_res_path:%s" % id)
			continue
		if seen_paths.has(path):
			entry["duplicate_group"] = String(seen_paths.get(path, ""))
		seen_paths[path] = id
		if ResourceLoader.exists(path):
			entry["loadable"] = true
			result["loadable_count"] = int(result.get("loadable_count", 0)) + 1
		else:
			entry["loadable"] = false
			_append_diagnostic(result, "portrait_path_not_loadable:%s:%s" % [id, path])
		if bool(entry.get("candidate", false)):
			result["candidate_count"] = int(result.get("candidate_count", 0)) + 1
		if not Array(entry.get("diagnostics", [])).is_empty():
			result["large_source_count"] = int(result.get("large_source_count", 0)) + 1
		entries.append(entry)
		entries_by_id[id] = entry
		for legacy_path in PackedStringArray(entry.get("legacy_paths", PackedStringArray())):
			if entries_by_legacy_path.has(legacy_path):
				_append_diagnostic(result, "duplicate_portrait_legacy_path:%s" % legacy_path)
				continue
			entries_by_legacy_path[legacy_path] = entry
	entries.sort_custom(func(a, b): return String(Dictionary(a).get("id", "")) < String(Dictionary(b).get("id", "")))
	result["entries"] = entries
	result["entries_by_id"] = entries_by_id
	result["entries_by_legacy_path"] = entries_by_legacy_path
	if catalog_path == CATALOG_PATH:
		_default_catalog_cache = result.duplicate(true)
	return result


static func validate_catalog(catalog_path: String = CATALOG_PATH) -> Dictionary:
	var loaded: Dictionary = load_catalog(catalog_path)
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray(loaded.get("diagnostics", PackedStringArray()))
	if int(loaded.get("schema_version", 0)) != 1:
		errors.append("portrait_catalog_schema_invalid")
	if String(loaded.get("catalog_id", "")) != "portrait_identity_catalog_v1":
		errors.append("portrait_catalog_id_invalid")
	var entries: Array = Array(loaded.get("entries", []))
	if entries.size() < MINIMUM_START_ROSTER_CANDIDATES:
		errors.append("portrait_catalog_entry_count_below_minimum")
	if int(loaded.get("candidate_count", 0)) < MINIMUM_START_ROSTER_CANDIDATES:
		errors.append("portrait_catalog_candidate_count_below_minimum")
	if int(loaded.get("loadable_count", 0)) < MINIMUM_START_ROSTER_CANDIDATES:
		errors.append("portrait_catalog_loadable_count_below_minimum")
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var path: String = String(entry.get("path", ""))
		if path.contains("C:/") or path.contains("C:\\") or path.begins_with("file:///"):
			errors.append("portrait_catalog_absolute_path:%s" % String(entry.get("id", "")))
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"entry_count": entries.size(),
		"candidate_count": int(loaded.get("candidate_count", 0)),
		"loadable_count": int(loaded.get("loadable_count", 0)),
		"large_source_count": int(loaded.get("large_source_count", 0)),
	}


static func get_candidate_entries(preferred_tags: PackedStringArray = PackedStringArray(), catalog_path: String = CATALOG_PATH) -> Array:
	var loaded: Dictionary = load_catalog(catalog_path)
	var all_candidates: Array = []
	var tagged_candidates: Array = []
	for entry_variant in Array(loaded.get("entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		if not bool(entry.get("candidate", false)) or not bool(entry.get("loadable", false)):
			continue
		all_candidates.append(entry)
		if _entry_matches_tags(entry, preferred_tags):
			tagged_candidates.append(entry)
	if tagged_candidates.size() >= MINIMUM_START_ROSTER_CANDIDATES:
		return tagged_candidates
	return all_candidates


static func build_deterministic_assignment(seed: String, count: int, role_categories: PackedStringArray = PackedStringArray(), catalog_path: String = CATALOG_PATH) -> Array:
	var pool: Array = get_candidate_entries(PackedStringArray(), catalog_path)
	var result: Array = []
	if pool.is_empty() or count <= 0:
		return result
	var offset: int = _seed_to_int(seed) % pool.size()
	var step: int = _pick_assignment_step(pool.size())
	for index in range(count):
		var entry_index: int = (offset + (index * step)) % pool.size()
		var entry: Dictionary = Dictionary(pool[entry_index]).duplicate(true)
		entry["assignment_index"] = index
		entry["assignment_role_category"] = String(role_categories[index]) if index < role_categories.size() else ""
		result.append(entry)
	return result


## Authored fictional-art metadata only. Unknown/custom identity data is never
## classified through a name, appearance guess or the fallback portrait.
static func get_presentation_group(portrait_id: String = "", portrait_path: String = "", catalog_path: String = CATALOG_PATH) -> String:
	var catalog: Dictionary = load_catalog(catalog_path)
	var by_id: Dictionary = catalog.get("entries_by_id", {})
	if by_id.has(portrait_id):
		return String(by_id[portrait_id].presentation_group)
	var legacy: Dictionary = catalog.get("entries_by_legacy_path", {})
	if legacy.has(portrait_path):
		return String(legacy[portrait_path].presentation_group)
	for entry: Dictionary in catalog.get("entries", []):
		if not portrait_path.is_empty() and String(entry.path) == portrait_path:
			return String(entry.presentation_group)
	return "unspecified"


## Used only while creating a new synthetic identity. No RNG draws and no
## mutation of existing profiles. Preserve uniqueness while supply permits;
## exhaustion uses unspecified art, then explicit compatible reuse, never an
## opposite authored group. The returned diagnostic describes that boundary.
static func select_generated_entry(preferred: Dictionary, presentation_group: String, used_ids: Dictionary, catalog_path: String = CATALOG_PATH) -> Dictionary:
	var pool: Array = get_candidate_entries(PackedStringArray(), catalog_path)
	if pool.is_empty():
		return {}
	var required: String = presentation_group if presentation_group in ["male", "female"] else "unspecified"
	var preferred_id: String = String(preferred.get("id", ""))
	var offset: int = 0
	for index in pool.size():
		if String(pool[index].id) == preferred_id:
			offset = index
			if (required == "unspecified" or String(pool[index].presentation_group) == required) and not used_ids.has(preferred_id):
				return Dictionary(pool[index]).duplicate(true)
			break
	var fallback: Dictionary = {}
	var reusable: Dictionary = {}
	for step in pool.size():
		var entry: Dictionary = pool[(offset + step) % pool.size()]
		var group: String = String(entry.presentation_group)
		if required == "unspecified" or group == required:
			if not used_ids.has(entry.id):
				return entry.duplicate(true)
			if reusable.is_empty():
				reusable = entry
		elif group == "unspecified" and not used_ids.has(entry.id) and fallback.is_empty():
			fallback = entry
	var selected: Dictionary = fallback.duplicate(true) if not fallback.is_empty() else reusable.duplicate(true)
	if not selected.is_empty():
		selected["assignment_diagnostic"] = "compatible_pool_exhausted_unspecified" if not fallback.is_empty() else "compatible_pool_exhausted_reuse"
	return selected


static func resolve_path(portrait_id: String = "", portrait_path: String = "", catalog_path: String = CATALOG_PATH) -> String:
	# Resolution only reads the snapshot; avoid copying all 42 entries per face.
	var loaded: Dictionary = _default_catalog_cache if catalog_path == CATALOG_PATH and not _default_catalog_cache.is_empty() else load_catalog(catalog_path)
	var entries_by_id: Dictionary = Dictionary(loaded.get("entries_by_id", {}))
	var normalized_id: String = portrait_id.strip_edges()
	if not normalized_id.is_empty() and entries_by_id.has(normalized_id):
		return String(Dictionary(entries_by_id.get(normalized_id, {})).get("path", ""))
	var normalized_path: String = portrait_path.strip_edges()
	var entries_by_legacy_path: Dictionary = Dictionary(loaded.get("entries_by_legacy_path", {}))
	if entries_by_legacy_path.has(normalized_path):
		return String(Dictionary(entries_by_legacy_path.get(normalized_path, {})).get("path", ""))
	if normalized_path.begins_with("res://") and ResourceLoader.exists(normalized_path):
		return normalized_path
	var fallback_id: String = String(loaded.get("fallback_portrait_id", "")).strip_edges()
	if not fallback_id.is_empty() and entries_by_id.has(fallback_id):
		return String(Dictionary(entries_by_id.get(fallback_id, {})).get("path", ""))
	return ""


static func load_texture(portrait_id: String = "", portrait_path: String = "", catalog_path: String = CATALOG_PATH) -> Texture2D:
	var path: String = resolve_path(portrait_id, portrait_path, catalog_path)
	if path.is_empty():
		return null
	var resource: Resource = load(path)
	return resource as Texture2D


static func apply_texture_rect_contract(texture_rect: TextureRect, usage: String = "roster") -> void:
	if texture_rect == null:
		return
	var target_size: Vector2 = get_target_size(usage)
	texture_rect.custom_minimum_size = target_size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.set_meta("portrait_target_size", target_size)
	texture_rect.set_meta("portrait_usage", usage)


static func get_target_size(usage: String = "roster") -> Vector2:
	match usage:
		"character_sheet":
			return CHARACTER_SHEET_TARGET_SIZE
		"compact":
			return COMPACT_THUMBNAIL_SIZE
		_:
			return ROSTER_THUMBNAIL_SIZE


static func _normalize_entry(source_entry: Dictionary) -> Dictionary:
	var entry: Dictionary = source_entry.duplicate(true)
	entry["id"] = String(entry.get("id", "")).strip_edges()
	entry["path"] = String(entry.get("path", "")).strip_edges()
	entry["file_name"] = String(entry.get("file_name", "")).strip_edges()
	entry["width"] = int(entry.get("width", 0))
	entry["height"] = int(entry.get("height", 0))
	entry["bytes"] = int(entry.get("bytes", 0))
	entry["candidate"] = bool(entry.get("candidate", true))
	var presentation: String = String(entry.get("presentation_group", "unspecified"))
	entry["presentation_group"] = presentation if presentation in ["male", "female", "unspecified"] else "unspecified"
	entry["duplicate_group"] = String(entry.get("duplicate_group", "")).strip_edges()
	entry["tags"] = _coerce_string_array(entry.get("tags", []))
	var legacy_paths: PackedStringArray = PackedStringArray()
	for legacy_path_variant in Array(entry.get("legacy_paths", [])):
		var legacy_path: String = String(legacy_path_variant).strip_edges()
		if legacy_path.begins_with("res://") and not legacy_paths.has(legacy_path):
			legacy_paths.append(legacy_path)
	entry["legacy_paths"] = legacy_paths
	entry["diagnostics"] = Array(entry.get("diagnostics", [])).duplicate(true)
	return entry


static func _entry_matches_tags(entry: Dictionary, preferred_tags: PackedStringArray) -> bool:
	if preferred_tags.is_empty():
		return false
	var tags: PackedStringArray = PackedStringArray(entry.get("tags", PackedStringArray()))
	for tag in preferred_tags:
		if tags.has(String(tag)):
			return true
	return false


static func _coerce_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry in Array(value):
		var text: String = String(entry).strip_edges().to_lower()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


static func _pick_assignment_step(pool_size: int) -> int:
	if pool_size <= 2:
		return 1
	var step: int = 7
	while _gcd(step, pool_size) != 1:
		step += 2
	return step


static func _gcd(a: int, b: int) -> int:
	var left: int = absi(a)
	var right: int = absi(b)
	while right != 0:
		var temp: int = right
		right = left % right
		left = temp
	return maxi(left, 1)


static func _seed_to_int(seed_text: String) -> int:
	var value: int = 2166136261
	for index in range(seed_text.length()):
		value = int((value ^ seed_text.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(value, 1)


static func _append_diagnostic(result: Dictionary, message: String) -> void:
	var diagnostics: PackedStringArray = PackedStringArray(result.get("diagnostics", PackedStringArray()))
	diagnostics.append(message)
	result["diagnostics"] = diagnostics


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)
