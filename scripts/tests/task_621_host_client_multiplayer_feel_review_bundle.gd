extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_621_host_client_multiplayer_feel_review_bundle.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const STATUS_HANDBOOK_REPORT_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const SOURCE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const REVIEW_BUNDLE_PATH: String = "res://tmp/host_client_multiplayer_feel_review.json"

const EXPECTED_HOST_BADGE: String = "HOST P1 ALPHA"
const EXPECTED_CLIENT_BADGE: String = "CLIENT P2 BRAVO"
const EXPECTED_NEXT_TASK: String = "TASK_622 - Host Client Command Authority Live Interaction Review"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_621 Host Client Multiplayer Feel Review Bundle ===")
	_test_docs_reports_and_contract()
	var bundle: Dictionary = _build_review_bundle()
	_write_json(REVIEW_BUNDLE_PATH, bundle)
	_test_bundle(bundle)
	_test_written_bundle()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_621: FAILED")
		quit(1)
		return
	print("TASK_621: ALL PASSED")
	quit(0)


func _test_docs_reports_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(STATUS_HANDBOOK_REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_621 task file exists")
	_assert(task_text.contains("Host Client Multiplayer Feel Review Bundle"), "TASK_621 task names multiplayer feel bundle")
	_assert(status_text.contains("TASK_621 - Host Client Multiplayer Feel Review Bundle"), "Implementation status tracks TASK_621")
	_assert(roadmap_text.contains("TASK_621 - Host Client Multiplayer Feel Review Bundle (implementiert)"), "Roadmap marks TASK_621 implemented")
	_assert(contract_text.contains("Host-Client-Multiplayer-Feel-Review-Bundle"), "Mission feedback contract documents TASK_621")
	_assert(report_text.contains("TASK_621 Host Client Multiplayer Feel Review Bundle"), "Rolling report tracks TASK_621")
	_assert(report_text.contains("TASK_622 - Host Client Command Authority Live Interaction Review"), "Rolling report advances to TASK_622 after TASK_621")
	_assert(handbook_text.contains("TASK_621 Review-Bundle"), "Status handbook tracks TASK_621 bundle")
	_assert(handbook_text.contains('current_task: "TASK_627 - Host Client Fireteam Eventlog Overlap Polish"'), "Status handbook current task advances beyond TASK_621")
	_assert(handbook_text.contains('latest_completed_task: "TASK_627 - Host Client Fireteam Eventlog Overlap Polish"'), "Status handbook latest task advances beyond TASK_621")
	_test_report_export_fields(report_text, handbook_text)


func _test_report_export_fields(report_text: String, handbook_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_multiplayer_feel.task_id",
		"host_client_multiplayer_feel.bundle_path",
		"host_client_multiplayer_feel.source_manifest_path",
		"host_client_multiplayer_feel.badge_recapture_gate",
		"host_client_multiplayer_feel.host_crop_path",
		"host_client_multiplayer_feel.client_crop_path",
		"host_client_multiplayer_feel.host_expected_badge_text",
		"host_client_multiplayer_feel.client_expected_badge_text",
		"host_client_multiplayer_feel.authority_evidence_tests",
		"host_client_multiplayer_feel.manual_review_required",
		"host_client_multiplayer_feel.recommended_next_task",
		"host_client_multiplayer_feel.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_multiplayer_feel"'), "Rolling report exports TASK_621 free note")
	_assert(handbook_text.contains('data-export-key="status.task_621_done"'), "Status handbook exports TASK_621 checkbox")
	_assert(report_text.contains("Host Client Command Authority Live Interaction Review"), "Reports keep TASK_622 recommendation in TASK_621 history")


func _build_review_bundle() -> Dictionary:
	var source_present: bool = FileAccess.file_exists(SOURCE_MANIFEST_PATH)
	var source_manifest: Dictionary = {}
	if source_present:
		source_manifest = _read_json(SOURCE_MANIFEST_PATH)
	var badge_gate: String = String(source_manifest.get("badge_recapture_gate", "manual_open"))
	var host_crop_path: String = String(source_manifest.get("host_badge_crop_path", source_manifest.get("host_screenshot_path", "tmp/host_client_two_window_host_review.png")))
	var client_crop_path: String = String(source_manifest.get("client_badge_crop_path", source_manifest.get("client_screenshot_path", "tmp/host_client_two_window_client_review.png")))
	var host_badge: String = String(source_manifest.get("host_expected_badge_text", EXPECTED_HOST_BADGE))
	var client_badge: String = String(source_manifest.get("client_expected_badge_text", EXPECTED_CLIENT_BADGE))
	var manual_checks: Dictionary = {
		"both_windows_visible": false,
		"host_client_badge_readable": false,
		"peer2_bravo_command_checked": false,
		"peer2_alpha_reject_checked": false,
		"snapshot_sync_checked": false,
		"f6_readability_checked": false,
		"performance_feel_checked": false,
		"input_latency_notes": "",
		"authority_notes": "",
		"sync_notes": "",
		"performance_notes": "",
		"next_decision": "manual_open",
	}
	return {
		"schema": "sternenbuergerchen.host_client_multiplayer_feel_review.v1",
		"task_id": "TASK_621",
		"source_real_run_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"source_manifest_present": source_present,
		"source_manifest_task_id": String(source_manifest.get("task_id", "")),
		"badge_recapture_gate": badge_gate,
		"host_crop_path": host_crop_path,
		"client_crop_path": client_crop_path,
		"host_expected_badge_text": host_badge,
		"client_expected_badge_text": client_badge,
		"badge_expected_style_id": String(source_manifest.get("badge_expected_style_id", "host_client_role_peer_badge_v1")),
		"badge_expected_hud_path": String(source_manifest.get("badge_expected_hud_path", "MissionIdentityHeaderLabel")),
		"authority_evidence_tests": [
			"scripts/tests/task_604_core_loop_host_client_feel_smoke.gd",
			"scripts/tests/task_607_two_instance_host_client_runtime_smoke.gd",
			"scripts/tests/task_610_host_client_two_window_playtest_notes.gd",
			"scripts/tests/task_620_host_client_badge_recapture_review.gd",
		],
		"manual_checks": manual_checks,
		"manual_review_required": true,
		"manual_review_done": false,
		"gate": "review_ready" if source_present and badge_gate == "review_ready" else "manual_open",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": EXPECTED_NEXT_TASK,
	}


func _test_bundle(bundle: Dictionary) -> void:
	_assert(String(bundle.get("schema", "")) == "sternenbuergerchen.host_client_multiplayer_feel_review.v1", "Bundle schema is stable")
	_assert(String(bundle.get("task_id", "")) == "TASK_621", "Bundle task id is TASK_621")
	_assert(bool(bundle.get("manual_review_required", false)), "Bundle requires manual review")
	_assert(not bool(bundle.get("manual_review_done", true)), "Bundle does not mark manual review done")
	_assert(bool(bundle.get("read_only", false)), "Bundle remains read-only")
	_assert(not bool(bundle.get("ui_sets_gameplay_truth", true)), "Bundle does not set gameplay truth")
	_assert(String(bundle.get("host_expected_badge_text", "")) == EXPECTED_HOST_BADGE, "Bundle carries expected host badge")
	_assert(String(bundle.get("client_expected_badge_text", "")) == EXPECTED_CLIENT_BADGE, "Bundle carries expected client badge")
	_assert(String(bundle.get("badge_expected_style_id", "")) == "host_client_role_peer_badge_v1", "Bundle carries expected badge style")
	_assert(String(bundle.get("badge_expected_hud_path", "")) == "MissionIdentityHeaderLabel", "Bundle carries expected HUD path")
	_assert(String(bundle.get("recommended_next_task", "")) == EXPECTED_NEXT_TASK, "Bundle recommends TASK_622")
	if bool(bundle.get("source_manifest_present", false)):
		var badge_recapture_gate: String = String(bundle.get("badge_recapture_gate", ""))
		var bundle_gate: String = String(bundle.get("gate", ""))
		_assert(badge_recapture_gate in ["review_ready", "manual_open"], "Existing source manifest has a valid badge review gate")
		_assert(bundle_gate == "review_ready" if badge_recapture_gate == "review_ready" else bundle_gate == "manual_open", "Bundle gate follows source readiness")
	_test_evidence_tests(bundle)
	_test_manual_checks(bundle)


func _test_evidence_tests(bundle: Dictionary) -> void:
	var evidence_tests: Array = Array(bundle.get("authority_evidence_tests", []))
	var required_tests: Array[String] = [
		"scripts/tests/task_604_core_loop_host_client_feel_smoke.gd",
		"scripts/tests/task_607_two_instance_host_client_runtime_smoke.gd",
		"scripts/tests/task_610_host_client_two_window_playtest_notes.gd",
		"scripts/tests/task_620_host_client_badge_recapture_review.gd",
	]
	for test_path in required_tests:
		_assert(evidence_tests.has(test_path), "Bundle lists %s" % test_path)
		_assert(FileAccess.file_exists("res://%s" % test_path), "Evidence test exists: %s" % test_path)


func _test_manual_checks(bundle: Dictionary) -> void:
	var manual_checks: Dictionary = Dictionary(bundle.get("manual_checks", {}))
	var required_keys: Array[String] = [
		"both_windows_visible",
		"host_client_badge_readable",
		"peer2_bravo_command_checked",
		"peer2_alpha_reject_checked",
		"snapshot_sync_checked",
		"f6_readability_checked",
		"performance_feel_checked",
		"input_latency_notes",
		"authority_notes",
		"sync_notes",
		"performance_notes",
		"next_decision",
	]
	for key in required_keys:
		_assert(manual_checks.has(key), "Manual check has %s" % key)


func _test_written_bundle() -> void:
	_assert(FileAccess.file_exists(REVIEW_BUNDLE_PATH), "TASK_621 review bundle was written")
	var written: Dictionary = _read_json(REVIEW_BUNDLE_PATH)
	_assert(String(written.get("schema", "")) == "sternenbuergerchen.host_client_multiplayer_feel_review.v1", "Written bundle schema is stable")
	_assert(String(written.get("recommended_next_task", "")) == EXPECTED_NEXT_TASK, "Written bundle recommends TASK_622")


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_assert(false, "Could open bundle path for writing")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
