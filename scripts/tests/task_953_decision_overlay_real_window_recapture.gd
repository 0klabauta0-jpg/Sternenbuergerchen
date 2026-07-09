extends SceneTree

const Recapture := preload("res://scripts/mission/decision_overlay_real_window_recapture.gd")

const TASK_PATH := "res://docs/tasks/TASK_953_decision_overlay_real_window_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/decision_overlay_real_window_recapture.gd"
const TOOL_PATH := "res://scripts/tools/capture_decision_overlay_real_window_recapture.ps1"
const SOURCE_MANIFEST_PATH := "res://tmp/decision_overlay_real_window_recapture.json"
const OUTPUT_PATH := "res://tmp/decision_overlay_real_window_recapture_acceptance.json"
const SCHEMA := "sternenbuergerchen.decision_overlay_real_window_recapture.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.decision_overlay_f6_visual_polish.v1"
const SOURCE_STYLE_ID := "task_952_decision_overlay_compact_badges_v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_954 - Decision Overlay Real Window Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_953 Decision Overlay Real Window Recapture ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_good_manifest_is_review_ready()
	_test_completed_manual_checks_accept()
	_test_optional_actual_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_953_decision_overlay_real_window_recapture: FAILED")
		quit(1)
		return
	print("TASK_953_decision_overlay_real_window_recapture: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_953 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_953 recapture analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_953 capture tool exists")
	_assert(task_text.contains("TASK_953 - Decision Overlay Real Window Recapture"), "Task names TASK_953")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_954 follow-up")
	_assert(status_text.contains("TASK_953 - Decision Overlay Real Window Recapture"), "Implementation status tracks TASK_953")
	_assert(roadmap_text.contains("TASK_953 - Decision Overlay Real Window Recapture (implementiert"), "Roadmap marks TASK_953 implemented")
	_assert(command_contract_text.contains("Decision Overlay Real Window Recapture (TASK_953)"), "Mission feedback contract documents TASK_953")
	_assert(clarity_contract_text.contains("Decision Overlay Real Window Recapture (TASK_953)"), "Decision clarity contract documents TASK_953")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_953 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_953\""), "Analyzer writes TASK_953 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_952\""), "Analyzer links TASK_952")
	_assert(service_text.contains("REQUIRED_RECAPTURE_CHECKS"), "Analyzer defines required recapture checks")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"read_only_capture\": true"), "Analyzer declares read-only capture")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer creates no multiplayer truth")
	_assert(tool_text.contains("decision_overlay_real_window_recapture.json"), "Capture tool writes TASK_953 manifest")
	_assert(tool_text.contains(SOURCE_STYLE_ID), "Capture tool records TASK_952 style")
	_assert(tool_text.contains("manual_review_done = $false"), "Capture tool does not auto-pass manual review")
	_assert(tool_text.contains("decision_overlay_badges_visible"), "Capture tool requires badge visibility review")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Capture tool updates no shortcuts")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing manifest blocks TASK_953")
	_assert(blocker_ids.has("manifest_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("manifest_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports TASK_952 mismatch")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing manifest reports source schema mismatch")
	_assert(blocker_ids.has("source_style_mismatch"), "Missing manifest reports source style mismatch")
	_assert(blocker_ids.has("launch_argument_mismatch"), "Missing manifest reports launch arg mismatch")
	_assert(blocker_ids.has("capture_not_after_trace"), "Missing manifest reports capture ordering mismatch")
	_assert(blocker_ids.has("selected_process_missing"), "Missing manifest reports missing process")
	_assert(blocker_ids.has("capture_method_not_handle_print"), "Missing manifest reports capture method mismatch")
	_assert(blocker_ids.has("window_capture_not_trusted"), "Missing manifest reports untrusted capture")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports missing screenshot")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_good_manifest_is_review_ready() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_good_manifest(false))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_953")
	_assert(String(snapshot.get("task_id", "")) == "TASK_953", "Snapshot task id matches TASK_953")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_952", "Snapshot links TASK_952")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_952 schema")
	_assert(String(snapshot.get("source_style_id", "")) == SOURCE_STYLE_ID, "Snapshot records TASK_952 style")
	_assert(String(snapshot.get("status", "")) == "review_ready", "Good capture manifest is review-ready")
	_assert(bool(snapshot.get("review_ready", false)), "Snapshot marks review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Snapshot does not auto-accept without manual checks")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) > 0, "Manual checks remain missing")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_954")
	_assert(String(snapshot.get("recommended_direction", "")) == "cut_visual_findings_from_decision_overlay_real_window_recapture", "Snapshot recommends visual findings")
	_assert(_snapshot_is_read_only(snapshot), "Good snapshot remains read-only")
	_assert(bool(snapshot.get("read_only_capture", false)), "Good snapshot capture is read-only")


func _test_completed_manual_checks_accept() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_good_manifest(true))
	_assert(String(snapshot.get("status", "")) == "accepted", "Completed manual checks accept TASK_953")
	_assert(bool(snapshot.get("accepted", false)), "Accepted snapshot sets accepted flag")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) == 0, "No manual checks missing")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Accepted snapshot has no blockers")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Accepted snapshot has no issues")


func _test_optional_actual_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_MANIFEST_PATH):
		_assert(true, "TASK_953 manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH)
	var snapshot: Dictionary = Recapture.build_snapshot(manifest)
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual manifest builds TASK_953 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_952", "Actual manifest links TASK_952")
	_assert(_snapshot_is_read_only(snapshot), "Actual manifest snapshot remains read-only")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH) if FileAccess.file_exists(SOURCE_MANIFEST_PATH) else _good_manifest(false)
	var snapshot: Dictionary = Recapture.build_snapshot(source_manifest)
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_953 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_953", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_952", "Roundtrip keeps TASK_952 link")
	_assert(bool(roundtrip.get("review_ready", false)) or String(roundtrip.get("status", "")) == "accepted", "Roundtrip keeps review state")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _good_manifest(accepted: bool) -> Dictionary:
	var required: Array = [
		"decision_overlay_badges_visible",
		"safe_risky_suicidal_order_visible",
		"badge_colors_do_not_fight_fire_lane",
		"mission_control_line_still_readable",
		"command_surfaces_still_usable",
		"manual_visual_review_done",
		"no_new_hud_gameplay_truth",
	]
	return {
		"schema": SCHEMA,
		"task_id": "TASK_953",
		"source_task_id": "TASK_952",
		"gate": "accepted" if accepted else "review_ready",
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"source_schema": SOURCE_SCHEMA,
		"source_style_id": SOURCE_STYLE_ID,
		"source_gate": "pass",
		"selected_process_id": 953,
		"capture_process_id": 953,
		"capture_after_deeplink_final": true,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/decision_overlay_real_window_recapture.png",
		"desktop_screenshot_path": "tmp/decision_overlay_real_window_recapture_desktop.png",
		"hard_failures": [],
		"source_polish_snapshot": {
			"schema": SOURCE_SCHEMA,
			"task_id": "TASK_952",
			"style_id": SOURCE_STYLE_ID,
			"gate": "pass",
			"visual_badge_count": 3,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
		},
		"manual_review_required": true,
		"manual_review_done": accepted,
		"required_checks": required,
		"completed_manual_checks": required if accepted else [],
		"read_only": true,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and bool(snapshot.get("read_only_capture", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
