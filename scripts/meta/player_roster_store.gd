class_name PlayerRosterStore
extends RefCounted

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")
const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const MULTIPLAYER_ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")

const SCHEMA_VERSION: int = 1
const STORE_ID: String = "player_roster_store_v1"
const DEFAULT_PROFILE_ID: String = "local_player"
const DEFAULT_SAVE_ROOT: String = "user://profiles"


static func get_save_path(profile_id: String = DEFAULT_PROFILE_ID) -> String:
	var safe_profile_id: String = _sanitize_profile_id(profile_id)
	return "%s/%s/roster_v1.json" % [DEFAULT_SAVE_ROOT, safe_profile_id]


static func ensure_roster(seed: String = START_ROSTER_GENERATOR_SCRIPT.DEFAULT_SEED, roster_size: int = START_ROSTER_GENERATOR_SCRIPT.DEFAULT_ROSTER_SIZE, profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "") -> Dictionary:
	var load_result: Dictionary = load_roster(profile_id, save_path)
	if bool(load_result.get("ok", false)):
		return {
			"ok": true,
			"created": false,
			"loaded": true,
			"reason": "loaded_existing_save",
			"path": String(load_result.get("path", "")),
			"profile_id": String(load_result.get("profile_id", profile_id)),
			"roster": Dictionary(load_result.get("roster", {})).duplicate(true),
			"summary": START_ROSTER_GENERATOR_SCRIPT.call("build_summary_snapshot", Dictionary(load_result.get("roster", {}))),
			"diagnostics": PackedStringArray(load_result.get("diagnostics", PackedStringArray())),
		}
	var generated: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", seed, roster_size, profile_id))
	var save_result: Dictionary = save_roster(generated, profile_id, save_path)
	return {
		"ok": bool(save_result.get("ok", false)),
		"created": true,
		"loaded": false,
		"reason": "generated_missing_or_invalid_save",
		"path": String(save_result.get("path", _resolve_save_path(profile_id, save_path))),
		"profile_id": _sanitize_profile_id(profile_id),
		"roster": generated.duplicate(true),
		"summary": START_ROSTER_GENERATOR_SCRIPT.call("build_summary_snapshot", generated),
		"diagnostics": _merge_diagnostics(load_result, save_result),
		"save_error": int(save_result.get("error", OK)),
	}


static func save_roster(roster: Dictionary, profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "") -> Dictionary:
	var path: String = _resolve_save_path(profile_id, save_path)
	var payload: Dictionary = build_save_payload(roster, profile_id)
	var validation: Dictionary = validate_payload(payload)
	if not bool(validation.get("valid", false)):
		return {
			"ok": false,
			"path": path,
			"profile_id": _sanitize_profile_id(profile_id),
			"error": ERR_INVALID_DATA,
			"diagnostics": PackedStringArray(validation.get("errors", PackedStringArray())),
		}
	var dir_error: Error = _ensure_parent_dir(path)
	if dir_error != OK:
		return {
			"ok": false,
			"path": path,
			"profile_id": _sanitize_profile_id(profile_id),
			"error": dir_error,
			"diagnostics": PackedStringArray(["save_dir_failed:%s:%d" % [path, dir_error]]),
		}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		return {
			"ok": false,
			"path": path,
			"profile_id": _sanitize_profile_id(profile_id),
			"error": open_error,
			"diagnostics": PackedStringArray(["save_open_failed:%s:%d" % [path, open_error]]),
		}
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return {
		"ok": true,
		"path": path,
		"profile_id": _sanitize_profile_id(profile_id),
		"payload": payload,
		"error": OK,
		"diagnostics": PackedStringArray(),
	}


