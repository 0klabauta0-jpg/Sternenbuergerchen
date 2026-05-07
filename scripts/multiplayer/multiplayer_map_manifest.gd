class_name MultiplayerMapManifest
extends RefCounted

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")

const FORMAT_VERSION: int = 1
const DOWNLOAD_ROOT: String = "user://downloaded_maps"
const HASH_LENGTH: int = 64
const MAX_MAP_BYTES: int = 1024 * 1024
const FORBIDDEN_MAP_PAYLOAD_KEYS: PackedStringArray = [
	"script",
	"resource_path",
	"absolute_path",
]


static func build_manifest_for_map(map_path: String, scenario_path: String = "", author: String = "") -> Dictionary:
	var normalized_path: String = map_path.strip_edges()
	if normalized_path.is_empty() or not FileAccess.file_exists(normalized_path):
		return {"valid": false, "errors": PackedStringArray(["map_file_missing"])}
	var map_text: String = _read_text(normalized_path)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", normalized_path)
	var map_name: String = normalized_path.get_file().get_basename()
	if terrain_map_data != null and terrain_map_data.has_method("get_map_name"):
		var loaded_name: String = String(terrain_map_data.call("get_map_name")).strip_edges()
		if not loaded_name.is_empty():
			map_name = loaded_name
	var map_id: String = _sanitize_id(map_name)
	if map_id.is_empty():
		map_id = _sanitize_id(normalized_path.get_file().get_basename())
	var manifest: Dictionary = {
		"schema_version": 1,
		"format_version": FORMAT_VERSION,
		"map_id": map_id,
		"map_name": map_name,
		"author": author.strip_edges(),
		"source": "host_editor_map",
		"map_hash": map_text.sha256_text(),
		"map_size_bytes": map_text.to_utf8_buffer().size(),
		"source_path": normalized_path,
		"download_required_policy": "client_consent_before_cache_write",
	}
	if not scenario_path.strip_edges().is_empty() and FileAccess.file_exists(scenario_path.strip_edges()):
		var scenario_text: String = _read_text(scenario_path.strip_edges())
		manifest["scenario_file_path"] = scenario_path.strip_edges()
		manifest["scenario_hash"] = scenario_text.sha256_text()
		manifest["scenario_size_bytes"] = scenario_text.to_utf8_buffer().size()
	var verification: Dictionary = verify_manifest(manifest)
	manifest["valid"] = bool(verification.get("valid", false))
	manifest["errors"] = PackedStringArray(verification.get("errors", PackedStringArray()))
	return manifest


static func normalize_manifest(manifest: Dictionary) -> Dictionary:
	return {
		"schema_version": maxi(int(manifest.get("schema_version", 1)), 1),
		"format_version": maxi(int(manifest.get("format_version", FORMAT_VERSION)), 1),
		"map_id": _sanitize_id(String(manifest.get("map_id", ""))),
		"map_name": String(manifest.get("map_name", "")).strip_edges(),
		"author": String(manifest.get("author", "")).strip_edges(),
		"source": String(manifest.get("source", "host_editor_map")).strip_edges(),
		"map_hash": String(manifest.get("map_hash", "")).strip_edges().to_lower(),
		"map_size_bytes": maxi(int(manifest.get("map_size_bytes", 0)), 0),
		"scenario_file_path": _sanitize_optional_path(String(manifest.get("scenario_file_path", ""))),
		"scenario_hash": String(manifest.get("scenario_hash", "")).strip_edges().to_lower(),
		"scenario_size_bytes": maxi(int(manifest.get("scenario_size_bytes", 0)), 0),
		"download_required_policy": "client_consent_before_cache_write",
	}


static func verify_manifest(manifest: Dictionary) -> Dictionary:
	var normalized: Dictionary = normalize_manifest(manifest)
	var errors: PackedStringArray = PackedStringArray()
	var raw_map_id: String = String(manifest.get("map_id", "")).strip_edges()
	if raw_map_id.contains("..") or raw_map_id.contains("/") or raw_map_id.contains("\\"):
		errors.append("map_id_unsafe")
	if int(normalized.get("format_version", 0)) != FORMAT_VERSION:
		errors.append("unsupported_format_version")
	if String(normalized.get("map_id", "")).is_empty():
		errors.append("map_id_required")
	if String(normalized.get("map_name", "")).is_empty():
		errors.append("map_name_required")
	if not _is_hash(String(normalized.get("map_hash", ""))):
		errors.append("map_hash_invalid")
	var size_bytes: int = int(normalized.get("map_size_bytes", 0))
	if size_bytes <= 0 or size_bytes > MAX_MAP_BYTES:
		errors.append("map_size_invalid")
	var raw_scenario_path: String = String(manifest.get("scenario_file_path", "")).strip_edges()
	var scenario_path: String = String(normalized.get("scenario_file_path", ""))
	if not raw_scenario_path.is_empty() and (scenario_path.is_empty() or not _is_safe_project_or_user_path(raw_scenario_path)):
		errors.append("scenario_path_unsafe")
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"manifest": normalized,
	}


