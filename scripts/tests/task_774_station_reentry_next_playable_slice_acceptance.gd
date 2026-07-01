extends SceneTree

const ACCEPTANCE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_next_playable_slice_acceptance.gd")
const IDENTITY_CUE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_host_client_fireteam_card_context.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_774_station_reentry_next_playable_slice_acceptance.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_774 Station Reentry Next Playable Slice Acceptance ===")
	_test_docs_contract_and_report()
	_test_missing_gates_block_acceptance()
	_test_all_but_capture_routes_to_recapture()
	_test_complete_gates_accept_slice()
	_test_identity_cue_failure_routes_back_to_task_773()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_774: FAILED")
		quit(1)
		return
	print("TASK_774: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_774 task file exists")
	_assert(task_text.contains("Station Reentry Next Playable Slice Acceptance"), "TASK_774 task names next playable slice acceptance")
	_assert(status_text.contains("TASK_774 - Station Reentry Next Playable Slice Acceptance"), "Implementation status tracks TASK_774")
	_assert(roadmap_text.contains("TASK_774 - Station Reentry Next Playable Slice Acceptance (implementiert)"), "Roadmap marks TASK_774 implemented")
	_assert(contract_text.contains("Station-Reentry-Next-Playable-Slice-Acceptance"), "Mission command feedback contract documents TASK_774")
	_assert(report_text.contains("Aktueller Griff: TASK_783"), "Reentry handbook advances to TASK_783 current")
	_assert(report_text.contains('data-export-key="reentry_acceptance.accepted_for_next_playable_slice"'), "Reentry handbook exports TASK_774 acceptance")


func _test_missing_gates_block_acceptance() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_next_playable_slice_acceptance.v1", "Acceptance schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_reentry_gates_green", "Missing inputs block acceptance")
	_assert(not bool(snapshot.get("accepted_for_next_playable_slice", true)), "Missing inputs are not accepted")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("first_preview_before_go"), "Missing preview gate is reported")
	_assert(_snapshot_is_read_only(snapshot), "Missing-gates snapshot remains read-only")


func _test_all_but_capture_routes_to_recapture() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs.erase("real_capture")
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_reentry_recapture", "Missing only real capture routes to recapture")
	_assert(Array(snapshot.get("failed_gate_ids", [])) == ["real_capture_written"], "Only capture gate is missing")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("rerun short Host/Client"), "Recapture status recommends short Host/Client rerun")
	_assert(not bool(snapshot.get("accepted_for_next_playable_slice", true)), "Missing capture is not accepted")


func _test_complete_gates_accept_slice() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _complete_inputs()))
	_assert(String(snapshot.get("status", "")) == "accepted_for_next_playable_slice", "Complete gates accept slice")
	_assert(bool(snapshot.get("accepted_for_next_playable_slice", false)), "Accepted flag is true")
	_assert(bool(snapshot.get("ready_for_next_design_slice", false)), "Accepted slice is ready for next design slice")
	_assert(String(snapshot.get("accepted_scope", "")) == "station_reentry_next_playable_slice_only", "Acceptance scope is narrow")
	_assert(bool(snapshot.get("not_full_game_acceptance", false)), "Acceptance is not a full game acceptance")
	_assert(Array(snapshot.get("failed_gate_ids", [])).is_empty(), "Accepted slice has no failed gates")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_775"), "Accepted slice routes to TASK_775")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_identity_cue_failure_routes_back_to_task_773() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs["identity_cue"] = {"schema": "wrong", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false}
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_identity_cue_polish", "Identity cue failure routes to identity polish")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("identity_cue"), "Identity cue gate is failed")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_773"), "Identity cue failure recommends TASK_773")


func _complete_inputs() -> Dictionary:
	return {
		"preview": {
			"task_id": "TASK_768",
			"preview_gate_ok": true,
			"station_context_ok": true,
			"selected_order_text": "WP 1/1 MOVE | WARTET AUF GO | PREVIEW Dist 120m | ETA~2s | RISK ? no intel",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
		},
		"performance": {
			"task_id": "TASK_769",
			"performance_gate": "pass",
			"ready_for_visible_playtest": true,
			"repeated_snapshot_budget_ok": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
		},
		"host_client_sync": {
			"task_id": "TASK_770",
			"sync_gate": "pass",
			"same_next_order": true,
			"same_route_line": true,
			"same_cue_line": true,
			"peer_context_distinct": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
		},
		"export_findings": {
			"task_id": "TASK_772",
			"status": "ready_for_next_station_iteration",
			"active_issue_count": 0,
			"missing_check_ids": [],
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
		},
		"identity_cue": Dictionary(IDENTITY_CUE_SCRIPT.call("build_context", {
			"role_label": "CLIENT",
			"peer_label": "P2",
			"team_id": "team_bravo",
			"team_label": "BRAVO",
		}, {
			"fireteam_id": "blue",
			"fireteam_team_id": "team_alpha",
			"fireteam_team_label": "ALPHA",
		})),
		"real_capture": {
			"schema": "sternenbuergerchen.host_client_two_window_real_run_review.v1",
			"launch_requested": true,
			"real_run_done": true,
			"screenshot_written": true,
			"host_screenshot_written": true,
			"client_screenshot_written": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
