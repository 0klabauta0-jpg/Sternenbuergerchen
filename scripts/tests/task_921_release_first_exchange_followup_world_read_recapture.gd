extends SceneTree

const Recapture := preload("res://scripts/mission/release_first_exchange_followup_world_read_recapture.gd")

const TASK_PATH := "res://docs/tasks/TASK_921_release_first_exchange_followup_world_read_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_followup_world_read_recapture.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_exchange_followup_world_read_recapture.ps1"
const SOURCE_MANIFEST_PATH := "res://tmp/release_first_exchange_followup_world_read_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_followup_world_read_recapture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_followup_world_read_recapture.v1"
const FOLLOWUP_SCHEMA := "sternenbuergerchen.release_first_exchange_final_world_read_followup_fix.v1"
const FOLLOWUP_STYLE_ID := "task_920_release_first_exchange_final_world_read_followup_v1"
const FINAL_SCHEMA := "sternenbuergerchen.release_first_exchange_fire_lane_world_read_final_polish.v1"
const FINAL_STYLE_ID := "task_916_release_first_exchange_fire_lane_world_read_final_v1"
const SOURCE_RECAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_final_world_read_recapture.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_922 - Release First Exchange Followup World Read Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_921 Release First Exchange Followup World Read Recapture ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_good_manifest_is_review_ready()
	_test_completed_manual_checks_accept()
	_test_optional_actual_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_921_release_first_exchange_followup_world_read_recapture: FAILED")
		quit(1)
		return
	print("TASK_921_release_first_exchange_followup_world_read_recapture: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_921 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_921 analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_921 capture tool exists")
	_assert(task_text.contains("Release First Exchange Followup World Read Recapture"), "Task names TASK_921")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_922 follow-up")
	_assert(status_text.contains("TASK_921 - Release First Exchange Followup World Read Recapture"), "Implementation status tracks TASK_921")
	_assert(roadmap_text.contains("TASK_921 - Release First Exchange Followup World Read Recapture (implementiert"), "Roadmap marks TASK_921 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_922 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Followup-World-Read-Recapture (TASK_921)"), "Contract documents TASK_921")
	_assert(report_text.contains("TASK_921") and report_text.contains("TASK_922"), "HTML report tracks TASK_921 and TASK_922")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_921 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_921\""), "Analyzer writes TASK_921 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_920\""), "Analyzer links TASK_920")
	_assert(service_text.contains("SOURCE_RECAPTURE_TASK_ID: String = \"TASK_917\""), "Analyzer links TASK_917")
	_assert(service_text.contains("SOURCE_FINAL_TASK_ID: String = \"TASK_916\""), "Analyzer links TASK_916")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_918\""), "Analyzer links TASK_918")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"read_only_capture\": true"), "Analyzer declares read-only capture")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "Analyzer declares no shortcut updates")
	_assert(tool_text.contains("capture_release_first_exchange_final_world_read_recapture.ps1"), "Capture tool reuses TASK_917 path")
	_assert(tool_text.contains("release_first_exchange_followup_world_read_recapture.json"), "Capture tool writes TASK_921 manifest")
	_assert(tool_text.contains(FOLLOWUP_STYLE_ID), "Capture tool records expected TASK_920 style")
	_assert(tool_text.contains(FINAL_STYLE_ID), "Capture tool records expected TASK_916 style")
	_assert(tool_text.contains("manual_review_done = $false"), "Capture tool does not auto-pass manual review")
	_assert(tool_text.contains("followup_fire_lane_is_first_world_movement"), "Capture tool requires follow-up first movement review")
	_assert(tool_text.contains("followup_source_target_anchors_carry_direction"), "Capture tool requires follow-up direction anchor review")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Capture tool updates no shortcuts")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing manifest blocks TASK_921")
	_assert(blocker_ids.has("manifest_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("manifest_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports TASK_920 mismatch")
	_assert(blocker_ids.has("source_recapture_task_mismatch"), "Missing manifest reports TASK_917 mismatch")
	_assert(blocker_ids.has("source_final_task_mismatch"), "Missing manifest reports TASK_916 mismatch")
	_assert(blocker_ids.has("source_findings_task_mismatch"), "Missing manifest reports TASK_918 mismatch")
	_assert(blocker_ids.has("source_recapture_schema_mismatch"), "Missing manifest reports TASK_917 schema mismatch")
	_assert(blocker_ids.has("followup_schema_mismatch"), "Missing manifest reports TASK_920 schema mismatch")
	_assert(blocker_ids.has("followup_style_mismatch"), "Missing manifest reports TASK_920 style mismatch")
	_assert(blocker_ids.has("final_schema_mismatch"), "Missing manifest reports TASK_916 schema mismatch")
	_assert(blocker_ids.has("final_style_mismatch"), "Missing manifest reports TASK_916 style mismatch")
	_assert(blocker_ids.has("launch_argument_mismatch"), "Missing manifest reports launch arg mismatch")
	_assert(blocker_ids.has("post_followup_capture_not_after_trace"), "Missing manifest reports capture ordering mismatch")
	_assert(blocker_ids.has("selected_process_missing"), "Missing manifest reports missing process")
	_assert(blocker_ids.has("post_followup_capture_method_not_handle_print"), "Missing manifest reports capture method mismatch")
	_assert(blocker_ids.has("post_followup_window_capture_not_trusted"), "Missing manifest reports untrusted capture")
	_assert(blocker_ids.has("post_followup_window_screenshot_missing"), "Missing manifest reports missing screenshot")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no command")


func _test_good_manifest_is_review_ready() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_good_manifest(false))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_921")
	_assert(String(snapshot.get("task_id", "")) == "TASK_921", "Snapshot task id matches TASK_921")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_920", "Snapshot links TASK_920")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_917", "Snapshot links TASK_917")
	_assert(String(snapshot.get("source_final_task_id", "")) == "TASK_916", "Snapshot links TASK_916")
	_assert(String(snapshot.get("source_findings_task_id", "")) == "TASK_918", "Snapshot links TASK_918")
	_assert(String(snapshot.get("expected_followup_schema", "")) == FOLLOWUP_SCHEMA, "Snapshot records TASK_920 schema")
	_assert(String(snapshot.get("expected_followup_style_id", "")) == FOLLOWUP_STYLE_ID, "Snapshot records TASK_920 style")
	_assert(String(snapshot.get("expected_final_schema", "")) == FINAL_SCHEMA, "Snapshot records TASK_916 schema")
	_assert(String(snapshot.get("expected_final_style_id", "")) == FINAL_STYLE_ID, "Snapshot records TASK_916 style")
	_assert(String(snapshot.get("source_recapture_schema", "")) == SOURCE_RECAPTURE_SCHEMA, "Snapshot records TASK_917 schema")
	_assert(String(snapshot.get("status", "")) == "review_ready", "Good capture manifest is review-ready")
	_assert(bool(snapshot.get("review_ready", false)), "Snapshot marks review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Snapshot does not auto-accept without manual checks")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Snapshot records final source CONTACT FIRE")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) > 0, "Manual checks remain missing")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_922")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(bool(snapshot.get("read_only_capture", false)), "Snapshot capture is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_completed_manual_checks_accept() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_good_manifest(true))
	_assert(String(snapshot.get("status", "")) == "accepted", "Completed manual checks accept TASK_921")
	_assert(bool(snapshot.get("accepted", false)), "Snapshot accepted flag is true")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) == 0, "No manual checks missing")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Accepted snapshot has no blockers")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Accepted snapshot has no issues")


