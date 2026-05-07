extends SceneTree

const CATALOG_PATH: String = "res://data/audio_sfx_catalog.json"
const INVENTORY_DOC_PATH: String = "res://docs/assets/audio_sfx_inventory.md"
const AUDIO_ROOT: String = "res://Assets/used/audio/kenney_all_in_one/"
const REQUIRED_CATEGORIES: PackedStringArray = ["ui", "combat", "movement", "impact", "explosion"]
const REQUIRED_EVENTS: PackedStringArray = ["ui_click", "combat_blaster", "movement_footstep_neutral", "impact_generic_light", "explosion_small"]
const LICENSE_FILES: PackedStringArray = [
	"res://Assets/used/audio/kenney_all_in_one/licenses/UI_Audio_License.txt",
	"res://Assets/used/audio/kenney_all_in_one/licenses/Interface_Sounds_License.txt",
	"res://Assets/used/audio/kenney_all_in_one/licenses/Digital_Audio_License.txt",
	"res://Assets/used/audio/kenney_all_in_one/licenses/Sci-Fi_Sounds_License.txt",
	"res://Assets/used/audio/kenney_all_in_one/licenses/Impact_Sounds_License.txt",
	"res://Assets/used/audio/kenney_all_in_one/licenses/Foley_Sounds_License.txt",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_242 Audio SFX Inventory Import Verifier ===")
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	_test_inventory_doc()
	_test_catalog_shape_and_coverage(catalog)
	_test_catalog_paths_and_imports(catalog)
	_test_license_files()
	_test_runtime_catalog_has_no_local_paths(catalog)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_inventory_doc() -> void:
	var text: String = _read_text(INVENTORY_DOC_PATH)
	_assert(not text.is_empty(), "Audio SFX inventory doc exists")
	for required_text in ["CC0", "UI Audio", "Sci-Fi Sounds", "Impact Sounds", "Assets/used/audio/kenney_all_in_one", "Known Placeholders"]:
		_assert(text.contains(required_text), "Inventory documents %s" % required_text)


func _test_catalog_shape_and_coverage(catalog: Dictionary) -> void:
	_assert(int(catalog.get("schema_version", 0)) == 1, "Audio catalog has schema version 1")
	_assert(String(catalog.get("catalog_id", "")) == "audio_sfx_catalog_v1", "Audio catalog has stable id")
	var entries: Array = Array(catalog.get("entries", []))
	_assert(entries.size() >= 25 and entries.size() <= 40, "Curated audio subset stays small and useful")
	var ids: Dictionary = {}
	var category_counts: Dictionary = {}
	var planned_events: Dictionary = {}
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var audio_id: String = String(entry.get("audio_id", "")).strip_edges()
		if not audio_id.is_empty():
			ids[audio_id] = int(ids.get(audio_id, 0)) + 1
		var category: String = String(entry.get("category", "")).strip_edges()
		category_counts[category] = int(category_counts.get(category, 0)) + 1
		planned_events[String(entry.get("planned_event", "")).strip_edges()] = true
	var duplicate_count: int = 0
	for count_variant in ids.values():
		if int(count_variant) > 1:
			duplicate_count += 1
	_assert(duplicate_count == 0, "Audio IDs are unique")
	for category in REQUIRED_CATEGORIES:
		_assert(int(category_counts.get(category, 0)) > 0, "Catalog covers category %s" % category)
	_assert(int(category_counts.get("ambient_short", 0)) > 0, "Catalog includes short sci-fi ambient cues")
	for event_id in REQUIRED_EVENTS:
		_assert(planned_events.has(event_id), "Catalog covers planned event %s" % event_id)


func _test_catalog_paths_and_imports(catalog: Dictionary) -> void:
	for entry_variant in Array(catalog.get("entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			_failed += 1
			push_error("FAIL: Catalog entry is not a dictionary")
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var audio_id: String = String(entry.get("audio_id", "")).strip_edges()
		var path: String = String(entry.get("path", "")).strip_edges()
		_assert(not audio_id.is_empty(), "Catalog entry has audio_id")
		_assert(path.begins_with(AUDIO_ROOT), "%s uses curated project audio root" % audio_id)
		_assert(path.ends_with(".ogg"), "%s uses OGG audio" % audio_id)
		_assert(FileAccess.file_exists(path), "%s audio file exists" % audio_id)
		_assert(ResourceLoader.exists(path), "%s audio file imports as a Godot resource" % audio_id)
		_assert(float(entry.get("duration_seconds", 0.0)) > 0.0 and float(entry.get("duration_seconds", 0.0)) <= 5.0, "%s duration is bounded" % audio_id)
		_assert(not bool(entry.get("loop", true)), "%s is not an unplanned loop" % audio_id)
		_assert(float(entry.get("default_volume_db", 99.0)) >= -30.0 and float(entry.get("default_volume_db", 99.0)) <= 6.0, "%s has sane default volume" % audio_id)
		var pitch_range: Array = Array(entry.get("random_pitch_range", []))
		_assert(pitch_range.size() == 2 and float(pitch_range[0]) <= float(pitch_range[1]), "%s has valid pitch randomization range" % audio_id)


func _test_license_files() -> void:
	for license_path in LICENSE_FILES:
		_assert(FileAccess.file_exists(license_path), "License file exists: %s" % license_path.get_file())
		var text: String = _read_text(license_path)
		_assert(text.contains("Creative Commons Zero") or text.contains("CC0"), "License file is CC0: %s" % license_path.get_file())


func _test_runtime_catalog_has_no_local_paths(catalog: Dictionary) -> void:
	var catalog_text: String = JSON.stringify(catalog)
	_assert(not _contains_local_path(catalog_text), "Audio catalog has no local user/file paths")
	for entry_variant in Array(catalog.get("entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry_text: String = JSON.stringify(entry_variant)
		_assert(not _contains_local_path(entry_text), "Catalog entry avoids local paths")


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _contains_local_path(text: String) -> bool:
	return text.contains("%USERPROFILE%") or text.contains("C:/Users") or text.contains("C:\\Users") or text.contains("file://")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
