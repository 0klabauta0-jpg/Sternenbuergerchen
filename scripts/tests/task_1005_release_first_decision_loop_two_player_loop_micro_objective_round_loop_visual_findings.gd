extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1005_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.v1"
const NEXT_REVIEW_TASK := "TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings"
const NEXT_POLISH_TASK := "TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish"
const NEXT_PLAYABILITY_TASK := "TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1005 Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_review_ready_without_notes_needs_manual_review()
	_test_issue_notes_route_to_polish()
	_test_clean_notes_accept_for_playability_slice()
	_test_controller_exports_round_loop_visual_findings()
	_test_round_loop_visual_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1005_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_1005_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1005 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1005 visual findings service exists")
	_assert(task_text.contains("TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings"), "Task names TASK_1005")
	_assert(task_text.contains(NEXT_POLISH_TASK), "Task names round-loop visual polish follow-up")
	_assert(task_text.contains(NEXT_PLAYABILITY_TASK), "Task names round-loop playability follow-up")
	_assert(status_text.contains("TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings"), "Implementation status tracks TASK_1005")
	_assert(roadmap_text.contains("TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings (implementiert"), "Roadmap marks TASK_1005 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings (TASK_1005)"), "Mission feedback contract documents TASK_1005")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings (TASK_1005)"), "Decision clarity contract documents TASK_1005")
	_assert(service_text.contains(SCHEMA), "Round-loop findings service exposes stable TASK_1005 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1005\""), "Round-loop findings service writes TASK_1005 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1004\""), "Round-loop findings service links TASK_1004")
	_assert(service_text.contains("round_surface_visible"), "Round-loop findings service checks ROUND surface")
	_assert(service_text.contains("next_surface_visible"), "Round-loop findings service checks NEXT surface")
	_assert(service_text.contains("go_separation_visible"), "Round-loop findings service checks GO separation")
	_assert(service_text.contains("selected_fireteam_runtime_line_visible"), "Round-loop findings service checks Selected Fireteam runtime line")
	_assert(service_text.contains("mission_control_runtime_line_visible"), "Round-loop findings service checks Mission Control runtime line")
	_assert(service_text.contains("command_feedback_runtime_line_visible"), "Round-loop findings service checks Command Feedback runtime line")
	_assert(service_text.contains("player_round_loop_readable"), "Round-loop findings service checks player readability")
	_assert(service_text.contains("\"creates_command\": false"), "Round-loop findings service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Round-loop findings service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Round-loop findings service creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_LOOP_VISUAL_FINDINGS_SCRIPT"), "Controller preloads TASK_1005 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings_snapshot"), "Controller exposes TASK_1005 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings_status"), "Command feedback exports TASK_1005 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1005")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_review_ready"), "Missing source reports not review-ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked findings snapshot remains read-only")


func _test_review_ready_without_notes_needs_manual_review() -> void:
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_manual_review", "Review-ready round-loop source without notes needs manual review")
	_assert(issue_ids.has("manual_round_loop_visual_review_open"), "Manual round-loop review issue is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_REVIEW_TASK, "Open review loops on TASK_1005")
	_assert(String(snapshot.get("recommended_direction", "")) == "complete_manual_round_loop_window_review", "Open review recommends manual round-loop review")
	_assert(_snapshot_is_read_only(snapshot), "Needs-review snapshot remains read-only")


func _test_issue_notes_route_to_polish() -> void:
	var notes: Dictionary = _clean_review_notes()
	notes["round_surface_visible"] = false
	notes["next_surface_visible"] = false
	notes["go_separation_visible"] = false
	notes["player_round_loop_readable"] = false
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), notes)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "ready_for_round_loop_visual_polish", "Issue notes route to round-loop visual polish")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Issue notes recommend round-loop visual polish")
	_assert(issue_ids.has("round_surface_not_visible"), "Missing ROUND surface is named")
	_assert(issue_ids.has("next_surface_not_visible"), "Missing NEXT surface is named")
	_assert(issue_ids.has("go_separation_not_visible"), "Missing GO separation is named")
	_assert(issue_ids.has("player_round_loop_not_readable"), "Weak round-loop readability is named")
	_assert(int(snapshot.get("positive_finding_count", 0)) > 0, "Mixed review keeps positive findings")
	_assert(not bool(snapshot.get("accepted", true)), "Issue notes are not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Issue snapshot remains read-only")


func _test_clean_notes_accept_for_playability_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), _clean_review_notes())
	_assert(String(snapshot.get("status", "")) == "accepted_for_round_loop_playability_slice", "Clean notes accept TASK_1005")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_PLAYABILITY_TASK, "Clean notes recommend round-loop playability slice")
	_assert(bool(snapshot.get("accepted", false)), "Clean notes set accepted")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 10, "Clean notes produce positive findings")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_controller_exports_round_loop_visual_findings() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings_snapshot(_review_ready_source(), _clean_review_notes())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1005 schema matches")
	_assert(String(snapshot.get("status", "")) == "accepted_for_round_loop_playability_slice", "Controller TASK_1005 accepts with clean notes")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1005 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings"), "Command feedback embeds TASK_1005")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings_status"), "Command feedback exports TASK_1005 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings_issue_count"), "Command feedback exports TASK_1005 issue count")
	controller.queue_free()


func _test_round_loop_visual_findings_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), _clean_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1005 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1005", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1004", "Roundtrip keeps TASK_1004 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_PLAYABILITY_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1005 service is loadable")
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
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1005 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_snapshot, review_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1005 service returns dictionary")
	return {}


func _review_ready_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1004",
		"source_task_id": "TASK_1003",
		"source_schema": "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.v1",
		"source_status": "micro_objective_round_loop_runtime_polish_ready",
		"source_runtime_surface_spec_count": 3,
		"source_runtime_surface_specs": [
			{"surface_id": "round_loop_status_surface", "token": "ROUND", "text": "ROUND 2 abgeschlossen", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false},
			{"surface_id": "next_decision_surface", "token": "NEXT", "text": "Naechstes Micro-Ziel waehlen", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false},
			{"surface_id": "go_boundary_surface", "token": "GO", "text": "GO separat bestaetigen", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false},
		],
		"source_selected_fireteam_runtime_line": "ROUND 2 stabil | NEXT bereit",
		"source_mission_control_runtime_line": "NEXT Micro-Ziel waehlen | GO separat",
		"source_command_feedback_runtime_line": "ROUND LOOP: Feedback gelesen | GO separat bleibt",
		"source_runtime_lines_within_limit": true,
		"source_go_separation_visible": true,
		"source_next_decision_visible": true,
		"launch_argument": "--release-singleplayer-lz-drop-preview",
		"capture_after_round_loop_runtime_polish_ready": true,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/round_loop_real_window_capture.png",
		"desktop_screenshot_path": "tmp/round_loop_real_window_capture_desktop.png",
		"review_ready": true,
		"accepted": false,
		"status": "review_ready",
		"gate": "round_loop_real_window_capture_review_ready",
		"manual_review_required": true,
		"manual_review_done": false,
		"missing_manual_checks": ["manual_visual_review_done"],
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
		"manual_round_loop_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"round_surface_visible": true,
		"next_surface_visible": true,
		"go_separation_visible": true,
		"selected_fireteam_runtime_line_visible": true,
		"mission_control_runtime_line_visible": true,
		"command_feedback_runtime_line_visible": true,
		"player_round_loop_readable": true,
		"hud_read_only_boundary_ok": true,
		"no_new_hud_gameplay_truth": true,
		"multiplayer_boundary_preserved": true,
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
