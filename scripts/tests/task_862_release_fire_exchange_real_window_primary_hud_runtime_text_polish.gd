extends SceneTree

const RuntimeText := preload("res://scripts/mission/release_fire_exchange_real_window_primary_hud_runtime_text_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_862_release_fire_exchange_real_window_primary_hud_runtime_text_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const SUMMARY_REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_PATH := "res://scripts/meta/meta_layer_flow.gd"
const SERVICE_PATH := "res://scripts/mission/release_fire_exchange_real_window_primary_hud_runtime_text_polish.gd"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_runtime_text_polish.v1"
const STYLE_ID := "task_862_release_fire_exchange_real_window_primary_hud_runtime_text_v1"
const NEXT_TASK := "TASK_863 - Release Fire Exchange Runtime Text Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_862 Release Fire Exchange Real Window Primary HUD Runtime Text Polish ===")
	_test_docs_and_static_hooks()
	_test_runtime_text_moves_contact_fire_first()
	_test_snapshot_accepts_runtime_text()
	_test_snapshot_flags_missing_runtime_contact_fire()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_862_release_fire_exchange_real_window_primary_hud_runtime_text_polish: FAILED")
		quit(1)
		return
	print("TASK_862_release_fire_exchange_real_window_primary_hud_runtime_text_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var summary_report_text: String = _read_text(SUMMARY_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var meta_text: String = _read_text(META_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_862 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_862 runtime text service exists")
	_assert(task_text.contains("Release Fire Exchange Real Window Primary HUD Runtime Text Polish"), "Task names runtime text polish")
	_assert(status_text.contains("TASK_862 - Release Fire Exchange Real Window Primary HUD Runtime Text Polish"), "Implementation status tracks TASK_862")
	_assert(roadmap_text.contains("TASK_862 - Release Fire Exchange Real Window Primary HUD Runtime Text Polish (implementiert)"), "Roadmap marks TASK_862 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_863 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Real-Window-Primary-HUD-Runtime-Text-Polish"), "Contract documents TASK_862")
	_assert(summary_report_text.contains("TASK_862") and summary_report_text.contains("Runtime-Text"), "Spielstand report tracks TASK_862")
	_assert(service_text.contains(SCHEMA), "Service exposes TASK_862 schema")
	_assert(service_text.contains(STYLE_ID), "Service exposes TASK_862 style id")
	_assert(service_text.contains("build_runtime_text"), "Service exposes reusable build_runtime_text")
	_assert(controller_text.contains("RELEASE_FIRE_EXCHANGE_REAL_WINDOW_PRIMARY_HUD_RUNTIME_TEXT_POLISH_SCRIPT"), "Controller preloads TASK_862 service")
	_assert(controller_text.contains("_apply_release_fire_exchange_real_window_primary_hud_runtime_text"), "Controller applies runtime text to visible labels")
	_assert(controller_text.contains("get_release_fire_exchange_real_window_primary_hud_runtime_text_polish_snapshot"), "Controller exposes TASK_862 snapshot")
	_assert(meta_text.contains("get_release_fire_exchange_real_window_primary_hud_runtime_text_polish_snapshot"), "MetaLayer exposes TASK_862 wrapper")
	_assert(service_text.contains("\"creates_fire_event\": false"), "TASK_862 declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "TASK_862 declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "TASK_862 declares no multiplayer truth mutation")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "TASK_862 declares no shortcut updates")
	_assert(not _function_body_contains(CONTROLLER_PATH, "func _apply_release_fire_exchange_real_window_primary_hud_runtime_text", "get_tree().get_nodes"), "Runtime text helper avoids SceneTree full scans")


func _test_runtime_text_moves_contact_fire_first() -> void:
	var primary_line: String = _primary_line()
	var stale_text: String = "NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL\nKampf NO FIRE NO_LOS | F8/E8 | DET 0\nCONTACT PRESSURE | LOS korrigieren"
	var runtime_text: String = RuntimeText.build_runtime_text(stale_text, primary_line, "")
	_assert(runtime_text.begins_with(primary_line), "Runtime text prepends CONTACT FIRE before stale first line")
	_assert(runtime_text.contains("Kampf NO FIRE NO_LOS"), "Runtime text keeps NO FIRE as downstream detail")
	_assert(not _contains_no_fire_before_contact_fire(runtime_text), "Runtime text has no NO FIRE before CONTACT FIRE")
	var duplicate_text: String = "%s\nNEXT LOS/RANGE KORRIGIEREN\n%s" % [primary_line, primary_line]
	var deduped_text: String = RuntimeText.build_runtime_text(duplicate_text, primary_line, "")
	_assert(_count_substring(deduped_text, primary_line) == 1, "Runtime text de-duplicates existing CONTACT FIRE line")


