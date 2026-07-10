extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1038_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window.ps1"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.v1"
const LAUNCH_ARGUMENT := "--release-singleplayer-first-contact-preview"
const NEXT_TASK := "TASK_1039 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1038 Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_passed_slice_without_manifest_needs_capture()
	_test_good_manifest_is_review_ready()
	_test_completed_manual_checks_accept()
	_test_controller_exports_first_contact_real_window_capture()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1038_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture: FAILED")
		quit(1)
		return
	print("TASK_1038_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1038 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1038 first-contact real-window analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_1038 first-contact real-window capture tool exists")
	_assert(task_text.contains("TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture"), "Task names TASK_1038")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_1039 follow-up")
	_assert(status_text.contains("TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture"), "Implementation status tracks TASK_1038")
	_assert(roadmap_text.contains("TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture (implementiert"), "Roadmap marks TASK_1038 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture (TASK_1038)"), "Mission feedback contract documents TASK_1038")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture (TASK_1038)"), "Decision clarity contract documents TASK_1038")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_1038 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1038\""), "Analyzer writes TASK_1038 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1037\""), "Analyzer links TASK_1037")
	_assert(service_text.contains("REQUIRED_CAPTURE_CHECKS"), "Analyzer defines required capture checks")
	_assert(service_text.contains("\"read_only_capture\": true"), "Analyzer declares read-only capture")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer creates no multiplayer truth")
	_assert(tool_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.json"), "Capture tool writes TASK_1038 manifest")
	_assert(tool_text.contains(LAUNCH_ARGUMENT), "Capture tool uses first-contact deep-link")
	_assert(tool_text.contains("manual_review_done = $false"), "Capture tool does not auto-pass manual review")
	_assert(tool_text.contains("contact_surface_visible"), "Capture tool requires CONTACT surface")
	_assert(tool_text.contains("fire_wait_choice_visible"), "Capture tool requires FIRE/WAIT choice")
	_assert(tool_text.contains("feedback_line_visible"), "Capture tool requires feedback line")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Capture tool updates no shortcuts")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_FIRST_CONTACT_REAL_WINDOW_CAPTURE_SCRIPT"), "Controller preloads TASK_1038 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_snapshot"), "Controller exposes TASK_1038 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_window_screenshot_path"), "Command feedback exports TASK_1038 screenshot")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1038")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_first_contact_playability_not_passed"), "Missing source reports playability not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_passed_slice_without_manifest_needs_capture() -> void:
	var snapshot: Dictionary = _build_snapshot(_first_contact_playability_slice(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_first_contact_real_window_capture", "Passed slice without manifest needs capture")
	_assert(String(snapshot.get("gate", "")) == "needs_first_contact_real_window_capture_run", "Missing manifest gates capture run")
	_assert(issue_ids.has("first_contact_real_window_capture_manifest_missing"), "Missing manifest is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture", "Missing manifest loops on TASK_1038")
	_assert(_snapshot_is_read_only(snapshot), "Needs-run snapshot remains read-only")


func _test_good_manifest_is_review_ready() -> void:
	var snapshot: Dictionary = _build_snapshot(_first_contact_playability_slice(), _good_manifest(false))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1038")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1038", "Snapshot task id matches TASK_1038")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1037", "Snapshot links TASK_1037")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_1037 schema")
	_assert(String(snapshot.get("status", "")) == "review_ready", "Good manifest is review-ready")
	_assert(bool(snapshot.get("review_ready", false)), "Snapshot marks review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Snapshot does not auto-accept")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) > 0, "Manual checks remain missing")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_1039")
	_assert(String(snapshot.get("recommended_direction", "")) == "cut_first_contact_visual_findings", "Snapshot recommends visual findings")
	_assert(_snapshot_is_read_only(snapshot), "Good snapshot remains read-only")


