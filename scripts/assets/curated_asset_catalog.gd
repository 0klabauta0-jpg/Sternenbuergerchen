class_name CuratedAssetCatalog
extends RefCounted

const CATALOG_PATH: String = "res://data/curated_asset_catalog.json"


static func load_catalog(catalog_path: String = CATALOG_PATH) -> Dictionary:
	var result: Dictionary = {
		"entries": {},
		"diagnostics": PackedStringArray(),
	}
	var central_catalog: Dictionary = _load_json(catalog_path)
	if central_catalog.is_empty():
		_append_diagnostic(result, "missing_or_invalid_curated_asset_catalog:%s" % catalog_path)
		return result
	for source_config_variant in Array(central_catalog.get("source_catalogs", [])):
		_merge_source_catalog(result, Dictionary(source_config_variant))
	for entry_variant in Array(central_catalog.get("entries", [])):
		_add_entry(result, Dictionary(entry_variant), "central_entries", "")
	return result


static func resolve_asset(asset_id: String, catalog_path: String = CATALOG_PATH) -> Dictionary:
	var normalized_id: String = asset_id.strip_edges()
	var loaded: Dictionary = load_catalog(catalog_path)
	var entries: Dictionary = Dictionary(loaded.get("entries", {}))
	if not entries.has(normalized_id):
		return {
			"ok": false,
			"id": normalized_id,
			"path": "",
			"diagnostic": "missing_catalog_asset_id:%s" % normalized_id,
		}
	var entry: Dictionary = Dictionary(entries.get(normalized_id, {}))
	var path: String = String(entry.get("path", "")).strip_edges()
	if String(entry.get("load_mode", "resource")) == "resource" and not ResourceLoader.exists(path):
		return {
			"ok": false,
			"id": normalized_id,
			"path": path,
			"entry": entry,
			"diagnostic": "missing_catalog_asset_path:%s:%s" % [normalized_id, path],
		}
	return {
		"ok": true,
		"id": normalized_id,
		"path": path,
		"entry": entry,
		"diagnostic": "",
	}


static func get_asset_path(asset_id: String, catalog_path: String = CATALOG_PATH) -> String:
	var resolved: Dictionary = resolve_asset(asset_id, catalog_path)
	if not bool(resolved.get("ok", false)):
		return ""
	return String(resolved.get("path", ""))


static func get_entry(asset_id: String, catalog_path: String = CATALOG_PATH) -> Dictionary:
	var resolved: Dictionary = resolve_asset(asset_id, catalog_path)
	if not bool(resolved.get("ok", false)):
		return {}
	return Dictionary(resolved.get("entry", {}))


static func get_entries_by_category(category: String, catalog_path: String = CATALOG_PATH) -> Array:
	var result: Array = []
	var requested_category: String = category.strip_edges()
	var loaded: Dictionary = load_catalog(catalog_path)
	for entry_variant in Dictionary(loaded.get("entries", {})).values():
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("category", "")) == requested_category:
			result.append(entry)
	return result


static func get_diagnostics(catalog_path: String = CATALOG_PATH) -> PackedStringArray:
	var loaded: Dictionary = load_catalog(catalog_path)
	return PackedStringArray(loaded.get("diagnostics", PackedStringArray()))


static func _merge_source_catalog(result: Dictionary, source_config: Dictionary) -> void:
	var source_path: String = String(source_config.get("path", "")).strip_edges()
	if source_path.is_empty():
		_append_diagnostic(result, "source_catalog_without_path")
		return
	var source_catalog: Dictionary = _load_json(source_path)
	if source_catalog.is_empty():
		_append_diagnostic(result, "missing_or_invalid_source_catalog:%s" % source_path)
		return
	for collection_variant in Array(source_config.get("collections", [])):
		var collection_name: String = String(collection_variant).strip_edges()
		if collection_name.is_empty():
			continue
		if not source_catalog.has(collection_name):
			_append_diagnostic(result, "missing_source_collection:%s:%s" % [source_path, collection_name])
			continue
		for source_entry_variant in Array(source_catalog.get(collection_name, [])):
			var source_entry: Dictionary = Dictionary(source_entry_variant)
			var normalized_entry: Dictionary = _normalize_source_entry(source_entry, source_config, source_catalog, collection_name)
			_add_entry(result, normalized_entry, source_path, collection_name)


static func _normalize_source_entry(source_entry: Dictionary, source_config: Dictionary, source_catalog: Dictionary, collection_name: String) -> Dictionary:
	var entry: Dictionary = source_entry.duplicate(true)
	var source_id: String = String(entry.get("source_id", "")).strip_edges()
	var source_info: Dictionary = Dictionary(Dictionary(source_catalog.get("sources", {})).get(source_id, {}))
	var source_path: String = String(source_config.get("path", "")).strip_edges()
	entry["category"] = _central_category(entry, source_config, collection_name)
	entry["original_category"] = String(source_entry.get("category", ""))
	entry["source_catalog"] = source_path
	entry["source_collection"] = collection_name
	entry["target_system"] = String(entry.get("target_system", entry.get("target_screen", source_config.get("target_system", ""))))
	entry["license"] = String(entry.get("license", source_info.get("license", "")))
	entry["load_mode"] = String(entry.get("load_mode", "resource"))
	return entry


static func _central_category(entry: Dictionary, source_config: Dictionary, collection_name: String) -> String:
	var strategy: String = String(source_config.get("category_strategy", "")).strip_edges()
	var id: String = String(entry.get("id", "")).strip_edges()
	var source_category: String = String(entry.get("category", "")).strip_edges()
	match strategy:
		"ui_input_cursor":
			if id.begins_with("prompt_") or source_category == "command_prompt":
				return "input_prompt"
			if id.begins_with("cursor_") or source_category == "cursor" or source_category == "editor_tool":
				return "cursor"
			return "ui"
		"rank_particle":
			return "rank_badge" if collection_name == "badges" else "particle"
		"setpiece":
			return "setpiece"
		_:
			return source_category


static func _add_entry(result: Dictionary, entry: Dictionary, source_path: String, collection_name: String) -> void:
	var id: String = String(entry.get("id", "")).strip_edges()
	var path: String = String(entry.get("path", "")).strip_edges()
	var category: String = String(entry.get("category", "")).strip_edges()
	if id.is_empty():
		_append_diagnostic(result, "catalog_entry_without_id:%s:%s" % [source_path, collection_name])
		return
	if path.is_empty():
		_append_diagnostic(result, "catalog_entry_without_path:%s" % id)
		return
	if category.is_empty():
		_append_diagnostic(result, "catalog_entry_without_category:%s" % id)
		return
	var entries: Dictionary = Dictionary(result.get("entries", {}))
	if entries.has(id):
		_append_diagnostic(result, "duplicate_catalog_asset_id:%s" % id)
		return
	entry["id"] = id
	entry["path"] = path
	entry["category"] = category
	if not entry.has("load_mode"):
		entry["load_mode"] = "resource"
	entries[id] = entry
	result["entries"] = entries


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