static func check_local_map(manifest: Dictionary, local_map_paths: Array) -> Dictionary:
	var verification: Dictionary = verify_manifest(manifest)
	if not bool(verification.get("valid", false)):
		return {
			"state": "invalid_manifest",
			"requires_consent": false,
			"errors": PackedStringArray(verification.get("errors", PackedStringArray())),
		}
	var normalized: Dictionary = Dictionary(verification.get("manifest", {}))
	var expected_hash: String = String(normalized.get("map_hash", ""))
	var candidate_found: bool = false
	for path_variant in local_map_paths:
		var path: String = String(path_variant).strip_edges()
		if path.is_empty() or not FileAccess.file_exists(path):
			continue
		var candidate_manifest: Dictionary = build_manifest_for_map(path)
		if String(candidate_manifest.get("map_id", "")) != String(normalized.get("map_id", "")):
			continue
		candidate_found = true
		if String(candidate_manifest.get("map_hash", "")) == expected_hash:
			return {
				"state": "known",
				"requires_consent": false,
				"local_path": path,
				"manifest": normalized,
			}
	if candidate_found:
		return {
			"state": "hash_mismatch",
			"requires_consent": true,
			"manifest": normalized,
		}
	return {
		"state": "missing",
		"requires_consent": true,
		"manifest": normalized,
	}


static func build_download_prompt(manifest: Dictionary, host_peer_id: int = 1) -> Dictionary:
	var verification: Dictionary = verify_manifest(manifest)
	var normalized: Dictionary = Dictionary(verification.get("manifest", normalize_manifest(manifest)))
	return {
		"visible": bool(verification.get("valid", false)),
		"host_peer_id": host_peer_id,
		"map_id": String(normalized.get("map_id", "")),
		"map_name": String(normalized.get("map_name", "")),
		"map_hash": String(normalized.get("map_hash", "")),
		"map_size_bytes": int(normalized.get("map_size_bytes", 0)),
		"message": "Host bietet Map '%s' an. Download nur nach Zustimmung." % String(normalized.get("map_name", "")),
		"errors": PackedStringArray(verification.get("errors", PackedStringArray())),
	}


static func accept_download(manifest: Dictionary, map_json_text: String, cache_root: String = DOWNLOAD_ROOT) -> Dictionary:
	var verification: Dictionary = verify_manifest(manifest)
	if not bool(verification.get("valid", false)):
		return _download_result(false, "invalid_manifest", "", verification)
	var normalized: Dictionary = Dictionary(verification.get("manifest", {}))
	var payload_hash: String = map_json_text.sha256_text()
	if payload_hash != String(normalized.get("map_hash", "")):
		return _download_result(false, "hash_mismatch", "", verification)
	var payload_size: int = map_json_text.to_utf8_buffer().size()
	if payload_size != int(normalized.get("map_size_bytes", 0)):
		return _download_result(false, "size_mismatch", "", verification)
	var validation: Dictionary = validate_map_json_text(map_json_text)
	if not bool(validation.get("valid", false)):
		return _download_result(false, "invalid_map_json", "", validation)
	var safe_root: String = cache_root.strip_edges()
	if safe_root.is_empty() or not safe_root.begins_with("user://"):
		return _download_result(false, "unsafe_cache_root", "", verification)
	var make_dir_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(safe_root))
	if make_dir_error != OK:
		return _download_result(false, "cache_dir_failed", "", verification)
	var cache_path: String = "%s/%s_%s.json" % [
		safe_root.trim_suffix("/"),
		String(normalized.get("map_id", "")),
		String(normalized.get("map_hash", "")).substr(0, 12),
	]
	var file := FileAccess.open(cache_path, FileAccess.WRITE)
	if file == null:
		return _download_result(false, "cache_write_failed", "", verification)
	file.store_string(map_json_text)
	file.close()
	return {
		"accepted": true,
		"state": "accepted",
		"cache_path": cache_path,
		"manifest": normalized,
		"registry_entry": {
			"map_id": String(normalized.get("map_id", "")),
			"map_hash": String(normalized.get("map_hash", "")),
			"map_path": cache_path,
			"source": "downloaded_from_host",
		},
		"can_start_client": true,
	}


