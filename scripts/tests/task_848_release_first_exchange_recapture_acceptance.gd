extends SceneTree

const Acceptance := preload("res://scripts/mission/release_first_exchange_recapture_acceptance.gd")

const TASK_PATH := "res://docs/tasks/TASK_848_release_first_exchange_recapture_acceptance.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_recapture_acceptance.gd"
const SOURCE_RECAPTURE_PATH := "res://tmp/release_first_exchange_real_window_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_recapture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_recapture_acceptance.v1"
const VISIBILITY_SCHEMA := "sternenbuergerchen.release_fire_exchange_visibility_persistence.v1"
const VISIBILITY_STYLE_ID := "task_847_release_fire_exchange_visibility_persistence_v1"
const EXCHANGE_SCHEMA := "sternenbuergerchen.release_first_exchange_tension_tuning.v1"
const EXCHANGE_STYLE_ID := "task_844_release_first_exchange_tension_tuning_v1"
const NEXT_TASK := "TASK_849 - Release Fire Exchange Visual Polish Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_848 Release First Exchange Recapture Acceptance ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_review_ready_manifest_builds_acceptance()
	_test_optional_actual_recapture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_848_release_first_exchange_recapture_acceptance: FAILED")
		quit(1)
		return
	print("TASK_848_release_first_exchange_recapture_acceptance: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_848 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_848 read-only acceptance analyzer exists")
	_assert(task_text.contains("Release First Exchange Recapture Acceptance"), "Task names recapture acceptance")
	_assert(status_text.contains("TASK_848 - Release First Exchange Recapture Acceptance"), "Implementation status tracks TASK_848")
	_assert(roadmap_text.contains("TASK_848 - Release First Exchange Recapture Acceptance (implementiert)"), "Roadmap marks TASK_848 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_849 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Recapture-Acceptance"), "Contract documents TASK_848")
	_assert(report_text.contains("TASK_848") and report_text.contains("release_first_exchange_recapture_acceptance.json"), "Interim report tracks TASK_848 artifact")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_848 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_848\""), "Analyzer writes TASK_848 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_845\""), "Analyzer links TASK_845 source")
	_assert(service_text.contains("SOURCE_VISIBILITY_TASK_ID: String = \"TASK_847\""), "Analyzer links TASK_847 source")
	_assert(service_text.contains(VISIBILITY_SCHEMA), "Analyzer records TASK_847 visibility schema")
	_assert(service_text.contains(VISIBILITY_STYLE_ID), "Analyzer records TASK_847 visibility style id")
	_assert(service_text.contains("\"contact_fire_or_fire_exchange_visible\""), "Analyzer requires visible contact fire")
	_assert(service_text.contains("\"event_log_contact_fire_or_exchange_detail_visible\""), "Analyzer requires event-log contact fire detail")
	_assert(service_text.contains("\"no_stale_contact_pressure_only_message\""), "Analyzer requires no stale pressure-only message")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "Analyzer declares no shortcut updates")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing recapture manifest blocks acceptance")
	_assert(blocker_ids.has("recapture_not_review_ready"), "Missing manifest reports recapture_not_review_ready")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports window_screenshot_missing")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports source_task_mismatch")
	_assert(blocker_ids.has("source_capture_mismatch"), "Missing manifest reports source_capture_mismatch")
	_assert(blocker_ids.has("exchange_schema_mismatch"), "Missing manifest reports exchange_schema_mismatch")
	_assert(blocker_ids.has("exchange_style_id_mismatch"), "Missing manifest reports exchange_style_id_mismatch")
	_assert(blocker_ids.has("required_acceptance_checks_missing"), "Missing manifest reports missing required checks")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot is still read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_review_ready_manifest_builds_acceptance() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot(_good_recapture_manifest(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_848")
	_assert(String(snapshot.get("task_id", "")) == "TASK_848", "Snapshot task id matches TASK_848")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_845", "Snapshot links TASK_845")
	_assert(String(snapshot.get("source_visibility_task_id", "")) == "TASK_847", "Snapshot links TASK_847")
	_assert(String(snapshot.get("source_exchange_task_id", "")) == "TASK_844", "Snapshot links TASK_844")
	_assert(String(snapshot.get("recapture_gate", "")) == "review_ready", "Snapshot accepts review_ready recapture")
	_assert(bool(snapshot.get("recapture_review_ready", false)), "Snapshot marks recapture review-ready")
	_assert(bool(snapshot.get("window_screenshot_written", false)), "Snapshot records window screenshot")
	_assert(bool(snapshot.get("desktop_screenshot_written", false)), "Snapshot records desktop screenshot")
	_assert(String(snapshot.get("expected_visibility_schema", "")) == VISIBILITY_SCHEMA, "Snapshot records TASK_847 visibility schema")
	_assert(String(snapshot.get("expected_visibility_style_id", "")) == VISIBILITY_STYLE_ID, "Snapshot records TASK_847 visibility style")
	_assert(bool(snapshot.get("exchange_schema_ok", false)), "Snapshot accepts TASK_844 exchange schema")
	_assert(bool(snapshot.get("exchange_style_id_ok", false)), "Snapshot accepts TASK_844 exchange style")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good recapture has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_manual_acceptance", "Good recapture waits for manual acceptance")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Manual review stays open")
	_assert(Array(snapshot.get("missing_acceptance_checks", [])).is_empty(), "All acceptance checks are present")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_849")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_recapture_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_RECAPTURE_PATH):
		_assert(true, "TASK_845 recapture manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_RECAPTURE_PATH)
	var snapshot: Dictionary = Acceptance.build_snapshot(manifest, {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual recapture builds TASK_848 schema")
	_assert(String(snapshot.get("source_visibility_task_id", "")) == "TASK_847", "Actual recapture links TASK_847")
	_assert(String(snapshot.get("expected_visibility_style_id", "")) == VISIBILITY_STYLE_ID, "Actual recapture records TASK_847 style")
	_assert(bool(snapshot.get("read_only", false)), "Actual recapture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual recapture snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual recapture snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(SOURCE_RECAPTURE_PATH) if FileAccess.file_exists(SOURCE_RECAPTURE_PATH) else _good_recapture_manifest()
	var snapshot: Dictionary = Acceptance.build_snapshot(source_manifest, {})
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_848 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_848", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("source_visibility_task_id", "")) == "TASK_847", "Roundtrip manifest keeps TASK_847 link")
	_assert(String(roundtrip.get("expected_visibility_style_id", "")) == VISIBILITY_STYLE_ID, "Roundtrip manifest keeps visibility style")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip manifest keeps read-only boundary")


func _good_recapture_manifest() -> Dictionary:
	return {
		"gate": "review_ready",
		"source_task_id": "TASK_844",
		"source_capture_task_id": "TASK_837",
		"branch": "task/release-first-exchange-recapture-acceptance",
		"git_head": "test",
		"launch_argument": "--release-singleplayer-first-go-firefight",
		"wait_seconds": 32,
		"expected_exchange_schema": EXCHANGE_SCHEMA,
		"expected_exchange_style_id": EXCHANGE_STYLE_ID,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_exchange_real_window.png",
		"desktop_screenshot_path": "tmp/release_first_exchange_real_window_desktop.png",
		"hard_failures": [],
		"warnings": [],
		"required_checks": [
			"contact_fire_or_fire_exchange_visible",
			"event_log_contact_fire_or_exchange_detail_visible",
			"selected_fireteam_next_why_mentions_contact_or_fire",
			"mission_control_next_why_mentions_contact_or_fire",
			"fire_event_trace_or_impact_visible",
			"no_stale_contact_pressure_only_message",
		],
		"manual_review_required": true,
		"manual_review_done": false,
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