func _test_snapshot_accepts_runtime_text() -> void:
	var snapshot: Dictionary = RuntimeText.build_snapshot(_good_runtime_fixture(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_862")
	_assert(String(snapshot.get("task_id", "")) == "TASK_862", "Snapshot task id is TASK_862")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_861", "Snapshot links TASK_861")
	_assert(String(snapshot.get("source_binding_task_id", "")) == "TASK_859", "Snapshot links TASK_859")
	_assert(String(snapshot.get("source_primary_hud_task_id", "")) == "TASK_856", "Snapshot links TASK_856")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Snapshot exposes TASK_862 style id")
	_assert(String(snapshot.get("status", "")) == "pass", "Snapshot passes CONTACT FIRE-first runtime text: %s" % JSON.stringify(snapshot.get("issues", [])))
	_assert(bool(snapshot.get("active", false)), "Snapshot is active during visibility persistence")
	_assert(bool(snapshot.get("selected_fireteam_runtime_text_contact_fire_first", false)), "#17 runtime text begins CONTACT FIRE")
	_assert(bool(snapshot.get("mission_control_runtime_text_contact_fire_first", false)), "#18 runtime text begins CONTACT FIRE")
	_assert(not bool(snapshot.get("primary_lines_contain_debug_no_fire_before_contact_fire", true)), "No debug NO FIRE before CONTACT FIRE")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_863 recapture")


func _test_snapshot_flags_missing_runtime_contact_fire() -> void:
	var fixture: Dictionary = _good_runtime_fixture()
	fixture["contact_fire_primary_line"] = ""
	var snapshot: Dictionary = RuntimeText.build_snapshot(fixture, {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "review", "Snapshot rejects missing runtime CONTACT FIRE source")
	_assert(issue_ids.has("primary_line_not_contact_fire"), "Snapshot flags missing CONTACT FIRE primary")
	_assert(issue_ids.has("selected_fireteam_runtime_text_not_contact_fire_first"), "Snapshot flags #17 runtime text")
	_assert(issue_ids.has("mission_control_runtime_text_not_contact_fire_first"), "Snapshot flags #18 runtime text")


func _good_runtime_fixture() -> Dictionary:
	var primary_line: String = _primary_line()
	var stale_selected: String = "NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL\nKampf NO FIRE NO_LOS | F8/E8 | DET 0"
	var stale_mission: String = "CONTACT PRESSURE | LOS korrigieren\nKampf NO FIRE NO_LOS"
	return {
		"active": true,
		"contact_fire_primary_line": primary_line,
		"raw_selected_fireteam_status_text": stale_selected,
		"raw_mission_control_status_text": stale_mission,
		"selected_fireteam_status_text": RuntimeText.build_runtime_text(stale_selected, primary_line, ""),
		"mission_control_status_text": RuntimeText.build_runtime_text(stale_mission, primary_line, ""),
		"combat_hud_density": {
			"active": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"visibility_persistence_active": true,
			"compact_line": "FIRE alpha_1>enemy_1 | COV PART RNG OK LOS CLR FLK SIDE",
			"visibility_persistence": {
				"active": true,
				"compact_line": "FIRE alpha_1>enemy_1 | COV PART RNG OK LOS CLR FLK SIDE",
			},
		},
	}


func _primary_line() -> String:
	return "CONTACT FIRE | FIRE alpha_1>enemy_1 | COV PART RNG OK LOS CLR FLK SIDE"


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) != TYPE_DICTIONARY:
			continue
		result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _contains_no_fire_before_contact_fire(text: String) -> bool:
	var upper: String = text.to_upper()
	var contact_index: int = upper.find("CONTACT FIRE")
	var no_fire_index: int = upper.find("NO FIRE")
	return no_fire_index >= 0 and (contact_index < 0 or no_fire_index < contact_index)


func _count_substring(text: String, needle: String) -> int:
	if needle.is_empty():
		return 0
	var count: int = 0
	var offset: int = 0
	while true:
		var found: int = text.find(needle, offset)
		if found < 0:
			break
		count += 1
		offset = found + needle.length()
	return count


func _function_body_contains(path: String, function_name: String, needle: String) -> bool:
	var text: String = _read_text(path)
	var start: int = text.find(function_name)
	if start < 0:
		return false
	var next_func: int = text.find("\nfunc ", start + function_name.length())
	var body: String = text.substr(start) if next_func < 0 else text.substr(start, next_func - start)
	return body.contains(needle)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