static func reject_download(manifest: Dictionary) -> Dictionary:
	return {
		"accepted": false,
		"state": "rejected",
		"manifest": normalize_manifest(manifest),
		"can_start_client": false,
	}


static func validate_map_json_text(map_json_text: String) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	if map_json_text.to_utf8_buffer().size() <= 0 or map_json_text.to_utf8_buffer().size() > MAX_MAP_BYTES:
		errors.append("map_payload_size_invalid")
	var parsed: Variant = JSON.parse_string(map_json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("map_json_not_dictionary")
		return {"valid": false, "errors": errors}
	var data: Dictionary = Dictionary(parsed)
	if String(data.get("map_name", "")).strip_edges().is_empty():
		errors.append("map_name_required")
	if typeof(data.get("grid_size", {})) != TYPE_DICTIONARY:
		errors.append("grid_size_required")
	if not (data.get("tiles", []) is Array) or Array(data.get("tiles", [])).is_empty():
		errors.append("tiles_required")
	_collect_forbidden_map_payload_keys(data, "$", errors)
	if typeof(data.get("grid_size", {})) == TYPE_DICTIONARY:
		_validate_enemy_team_configs(data.get("enemy_team_configs", {}), _coerce_grid_size(data.get("grid_size", {})), errors)
	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


static func _download_result(accepted: bool, state: String, cache_path: String, diagnostics: Dictionary) -> Dictionary:
	return {
		"accepted": accepted,
		"state": state,
		"cache_path": cache_path,
		"errors": PackedStringArray(diagnostics.get("errors", PackedStringArray())),
		"can_start_client": false,
	}


static func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


static func _sanitize_id(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	var result: String = ""
	for index in range(normalized.length()):
		var character: String = normalized.substr(index, 1)
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "_" or character == "-":
			result += character
		elif character == " ":
			result += "_"
	return result.strip_edges()


static func _sanitize_optional_path(path: String) -> String:
	var normalized: String = path.strip_edges()
	if normalized.is_empty():
		return ""
	if _is_safe_project_or_user_path(normalized):
		return normalized
	return ""


static func _is_hash(value: String) -> bool:
	if value.length() != HASH_LENGTH:
		return false
	for index in range(value.length()):
		var character: String = value.substr(index, 1)
		if not ((character >= "a" and character <= "f") or (character >= "0" and character <= "9")):
			return false
	return true


static func _is_safe_project_or_user_path(path: String) -> bool:
	var normalized: String = path.strip_edges()
	if normalized.contains("..") or normalized.contains("\\"):
		return false
	return normalized.begins_with("res://") or normalized.begins_with("user://")


static func _collect_forbidden_map_payload_keys(value: Variant, path: String, errors: PackedStringArray) -> void:
	if typeof(value) == TYPE_DICTIONARY:
		var source: Dictionary = Dictionary(value)
		for key_variant in source.keys():
			var key: String = String(key_variant)
			var child_path: String = "%s.%s" % [path, key]
			if FORBIDDEN_MAP_PAYLOAD_KEYS.has(key.strip_edges().to_lower()):
				errors.append("forbidden_key_%s:%s" % [key.strip_edges().to_lower(), child_path])
			_collect_forbidden_map_payload_keys(source.get(key_variant), child_path, errors)
		return
	if value is Array:
		var array_value: Array = Array(value)
		for index in range(array_value.size()):
			_collect_forbidden_map_payload_keys(array_value[index], "%s[%d]" % [path, index], errors)


static func _validate_enemy_team_configs(value: Variant, grid_size: Vector2i, errors: PackedStringArray) -> void:
	if value == null:
		return
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("enemy_team_configs_not_dictionary")
		return
	var configs: Dictionary = Dictionary(value)
	for config_id_variant in configs.keys():
		var config_id: String = String(config_id_variant).strip_edges()
		if config_id.is_empty():
			errors.append("enemy_team_config_id_empty")
			continue
		if config_id == "default":
			continue
		var validation: Dictionary = Dictionary(ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("validate_config", configs.get(config_id_variant), grid_size))
		for error_variant in PackedStringArray(validation.get("errors", PackedStringArray())):
			errors.append("enemy_team_config:%s:%s" % [config_id, String(error_variant)])


static func _coerce_grid_size(value: Variant) -> Vector2i:
	if typeof(value) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	var source: Dictionary = Dictionary(value)
	return Vector2i(maxi(int(source.get("x", 0)), 0), maxi(int(source.get("y", 0)), 0))
