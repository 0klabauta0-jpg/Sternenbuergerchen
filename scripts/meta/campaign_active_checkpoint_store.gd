extends RefCounted
## Separate atomic file. A domain owner must validate the complete world on
## both write and read; the last safe home checkpoint is never touched here.
const DEFAULT_PATH := "user://campaigns/introduction/active_checkpoint_v1.json"
const HOME_PATH := "user://campaigns/introduction/checkpoint_v1.json"
const MAX_BYTES := 8 * 1024 * 1024
const MAX_ITEMS := 65536
const MAX_DEPTH := 32

static func save_checkpoint(payload: Dictionary, validator: Callable, path: String = DEFAULT_PATH) -> Dictionary:
	if not _valid_path(path): return _reject("invalid_checkpoint_path")
	if not validator.is_valid() or not _json_value(payload): return _reject("invalid_active_checkpoint")
	var validated: Variant = validator.call(payload.duplicate(true))
	if not validated is Dictionary or not validated.get("ok",false): return validated if validated is Dictionary else _reject("invalid_active_checkpoint")
	var content := JSON.stringify(payload, "\t", true, true)
	if content.to_utf8_buffer().size() > MAX_BYTES: return _reject("checkpoint_too_large")
	var parsed: Variant = JSON.parse_string(content)
	if not parsed is Dictionary: return _reject("invalid_active_checkpoint")
	validated = validator.call(parsed.duplicate(true))
	if not validated is Dictionary or not validated.get("ok",false): return validated if validated is Dictionary else _reject("invalid_active_checkpoint")
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK: return _reject("checkpoint_directory_failed")
	var temporary := absolute + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return _reject("checkpoint_write_failed")
	file.store_string(content)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return _reject("checkpoint_write_failed")
	if DirAccess.rename_absolute(temporary, absolute) != OK: return _reject("checkpoint_replace_failed")
	return {"ok":true}

static func load_checkpoint(validator: Callable, path: String = DEFAULT_PATH) -> Dictionary:
	if not _valid_path(path): return _reject("invalid_checkpoint_path")
	if not validator.is_valid(): return _reject("invalid_active_checkpoint")
	if not FileAccess.file_exists(path): return _reject("checkpoint_missing")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES: return _reject("checkpoint_unreadable")
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK: return _reject("invalid_checkpoint_json")
	var parsed: Variant = parser.data
	if not parsed is Dictionary or not _json_value(parsed): return _reject("invalid_checkpoint_json")
	var validated: Variant = validator.call(parsed.duplicate(true))
	if not validated is Dictionary or not validated.get("ok",false): return validated if validated is Dictionary else _reject("invalid_active_checkpoint")
	return {"ok":true,"payload":parsed}

# Preserve the exact prior artifact, including malformed JSON. The expected
# digest prevents a newly written active save from being retired by stale work.
static func archive_checkpoint(expected_sha256: String, path: String = DEFAULT_PATH) -> Dictionary:
	if not _valid_path(path): return _reject("invalid_checkpoint_path")
	if not FileAccess.file_exists(path): return {"ok":true,"unchanged":true}
	if expected_sha256.length() != 64 or FileAccess.get_sha256(path) != expected_sha256: return _reject("active_checkpoint_changed")
	var archived := path.trim_suffix(".json") + ".retired-" + expected_sha256 + ".json"
	if FileAccess.file_exists(archived) and FileAccess.get_sha256(archived) != expected_sha256: return _reject("active_archive_conflict")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(archived)) != OK: return _reject("active_archive_failed")
	return {"ok":true,"archived_path":archived}

static func _valid_path(path: String) -> bool:
	if not path.begins_with("user://campaigns/") or path.contains("\\") or not path.to_lower().ends_with(".json"): return false
	var relative := path.substr("user://campaigns/".length())
	if relative.contains(":"): return false
	for segment in relative.split("/", true):
		if segment in ["", ".", ".."]: return false
	return path.to_lower() != HOME_PATH.to_lower()

static func _json_value(value: Variant, depth: int = 0) -> bool:
	if depth > MAX_DEPTH: return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING: return true
		TYPE_INT: return abs(float(value)) <= 9007199254740991.0
		TYPE_FLOAT: return is_finite(value)
		TYPE_ARRAY:
			if value.size() > MAX_ITEMS: return false
			for child in value:
				if not _json_value(child,depth+1): return false
			return true
		TYPE_DICTIONARY:
			if value.size() > MAX_ITEMS: return false
			for key in value:
				if typeof(key) != TYPE_STRING or not _json_value(value[key],depth+1): return false
			return true
	return false

static func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
