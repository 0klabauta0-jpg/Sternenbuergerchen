class_name PlayerRosterStore
extends RefCounted

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")
const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const MULTIPLAYER_ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")
const TEAM_NAME_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/team_name_generator.gd")

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
		var diagnostics: PackedStringArray = PackedStringArray(validation.get("errors", PackedStringArray()))
		for load_diagnostic in PackedStringArray(payload.get("_load_diagnostics", PackedStringArray())):
			diagnostics.append(String(load_diagnostic))
		return {
			"ok": false,
			"exists": true,
			"path": path,
			"profile_id": _sanitize_profile_id(profile_id),
			"payload": payload,
			"roster": {},
			"diagnostics": diagnostics,
		}
	var roster: Dictionary = Dictionary(payload.get("roster", {})).duplicate(true)
	roster = TEAM_NAME_GENERATOR_SCRIPT.call("apply_team_name", roster, String(roster.get("team_name", "")), String(roster.get("seed", "")), int(Dictionary(roster.get("team_identity", {})).get("name_generation_index", 0)))
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


static func list_roster_entries(profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "") -> Dictionary:
	var current_path: String = _resolve_save_path(profile_id, save_path)
	var entries: Array = []
	if FileAccess.file_exists(current_path):
		entries.append(_build_roster_entry(current_path, profile_id, true, false))
	var archive_dir: String = "%s/archive" % current_path.get_base_dir()
	var dir := DirAccess.open(archive_dir)
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var entry_path: String = "%s/%s" % [archive_dir, file_name]
				entries.append(_build_roster_entry(entry_path, profile_id, false, true))
			file_name = dir.get_next()
		dir.list_dir_end()
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _sort_roster_entries(a, b))
	return {
		"ok": true,
		"profile_id": _sanitize_profile_id(profile_id),
		"active_path": current_path,
		"archive_dir": archive_dir,
		"entries": entries,
		"entry_count": entries.size(),
	}


static func delete_roster_entry(entry_path: String, profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "") -> Dictionary:
	var path: String = entry_path.strip_edges()
	var current_path: String = _resolve_save_path(profile_id, save_path)
	if path.is_empty():
		return {"ok": false, "reason": "missing_entry_path", "path": path}
	if path == current_path:
		return {"ok": false, "reason": "active_roster_protected", "path": path}
	var archive_dir: String = "%s/archive" % current_path.get_base_dir()
	if not _is_archive_entry_path(path, archive_dir):
		return {"ok": false, "reason": "outside_roster_archive", "path": path, "archive_dir": archive_dir}
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": "entry_missing", "path": path}
	var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return {
		"ok": error == OK,
		"reason": "deleted" if error == OK else "delete_failed",
		"error": error,
		"path": path,
	}


