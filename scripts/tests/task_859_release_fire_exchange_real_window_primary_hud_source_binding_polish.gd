extends SceneTree

const SourceBinding := preload("res://scripts/mission/release_fire_exchange_real_window_primary_hud_source_binding_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_859_release_fire_exchange_real_window_primary_hud_source_binding_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const SUMMARY_REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_PATH := "res://scripts/meta/meta_layer_flow.gd"
const SERVICE_PATH := "res://scripts/mission/release_fire_exchange_real_window_primary_hud_source_binding_polish.gd"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_real_window_primary_hud_source_binding_polish.v1"
const STYLE_ID := "task_859_release_fire_exchange_real_window_primary_hud_source_binding_v1"
const NEXT_TASK := "TASK_860 - Release Fire Exchange Real Window Contact-Fire Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_859 Release Fire Exchange Real Window Primary HUD Source Binding Polish ===")
	_test_docs_and_static_hooks()
	_test_binding_moves_contact_fire_before_stale_no_fire()
	_test_snapshot_accepts_bound_real_window_text()
	_test_snapshot_flags_missing_binding()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_859_release_fire_exchange_real_window_primary_hud_source_binding_polish: FAILED")
		quit(1)
		return
	print("TASK_859_release_fire_exchange_real_window_primary_hud_source_binding_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var summary_report_text: String = _read_text(SUMMARY_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var meta_text: String = _read_text(META_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_859 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_859 source-binding service exists")
	_assert(task_text.contains("Release Fire Exchange Real Window Primary HUD Source Binding Polish"), "Task names real-window source binding polish")
	_assert(status_text.contains("TASK_859 - Release Fire Exchange Real Window Primary HUD Source Binding Polish"), "Implementation status tracks TASK_859")
	_assert(roadmap_text.contains("TASK_859 - Release Fire Exchange Real Window Primary HUD Source Binding Polish (implementiert)"), "Roadmap marks TASK_859 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_860 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Real-Window-Primary-HUD-Source-Binding-Polish"), "Contract documents TASK_859")
	_assert(report_text.contains("TASK_859") and report_text.contains("Source-Binding"), "Fire-exchange report tracks TASK_859")
	_assert(summary_report_text.contains("TASK_859") and summary_report_text.contains("TASK_860"), "Spielstand report tracks TASK_859 and TASK_860")
	_assert(service_text.contains(SCHEMA), "Service exposes TASK_859 schema")
	_assert(service_text.contains(STYLE_ID), "Service exposes TASK_859 style id")
	_assert(service_text.contains("bind_status_text"), "Service exposes reusable bind_status_text")
	_assert(controller_text.contains("RELEASE_FIRE_EXCHANGE_REAL_WINDOW_PRIMARY_HUD_SOURCE_BINDING_POLISH_SCRIPT"), "Controller preloads TASK_859 service")
	_assert(controller_text.contains("_bind_release_fire_exchange_real_window_primary_hud_text"), "Controller binds real-window HUD text")
	_assert(controller_text.contains("get_release_fire_exchange_real_window_primary_hud_source_binding_polish_snapshot"), "Controller exposes TASK_859 snapshot")
	_assert(meta_text.contains("get_release_fire_exchange_real_window_primary_hud_source_binding_polish_snapshot"), "MetaLayer exposes TASK_859 wrapper")
	_assert(service_text.contains("\"creates_fire_event\": false"), "TASK_859 declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "TASK_859 declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "TASK_859 declares no multiplayer truth mutation")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "TASK_859 declares no shortcut updates")
	_assert(not _function_body_contains(CONTROLLER_PATH, "func _bind_release_fire_exchange_real_window_primary_hud_text", "get_tree().get_nodes"), "Binding helper avoids SceneTree full scans")


