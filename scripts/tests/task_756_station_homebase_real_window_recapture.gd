extends SceneTree

const PLAYTEST_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_f6_host_client_playtest_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_756_station_homebase_real_window_recapture.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const PREPARE_TOOL_PATH: String = "res://scripts/tools/prepare_station_homebase_host_client_recapture.ps1"
const CAPTURE_TOOL_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const LAUNCH_TOOL_PATH: String = "res://scripts/tools/launch_host_client_two_window_review.ps1"
const PACKET_PATH: String = "res://tmp/station_homebase_host_client_recapture_packet.json"
const CAPTURE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const EXPECTED_LINE: String = "Naechste Sortie: Fireteam bereitstellen | danach: Loadout pruefen, Dropship beladen, Start freigeben"
const EXPECTED_STYLE_ID: String = "task_755_station_homebase_return_panel_v1"
const EXPECTED_TITLE: String = "Rueckkehr abgeschlossen"
const EXPECTED_ACTION: String = "Naechster Auftrag: Fireteam bereitstellen"

const PANEL_CHECK_IDS: Array[String] = [
	"homebase_return_panel_title_visible",
	"homebase_return_panel_action_visible",
	"homebase_return_panel_chips_visible",
	"homebase_return_panel_matches_task_755",
]

const HOMEBASE_CHECK_IDS: Array[String] = [
	"cargo_end_reached",
	"debrief_visible_after_cargo",
	"return_homebase_clicked",
	"homebase_summary_mentions_station_drill",
	"homebase_return_panel_title_visible",
	"homebase_return_panel_action_visible",
	"homebase_return_panel_chips_visible",
	"homebase_return_panel_matches_task_755",
	"homebase_next_sortie_line_matches_task_749",
	"old_debug_next_sortie_markers_absent",
	"performance_feels_fast",
	"workbench_notes_exported",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_756 Station Homebase Real Window Recapture ===")
	_test_docs_contract_reports_and_scripts()
	_refresh_packet_and_manifest()
	_test_packet()
	_test_capture_manifest()
	_test_analyzer_evidence_and_gate()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_756: FAILED")
		quit(1)
		return
	print("TASK_756: ALL PASSED")
	quit(0)


func _test_docs_contract_reports_and_scripts() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	var prepare_text: String = _read_text(PREPARE_TOOL_PATH)
	var capture_text: String = _read_text(CAPTURE_TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_756 task file exists")
	_assert(task_text.contains("Station Homebase Real Window Recapture"), "TASK_756 task names real window recapture")
	_assert(status_text.contains("TASK_756 - Station Homebase Real Window Recapture"), "Implementation status tracks TASK_756")
	_assert(roadmap_text.contains("TASK_756 - Station Homebase Real Window Recapture"), "Roadmap tracks TASK_756")
	_assert(contract_text.contains("Station-Homebase-Real-Window-Recapture (TASK_756)"), "Mission command feedback contract documents TASK_756")
	_assert(handbook_text.contains("TASK_756 - Station Homebase Real Window Recapture"), "Current handbook references TASK_756")
	_assert(handbook_text.contains('data-export-key="status.task_756_done"'), "Current handbook exports TASK_756 checkbox")
	_assert(workbench_text.contains("homebase_return_panel_matches_task_755"), "Workbench exports TASK_755 panel match check")
	for key in [
		"station_homebase_real_window_recapture.task_id",
		"station_homebase_real_window_recapture.packet_path",
		"station_homebase_real_window_recapture.capture_manifest_path",
		"station_homebase_real_window_recapture.required_panel_checks",
		"station_homebase_real_window_recapture.recommended_next_task",
		"station_homebase_real_window_recapture.notes",
	]:
		_assert(handbook_text.contains(key), "Current handbook exports %s" % key)
	for term in [
		"TASK_756",
		"TASK_755",
		EXPECTED_STYLE_ID,
		EXPECTED_TITLE,
		EXPECTED_ACTION,
		"homebase_return_panel_matches_task_755",
	]:
		_assert(prepare_text.contains(term), "Prepare tool contains %s" % term)
		_assert(capture_text.contains(term), "Capture tool contains %s" % term)


func _refresh_packet_and_manifest() -> void:
	_run_powershell(["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(LAUNCH_TOOL_PATH), "-ScenarioPath", "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"])
	_run_powershell(["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(PREPARE_TOOL_PATH)])
	_run_powershell(["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(CAPTURE_TOOL_PATH)])
	_assert(FileAccess.file_exists(PACKET_PATH), "TASK_756 packet exists after refresh")
	_assert(FileAccess.file_exists(CAPTURE_MANIFEST_PATH), "TASK_756 capture manifest exists after refresh")


func _test_packet() -> void:
	var packet: Dictionary = _read_json(PACKET_PATH)
	_assert(String(packet.get("schema", "")) == "sternenbuergerchen.station_homebase_host_client_recapture_packet.v1", "Packet schema is stable")
	_assert(String(packet.get("task_id", "")) == "TASK_750", "Packet keeps TASK_750 identity")
	_assert(String(packet.get("refresh_task_id", "")) == "TASK_756", "Packet records TASK_756 refresh")
	_assert(String(packet.get("source_task_id", "")) == "TASK_755", "Packet records TASK_755 source")
	_assert(String(packet.get("source_microcopy_task_id", "")) == "TASK_749", "Packet keeps TASK_749 microcopy source")
	_assert(String(packet.get("status", "")) == "ready_to_run_homebase_recapture", "Packet is ready after TASK_755 refresh")
	_assert(bool(packet.get("task_755_ready", false)), "Packet sees TASK_755 manifest ready")
	_assert(String(packet.get("expected_homebase_readiness_line", "")) == EXPECTED_LINE, "Packet keeps TASK_749 readiness line")
	_assert(String(packet.get("expected_homebase_return_panel_style_id", "")) == EXPECTED_STYLE_ID, "Packet records TASK_755 style id")
	_assert(String(packet.get("expected_homebase_return_panel_title", "")) == EXPECTED_TITLE, "Packet records TASK_755 title")
	_assert(String(packet.get("expected_homebase_return_panel_action", "")) == EXPECTED_ACTION, "Packet records TASK_755 action")
	_assert(int(packet.get("expected_homebase_return_panel_chip_count", 0)) >= 5, "Packet records TASK_755 chip count")
	for check_id in PANEL_CHECK_IDS:
		_assert(Array(packet.get("required_manual_checks", [])).has(check_id), "Packet requires %s" % check_id)
	_assert(bool(packet.get("read_only", false)) and not bool(packet.get("ui_sets_gameplay_truth", true)), "Packet remains read-only")


func _test_capture_manifest() -> void:
	var manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Capture manifest schema is stable")
	_assert(String(manifest.get("station_homebase_real_window_recapture_task_id", "")) == "TASK_756", "Capture manifest records TASK_756")
	_assert(String(manifest.get("station_homebase_return_panel_polish_task_id", "")) == "TASK_755", "Capture manifest records TASK_755")
	_assert(String(manifest.get("station_homebase_expected_return_panel_style_id", "")) == EXPECTED_STYLE_ID, "Capture manifest records style id")
	_assert(String(manifest.get("station_homebase_expected_return_panel_title", "")) == EXPECTED_TITLE, "Capture manifest records title")
	_assert(String(manifest.get("station_homebase_expected_return_panel_action", "")) == EXPECTED_ACTION, "Capture manifest records action")
	_assert(int(manifest.get("station_homebase_expected_return_panel_chip_count", 0)) >= 5, "Capture manifest records chip count")
	for check_id in PANEL_CHECK_IDS:
		_assert(Array(manifest.get("station_homebase_recapture_manual_checks", [])).has(check_id), "Capture manifest requires %s" % check_id)
		_assert(Array(manifest.get("review_checks", [])).has("station_%s" % check_id), "Capture review checks include station_%s" % check_id)
	_assert(bool(manifest.get("manual_review_required", false)), "Capture manifest still requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Capture manifest does not claim manual review done")
	_assert(bool(manifest.get("read_only", false)) and not bool(manifest.get("ui_sets_gameplay_truth", true)), "Capture manifest remains read-only")


func _test_analyzer_evidence_and_gate() -> void:
	var manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	manifest["real_run_done"] = true
	manifest["host_crop_ready"] = true
	manifest["client_crop_ready"] = true
	manifest["cue_visible"] = true
	manifest["future_blocker_hidden_in_display"] = true
	var snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), {}, {
		"recapture_findings": manifest,
		"recapture_manifest_path": "tmp/host_client_two_window_real_run_review.json",
	}))
	var evidence: Dictionary = Dictionary(snapshot.get("recapture_evidence", {}))
	var review: Dictionary = Dictionary(snapshot.get("homebase_recapture_review", {}))
	_assert(bool(evidence.get("homebase_return_panel_evidence_ready", false)), "Analyzer marks TASK_755 return panel evidence ready")
	_assert(String(evidence.get("homebase_return_panel_polish_task_id", "")) == "TASK_755", "Analyzer carries TASK_755 panel task id")
	_assert(String(evidence.get("homebase_return_panel_style_id", "")) == EXPECTED_STYLE_ID, "Analyzer carries TASK_755 style id")
	_assert(String(evidence.get("homebase_return_panel_title", "")) == EXPECTED_TITLE, "Analyzer carries TASK_755 title")
	_assert(String(evidence.get("homebase_return_panel_action", "")) == EXPECTED_ACTION, "Analyzer carries TASK_755 action")
	_assert(bool(evidence.get("homebase_recapture_ready_for_workbench", false)), "Analyzer marks Homebase recapture ready for workbench")
	_assert(String(review.get("status", "")) == "needs_homebase_recapture_review", "Analyzer requires manual Homebase review")
	for check_id in PANEL_CHECK_IDS:
		_assert(_review_has_check(review, check_id), "Analyzer review requires %s" % check_id)
	_assert(bool(review.get("read_only", false)) and not bool(review.get("ui_sets_gameplay_truth", true)), "Analyzer review remains read-only")


func _fake_task_726_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_one_screen_scenario_drill.v1",
		"task_id": "TASK_726",
		"status": "ready_for_f6_host_client_playtest",
		"scenario_path": "data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _review_has_check(review: Dictionary, check_id: String) -> bool:
	for check_variant in Array(review.get("required_checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return true
	return false


func _run_powershell(args: Array[String]) -> void:
	var output: Array = []
	var exit_code: int = OS.execute("powershell", args, output, true, false)
	_assert(exit_code == 0, "PowerShell command exits 0: %s" % " ".join(args))
	if exit_code != 0:
		for line in output:
			print(line)


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
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
