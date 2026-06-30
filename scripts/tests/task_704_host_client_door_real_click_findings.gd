extends SceneTree

const HOST_CLIENT_DOOR_REAL_CLICK_WORKBENCH_SCRIPT: GDScript = preload("res://scripts/mission/mission_host_client_door_real_click_workbench.gd")
const HOST_CLIENT_DOOR_REAL_CLICK_FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/mission_host_client_door_real_click_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_704_host_client_door_real_click_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const WORKBENCH_REPORT_PATH: String = "res://docs/reports/host_client_door_real_click_workbench_2026_06_30.html"
const WORKBENCH_SCRIPT_PATH: String = "res://scripts/mission/mission_host_client_door_real_click_workbench.gd"
const FINDINGS_SCRIPT_PATH: String = "res://scripts/mission/mission_host_client_door_real_click_findings.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/host_client_door_real_click_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_704 Host/Client Door Real Click Findings ===")
	_test_docs()
	_test_open_findings_snapshot()
	_test_manual_negative_findings_snapshot()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_704: FAILED")
		quit(1)
		return
	print("TASK_704: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_report_text: String = _read_text(WORKBENCH_REPORT_PATH)
	var workbench_script_text: String = _read_text(WORKBENCH_SCRIPT_PATH)
	var findings_script_text: String = _read_text(FINDINGS_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_704 task file exists")
	_assert(task_text.contains("Host/Client Door Real Click Findings"), "Task documents Door real click findings")
	_assert(contract_text.contains("Host/Client Door Real Click Findings"), "Interaction contract documents TASK_704 findings")
	_assert(status_text.contains("TASK_704 - Host/Client Door Real Click Findings"), "Implementation status tracks TASK_704")
	_assert(roadmap_text.contains("TASK_704 - Host/Client Door Real Click Findings (implementiert)"), "Roadmap marks TASK_704 implemented")
	_assert(handbook_text.contains("TASK_704 - Host/Client Door Real Click Findings"), "Current handbook references TASK_704")
	_assert(handbook_text.contains('data-export-key="host_client_door_real_click_findings.manifest_path"'), "Current handbook exports TASK_704 manifest path")
	_assert(workbench_report_text.contains("TASK_704 - Host/Client Door Real Click Findings"), "Door workbench recommends TASK_704")
	_assert(workbench_script_text.contains("TASK_704 - Host/Client Door Real Click Findings"), "Workbench helper recommends TASK_704")
	_assert(findings_script_text.contains("manual_click_findings_gate"), "Findings helper exposes manual gate")
	_assert(findings_script_text.contains("technical_path_gate"), "Findings helper exposes technical gate")


func _test_open_findings_snapshot() -> void:
	var capture: Dictionary = _fake_capture()
	var workbench: Dictionary = Dictionary(HOST_CLIENT_DOOR_REAL_CLICK_WORKBENCH_SCRIPT.call("build_snapshot", capture, {}))
	var findings: Dictionary = Dictionary(HOST_CLIENT_DOOR_REAL_CLICK_FINDINGS_SCRIPT.call("build_snapshot", capture, workbench, {}))
	_assert(_snapshot_is_read_only(findings), "Open findings snapshot is read-only")
	_assert(String(findings.get("schema", "")) == "sternenbuergerchen.host_client_door_real_click_findings.v1", "Findings schema is stable")
	_assert(String(findings.get("technical_path_gate", "")) == "pass", "Findings confirms technical capture pass")
	_assert(String(findings.get("manual_click_findings_gate", "")) == "manual_still_open", "Findings keeps manual click gate open")
	_assert(bool(findings.get("manual_review_required", false)), "Findings requires manual review")
	_assert(not bool(findings.get("manual_review_done", true)), "Findings does not claim manual review done")
	var confirmed: Array = Array(findings.get("confirmed_findings", []))
	_assert(confirmed.has("host_command_feedback_visible"), "Findings confirms host command feedback")
	_assert(confirmed.has("wrong_team_reject_visible"), "Findings confirms wrong-team reject")
	_assert(confirmed.has("state_mutation_reject_visible"), "Findings confirms state-mutation reject")
	_assert(confirmed.has("door_open_feedback_bound_to_runtime_producer"), "Findings confirms Door open producer feedback")
	_assert(Array(findings.get("open_manual_findings", [])).has("host_window_launched"), "Findings keeps host window manual check open")
	_assert(Array(findings.get("open_manual_findings", [])).has("hud_feedback_readable"), "Findings keeps HUD readability manual check open")
	_assert(String(findings.get("recommended_next_task", "")) == "TASK_705 - Host/Client Door Real Click Manual Run Packet", "Open findings recommend manual run packet")


func _test_manual_negative_findings_snapshot() -> void:
	var capture: Dictionary = _fake_capture()
	var notes: Dictionary = {
		"manual_review_done": true,
		"controls": {
			"door_real_click": {
				"manual_review_done": true,
				"host_window_launched": true,
				"client_window_launched": true,
				"host_door_button_visible": true,
				"client_door_button_visible": true,
				"shortcut_b_triggers_hook": true,
				"go_required_visible": true,
				"wrong_team_reject_visible": true,
				"door_open_visible_on_host": true,
				"door_open_visible_on_client": true,
				"hud_feedback_readable": true,
				"timing_notes": "zu langsam im Client-Fenster",
			},
		},
	}
	var workbench: Dictionary = Dictionary(HOST_CLIENT_DOOR_REAL_CLICK_WORKBENCH_SCRIPT.call("build_snapshot", capture, notes))
	var findings: Dictionary = Dictionary(HOST_CLIENT_DOOR_REAL_CLICK_FINDINGS_SCRIPT.call("build_snapshot", capture, workbench, notes))
	_assert(String(findings.get("manual_click_findings_gate", "")) == "manual_done", "Manual notes can close manual gate")
	_assert(bool(findings.get("manual_review_done", false)), "Manual notes mark review done")
	_assert(bool(findings.get("negative_note_detected", false)), "Findings detect negative note")
	_assert(String(findings.get("recommended_next_task", "")) == "TASK_706 - Mission Door Layout/Visual Polish", "Negative notes recommend Door polish")
	_assert(int(findings.get("completed_check_count", 0)) >= 10, "Completed manual notes propagate check count")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var capture: Dictionary = _fake_capture()
	var workbench: Dictionary = Dictionary(HOST_CLIENT_DOOR_REAL_CLICK_WORKBENCH_SCRIPT.call("build_snapshot", capture, {}))
	var findings: Dictionary = Dictionary(HOST_CLIENT_DOOR_REAL_CLICK_FINDINGS_SCRIPT.call("build_snapshot", capture, workbench, {}))
	findings["task_id"] = "TASK_704"
	findings["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(findings)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_704 findings manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_704", "Manifest records TASK_704")
	_assert(String(parsed.get("technical_path_gate", "")) == "pass", "Manifest records technical pass")
	_assert(String(parsed.get("manual_click_findings_gate", "")) == "manual_still_open", "Manifest keeps manual gate open")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _fake_capture() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mission_multiplayer_door_feedback_capture.v1",
		"gate": "pass",
		"summary": "Door feedback capture OK: host accepted/open, wrong-team and state-mutation blocked, producer-open visible.",
		"manifest_path": "tmp/multiplayer_door_feedback_capture.json",
		"host_status": "accepted",
		"wrong_team_status": "blocked",
		"state_mutation_status": "blocked",
		"open_status": "open",
		"wrong_team_reason": "peer_team_mismatch",
		"state_mutation_reason": "state_mutation_key:runtime_state",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_704 manifest for writing")
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