static func load_roster(profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "") -> Dictionary:
	var path: String = _resolve_save_path(profile_id, save_path)
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"exists": false,
			"path": path,
			"profile_id": _sanitize_profile_id(profile_id),
			"roster": {},
			"diagnostics": PackedStringArray(["save_missing:%s" % path]),
		}
	var payload: Dictionary = _load_json(path)
	var validation: Dictionary = validate_payload(payload)
	if not bool(validation.get("valid", false)):
		return {
			"ok": false,
			"exists": true,
			"path": path,
			"profile_id": _sanitize_profile_id(profile_id),
			"payload": payload,
			"roster": {},
			"diagnostics": PackedStringArray(validation.get("errors", PackedStringArray())),
		}
	var roster: Dictionary = Dictionary(payload.get("roster", {})).duplicate(true)
	return {
		"ok": true,
		"exists": true,
		"path": path,
		"profile_id": String(payload.get("profile_id", _sanitize_profile_id(profile_id))),
		"payload": payload,
		"roster": roster,
		"summary": START_ROSTER_GENERATOR_SCRIPT.call("build_summary_snapshot", roster),
		"diagnostics": PackedStringArray(validation.get("warnings", PackedStringArray())),
	}


static func reset_roster(seed: String, roster_size: int, profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "", archive_existing: bool = true) -> Dictionary:
	var archive_result: Dictionary = {}
	if archive_existing:
		archive_result = archive_existing_roster(profile_id, save_path)
	var generated: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", seed, roster_size, profile_id))
	var save_result: Dictionary = save_roster(generated, profile_id, save_path)
	return {
		"ok": bool(save_result.get("ok", false)),
		"created": true,
		"loaded": false,
		"reason": "confirmed_reset",
		"path": String(save_result.get("path", _resolve_save_path(profile_id, save_path))),
		"profile_id": _sanitize_profile_id(profile_id),
		"roster": generated.duplicate(true),
		"summary": START_ROSTER_GENERATOR_SCRIPT.call("build_summary_snapshot", generated),
		"archive_path": String(archive_result.get("archive_path", "")),
		"archive_ok": bool(archive_result.get("ok", false)),
		"diagnostics": _merge_diagnostics(archive_result, save_result),
	}


static func archive_existing_roster(profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "") -> Dictionary:
	var path: String = _resolve_save_path(profile_id, save_path)
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"archive_path": "",
			"diagnostics": PackedStringArray(["archive_source_missing:%s" % path]),
		}
	var archive_dir: String = "%s/archive" % path.get_base_dir()
	var dir_error: Error = _ensure_dir(archive_dir)
	if dir_error != OK:
		return {
			"ok": false,
			"archive_path": "",
			"diagnostics": PackedStringArray(["archive_dir_failed:%s:%d" % [archive_dir, dir_error]]),
		}
	var archive_path: String = "%s/roster_v1_%d.json" % [archive_dir, int(Time.get_unix_time_from_system())]
	var source_file := FileAccess.open(path, FileAccess.READ)
	if source_file == null:
		return {
			"ok": false,
			"archive_path": archive_path,
			"diagnostics": PackedStringArray(["archive_source_open_failed:%s" % path]),
		}
	var source_text: String = source_file.get_as_text()
	source_file.close()
	var archive_file := FileAccess.open(archive_path, FileAccess.WRITE)
	if archive_file == null:
		return {
			"ok": false,
			"archive_path": archive_path,
			"diagnostics": PackedStringArray(["archive_write_failed:%s" % archive_path]),
		}
	archive_file.store_string(source_text)
	archive_file.close()
	return {
		"ok": true,
		"archive_path": archive_path,
		"diagnostics": PackedStringArray(),
	}


static func build_save_payload(roster: Dictionary, profile_id: String = DEFAULT_PROFILE_ID) -> Dictionary:
	var normalized_roster: Dictionary = roster.duplicate(true)
	var validation: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("validate_roster", normalized_roster))
	normalized_roster["valid"] = bool(validation.get("valid", false))
	normalized_roster["validation"] = validation
	var units: Array = Array(normalized_roster.get("units", []))
	return {
		"schema_version": SCHEMA_VERSION,
		"store_id": STORE_ID,
		"profile_id": _sanitize_profile_id(profile_id),
		"saved_at_unix_time": int(Time.get_unix_time_from_system()),
		"generator_id": String(normalized_roster.get("generator_id", "")),
		"generator_seed": String(normalized_roster.get("seed", "")),
		"progression_schema_version": int(normalized_roster.get("progression_schema_version", 1)),
		"roster_size": units.size(),
		"roster": normalized_roster,
		"multiplayer_boundary": {
			"scope": "local_player_profile",
			"host_policy": "host_uses_own_profile_or_explicit_scenario_roster",
			"join_policy": "joining_player_keeps_private_profile_roster",
			"public_preview_policy": "identity_role_portrait_fireteam_badges_only",
			"snapshot_policy": "owner_source_and_calculated_mission_state_only",
		},
	}


