extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_946_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.ps1"
const SOURCE_MANIFEST_PATH := "res://tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.v1"
const SECOND_FIX_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.v1"
const SECOND_FIX_STYLE_ID := "task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix_v1"
const FINDINGS_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.v1"
const FOLLOWUP_FIX_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
const FOLLOWUP_FIX_STYLE_ID := "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
const SOURCE_RECAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_947 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_946 Release First Exchange Followup Second Recapture ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_good_manifest_is_review_ready()
	_test_completed_manual_checks_accept()
	_test_optional_actual_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_946_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture: FAILED")
		quit(1)
		return
	print("TASK_946_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_946 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_946 analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_946 capture tool exists")
	_assert(task_text.contains("Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Recapture"), "Task names TASK_946")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_947 follow-up")
	_assert(status_text.contains("TASK_946 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Recapture"), "Implementation status tracks TASK_946")
	_assert(roadmap_text.contains("TASK_946 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Recapture (implementiert"), "Roadmap marks TASK_946 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_947 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Followup-Fix-Player-Polish-Final-Tuning-Followup-Second-Recapture (TASK_946)"), "Contract documents TASK_946")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_946 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_946\""), "Analyzer writes TASK_946 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_945\""), "Analyzer links TASK_945")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_944\""), "Analyzer links TASK_944")
	_assert(service_text.contains("SOURCE_FOLLOWUP_FIX_TASK_ID: String = \"TASK_942\""), "Analyzer links TASK_942")
	_assert(service_text.contains("SOURCE_RECAPTURE_TASK_ID: String = \"TASK_943\""), "Analyzer links TASK_943")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"read_only_capture\": true"), "Analyzer declares read-only capture")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "Analyzer declares no shortcut updates")
	_assert(tool_text.contains("capture_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.ps1"), "Capture tool reuses TASK_943 path")
	_assert(tool_text.contains("release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.json"), "Capture tool writes TASK_946 manifest")
	_assert(tool_text.contains(SECOND_FIX_STYLE_ID), "Capture tool records expected TASK_945 style")
	_assert(tool_text.contains(FOLLOWUP_FIX_STYLE_ID), "Capture tool preserves TASK_942 style")
	_assert(tool_text.contains("manual_review_done = $false"), "Capture tool does not auto-pass manual review")
	_assert(tool_text.contains("second_fire_lane_is_first_world_movement"), "Capture tool requires second-fix lane first movement review")
	_assert(tool_text.contains("second_lane_reads_before_fire_contact_text"), "Capture tool requires second-fix lane-before-text review")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Capture tool updates no shortcuts")


