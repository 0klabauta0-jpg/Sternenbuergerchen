extends SceneTree

const Smoke := preload("res://scripts/mission/release_first_decision_loop_two_playability_smoke.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_972_release_first_decision_loop_two_playability_smoke.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_playability_smoke.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_playability_smoke_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_playability_smoke.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_visual_polish.v1"
const NEXT_TASK := "TASK_973 - Release First Decision Loop Two Real Window Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_972 Release First Decision Loop Two Playability Smoke ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_smoke_run()
	_test_failed_trace_routes_to_polish()
	_test_good_trace_passes_playability_smoke()
	_test_controller_exports_playability_smoke()
	_test_smoke_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_972_release_first_decision_loop_two_playability_smoke: FAILED")
		quit(1)
		return
	print("TASK_972_release_first_decision_loop_two_playability_smoke: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_972 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_972 playability smoke service exists")
	_assert(task_text.contains("TASK_972 - Release First Decision Loop Two Playability Smoke"), "Task names TASK_972")
	_assert(task_text.contains(NEXT_TASK), "Task names real-window follow-up")
	_assert(status_text.contains("TASK_972 - Release First Decision Loop Two Playability Smoke"), "Implementation status tracks TASK_972")
	_assert(roadmap_text.contains("TASK_972 - Release First Decision Loop Two Playability Smoke (implementiert"), "Roadmap marks TASK_972 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Playability Smoke (TASK_972)"), "Mission feedback contract documents TASK_972")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Playability Smoke (TASK_972)"), "Decision clarity contract documents TASK_972")
	_assert(service_text.contains(SCHEMA), "Smoke service exposes stable TASK_972 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_972\""), "Smoke service writes TASK_972 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_971\""), "Smoke service links TASK_971")
	_assert(service_text.contains("REQUIRED_SMOKE_CHECKS"), "Smoke service defines required checks")
	_assert(service_text.contains("\"read_only\": true"), "Smoke service declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Smoke service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Smoke service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Smoke service creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYABILITY_SMOKE_SCRIPT"), "Controller preloads TASK_972 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_playability_smoke_snapshot"), "Controller exposes TASK_972 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_playability_smoke_line"), "Command feedback exports TASK_972 line")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Smoke.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_972")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports ready mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_ready_source_without_trace_needs_smoke_run() -> void:
	var snapshot: Dictionary = Smoke.build_snapshot(_visual_polish(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_playability_smoke_run", "Ready source without trace needs smoke run")
	_assert(String(snapshot.get("gate", "")) == "needs_loop_two_playability_smoke_run", "Missing trace gates smoke run")
	_assert(issue_ids.has("playability_trace_missing"), "Missing trace issue is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_972 - Release First Decision Loop Two Playability Smoke", "Missing trace loops on TASK_972")
	_assert(_snapshot_is_read_only(snapshot), "Needs-run snapshot remains read-only")


func _test_failed_trace_routes_to_polish() -> void:
	var snapshot: Dictionary = Smoke.build_snapshot(_visual_polish(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "loop_two_playability_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "loop_two_playability_regression_found", "Failed trace gate names regression")
	_assert(issue_ids.has("go_not_executed"), "Failed trace names missing GO")
	_assert(issue_ids.has("post_go_feedback_missing"), "Failed trace names missing feedback")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_971 - Release First Decision Loop Two Visual Polish", "Failed trace routes back to polish")
	_assert(_snapshot_is_read_only(snapshot), "Failed trace remains read-only")


func _test_good_trace_passes_playability_smoke() -> void:
	var snapshot: Dictionary = Smoke.build_snapshot(_visual_polish(), _good_trace())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_972")
	_assert(String(snapshot.get("task_id", "")) == "TASK_972", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_971", "Snapshot links TASK_971")
	_assert(String(snapshot.get("status", "")) == "loop_two_playability_smoke_passed", "Good trace passes smoke")
	_assert(String(snapshot.get("gate", "")) == "loop_two_playability_smoke_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("playability_smoke_passed", false)), "Good trace sets pass flag")
	_assert(String(snapshot.get("smoke_line", "")).contains("2ND"), "Smoke line names 2ND")
	_assert(String(snapshot.get("smoke_line", "")).contains("GO"), "Smoke line names GO")
	_assert(String(snapshot.get("post_go_feedback_line", "")).contains("Feedback"), "Post-GO feedback is retained")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Good trace recommends real-window recapture")
	_assert(_snapshot_is_read_only(snapshot), "Good trace remains read-only")


func _test_controller_exports_playability_smoke() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_playability_smoke_snapshot(_visual_polish(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_972 schema matches")
	_assert(String(snapshot.get("status", "")) == "loop_two_playability_smoke_passed", "Controller TASK_972 can pass with trace")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_972 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_playability_smoke"), "Command feedback embeds TASK_972")
	_assert(String(feedback.get("release_first_decision_loop_two_playability_smoke_line", "")).contains("2ND"), "Command feedback exports TASK_972 line")
	controller.queue_free()


func _test_smoke_roundtrip() -> void:
	var snapshot: Dictionary = Smoke.build_snapshot(_visual_polish(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_972 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_972", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_971", "Roundtrip keeps TASK_971 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _visual_polish() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_971",
		"source_task_id": "TASK_970",
		"runtime_task_id": "TASK_968",
		"status": "visual_polish_ready",
		"active": true,
		"button_enabled": true,
		"button_text": "2ND",
		"hud_line": "2ND HOLD -> Defend vorbereiten | danach GO separat",
		"go_separation_line": "GO bleibt separat: 2ND bestaetigt nur den zweiten Griff.",
		"post_confirm_line": "Nach 2ND: Defend ist vorbereitet, danach GO druecken.",
		"recommended_next_task": "TASK_972 - Release First Decision Loop Two Playability Smoke",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _good_trace() -> Dictionary:
	var checks: Array = [
		"second_decision_button_visible",
		"second_decision_confirmed",
		"go_button_still_separate",
		"go_executed_after_confirm",
		"post_go_feedback_visible",
		"no_go_before_second_confirm",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
	]
	return {
		"trace_available": true,
		"completed_checks": checks,
		"second_decision_button_visible": true,
		"second_decision_confirmed": true,
		"go_button_still_separate": true,
		"go_executed_after_confirm": true,
		"post_go_feedback_visible": true,
		"post_go_feedback_line": "Feedback: zweiter Griff vorbereitet, GO ausgefuehrt.",
		"no_go_before_second_confirm": true,
		"no_new_hud_gameplay_truth": true,
		"multiplayer_boundary_preserved": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["completed_checks"] = ["second_decision_button_visible", "second_decision_confirmed", "go_button_still_separate"]
	trace["go_executed_after_confirm"] = false
	trace["post_go_feedback_visible"] = false
	trace["post_go_feedback_line"] = ""
	return trace


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