static func validate_payload(payload: Dictionary) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()
	if payload.is_empty():
		errors.append("payload_missing_or_invalid")
		return {"valid": false, "errors": errors, "warnings": warnings}
	if int(payload.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("schema_version_invalid")
	if String(payload.get("store_id", "")) != STORE_ID:
		errors.append("store_id_invalid")
	if String(payload.get("profile_id", "")).strip_edges().is_empty():
		errors.append("profile_id_missing")
	if String(payload.get("generator_seed", "")).strip_edges().is_empty():
		errors.append("generator_seed_missing")
	var roster: Dictionary = Dictionary(payload.get("roster", {}))
	var roster_validation: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("validate_roster", roster))
	if not bool(roster_validation.get("valid", false)):
		for error in PackedStringArray(roster_validation.get("errors", PackedStringArray())):
			errors.append("roster_%s" % error)
	for unit_variant in Array(roster.get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if String(unit.get("portrait_id", "")).strip_edges().is_empty():
			errors.append("unit_portrait_id_missing:%s" % unit_id)
		if PackedStringArray(unit.get("trait_ids", PackedStringArray())).is_empty():
			warnings.append("unit_traits_empty:%s" % unit_id)
	var relationship_validation: Dictionary = Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("validate_roster_relationships", Array(roster.get("units", [])), Array(roster.get("relationship_pairs", []))))
	if not bool(relationship_validation.get("valid", false)):
		for relationship_error in PackedStringArray(relationship_validation.get("errors", PackedStringArray())):
			errors.append("roster_%s" % relationship_error)
	for relationship_warning in PackedStringArray(relationship_validation.get("warnings", PackedStringArray())):
		warnings.append("roster_%s" % relationship_warning)
	var personnel_validation: Dictionary = Dictionary(PERSONNEL_EVENT_MODEL_SCRIPT.call("validate_events", Array(roster.get("personnel_events", []))))
	if not bool(personnel_validation.get("valid", false)):
		for personnel_error in PackedStringArray(personnel_validation.get("errors", PackedStringArray())):
			errors.append("personnel_%s" % personnel_error)
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
	}


static func roster_to_unit_array(roster: Dictionary) -> Array:
	var result: Array = []
	for unit_variant in Array(roster.get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		result.append(Dictionary(unit_variant).duplicate(true))
	return result


static func build_public_roster_preview(roster: Dictionary, owner_peer_id: int = 1, roster_source: String = "player", roster_mode: String = "player_rosters") -> Dictionary:
	var preview: Dictionary = Dictionary(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("build_public_roster_preview", roster, owner_peer_id, roster_source, roster_mode))
	var validation: Dictionary = Dictionary(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("validate_public_roster_payload", preview))
	preview["valid"] = bool(validation.get("valid", false))
	preview["public_validation"] = validation
	return preview


static func delete_roster_for_tests(profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "") -> void:
	var path: String = _resolve_save_path(profile_id, save_path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _resolve_save_path(profile_id: String, save_path: String) -> String:
	var normalized_path: String = save_path.strip_edges()
	if not normalized_path.is_empty():
		return normalized_path
	return get_save_path(profile_id)


static func _sanitize_profile_id(profile_id: String) -> String:
	var normalized: String = profile_id.strip_edges().to_lower()
	var result: String = ""
	for index in range(normalized.length()):
		var character: String = normalized.substr(index, 1)
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			result += character
		elif character == "_" or character == "-":
			result += character
	if result.is_empty():
		result = DEFAULT_PROFILE_ID
	return result.substr(0, 48)


static func _ensure_parent_dir(path: String) -> Error:
	return _ensure_dir(path.get_base_dir())


static func _ensure_dir(path: String) -> Error:
	if path.strip_edges().is_empty():
		return ERR_INVALID_PARAMETER
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


static func _merge_diagnostics(first: Dictionary, second: Dictionary) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry in PackedStringArray(first.get("diagnostics", PackedStringArray())):
		result.append(String(entry))
	for entry in PackedStringArray(second.get("diagnostics", PackedStringArray())):
		result.append(String(entry))
	return result


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