static func activate_roster_entry(entry_path: String, profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "") -> Dictionary:
	var path: String = entry_path.strip_edges()
	var current_path: String = _resolve_save_path(profile_id, save_path)
	if path.is_empty():
		return {"ok": false, "reason": "missing_entry_path", "path": path}
	if path == current_path:
		var active_load: Dictionary = load_roster(profile_id, save_path)
		return {
			"ok": bool(active_load.get("ok", false)),
			"reason": "already_active",
			"path": current_path,
			"profile_id": _sanitize_profile_id(profile_id),
			"roster": Dictionary(active_load.get("roster", {})).duplicate(true),
			"diagnostics": PackedStringArray(active_load.get("diagnostics", PackedStringArray())),
		}
	var archive_dir: String = "%s/archive" % current_path.get_base_dir()
	if not _is_archive_entry_path(path, archive_dir):
		return {"ok": false, "reason": "outside_roster_archive", "path": path, "archive_dir": archive_dir}
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": "entry_missing", "path": path}
	var load_result: Dictionary = load_roster(profile_id, path)
	if not bool(load_result.get("ok", false)):
		return {
			"ok": false,
			"reason": "entry_invalid",
			"path": path,
			"diagnostics": PackedStringArray(load_result.get("diagnostics", PackedStringArray())),
		}
	var archive_result: Dictionary = {}
	if FileAccess.file_exists(current_path):
		archive_result = archive_existing_roster(profile_id, save_path)
		if not bool(archive_result.get("ok", false)):
			return {
				"ok": false,
				"reason": "active_archive_failed",
				"path": path,
				"archive": archive_result,
				"diagnostics": PackedStringArray(archive_result.get("diagnostics", PackedStringArray())),
			}
	var roster: Dictionary = Dictionary(load_result.get("roster", {})).duplicate(true)
	var save_result: Dictionary = save_roster(roster, profile_id, save_path)
	var remove_error: Error = OK
	if bool(save_result.get("ok", false)) and FileAccess.file_exists(path):
		remove_error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var diagnostics: PackedStringArray = _merge_diagnostics(load_result, save_result)
	for diagnostic in PackedStringArray(archive_result.get("diagnostics", PackedStringArray())):
		diagnostics.append(String(diagnostic))
	if remove_error != OK:
		diagnostics.append("activated_archive_remove_failed:%s:%d" % [path, remove_error])
	return {
		"ok": bool(save_result.get("ok", false)),
		"reason": "activated" if bool(save_result.get("ok", false)) else "save_failed",
		"path": current_path,
		"activated_from_path": path,
		"profile_id": _sanitize_profile_id(profile_id),
		"roster": roster,
		"save": save_result,
		"archive": archive_result,
		"removed_activated_archive": remove_error == OK,
		"diagnostics": diagnostics,
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
	var archive_path: String = _build_unique_archive_path(archive_dir)
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
	normalized_roster = TEAM_NAME_GENERATOR_SCRIPT.call("apply_team_name", normalized_roster, String(normalized_roster.get("team_name", "")), String(normalized_roster.get("seed", "")), int(Dictionary(normalized_roster.get("team_identity", {})).get("name_generation_index", 0)))
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


static func rename_team(roster: Dictionary, next_team_name: String, profile_id: String = DEFAULT_PROFILE_ID, save_path: String = "") -> Dictionary:
	var renamed_roster: Dictionary = TEAM_NAME_GENERATOR_SCRIPT.call("apply_team_name", roster, next_team_name, String(roster.get("seed", "")), int(Dictionary(roster.get("team_identity", {})).get("name_generation_index", 0)))
	var save_result: Dictionary = save_roster(renamed_roster, profile_id, save_path)
	return {
		"ok": bool(save_result.get("ok", false)),
		"roster": renamed_roster,
		"summary": START_ROSTER_GENERATOR_SCRIPT.call("build_summary_snapshot", renamed_roster),
		"save": save_result,
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


static func _build_roster_entry(path: String, profile_id: String, active: bool, archived: bool) -> Dictionary:
	var load_result: Dictionary = load_roster(profile_id, path)
	var roster: Dictionary = Dictionary(load_result.get("roster", {})).duplicate(true)
	var payload: Dictionary = Dictionary(load_result.get("payload", {}))
	var identity: Dictionary = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("build_team_identity_snapshot", roster))
	var team_name: String = String(identity.get("team_name", "")).strip_edges()
	if not bool(load_result.get("ok", false)):
		team_name = "Ungueltiger Team-Save"
	return {
		"entry_id": path,
		"path": path,
		"profile_id": String(load_result.get("profile_id", _sanitize_profile_id(profile_id))),
		"team_name": team_name,
		"seed": String(roster.get("seed", payload.get("generator_seed", ""))),
		"roster_size": Array(roster.get("units", [])).size(),
		"saved_at_unix_time": int(payload.get("saved_at_unix_time", 0)),
		"active": active,
		"archived": archived,
		"valid": bool(load_result.get("ok", false)),
		"can_delete": not active,
		"source": "current" if active else "archive",
		"diagnostics": PackedStringArray(load_result.get("diagnostics", PackedStringArray())),
	}


static func _sort_roster_entries(a: Dictionary, b: Dictionary) -> bool:
	if bool(a.get("active", false)) != bool(b.get("active", false)):
		return bool(a.get("active", false))
	var a_saved: int = int(a.get("saved_at_unix_time", 0))
	var b_saved: int = int(b.get("saved_at_unix_time", 0))
	if a_saved != b_saved:
		return a_saved > b_saved
	return String(a.get("path", "")) < String(b.get("path", ""))


static func _is_archive_entry_path(path: String, archive_dir: String) -> bool:
	if path.is_empty() or archive_dir.is_empty():
		return false
	if not path.ends_with(".json"):
		return false
	var normalized_archive_dir: String = archive_dir
	while normalized_archive_dir.ends_with("/"):
		normalized_archive_dir = normalized_archive_dir.substr(0, normalized_archive_dir.length() - 1)
	var prefix: String = "%s/" % normalized_archive_dir
	return path.begins_with(prefix)


static func _build_unique_archive_path(archive_dir: String) -> String:
	var timestamp: int = int(Time.get_unix_time_from_system())
	var base_path: String = "%s/roster_v1_%d" % [archive_dir, timestamp]
	var candidate: String = "%s.json" % base_path
	var suffix: int = 1
	while FileAccess.file_exists(candidate):
		candidate = "%s_%02d.json" % [base_path, suffix]
		suffix += 1
	return candidate


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
		return {"_load_diagnostics": PackedStringArray(["load_missing:%s" % path])}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"_load_diagnostics": PackedStringArray(["load_open_failed:%s:%d" % [path, FileAccess.get_open_error()]])}
	var length: int = file.get_length()
	if length <= 0:
		file.close()
		return {"_load_diagnostics": PackedStringArray(["load_empty:%s" % path])}
	var text: String = file.get_as_text()
	file.close()
	if text.strip_edges().is_empty():
		return {"_load_diagnostics": PackedStringArray(["load_empty:%s" % path])}
	var json := JSON.new()
	var parse_error: Error = json.parse(text)
	if parse_error != OK:
		return {
			"_load_diagnostics": PackedStringArray([
				"load_parse_failed:%s:%d:%s" % [path, int(json.get_error_line()), json.get_error_message()]
			])
		}
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"_load_diagnostics": PackedStringArray(["load_not_dictionary:%s" % path])}
	return Dictionary(parsed)
