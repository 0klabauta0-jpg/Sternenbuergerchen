extends SceneTree

const CONTRACT_PATH: String = "res://docs/dev/contextual_help_popup_ux_contract.md"
const CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const MATRIX_PATH: String = "res://docs/qa/playability_coverage_matrix.md"
const TASK_PATH: String = "res://docs/tasks/TASK_263_contextual_help_popup_ux_contract.md"

const REQUIRED_DOC_SECTIONS: Array = [
	"Purpose",
	"Help Levels",
	"Timing",
	"Layout",
	"Settings",
	"Global Help Button",
	"Content Catalog",
	"Quality Rules",
	"Coverage",
	"Non Goals",
]

const REQUIRED_HELP_LEVELS: Array = ["none", "compact", "detail"]
const REQUIRED_SETTINGS_MODES: Array = ["off", "compact", "expanded"]
const REQUIRED_ENTRY_FIELDS: Array = [
	"help_id",
	"screen_id",
	"area_id",
	"status",
	"title",
	"compact_lines",
	"detail_lines",
	"target_audience",
	"manual_review",
]

const REQUIRED_SCREEN_AREAS: Array = [
	"main_menu.primary_routes",
	"settings.contextual_help_mode",
	"settings.fog_of_war_mode",
	"shell.global_help_button",
	"homebase.roster",
	"homebase.transfer_team",
	"fob.fireteams",
	"fob.flightdeck",
	"loadout.weight",
	"character_sheet.core_values",
	"mission_hud.command_matrix",
	"mission_hud.mission_control",
	"map_editor.height_tool",
	"map_editor.save_load",
	"multiplayer_lobby.host_join",
	"debrief.character_updates",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_263 Contextual Help Popup UX Contract ===")
	var contract_text: String = _read_text(CONTRACT_PATH)
	var matrix_text: String = _read_text(MATRIX_PATH)
	var task_text: String = _read_text(TASK_PATH)
	var catalog: Dictionary = _read_catalog(CATALOG_PATH)
	_test_contract_doc(contract_text)
	_test_catalog_shape(catalog)
	_test_catalog_entries(catalog)
	_test_coverage_matrix(matrix_text)
	_test_task_status(task_text)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_contract_doc(contract_text: String) -> void:
	_assert(not contract_text.is_empty(), "Contextual help UX contract exists")
	for section in REQUIRED_DOC_SECTIONS:
		_assert(contract_text.contains("## %s" % section), "Contract has %s section" % section)
	for token in ["0.45s", "3.5s", "220 px", "260 px", "45%", "`off`", "`compact`", "`expanded`", "`shell.global_help_button`"]:
		_assert(contract_text.contains(token), "Contract names %s" % token)
	_assert(contract_text.contains("must never become gameplay truth"), "Contract forbids help as gameplay truth")
	_assert(contract_text.contains("Controls reference a stable `help_id`"), "Contract requires stable help_id references")
	_assert(contract_text.contains("1 to 3 short lines"), "Contract separates compact text length")


func _test_catalog_shape(catalog: Dictionary) -> void:
	_assert(not catalog.is_empty(), "Contextual help catalog parses as dictionary")
	_assert(int(catalog.get("schema_version", 0)) == 1, "Catalog schema version is 1")
	_assert(String(catalog.get("catalog_id", "")) == "contextual_help_v1", "Catalog ID is stable")
	var runtime_contract: Dictionary = Dictionary(catalog.get("runtime_contract", {}))
	_assert(bool(runtime_contract.get("visual_only", false)), "Catalog marks help as visual-only")
	_assert(bool(runtime_contract.get("no_gameplay_truth", false)), "Catalog forbids gameplay truth")
	_assert(bool(runtime_contract.get("controls_reference_help_id", false)), "Catalog requires help_id references")
	_assert(float(runtime_contract.get("compact_delay_seconds", 0.0)) == 0.45, "Catalog compact delay matches contract")
	_assert(float(runtime_contract.get("detail_delay_seconds", 0.0)) == 3.5, "Catalog detail delay matches contract")
	_assert(int(runtime_contract.get("compact_max_width_px", 0)) == 220, "Catalog compact width matches contract")
	_assert(int(runtime_contract.get("detail_max_width_px", 0)) == 260, "Catalog detail width matches contract")
	_assert(float(runtime_contract.get("max_viewport_height_ratio", 0.0)) == 0.45, "Catalog viewport height rule matches contract")
	_assert(_array_contains_all(Array(catalog.get("help_levels", [])), REQUIRED_HELP_LEVELS), "Catalog includes help levels")
	_assert(_array_contains_all(Array(catalog.get("settings_modes", [])), REQUIRED_SETTINGS_MODES), "Catalog includes settings modes")
	_assert(_array_contains_all(Array(catalog.get("required_fields", [])), REQUIRED_ENTRY_FIELDS), "Catalog defines required entry fields")
	_assert(_required_area_keys(catalog).size() >= REQUIRED_SCREEN_AREAS.size(), "Catalog lists required screen areas")


func _test_catalog_entries(catalog: Dictionary) -> void:
	var entries: Array = Array(catalog.get("entries", []))
	_assert(entries.size() >= REQUIRED_SCREEN_AREAS.size(), "Catalog has entries for required areas")
	var allowed_statuses: Array = Array(catalog.get("allowed_statuses", []))
	var allowed_audiences: Array = Array(catalog.get("allowed_audiences", []))
	var seen_help_ids: Dictionary = {}
	var entry_keys: Dictionary = {}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var help_id: String = String(entry.get("help_id", ""))
		var screen_id: String = String(entry.get("screen_id", ""))
		var area_id: String = String(entry.get("area_id", ""))
		var entry_key: String = "%s.%s" % [screen_id, area_id]
		for field in REQUIRED_ENTRY_FIELDS:
			_assert(entry.has(field), "%s has field %s" % [help_id, field])
		_assert(_is_stable_help_id(help_id), "%s uses stable help_id syntax" % help_id)
		_assert(not seen_help_ids.has(help_id), "%s is unique" % help_id)
		seen_help_ids[help_id] = true
		entry_keys[entry_key] = true
		_assert(String(entry.get("status", "")) in allowed_statuses, "%s has allowed status" % help_id)
		_assert(String(entry.get("target_audience", "")) in allowed_audiences, "%s has allowed audience" % help_id)
		_assert(entry.get("manual_review", null) is bool, "%s has boolean manual_review" % help_id)
		_assert(String(entry.get("title", "")).length() <= 48, "%s title is compact" % help_id)
		var compact_lines: Array = Array(entry.get("compact_lines", []))
		_assert(compact_lines.size() >= 1 and compact_lines.size() <= 3, "%s has 1-3 compact lines" % help_id)
		for compact_line in compact_lines:
			_assert(String(compact_line).length() <= 96, "%s compact line fits" % help_id)
			_assert(not String(compact_line).contains("C:\\Users\\"), "%s compact line has no local path" % help_id)
		for detail_line in Array(entry.get("detail_lines", [])):
			_assert(String(detail_line).length() <= 140, "%s detail line fits" % help_id)
			_assert(not String(detail_line).contains("C:\\Users\\"), "%s detail line has no local path" % help_id)
	for required_key in REQUIRED_SCREEN_AREAS:
		_assert(entry_keys.has(required_key), "Catalog has entry for %s" % required_key)


func _test_coverage_matrix(matrix_text: String) -> void:
	_assert(not matrix_text.is_empty(), "Playability coverage matrix exists")
	_assert(matrix_text.contains("Contextual Help Coverage"), "Matrix has contextual help section")
	for required_key in REQUIRED_SCREEN_AREAS:
		_assert(matrix_text.contains("`%s`" % required_key), "Matrix covers %s" % required_key)
	for token in ["help_catalog_schema", "help_global_button", "help_timing_contract", "help_layout_contract"]:
		_assert(matrix_text.contains(token), "Matrix covers %s" % token)
	_assert(matrix_text.contains("TASK_263"), "Matrix references TASK_263")


func _test_task_status(task_text: String) -> void:
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_263 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_263 checklist is complete")


func _required_area_keys(catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for item_variant in Array(catalog.get("required_screen_areas", [])):
		var item: Dictionary = Dictionary(item_variant)
		var screen_id: String = String(item.get("screen_id", ""))
		var area_id: String = String(item.get("area_id", ""))
		if not screen_id.is_empty() and not area_id.is_empty():
			result["%s.%s" % [screen_id, area_id]] = true
	return result


func _array_contains_all(values: Array, required_values: Array) -> bool:
	for required_value in required_values:
		if not values.has(required_value):
			return false
	return true


func _is_stable_help_id(value: String) -> bool:
	if value.is_empty() or value.begins_with(".") or value.ends_with("."):
		return false
	for character_index in range(value.length()):
		var code: int = value.unicode_at(character_index)
		var is_lower: bool = code >= 97 and code <= 122
		var is_number: bool = code >= 48 and code <= 57
		var is_separator: bool = code == 46 or code == 95
		if not (is_lower or is_number or is_separator):
			return false
	return value.find("..") < 0


func _read_catalog(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
