extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_751_station_homebase_capture_metadata_hook.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const CAPTURE_SCRIPT_PATH: String = "res://scripts/tools/capture_host_client_two_window_real_run.ps1"
const CAPTURE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const EXPECTED_LINE: String = "Naechste Sortie: Fireteam bereitstellen | danach: Loadout pruefen, Dropship beladen, Start freigeben"
const EXPECTED_TITLE: String = "Rueckkehr abgeschlossen"
const EXPECTED_ACTION: String = "Naechster Auftrag: Fireteam bereitstellen"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_751 Station Homebase Capture Metadata Hook ===")
	_test_docs_contract_report_and_script()
	_test_capture_manifest_metadata()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_751: FAILED")
		quit(1)
		return
	print("TASK_751: ALL PASSED")
	quit(0)


func _test_docs_contract_report_and_script() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var capture_text: String = _read_text(CAPTURE_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_751 task file exists")
	_assert(task_text.contains("Station Homebase Capture Metadata Hook"), "TASK_751 task names capture metadata hook")
	_assert(status_text.contains("TASK_751 - Station Homebase Capture Metadata Hook"), "Implementation status tracks TASK_751")
	_assert(roadmap_text.contains("TASK_751 - Station Homebase Capture Metadata Hook"), "Roadmap tracks TASK_751")
	_assert(contract_text.contains("Station-Homebase-Capture-Metadata-Hook"), "Mission command feedback contract documents TASK_751")
	_assert(handbook_text.contains("TASK_751 - Station Homebase Capture Metadata Hook"), "Current handbook references TASK_751")
	_assert(handbook_text.contains('data-export-key="status.task_751_done"'), "Current handbook exports TASK_751 checkbox")
	for term in [
		"station_homebase_host_client_recapture_task_id",
		"station_homebase_host_client_recapture_packet_path",
		"station_homebase_expected_readiness_line",
		"station_homebase_real_window_recapture_task_id",
		"station_homebase_return_panel_polish_task_id",
		"station_homebase_expected_return_panel_title",
		"station_homebase_expected_return_panel_action",
		"station_homebase_expected_return_panel_step_labels",
		"station_homebase_forbidden_debug_fragments",
		"station_homebase_recapture_manual_checks",
		"station_homebase_next_sortie_line_matches_task_749",
		"recommended_next_station_homebase_after_recapture_task",
	]:
		_assert(capture_text.contains(term), "Capture script contains %s" % term)
	for key in [
		"station_homebase_capture_metadata_hook.task_id",
		"station_homebase_capture_metadata_hook.capture_manifest_path",
		"station_homebase_capture_metadata_hook.expected_homebase_readiness_line",
		"station_homebase_capture_metadata_hook.manual_checks",
		"station_homebase_capture_metadata_hook.recommended_next_task",
		"station_homebase_capture_metadata_hook.notes",
	]:
		_assert(handbook_text.contains(key), "Current handbook exports %s" % key)


func _test_capture_manifest_metadata() -> void:
	_assert(FileAccess.file_exists(CAPTURE_MANIFEST_PATH), "Capture manifest exists")
	var manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Capture manifest schema is stable")
	_assert(String(manifest.get("station_homebase_host_client_recapture_task_id", "")) == "TASK_750", "Capture manifest points to TASK_750")
	_assert(String(manifest.get("station_homebase_real_window_recapture_task_id", "")) == "TASK_756", "Capture manifest points to TASK_756")
	_assert(String(manifest.get("station_homebase_host_client_recapture_packet_path", "")) == "tmp/station_homebase_host_client_recapture_packet.json", "Capture manifest records TASK_750 packet path")
	_assert(String(manifest.get("station_homebase_expected_readiness_line", "")) == EXPECTED_LINE, "Capture manifest records TASK_749 Homebase line")
	_assert(String(manifest.get("station_homebase_return_panel_polish_task_id", "")) == "TASK_755", "Capture manifest records TASK_755 return panel source")
	_assert(String(manifest.get("station_homebase_expected_return_panel_title", "")) == EXPECTED_TITLE, "Capture manifest records TASK_755 return panel title")
	_assert(String(manifest.get("station_homebase_expected_return_panel_action", "")) == EXPECTED_ACTION, "Capture manifest records TASK_755 return panel action")
	_assert(int(manifest.get("station_homebase_expected_return_panel_chip_count", 0)) >= 5, "Capture manifest records TASK_755 chip count")
	_assert(bool(manifest.get("station_homebase_recapture_review_required", false)), "Capture manifest requires Homebase recapture review")
	_assert(not bool(manifest.get("station_homebase_recapture_review_done", true)), "Capture manifest does not claim Homebase review done")
	_assert(bool(manifest.get("manual_review_required", false)), "Capture manifest keeps manual review required")
	_assert(not bool(manifest.get("manual_review_done", true)), "Capture manifest keeps manual review open")
	_assert(bool(manifest.get("read_only", false)), "Capture manifest is read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Capture manifest does not set gameplay truth")
	var checks: Array = Array(manifest.get("station_homebase_recapture_manual_checks", []))
	for check_id in [
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
	]:
		_assert(checks.has(check_id), "Capture manifest requires Homebase check %s" % check_id)
	var review_checks: Array = Array(manifest.get("review_checks", []))
	_assert(review_checks.has("station_homebase_return_panel_matches_task_755"), "General review checks include TASK_755 panel match")
	_assert(review_checks.has("station_homebase_next_sortie_line_matches_task_749"), "General review checks include Homebase line match")
	_assert(review_checks.has("station_homebase_workbench_notes_exported"), "General review checks include Homebase workbench export")
	var forbidden: Array = Array(manifest.get("station_homebase_forbidden_debug_fragments", []))
	_assert(forbidden.has("Next sortie") and forbidden.has("Stage fireteam"), "Capture manifest lists old debug markers")


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
