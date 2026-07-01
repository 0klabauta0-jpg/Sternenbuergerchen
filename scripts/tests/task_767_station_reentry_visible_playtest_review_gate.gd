extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_playtest_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_767_station_reentry_visible_playtest_review_gate.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const FINDINGS_PATH: String = "res://scripts/mission/station_reentry_playtest_findings.gd"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_visible_playtest_review_gate.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_767 Station Reentry Visible Playtest Review Gate ===")
	_test_docs_contract_and_reports()
	_test_open_playtest_routes_to_task_767()
	_test_first_order_followup_routes_beyond_task_767()
	_test_clean_review_routes_to_next_iteration()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_767: FAILED")
		quit(1)
		return
	print("TASK_767: ALL PASSED")
	quit(0)


func _test_docs_contract_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	var findings_text: String = _read_text(FINDINGS_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_767 task file exists")
	_assert(task_text.contains("Station Reentry Visible Playtest Review Gate"), "TASK_767 task names review gate")
	_assert(status_text.contains("TASK_767 - Station Reentry Visible Playtest Review Gate"), "Implementation status tracks TASK_767")
	_assert(roadmap_text.contains("TASK_767 - Station Reentry Visible Playtest Review Gate (implementiert)"), "Roadmap marks TASK_767 implemented")
	_assert(contract_text.contains("Station-Reentry-Visible-Playtest-Review-Gate (TASK_767)"), "Contract documents TASK_767")
	_assert(handbook_text.contains("TASK_767 - Station Reentry Visible Playtest Review Gate"), "Current handbook references TASK_767")
	_assert(workbench_text.contains("latest_station_reentry_visible_playtest_review_gate_task"), "Workbench records TASK_767 review gate")
	_assert(workbench_text.contains("TASK_768 - Station Reentry First Mission Preview Polish"), "Workbench recommends post-TASK_767 followup")
	_assert(findings_text.contains("TASK_767 - Station Reentry Visible Playtest Execute/Review"), "Findings route open playtest to TASK_767")
	_assert(findings_text.contains("TASK_768 - Station Reentry First Mission Preview Polish"), "Findings route first-order followup beyond TASK_767")


func _test_open_playtest_routes_to_task_767() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _ready_packet(), {}))
	_assert(_snapshot_is_read_only(snapshot), "Open review snapshot remains read-only")
	_assert(String(snapshot.get("status", "")) == "needs_visible_reentry_playtest", "Open review still requires visible playtest")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_767"), "Open review recommends TASK_767")
	_assert(_finding_suggests(snapshot, "visible_reentry_playtest_open", "TASK_767"), "Open finding suggests TASK_767")


func _test_first_order_followup_routes_beyond_task_767() -> void:
	var notes: Dictionary = _complete_notes()
	notes["controls"]["station_scenario_playtest"]["reentry"]["issues"] = {
		"needs_first_order_preview_polish": true,
		"needs_reentry_performance_pass": true,
		"needs_host_client_next_order_sync": true,
	}
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _ready_packet(), notes))
	_assert(_snapshot_is_read_only(snapshot), "Issue review snapshot remains read-only")
	_assert(String(snapshot.get("status", "")) == "needs_targeted_reentry_polish", "Issue review requests targeted polish")
	_assert(_action_task_exists(snapshot, "needs_first_order_preview_polish", "TASK_768"), "First-order preview routes to TASK_768")
	_assert(_action_task_exists(snapshot, "needs_reentry_performance_pass", "TASK_769"), "Performance routes to TASK_769")
	_assert(_action_task_exists(snapshot, "needs_host_client_next_order_sync", "TASK_770"), "Host/client sync routes to TASK_770")


func _test_clean_review_routes_to_next_iteration() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _ready_packet(), _complete_notes()))
	_assert(_snapshot_is_read_only(snapshot), "Clean review snapshot remains read-only")
	_assert(String(snapshot.get("status", "")) == "ready_for_next_station_iteration", "Clean review is ready for next station iteration")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_768"), "Clean review routes beyond TASK_767")


func _test_manifest_write() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _ready_packet(), {}, {
		"packet_path": "tmp/station_reentry_playtest_run_packet.json",
		"manifest_path": "tmp/station_reentry_visible_playtest_review_gate.json",
	}))
	var manifest: Dictionary = snapshot.duplicate(true)
	manifest["task_id"] = "TASK_767"
	manifest["schema"] = "sternenbuergerchen.station_reentry_visible_playtest_review_gate.v1"
	manifest["source_findings_schema"] = String(snapshot.get("schema", ""))
	manifest["source_findings_task_id"] = String(snapshot.get("task_id", ""))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_767 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_767", "Manifest records TASK_767")
	_assert(String(parsed.get("source_findings_task_id", "")) == "TASK_761", "Manifest records TASK_761 source")
	_assert(String(parsed.get("recommended_next_task", "")).contains("TASK_767"), "Manifest routes open review to TASK_767")


func _ready_packet() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_playtest_run_packet.v1",
		"task_id": "TASK_760",
		"source_task_id": "TASK_759",
		"target_id": "station_reentry_playtest",
		"target_title": "Homebase -> naechste Station-Sortie",
		"status": "ready_to_run_station_reentry_playtest",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"manual_review_required": true,
		"manual_review_done": false,
	}


func _complete_notes() -> Dictionary:
	var reentry: Dictionary = {
		"manual_review_done": true,
		"playtest_done": true,
	}
	for id in [
		"homebase_return_panel_readable",
		"fireteam_staging_readable",
		"loadout_check_readable",
		"dropship_payload_consistent",
		"start_release_visible",
		"host_client_same_next_order",
		"first_mission_preview_visible",
		"first_mission_cue_readable",
		"performance_feels_fast",
		"workbench_notes_exported",
	]:
		reentry[id] = true
	return {"controls": {"station_scenario_playtest": {"reentry": reentry}}}


func _finding_suggests(snapshot: Dictionary, finding_id: String, task_id: String) -> bool:
	for finding_variant in Array(snapshot.get("findings", [])):
		var finding: Dictionary = Dictionary(finding_variant)
		if String(finding.get("id", "")) == finding_id and String(finding.get("suggested_next", "")).contains(task_id):
			return true
	return false


func _action_task_exists(snapshot: Dictionary, action_id: String, task_id: String) -> bool:
	for action_variant in Array(snapshot.get("action_items", [])):
		var action: Dictionary = Dictionary(action_variant)
		if String(action.get("id", "")) == action_id and String(action.get("recommended_task", "")).contains(task_id):
			return true
	return false


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true)) and not bool(snapshot.get("creates_command", true))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_767 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


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