func _test_missing_manifest_blocks() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_946 analyzer can be loaded")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing manifest blocks TASK_946")
	_assert(blocker_ids.has("manifest_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("manifest_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports TASK_945 mismatch")
	_assert(blocker_ids.has("source_findings_task_mismatch"), "Missing manifest reports TASK_944 mismatch")
	_assert(blocker_ids.has("source_followup_fix_task_mismatch"), "Missing manifest reports TASK_942 mismatch")
	_assert(blocker_ids.has("source_recapture_task_mismatch"), "Missing manifest reports TASK_943 mismatch")
	_assert(blocker_ids.has("source_recapture_schema_mismatch"), "Missing manifest reports TASK_943 schema mismatch")
	_assert(blocker_ids.has("second_fix_schema_mismatch"), "Missing manifest reports TASK_945 schema mismatch")
	_assert(blocker_ids.has("second_fix_style_mismatch"), "Missing manifest reports TASK_945 style mismatch")
	_assert(blocker_ids.has("findings_schema_mismatch"), "Missing manifest reports TASK_944 schema mismatch")
	_assert(blocker_ids.has("followup_fix_schema_mismatch"), "Missing manifest reports TASK_942 schema mismatch")
	_assert(blocker_ids.has("followup_fix_style_mismatch"), "Missing manifest reports TASK_942 style mismatch")
	_assert(blocker_ids.has("launch_argument_mismatch"), "Missing manifest reports launch arg mismatch")
	_assert(blocker_ids.has("second_capture_not_after_trace"), "Missing manifest reports capture ordering mismatch")
	_assert(blocker_ids.has("selected_process_missing"), "Missing manifest reports missing process")
	_assert(blocker_ids.has("second_capture_method_not_handle_print"), "Missing manifest reports capture method mismatch")
	_assert(blocker_ids.has("second_window_capture_not_trusted"), "Missing manifest reports untrusted capture")
	_assert(blocker_ids.has("second_window_screenshot_missing"), "Missing manifest reports missing screenshot")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_good_manifest_is_review_ready() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_946 analyzer can be loaded for review-ready manifest")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _good_manifest(false)))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_946")
	_assert(String(snapshot.get("task_id", "")) == "TASK_946", "Snapshot task id matches TASK_946")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_945", "Snapshot links TASK_945")
	_assert(String(snapshot.get("source_findings_task_id", "")) == "TASK_944", "Snapshot links TASK_944")
	_assert(String(snapshot.get("source_followup_fix_task_id", "")) == "TASK_942", "Snapshot links TASK_942")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_943", "Snapshot links TASK_943")
	_assert(String(snapshot.get("expected_second_fix_schema", "")) == SECOND_FIX_SCHEMA, "Snapshot records TASK_945 schema")
	_assert(String(snapshot.get("expected_second_fix_style_id", "")) == SECOND_FIX_STYLE_ID, "Snapshot records TASK_945 style")
	_assert(String(snapshot.get("expected_findings_schema", "")) == FINDINGS_SCHEMA, "Snapshot records TASK_944 schema")
	_assert(String(snapshot.get("expected_followup_fix_schema", "")) == FOLLOWUP_FIX_SCHEMA, "Snapshot records TASK_942 schema")
	_assert(String(snapshot.get("expected_followup_fix_style_id", "")) == FOLLOWUP_FIX_STYLE_ID, "Snapshot records TASK_942 style")
	_assert(String(snapshot.get("source_recapture_schema", "")) == SOURCE_RECAPTURE_SCHEMA, "Snapshot records TASK_943 schema")
	_assert(String(snapshot.get("status", "")) == "review_ready", "Good capture manifest is review-ready")
	_assert(bool(snapshot.get("review_ready", false)), "Snapshot marks review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Snapshot does not auto-accept without manual checks")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Snapshot records final source CONTACT FIRE")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) > 0, "Manual checks remain missing")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_947")
	_assert(String(snapshot.get("recommended_direction", "")) == "cut_visual_findings_from_real_window_second_recapture", "Snapshot recommends findings slice")
	_assert(_snapshot_is_read_only(snapshot), "Snapshot is read-only")


func _test_completed_manual_checks_accept() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_946 analyzer can be loaded for accepted manifest")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _good_manifest(true)))
	_assert(String(snapshot.get("status", "")) == "accepted", "Completed manual checks accept TASK_946")
	_assert(bool(snapshot.get("accepted", false)), "Snapshot accepted flag is true")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) == 0, "No manual checks missing")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Accepted snapshot has no blockers")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Accepted snapshot has no issues")


func _test_optional_actual_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_MANIFEST_PATH):
		_assert(true, "TASK_946 manifest is optional before local capture")
		return
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_946 analyzer can be loaded for actual manifest")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH)
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", manifest))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual manifest builds TASK_946 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_945", "Actual manifest links TASK_945")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_943", "Actual manifest links TASK_943")
	_assert(_snapshot_is_read_only(snapshot), "Actual manifest snapshot remains read-only")


