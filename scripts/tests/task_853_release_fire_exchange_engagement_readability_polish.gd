extends SceneTree

const Readability := preload("res://scripts/mission/release_fire_exchange_engagement_readability_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_853_release_fire_exchange_engagement_readability_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SERVICE_PATH := "res://scripts/mission/release_fire_exchange_engagement_readability_polish.gd"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_engagement_readability_polish.v1"
const STYLE_ID := "task_853_release_fire_exchange_engagement_readability_v1"
const NEXT_TASK := "TASK_854 - Release Fire Exchange Focused Recapture After Readability Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_853 Release Fire Exchange Engagement Readability Polish ===")
	_test_docs_and_static_hooks()
	await _test_meta_layer_engagement_readability_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_853_release_fire_exchange_engagement_readability_polish: FAILED")
		quit(1)
		return
	print("TASK_853_release_fire_exchange_engagement_readability_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_853 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_853 read-only analyzer exists")
	_assert(task_text.contains("Release Fire Exchange Engagement Readability Polish"), "Task names engagement readability polish")
	_assert(status_text.contains("TASK_853 - Release Fire Exchange Engagement Readability Polish"), "Implementation status tracks TASK_853")
	_assert(roadmap_text.contains("TASK_853 - Release Fire Exchange Engagement Readability Polish (implementiert)"), "Roadmap marks TASK_853 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_854 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Engagement-Readability-Polish"), "Contract documents TASK_853")
	_assert(report_text.contains("TASK_853") and report_text.contains("45s"), "HTML report tracks TASK_853")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes TASK_853 schema")
	_assert(service_text.contains(STYLE_ID), "Analyzer exposes TASK_853 style id")
	_assert(controller_text.contains("RELEASE_FIRE_EXCHANGE_VISIBILITY_PERSISTENCE_MSEC: int = 45000"), "Persistence window covers real capture delay")
	_assert(service_text.contains("\"creates_fire_event\": false"), "TASK_853 declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "TASK_853 declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "TASK_853 declares no multiplayer truth mutation")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "TASK_853 declares no shortcut updates")


func _test_meta_layer_engagement_readability_polish() -> void:
	var source: Dictionary = _focused_visual_fixture()
	var snapshot: Dictionary = Readability.build_snapshot(source, {})
	var primary_text: String = String(snapshot.get("primary_lines_text", "")).strip_edges()
	if String(snapshot.get("status", "")) != "pass":
		print("TASK_853_DIAGNOSTIC %s" % JSON.stringify({
			"issues": snapshot.get("issues", []),
			"primary_lines_text": primary_text,
			"compact_line": snapshot.get("compact_line", ""),
			"event_log_short_text": snapshot.get("event_log_short_text", ""),
			"persistence_duration_msec": snapshot.get("persistence_duration_msec", 0),
			"source_gate": snapshot.get("source_focus_gate", ""),
			"source_visibility_gate": snapshot.get("source_visibility_gate", ""),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Analyzer snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_853", "Analyzer snapshot task id is TASK_853")
	_assert(String(snapshot.get("status", "")) == "pass", "TASK_853 gate passes: %s" % JSON.stringify(snapshot.get("issues", [])))
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Analyzer snapshot exposes TASK_853 style id")
	_assert(bool(snapshot.get("active", false)), "Engagement readability is active")
	_assert(int(snapshot.get("persistence_duration_msec", 0)) >= 42000, "Persistence window covers real capture delay")
	_assert(String(snapshot.get("compact_line", "")).to_upper().begins_with("FIRE"), "Compact line starts with FIRE")
	_assert(String(snapshot.get("event_log_short_text", "")).contains("CONTACT FIRE"), "Event log names CONTACT FIRE")
	_assert(bool(snapshot.get("surfaces_share_contact_fire", false)), "#17 #18 #19 share contact fire status")
	_assert(not bool(snapshot.get("primary_lines_contain_no_fire", true)), "Primary lines hide debug NO FIRE")
	_assert(not primary_text.to_upper().contains("NO FIRE"), "Primary text does not contain NO FIRE")
	_assert(bool(snapshot.get("read_only", false)), "Analyzer snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Analyzer snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Analyzer snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Analyzer snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Analyzer snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Analyzer snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Analyzer snapshot updates no shortcuts")


func _focused_visual_fixture() -> Dictionary:
	var visibility: Dictionary = {
		"schema": "sternenbuergerchen.release_fire_exchange_visibility_persistence.v1",
		"task_id": "TASK_847",
		"gate": "pass",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"compact_line": "FIRE alpha_1>enemy_1 | COV PART | LOS CLR | RNG OK",
		"selected_fireteam_line": "Kampf FIRE alpha_1>enemy_1 | COV PART | LOS CLR | RNG OK",
		"mission_control_line": "FIRE alpha_1>enemy_1 | COV PART | LOS CLR | RNG OK",
		"decision_line": "NEXT HIT LESEN / DEFEND | WHY FEUER",
		"event_log_short_text": "CONTACT FIRE: Feuerwechsel lesen",
		"fire_event_id": "fire_001",
		"duration_msec": 45000,
		"visibility_persistence": {
			"active": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
			"sets_multiplayer_truth": false,
			"fire_event_id": "fire_001",
			"duration_msec": 45000,
		},
		"event_log_display": {
			"entries": [
				{
					"short_text": "CONTACT FIRE: Feuerwechsel lesen",
					"map_label": "CONTACT FIRE",
				}
			]
		}
	}
	return {
		"schema": "sternenbuergerchen.release_fire_exchange_focused_visual_polish.v1",
		"task_id": "TASK_850",
		"status": "pass",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"tactical_focus": {
			"gate": "pass",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"source": visibility,
		}
	}


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