func _test_completed_manual_checks_accept() -> void:
	var snapshot: Dictionary = _build_snapshot(_first_contact_playability_slice(), _good_manifest(true))
	_assert(String(snapshot.get("status", "")) == "accepted", "Completed manual checks accept TASK_1038")
	_assert(bool(snapshot.get("accepted", false)), "Accepted snapshot sets accepted flag")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) == 0, "No manual checks missing")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Accepted snapshot has no blockers")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Accepted snapshot has no issues")


func _test_controller_exports_first_contact_real_window_capture() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_snapshot"):
		_assert(false, "Controller exposes TASK_1038 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_snapshot(_first_contact_playability_slice(), _good_manifest(true))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1038 schema matches")
	_assert(String(snapshot.get("status", "")) == "accepted", "Controller TASK_1038 accepts with manifest")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1038 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture"), "Command feedback embeds TASK_1038")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_status"), "Command feedback exports TASK_1038 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_gate"), "Command feedback exports TASK_1038 gate")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_window_screenshot_path"), "Command feedback exports TASK_1038 screenshot")
	controller.queue_free()


func _test_manifest_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_first_contact_playability_slice(), _good_manifest(false))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1038 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1038", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1037", "Roundtrip keeps TASK_1037 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_playability_slice: Dictionary, manifest: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1038 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1038 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_playability_slice, manifest)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1038 service returns dictionary")
	return _read_only_fallback()


func _first_contact_playability_slice() -> Dictionary:
	var checks: Array = [
		"contact_line_readable",
		"why_actionable",
		"next_grip_readable",
		"fire_wait_choice_readable",
		"go_stays_separate",
		"feedback_returns_to_next",
		"hud_stays_calm",
		"performance_feels_responsive",
		"multiplayer_boundary_preserved",
		"no_gameplay_truth_mutation",
		"first_contact_feels_tactical",
	]
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1037",
		"source_task_id": "TASK_1036",
		"status": "first_contact_playability_slice_passed",
		"gate": "first_contact_playability_passed",
		"trace_available": true,
		"trace_id": "first_contact_playability_fixture",
		"completed_checks": checks,
		"missing_playability_checks": [],
		"first_contact_playability_line": "FIRST CONTACT PASS: CONTACT rund | WHY klar | NEXT bereit | GO separat | FIRE/WAIT lesbar",
		"first_contact_feedback_line": "FEEDBACK: Kontakt gelesen, NEXT wieder bereit.",
		"first_contact_playability_slice_passed": true,
		"ready_for_first_contact_real_window_capture": true,
		"recommended_next_task": "TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture",
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


func _good_manifest(accepted: bool) -> Dictionary:
	var required: Array = [
		"real_window_launched",
		"correct_window_content_confirmed",
		"window_capture_trusted",
		"window_screenshot_written",
		"contact_surface_visible",
		"why_surface_visible",
		"next_surface_visible",
		"fire_wait_choice_visible",
		"go_boundary_visible",
		"feedback_line_visible",
		"calm_hud_guidance_visible",
		"first_contact_playability_line_visible",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
		"manual_visual_review_done",
	]
	return {
		"schema": SCHEMA,
		"task_id": "TASK_1038",
		"source_task_id": "TASK_1037",
		"gate": "accepted" if accepted else "review_ready",
		"branch": "task/release-first-contact-real-window-capture",
		"git_head": "test",
		"launch_argument": LAUNCH_ARGUMENT,
		"source_schema": SOURCE_SCHEMA,
		"source_gate": "first_contact_playability_passed",
		"source_status": "first_contact_playability_slice_passed",
		"selected_process_id": 1038,
		"capture_process_id": 1038,
		"capture_after_first_contact_playability_slice_passed": true,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.png",
		"desktop_screenshot_path": "tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture_desktop.png",
		"hard_failures": [],
		"source_first_contact_playability_slice_snapshot": _first_contact_playability_slice(),
		"manual_review_required": true,
		"manual_review_done": accepted,
		"required_checks": required,
		"completed_manual_checks": required if accepted else [],
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _read_only_fallback() -> Dictionary:
	return {
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and bool(snapshot.get("read_only_capture", false)) \
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
