extends SceneTree

const Recapture := preload("res://scripts/mission/release_first_exchange_contact_fire_real_window_recapture.gd")

const TASK_PATH := "res://docs/tasks/TASK_874_release_first_exchange_contact_fire_real_window_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_contact_fire_real_window_recapture.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_exchange_contact_fire_real_window_recapture.ps1"
const MANIFEST_PATH := "res://tmp/release_first_exchange_contact_fire_real_window_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_contact_fire_real_window_recapture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_contact_fire_real_window_recapture.v1"
const CONTACT_FIRE_SCHEMA := "sternenbuergerchen.release_first_exchange_contact_fire_readability_fix.v1"
const CONTACT_FIRE_STYLE_ID := "task_873_release_first_exchange_contact_fire_readability_fix_v1"
const NEXT_TASK := "TASK_875 - Release First Exchange CONTACT-FIRE Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_874 Release First Exchange CONTACT-FIRE Real Window Recapture ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_review_ready_manifest_builds_acceptance()
	_test_optional_actual_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_874_release_first_exchange_contact_fire_real_window_recapture: FAILED")
		quit(1)
		return
	print("TASK_874_release_first_exchange_contact_fire_real_window_recapture: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_874 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_874 recapture analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_874 capture tool exists")
	_assert(task_text.contains("Release First Exchange CONTACT-FIRE Real Window Recapture"), "Task names TASK_874")
	_assert(status_text.contains("TASK_874 - Release First Exchange CONTACT-FIRE Real Window Recapture"), "Implementation status tracks TASK_874")
	_assert(roadmap_text.contains("TASK_874 - Release First Exchange CONTACT-FIRE Real Window Recapture (implementiert)"), "Roadmap marks TASK_874 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_875 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-CONTACT-FIRE-Real-Window-Recapture (TASK_874)"), "Contract documents TASK_874")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes TASK_874 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_874\""), "Analyzer writes TASK_874 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_873\""), "Analyzer links TASK_873")
	_assert(service_text.contains("SOURCE_RECAPTURE_TASK_ID: String = \"TASK_869\""), "Analyzer links TASK_869")
	_assert(service_text.contains(CONTACT_FIRE_STYLE_ID), "Analyzer records TASK_873 style")
	_assert(service_text.contains("\"window_handle_capture_trusted\""), "Analyzer requires trusted window-handle capture")
	_assert(service_text.contains("\"selected_fireteam_contact_fire_first_visible\""), "Analyzer requires #17 CONTACT FIRE visibility")
	_assert(service_text.contains("\"event_log_contact_fire_visible\""), "Analyzer requires event-log CONTACT FIRE")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")
	_assert(tool_text.contains("capture_release_first_exchange_los_setup_real_window_recapture.ps1"), "Capture tool reuses TASK_869")
	_assert(tool_text.contains("release_first_exchange_contact_fire_real_window_recapture.json"), "Capture tool writes TASK_874 manifest")
	_assert(tool_text.contains(CONTACT_FIRE_STYLE_ID), "Capture tool records TASK_873 style")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing capture manifest blocks TASK_874")
	_assert(blocker_ids.has("recapture_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("recapture_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports TASK_873 mismatch")
	_assert(blocker_ids.has("source_recapture_mismatch"), "Missing manifest reports TASK_869 mismatch")
	_assert(blocker_ids.has("source_los_setup_mismatch"), "Missing manifest reports TASK_868 mismatch")
	_assert(blocker_ids.has("source_exchange_mismatch"), "Missing manifest reports TASK_844 mismatch")
	_assert(blocker_ids.has("source_capture_fix_mismatch"), "Missing manifest reports TASK_871 mismatch")
	_assert(blocker_ids.has("capture_not_review_ready"), "Missing manifest reports capture gate")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports missing screenshot")
	_assert(blocker_ids.has("contact_fire_readability_schema_mismatch"), "Missing manifest reports TASK_873 schema")
	_assert(blocker_ids.has("contact_fire_readability_style_id_mismatch"), "Missing manifest reports TASK_873 style")
	_assert(blocker_ids.has("window_capture_method_not_handle_print"), "Missing manifest reports capture method")
	_assert(blocker_ids.has("window_capture_not_trusted"), "Missing manifest reports capture trust")
	_assert(blocker_ids.has("window_handle_capture_failed"), "Missing manifest reports handle failure")
	_assert(blocker_ids.has("required_recapture_checks_missing"), "Missing manifest reports missing checks")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_review_ready_manifest_builds_acceptance() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_good_manifest(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_874")
	_assert(String(snapshot.get("task_id", "")) == "TASK_874", "Snapshot task id matches TASK_874")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_873", "Snapshot links TASK_873")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_869", "Snapshot links TASK_869")
	_assert(String(snapshot.get("source_los_setup_task_id", "")) == "TASK_868", "Snapshot links TASK_868")
	_assert(String(snapshot.get("source_exchange_task_id", "")) == "TASK_844", "Snapshot links TASK_844")
	_assert(String(snapshot.get("source_capture_fix_task_id", "")) == "TASK_871", "Snapshot links TASK_871")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Snapshot accepts review_ready capture")
	_assert(bool(snapshot.get("capture_review_ready", false)), "Snapshot marks capture review-ready")
	_assert(bool(snapshot.get("window_screenshot_written", false)), "Snapshot records window screenshot")
	_assert(String(snapshot.get("window_capture_method", "")) == "window_handle_print", "Snapshot records handle capture")
	_assert(bool(snapshot.get("window_capture_trusted", false)), "Snapshot records trusted capture")
	_assert(bool(snapshot.get("window_handle_capture_succeeded", false)), "Snapshot records handle capture success")
	_assert(bool(snapshot.get("contact_fire_readability_schema_ok", false)), "Snapshot accepts TASK_873 schema")
	_assert(bool(snapshot.get("contact_fire_readability_style_id_ok", false)), "Snapshot accepts TASK_873 style")
	_assert(Array(snapshot.get("missing_recapture_checks", [])).is_empty(), "All recapture checks are present")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good capture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_manual_acceptance", "Good capture waits for manual acceptance")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_875")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_assert(true, "TASK_874 capture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(MANIFEST_PATH)
	var snapshot: Dictionary = Recapture.build_snapshot(manifest, {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual capture builds TASK_874 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_873", "Actual capture links TASK_873")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_869", "Actual capture links TASK_869")
	_assert(String(snapshot.get("expected_contact_fire_readability_style_id", "")) == CONTACT_FIRE_STYLE_ID, "Actual capture records TASK_873 style")
	_assert(bool(snapshot.get("read_only", false)), "Actual capture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual capture snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual capture snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(MANIFEST_PATH) if FileAccess.file_exists(MANIFEST_PATH) else _good_manifest()
	var snapshot: Dictionary = Recapture.build_snapshot(source_manifest, {})
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_874 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_874", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_873", "Roundtrip manifest keeps TASK_873 link")
	_assert(String(roundtrip.get("expected_contact_fire_readability_style_id", "")) == CONTACT_FIRE_STYLE_ID, "Roundtrip manifest keeps TASK_873 style")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip manifest keeps read-only boundary")


func _good_manifest() -> Dictionary:
	return {
		"schema": SCHEMA,
		"task_id": "TASK_874",
		"source_task_id": "TASK_873",
		"source_recapture_task_id": "TASK_869",
		"source_los_setup_task_id": "TASK_868",
		"source_exchange_task_id": "TASK_844",
		"source_capture_fix_task_id": "TASK_871",
		"gate": "review_ready",
		"branch": "task/release-first-exchange-contact-fire-real-window-recapture",
		"git_head": "test",
		"launch_argument": "--release-singleplayer-first-go-firefight",
		"wait_seconds": 38,
		"expected_contact_fire_readability_schema": CONTACT_FIRE_SCHEMA,
		"expected_contact_fire_readability_style_id": CONTACT_FIRE_STYLE_ID,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_handle_capture_succeeded": true,
		"foreground_matches_selected_process": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_exchange_contact_fire_real_window_recapture.png",
		"desktop_screenshot_path": "tmp/release_first_exchange_contact_fire_real_window_recapture_desktop.png",
		"hard_failures": [],
		"warnings": [],
		"required_checks": [
			"release_exe_started_with_first_go_firefight_arg",
			"task_873_contact_fire_readability_fix_expected",
			"task_869_real_window_recapture_source_expected",
			"task_868_los_setup_expected",
			"task_844_first_exchange_expected",
			"window_handle_capture_trusted",
			"selected_fireteam_contact_fire_first_visible",
			"mission_control_contact_fire_first_visible",
			"event_log_contact_fire_visible",
			"fire_trace_or_impact_target_focus_visible",
			"no_stale_no_los_or_contact_pressure_only_message",
			"command_surfaces_still_usable",
			"manual_visual_review_done",
		],
	}


func _issue_ids(issues: Array) -> Array:
	var ids: Array = []
	for issue_variant in issues:
		ids.append(String(Dictionary(issue_variant).get("id", "")))
	return ids


func _read_json_dict(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
