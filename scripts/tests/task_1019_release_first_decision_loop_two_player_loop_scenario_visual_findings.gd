extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1019_release_first_decision_loop_two_player_loop_scenario_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_visual_findings.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_visual_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_real_window_capture.v1"
const NEXT_POLISH_TASK := "TASK_1020 - Release First Decision Loop Two Player Loop Scenario Visual Polish"
const NEXT_ACCEPTANCE_TASK := "TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1019 Release First Decision Loop Two Player Loop Scenario Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_review_ready_without_notes_needs_manual_review()
	_test_issue_notes_route_to_polish()
	_test_clean_notes_accept_for_acceptance_slice()
	_test_controller_exports_scenario_visual_findings()
	_test_visual_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1019_release_first_decision_loop_two_player_loop_scenario_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_1019_release_first_decision_loop_two_player_loop_scenario_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var feedback_source_text: String = _read_text("res://scripts/mission/diagnostics/mission_command_feedback_diagnostics.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1019 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1019 visual findings service exists")
	_assert(task_text.contains("TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings"), "Task names TASK_1019")
	_assert(task_text.contains(NEXT_POLISH_TASK), "Task names scenario visual polish follow-up")
	_assert(task_text.contains(NEXT_ACCEPTANCE_TASK), "Task names scenario acceptance follow-up")
	_assert(status_text.contains("TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings"), "Implementation status tracks TASK_1019")
	_assert(roadmap_text.contains("TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings (implementiert"), "Roadmap marks TASK_1019 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Visual Findings (TASK_1019)"), "Mission feedback contract documents TASK_1019")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Visual Findings (TASK_1019)"), "Decision clarity contract documents TASK_1019")
	_assert(service_text.contains(SCHEMA), "Scenario visual findings service exposes stable TASK_1019 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1019\""), "Scenario visual findings service writes TASK_1019 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1018\""), "Scenario visual findings service links TASK_1018")
	_assert(service_text.contains("fob_entry_surface_visible"), "Scenario visual findings checks FOB entry")
	_assert(service_text.contains("feedback_line_visible"), "Scenario visual findings checks feedback")
	_assert(service_text.contains("multiplayer_boundary_preserved"), "Scenario visual findings checks multiplayer boundary")
	_assert(service_text.contains("\"creates_command\": false"), "Scenario visual findings creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Scenario visual findings creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Scenario visual findings creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_VISUAL_FINDINGS_SCRIPT"), "Controller preloads TASK_1019 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_visual_findings_snapshot"), "Controller exposes TASK_1019 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_visual_findings_status"), "Command feedback exports TASK_1019 status")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_visual_findings_issue_count"), "Command feedback exports TASK_1019 issue count")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1019")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_review_ready"), "Missing source reports not review-ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_review_ready_without_notes_needs_manual_review() -> void:
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_manual_review", "Review-ready source without notes needs manual review")
	_assert(issue_ids.has("manual_scenario_visual_review_open"), "Manual scenario review issue is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings", "Open review loops on TASK_1019")
	_assert(String(snapshot.get("recommended_direction", "")) == "complete_manual_scenario_window_review", "Open review recommends manual review")
	_assert(_snapshot_is_read_only(snapshot), "Needs-review snapshot remains read-only")


func _test_issue_notes_route_to_polish() -> void:
	var notes: Dictionary = _clean_review_notes()
	notes["roles_surface_visible"] = false
	notes["feedback_line_visible"] = false
	notes["player_readability_ok"] = false
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), notes)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "ready_for_scenario_visual_polish", "Issue notes route to scenario polish")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Issue notes recommend scenario visual polish")
	_assert(issue_ids.has("roles_surface_not_visible"), "Missing roles surface is named")
	_assert(issue_ids.has("feedback_line_not_visible"), "Missing feedback line is named")
	_assert(issue_ids.has("player_readability_not_ok"), "Weak player readability is named")
	_assert(int(snapshot.get("positive_finding_count", 0)) > 0, "Mixed review keeps positive findings")
	_assert(not bool(snapshot.get("accepted", true)), "Issue notes are not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Issue snapshot remains read-only")


func _test_clean_notes_accept_for_acceptance_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), _clean_review_notes())
	_assert(String(snapshot.get("status", "")) == "accepted_for_scenario_acceptance_slice", "Clean notes accept TASK_1019")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_ACCEPTANCE_TASK, "Clean notes recommend scenario acceptance slice")
	_assert(bool(snapshot.get("accepted", false)), "Clean notes set accepted")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 12, "Clean notes produce positive findings")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_controller_exports_scenario_visual_findings() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_visual_findings_snapshot"):
		_assert(false, "Controller exposes TASK_1019 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_visual_findings_snapshot(_review_ready_source(), _clean_review_notes())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1019 schema matches")
	_assert(String(snapshot.get("status", "")) == "accepted_for_scenario_acceptance_slice", "Controller TASK_1019 accepts with clean notes")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1019 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_visual_findings"), "Command feedback embeds TASK_1019")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_visual_findings_status"), "Command feedback exports TASK_1019 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_visual_findings_issue_count"), "Command feedback exports TASK_1019 issue count")
	controller.queue_free()


func _test_visual_findings_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), _clean_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1019 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1019", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1018", "Roundtrip keeps TASK_1018 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_ACCEPTANCE_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_capture: Dictionary, review_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1019 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1019 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_capture, review_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1019 service returns dictionary")
	return _read_only_fallback()


func _review_ready_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1018",
		"source_task_id": "TASK_1017",
		"source_schema": "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_playability_slice.v1",
		"source_gate": "scenario_playability_passed",
		"source_status": "scenario_playability_slice_passed",
		"source_scenario_playability_line": "SCENARIO PASS: FOB rund | Rollen klar | NEXT bereit | GO separat | FEEDBACK gelesen",
		"source_scenario_playability_slice_passed": true,
		"manifest_available": true,
		"launch_argument": "--release-singleplayer-lz-drop-preview",
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_decision_loop_two_player_loop_scenario_real_window_capture.png",
		"desktop_screenshot_path": "tmp/release_first_decision_loop_two_player_loop_scenario_real_window_capture_desktop.png",
		"review_ready": true,
		"accepted": false,
		"status": "review_ready",
		"gate": "scenario_real_window_capture_review_ready",
		"missing_manual_check_count": 15,
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


func _clean_review_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"fob_entry_surface_visible": true,
		"objective_surface_visible": true,
		"roles_surface_visible": true,
		"next_confirm_go_flow_visible": true,
		"go_boundary_visible": true,
		"feedback_line_visible": true,
		"calm_hud_guidance_visible": true,
		"scenario_playability_line_visible": true,
		"fob_entry_surface_readable": true,
		"objective_surface_readable": true,
		"roles_surface_readable": true,
		"next_confirm_go_flow_readable": true,
		"feedback_line_readable": true,
		"no_new_hud_gameplay_truth": true,
		"multiplayer_boundary_preserved": true,
		"player_readability_ok": true,
	}


func _read_only_fallback() -> Dictionary:
	return {
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


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