func _test_manifest_roundtrip() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_946 analyzer can be loaded for roundtrip")
		return
	var source_manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH) if FileAccess.file_exists(SOURCE_MANIFEST_PATH) else _good_manifest(false)
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", source_manifest))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_946 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_946", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_945", "Roundtrip keeps TASK_945 link")
	_assert(String(roundtrip.get("source_recapture_task_id", "")) == "TASK_943", "Roundtrip keeps TASK_943 link")
	_assert(bool(roundtrip.get("review_ready", false)) or String(roundtrip.get("status", "")) == "accepted", "Roundtrip keeps review state")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _good_manifest(accepted: bool) -> Dictionary:
	var required: Array = [
		"contact_fire_visible_in_selected_fireteam",
		"contact_fire_visible_in_mission_control",
		"event_log_contact_fire_visible_without_blocking",
		"second_fire_lane_is_first_world_movement",
		"second_source_target_anchors_carry_direction",
		"second_anchors_do_not_read_as_discs",
		"second_world_fire_label_stays_behind_lane",
		"second_target_halo_stays_behind_lane",
		"second_grid_world_noise_not_competing",
		"second_lane_reads_before_fire_contact_text",
		"command_surfaces_still_usable",
		"no_new_hud_gameplay_truth",
	]
	return {
		"schema": SCHEMA,
		"task_id": "TASK_946",
		"source_task_id": "TASK_945",
		"source_findings_task_id": "TASK_944",
		"source_followup_fix_task_id": "TASK_942",
		"source_recapture_task_id": "TASK_943",
		"gate": "accepted" if accepted else "review_ready",
		"launch_argument": FIRST_GO_ARG,
		"expected_second_fix_schema": SECOND_FIX_SCHEMA,
		"expected_second_fix_style_id": SECOND_FIX_STYLE_ID,
		"expected_findings_schema": FINDINGS_SCHEMA,
		"expected_followup_fix_schema": FOLLOWUP_FIX_SCHEMA,
		"expected_followup_fix_style_id": FOLLOWUP_FIX_STYLE_ID,
		"source_recapture_schema": SOURCE_RECAPTURE_SCHEMA,
		"source_recapture_gate": "review_ready",
		"selected_process_id": 946,
		"second_capture_process_id": 946,
		"second_capture_after_deeplink_final": true,
		"second_window_capture_method": "window_handle_print",
		"second_window_capture_trusted": true,
		"second_window_handle_capture_succeeded": true,
		"second_window_screenshot_written": true,
		"second_desktop_screenshot_written": true,
		"second_window_screenshot_path": "tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.png",
		"second_desktop_screenshot_path": "tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture_desktop.png",
		"hard_failures": [],
		"final_source_snapshot": {
			"source_observed_state": "FINAL_SOURCE_CONTACT_FIRE",
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
		},
		"source_second_fix_snapshot": {
			"schema": SECOND_FIX_SCHEMA,
			"task_id": "TASK_945",
			"style_id": SECOND_FIX_STYLE_ID,
			"gate": "pass",
		},
		"source_findings_snapshot": {
			"schema": FINDINGS_SCHEMA,
			"task_id": "TASK_944",
			"status": "ready_for_followup_fix_player_polish_final_tuning_followup_second_fix",
		},
		"source_followup_fix_snapshot": {
			"schema": FOLLOWUP_FIX_SCHEMA,
			"task_id": "TASK_942",
			"style_id": FOLLOWUP_FIX_STYLE_ID,
		},
		"source_recapture_review": {
			"screenshot_observed_state": "TASK_943_REVIEW_READY",
		},
		"second_world_read_render_review": {
			"frame_trace_method": "post_deeplink_final_window_handle_screenshot_second_review_required",
			"rendered_texts_collected": accepted,
			"screenshot_observed_state": "TASK_946_ACCEPTED" if accepted else "TASK_946_REVIEW_REQUIRED",
			"expected_second_fix_schema": SECOND_FIX_SCHEMA,
			"expected_second_fix_style_id": SECOND_FIX_STYLE_ID,
			"expected_fire_lane_is_first_world_movement": true,
			"expected_fire_lane_reads_before_fire_contact_text": true,
		},
		"required_checks": required,
		"completed_manual_checks": required if accepted else [],
		"manual_review_required": true,
		"manual_review_done": accepted,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and bool(snapshot.get("read_only_capture", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true)) \
		and not bool(snapshot.get("updates_shortcuts", true))


func _issue_ids(issues: Array) -> Array:
	var ids: Array = []
	for issue_variant in issues:
		ids.append(String(Dictionary(issue_variant).get("id", "")))
	return ids


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
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
		return
	_failed += 1
	push_error("FAIL: %s" % message)
