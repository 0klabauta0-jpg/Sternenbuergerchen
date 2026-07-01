extends SceneTree

const ACCEPTANCE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_decision_polish_acceptance.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_790_station_reentry_firefight_decision_polish_acceptance.md"
const TASK_789_PATH: String = "res://docs/tasks/TASK_789_station_reentry_firefight_decision_evidence_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_decision_polish_acceptance.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_790 Station Reentry Firefight Decision Polish Acceptance ===")
	_test_docs_contract_and_report()
	_test_missing_findings_blocks()
	_test_open_visible_review_routes_back_to_task_788()
	_test_incomplete_checks_route_to_completion()
	_test_issue_findings_route_to_first_action_item()
	_test_clean_findings_are_accepted()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_790: FAILED")
		quit(1)
		return
	print("TASK_790: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_790 task file exists")
	_assert(FileAccess.file_exists(TASK_789_PATH), "TASK_789 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Decision Polish Acceptance"), "TASK_790 task names decision polish acceptance")
	_assert(status_text.contains("TASK_790 - Station Reentry Firefight Decision Polish Acceptance"), "Implementation status tracks TASK_790")
	_assert(roadmap_text.contains("TASK_790 - Station Reentry Firefight Decision Polish Acceptance (implementiert)"), "Roadmap marks TASK_790 implemented")
	_assert(roadmap_text.contains("TASK_791 - Station Reentry Firefight Decision Host Client Recapture"), "Roadmap advances to TASK_791")
	_assert(contract_text.contains("Station-Reentry-Firefight-Decision-Polish-Acceptance"), "Mission command feedback contract documents TASK_790")
	_assert(report_text.contains("Aktueller Griff: TASK_791"), "Reentry handbook marks TASK_791 current")
	_assert(report_text.contains("station_reentry_firefight_decision_polish_acceptance.json"), "Reentry handbook names TASK_790 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_decision_acceptance.accepted_for_next_slice"'), "Reentry handbook exports TASK_790 acceptance check")
	_assert(report_text.contains('data-export-key="reentry_firefight_decision_acceptance.no_active_issues"'), "Reentry handbook exports TASK_790 issue gate")


func _test_missing_findings_blocks() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_decision_polish_acceptance.v1", "TASK_790 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_decision_evidence_findings", "Missing TASK_789 findings block")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_789"), "Missing findings recommend TASK_789")
	_assert(not bool(snapshot.get("accepted_for_next_firefight_decision_slice", true)), "Missing findings are not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Missing-findings acceptance remains read-only")


func _test_open_visible_review_routes_back_to_task_788() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("needs_visible_decision_evidence_review", false, false, ["decision_card_visible"], 0, []), {}))
	_assert(String(snapshot.get("status", "")) == "needs_visible_decision_evidence_review", "Open visible review routes back to TASK_788")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_788"), "Open review recommends TASK_788")
	_assert(_failed_ids(snapshot).has("findings_ready"), "Open review fails findings-ready gate")
	_assert(_failed_ids(snapshot).has("manual_review_done"), "Open review fails manual gate")
	_assert(_snapshot_is_read_only(snapshot), "Open acceptance remains read-only")


func _test_incomplete_checks_route_to_completion() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("needs_decision_evidence_review_completion", true, true, ["guard_line_visible", "workbench_json_exported"], 0, []), {}))
	_assert(String(snapshot.get("status", "")) == "needs_decision_evidence_review_completion", "Incomplete checks route to completion")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_788"), "Incomplete checks recommend TASK_788 completion")
	_assert(Array(snapshot.get("source_missing_check_ids", [])).has("guard_line_visible"), "Source missing checks are preserved")
	_assert(_failed_ids(snapshot).has("no_missing_checks"), "Incomplete checks fail no-missing gate")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete acceptance remains read-only")


func _test_issue_findings_route_to_first_action_item() -> void:
	var action_items: Array = [
		{
			"id": "quick_actions_hidden",
			"label": "Quick-Actions versteckt",
			"recommended_task": "TASK_787 - Station Reentry Firefight Player Decision Readability Pass",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		}
	]
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("needs_targeted_decision_evidence_polish", true, true, [], 1, action_items), {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_decision_evidence_polish", "Active issues route to targeted polish")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_787"), "First action item controls targeted route")
	_assert(int(snapshot.get("source_active_issue_count", 0)) == 1, "Source active issues are preserved")
	_assert(_failed_ids(snapshot).has("no_active_issues"), "Active issues fail no-active gate")
	_assert(_snapshot_is_read_only(snapshot), "Issue acceptance remains read-only")


func _test_clean_findings_are_accepted() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("ready_for_firefight_decision_polish_acceptance", true, true, [], 0, []), {}))
	_assert(String(snapshot.get("status", "")) == "accepted_for_next_firefight_decision_slice", "Clean findings are accepted")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_791"), "Accepted findings recommend TASK_791")
	_assert(bool(snapshot.get("accepted_for_next_firefight_decision_slice", false)), "Accepted flag is true")
	_assert(Array(snapshot.get("failed_gate_ids", [])).is_empty(), "Accepted findings have no failed gates")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("ready_for_firefight_decision_polish_acceptance", true, true, [], 0, []), {
		"manifest_path": "tmp/station_reentry_firefight_decision_polish_acceptance.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_790 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_790 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_790", "Manifest records TASK_790")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_789", "Manifest records TASK_789 source")
	_assert(String(parsed.get("status", "")) == "accepted_for_next_firefight_decision_slice", "Manifest preserves accepted status")
	_assert(String(parsed.get("expected_decision_line", "")).contains("NEXT HOLD"), "Manifest carries expected decision line")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _findings(status: String, manual_done: bool, visible_done: bool, missing_checks: Array, active_issues: int, action_items: Array) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_decision_evidence_findings.v1",
		"task_id": "TASK_789",
		"source_task_id": "TASK_788",
		"status": status,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"manual_review_done": manual_done,
		"visible_review_done": visible_done,
		"missing_check_ids": missing_checks.duplicate(true),
		"active_issue_count": active_issues,
		"action_items": action_items.duplicate(true),
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_primary_action_label": "HOLD",
		"expected_quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
		"expected_reason_line": "WHY FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"expected_confirm_control": "existing command buttons / GO",
		"expected_no_auto_command_commit": true,
		"expected_existing_commands_only": true,
		"expected_host_client_context_visible": true,
	}


func _failed_ids(snapshot: Dictionary) -> Array:
	return Array(snapshot.get("failed_gate_ids", []))


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
