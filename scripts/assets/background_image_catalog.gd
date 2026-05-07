class_name BackgroundImageCatalog
extends RefCounted

const CATALOG_PATH: String = "res://data/background_image_catalog.json"


static func load_catalog(catalog_path: String = CATALOG_PATH) -> Dictionary:
	var parsed: Dictionary = _load_json(catalog_path)
	var result: Dictionary = {
		"schema_version": int(parsed.get("schema_version", 0)),
		"catalog_id": String(parsed.get("catalog_id", "")),
		"runtime_contract": Dictionary(parsed.get("runtime_contract", {})).duplicate(true),
		"backgrounds": {},
		"diagnostics": PackedStringArray(),
	}
	if parsed.is_empty():
		_append_diagnostic(result, "missing_or_invalid_catalog:%s" % catalog_path)
		return result
	for entry_variant in Array(parsed.get("backgrounds", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			_append_diagnostic(result, "background_entry_not_dictionary")
			continue
		_add_entry(result, Dictionary(entry_variant))
	return result


static func get_entry(background_id: String, catalog_path: String = CATALOG_PATH) -> Dictionary:
	var loaded: Dictionary = load_catalog(catalog_path)
	var backgrounds: Dictionary = Dictionary(loaded.get("backgrounds", {}))
	var normalized_id: String = background_id.strip_edges()
	if not backgrounds.has(normalized_id):
		return {}
	return Dictionary(backgrounds.get(normalized_id, {})).duplicate(true)


static func get_path(background_id: String, catalog_path: String = CATALOG_PATH) -> String:
	var entry: Dictionary = get_entry(background_id, catalog_path)
	return String(entry.get("res_path", "")).strip_edges()


static func load_texture(background_id: String, catalog_path: String = CATALOG_PATH) -> Texture2D:
	var path: String = get_path(background_id, catalog_path)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


static func apply_to_texture_rect(texture_rect: TextureRect, background_id: String, catalog_path: String = CATALOG_PATH) -> Dictionary:
	if texture_rect == null:
		return {"ok": false, "reason": "missing_texture_rect", "background_id": background_id}
	var entry: Dictionary = get_entry(background_id, catalog_path)
	if entry.is_empty():
		return {"ok": false, "reason": "missing_background_id", "background_id": background_id}
	var texture := load_texture(background_id, catalog_path)
	if texture == null:
		return {"ok": false, "reason": "missing_texture_resource", "background_id": background_id, "path": String(entry.get("res_path", ""))}
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return {"ok": true, "background_id": background_id, "path": String(entry.get("res_path", "")), "entry": entry}


static func build_screen_assignment_snapshot(catalog_path: String = CATALOG_PATH) -> Dictionary:
	var loaded: Dictionary = load_catalog(catalog_path)
	var by_screen: Dictionary = {}
	for entry_variant in Dictionary(loaded.get("backgrounds", {})).values():
		var entry: Dictionary = Dictionary(entry_variant)
		for screen_hint_variant in Array(entry.get("screen_hint", [])):
			var screen_hint: String = String(screen_hint_variant).strip_edges()
			if screen_hint.is_empty():
				continue
			var ids: Array = Array(by_screen.get(screen_hint, []))
			ids.append(String(entry.get("background_id", "")))
			by_screen[screen_hint] = ids
	return {
		"catalog_id": String(loaded.get("catalog_id", "")),
		"schema_version": int(loaded.get("schema_version", 0)),
		"background_count": Dictionary(loaded.get("backgrounds", {})).size(),
		"screen_assignments": by_screen,
		"diagnostics": Array(PackedStringArray(loaded.get("diagnostics", PackedStringArray()))),
		"res_only_no_local_user_paths": _catalog_paths_are_res_only(loaded),
		"visual_only": true,
	}


static func get_diagnostics(catalog_path: String = CATALOG_PATH) -> PackedStringArray:
	var loaded: Dictionary = load_catalog(catalog_path)
	return PackedStringArray(loaded.get("diagnostics", PackedStringArray()))


static func _add_entry(result: Dictionary, entry: Dictionary) -> void:
	var background_id: String = String(entry.get("background_id", "")).strip_edges()
	var path: String = String(entry.get("res_path", "")).strip_edges()
	if background_id.is_empty():
		_append_diagnostic(result, "background_without_id")
		return
	if path.is_empty():
		_append_diagnostic(result, "background_without_path:%s" % background_id)
		return
	if not path.begins_with("res://"):
		_append_diagnostic(result, "background_path_not_res:%s" % background_id)
		return
	var backgrounds: Dictionary = Dictionary(result.get("backgrounds", {}))
	if backgrounds.has(background_id):
		_append_diagnostic(result, "duplicate_background_id:%s" % background_id)
		return
	entry["background_id"] = background_id
	entry["res_path"] = path
	entry["screen_hint"] = Array(entry.get("screen_hint", []))
	entry["dim_strength"] = clampf(float(entry.get("dim_strength", 0.5)), 0.0, 0.95)
	backgrounds[background_id] = entry.duplicate(true)
	result["backgrounds"] = backgrounds
	if not FileAccess.file_exists(path):
		_append_diagnostic(result, "missing_background_file:%s:%s" % [background_id, path])
	elif not ResourceLoader.exists(path):
		_append_diagnostic(result, "missing_background_resource:%s:%s" % [background_id, path])


static func _catalog_paths_are_res_only(loaded: Dictionary) -> bool:
	for entry_variant in Dictionary(loaded.get("backgrounds", {})).values():
		var path: String = String(Dictionary(entry_variant).get("res_path", ""))
		if not path.begins_with("res://"):
			return false
		if path.contains("C:/") or path.contains("C:" + "\\") or path.begins_with("file://"):
			return false
	return true


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