func _test_binding_moves_contact_fire_before_stale_no_fire() -> void:
	var primary_line: String = _primary_line()
	var stale_text: String = "NO FIRE NO_LOS | F8/E8 | DET 0\nCONTACT PRESSURE | LOS korrigieren"
	var bound_text: String = SourceBinding.bind_status_text(stale_text, primary_line, "")
	_assert(bound_text.begins_with(primary_line), "Binding prepends CONTACT FIRE before stale NO FIRE")
	_assert(bound_text.contains("NO FIRE NO_LOS"), "Binding keeps stale NO FIRE as downstream detail")
	_assert(not _contains_no_fire_before_contact_fire(bound_text), "Bound text has no NO FIRE before CONTACT FIRE")
	var duplicate_text: String = "%s\nNO FIRE NO_LOS | F8/E8 | DET 0\n%s" % [primary_line, primary_line]
	var deduped_text: String = SourceBinding.bind_status_text(duplicate_text, primary_line, "")
	_assert(_count_substring(deduped_text, primary_line) == 1, "Binding de-duplicates existing primary line")


func _test_snapshot_accepts_bound_real_window_text() -> void:
	var snapshot: Dictionary = SourceBinding.build_snapshot(_good_binding_fixture(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_859")
	_assert(String(snapshot.get("task_id", "")) == "TASK_859", "Snapshot task id is TASK_859")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_858", "Snapshot links TASK_858")
	_assert(String(snapshot.get("source_primary_hud_task_id", "")) == "TASK_856", "Snapshot links TASK_856")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Snapshot exposes TASK_859 style id")
	_assert(String(snapshot.get("status", "")) == "pass", "Snapshot passes bound CONTACT FIRE real-window text: %s" % JSON.stringify(snapshot.get("issues", [])))
	_assert(bool(snapshot.get("active", false)), "Snapshot is active during visibility persistence")
	_assert(bool(snapshot.get("selected_fireteam_real_window_bound_to_contact_fire", false)), "#17 is bound to CONTACT FIRE")
	_assert(bool(snapshot.get("mission_control_real_window_bound_to_contact_fire", false)), "#18 is bound to CONTACT FIRE")
	_assert(not bool(snapshot.get("primary_lines_contain_debug_no_fire_before_contact_fire", true)), "No debug NO FIRE before CONTACT FIRE")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_860 recapture")


func _test_snapshot_flags_missing_binding() -> void:
	var fixture: Dictionary = _good_binding_fixture()
	fixture["contact_fire_primary_line"] = ""
	var snapshot: Dictionary = SourceBinding.build_snapshot(fixture, {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "review", "Snapshot rejects missing primary source")
	_assert(issue_ids.has("primary_line_not_contact_fire"), "Snapshot flags missing CONTACT FIRE source")
	_assert(issue_ids.has("selected_fireteam_not_bound_to_primary_line"), "Snapshot flags #17 missing binding")
	_assert(issue_ids.has("mission_control_not_bound_to_primary_line"), "Snapshot flags #18 missing binding")


func _good_binding_fixture() -> Dictionary:
	var compact_line: String = "FIRE alpha_1>enemy_1 | COV PART RNG OK LOS CLR FLK SIDE"
	var primary_line: String = _primary_line()
	return {
		"active": true,
		"contact_fire_primary_line": primary_line,
		"raw_selected_fireteam_status_text": "NO FIRE NO_LOS | F8/E8 | DET 0\nFT1 | Karten 4",
		"raw_mission_control_status_text": "CONTACT PRESSURE | LOS korrigieren\nKampf NO FIRE NO_LOS",
		"selected_fireteam_status_text": SourceBinding.bind_status_text("NO FIRE NO_LOS | F8/E8 | DET 0\nFT1 | Karten 4", primary_line, ""),
		"mission_control_status_text": SourceBinding.bind_status_text("CONTACT PRESSURE | LOS korrigieren\nKampf NO FIRE NO_LOS", primary_line, ""),
		"combat_hud_density": {
			"active": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"visibility_persistence_active": true,
			"compact_line": compact_line,
			"visibility_persistence": {
				"active": true,
				"read_only": true,
				"ui_sets_gameplay_truth": false,
				"creates_command": false,
				"creates_fire_event": false,
				"creates_damage_event": false,
				"sets_multiplayer_truth": false,
				"compact_line": compact_line,
			}
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