func _test_optional_actual_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_MANIFEST_PATH):
		_assert(true, "TASK_921 manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH)
	var snapshot: Dictionary = Recapture.build_snapshot(manifest)
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual manifest builds TASK_921 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_920", "Actual manifest links TASK_920")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_917", "Actual manifest links TASK_917")
	_assert(bool(snapshot.get("read_only", false)), "Actual manifest snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual manifest snapshot sets no gameplay truth")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH) if FileAccess.file_exists(SOURCE_MANIFEST_PATH) else _good_manifest(false)
	var snapshot: Dictionary = Recapture.build_snapshot(source_manifest)
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_921 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_921", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_920", "Roundtrip keeps TASK_920 link")
	_assert(String(roundtrip.get("source_recapture_task_id", "")) == "TASK_917", "Roundtrip keeps TASK_917 link")
	_assert(bool(roundtrip.get("review_ready", false)) or String(roundtrip.get("status", "")) == "accepted", "Roundtrip keeps review state")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_manifest(accepted: bool) -> Dictionary:
	var required: Array = [
		"contact_fire_visible_in_selected_fireteam",
		"contact_fire_visible_in_mission_control",
		"event_log_contact_fire_visible_without_blocking",
		"followup_fire_lane_is_first_world_movement",
		"followup_source_target_anchors_carry_direction",
		"followup_world_fire_label_stays_behind_lane",
		"followup_target_halo_stays_behind_lane",
		"followup_grid_world_noise_not_competing",
		"command_surfaces_still_usable",
		"no_new_hud_gameplay_truth",
	]
	return {
		"schema": SCHEMA,
		"task_id": "TASK_921",
		"source_task_id": "TASK_920",
		"source_recapture_task_id": "TASK_917",
		"source_final_task_id": "TASK_916",
		"source_findings_task_id": "TASK_918",
		"gate": "accepted" if accepted else "review_ready",
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"expected_followup_schema": FOLLOWUP_SCHEMA,
		"expected_followup_style_id": FOLLOWUP_STYLE_ID,
		"expected_final_schema": FINAL_SCHEMA,
		"expected_final_style_id": FINAL_STYLE_ID,
		"source_recapture_schema": SOURCE_RECAPTURE_SCHEMA,
		"source_recapture_gate": "review_ready",
		"selected_process_id": 333,
		"post_followup_capture_process_id": 333,
		"post_followup_capture_after_deeplink_final": true,
		"post_followup_window_capture_method": "window_handle_print",
		"post_followup_window_capture_trusted": true,
		"post_followup_window_handle_capture_succeeded": true,
		"post_followup_window_screenshot_written": true,
		"post_followup_desktop_screenshot_written": true,
		"post_followup_window_screenshot_path": "tmp/release_first_exchange_followup_world_read_recapture.png",
		"post_followup_desktop_screenshot_path": "tmp/release_first_exchange_followup_world_read_recapture_desktop.png",
		"hard_failures": [],
		"final_source_snapshot": {
			"source_observed_state": "FINAL_SOURCE_CONTACT_FIRE",
			"stage": "deeplink_final",
			"timestamp_msec": 73104,
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
		},
		"post_followup_world_read_render_review": {
			"frame_trace_method": "post_deeplink_final_window_handle_screenshot_followup_world_read_review_required",
			"rendered_texts_collected": accepted,
			"screenshot_observed_state": "TASK_921_ACCEPTED" if accepted else "TASK_921_REVIEW_REQUIRED",
			"expected_followup_schema": FOLLOWUP_SCHEMA,
			"expected_followup_style_id": FOLLOWUP_STYLE_ID,
			"expected_final_schema": FINAL_SCHEMA,
			"expected_final_style_id": FINAL_STYLE_ID,
			"expected_fire_lane_is_first_world_movement": true,
			"expected_source_target_anchors_carry_direction": true,
		},
		"required_checks": required,
		"completed_manual_checks": required if accepted else [],
		"manual_review_required": true,
		"manual_review_done": accepted,
	}


func _issue_ids(issues: Array) -> Array:
	var ids: Array = []
	for issue_variant in issues:
		ids.append(String(Dictionary(issue_variant).get("id", "")))
	return ids


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if parsed is Dictionary else {}


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
