extends SceneTree

const Findings := preload("res://scripts/mission/release_fire_exchange_visual_polish_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_849_release_fire_exchange_visual_polish_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_fire_exchange_visual_polish_findings.gd"
const ACCEPTANCE_PATH := "res://tmp/release_first_exchange_recapture_acceptance.json"
const OUTPUT_PATH := "res://tmp/release_fire_exchange_visual_polish_findings.json"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_visual_polish_findings.v1"
const ACCEPTANCE_SCHEMA := "sternenbuergerchen.release_first_exchange_recapture_acceptance.v1"
const NEXT_TASK := "TASK_850 - Release Fire Exchange Focused Visual Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_849 Release Fire Exchange Visual Polish Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_acceptance_blocks()
	_test_ready_acceptance_builds_visual_findings()
	_test_optional_actual_acceptance_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_849_release_fire_exchange_visual_polish_findings: FAILED")
		quit(1)
		return
	print("TASK_849_release_fire_exchange_visual_polish_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_849 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_849 read-only findings analyzer exists")
	_assert(task_text.contains("Release Fire Exchange Visual Polish Findings"), "Task names visual polish findings")
	_assert(status_text.contains("TASK_849 - Release Fire Exchange Visual Polish Findings"), "Implementation status tracks TASK_849")
	_assert(roadmap_text.contains("TASK_849 - Release Fire Exchange Visual Polish Findings (implementiert)"), "Roadmap marks TASK_849 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_850 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Visual-Polish-Findings"), "Contract documents TASK_849")
	_assert(report_text.contains("Start-/Overlay") or report_text.contains("Start-Overlay"), "Report keeps the start-overlay friction visible")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_849 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_849\""), "Analyzer writes TASK_849 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_848\""), "Analyzer links TASK_848 source")
	_assert(service_text.contains("SOURCE_VISIBILITY_TASK_ID: String = \"TASK_847\""), "Analyzer links TASK_847")
	_assert(service_text.contains("SOURCE_EXCHANGE_TASK_ID: String = \"TASK_844\""), "Analyzer links TASK_844")
	_assert(service_text.contains("\"start_overlay_competes_with_combat\""), "Analyzer names start overlay issue")
	_assert(service_text.contains("\"world_lines_dominate_exchange\""), "Analyzer names world line issue")
	_assert(service_text.contains("\"fire_trace_or_impact_not_readable\""), "Analyzer names trace/impact readability issue")
	_assert(service_text.contains("\"hud_contact_fire_not_confirmed\""), "Analyzer names HUD confirmation issue")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth mutation")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "Analyzer declares no shortcut updates")


func _test_missing_acceptance_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing acceptance manifest blocks TASK_849")
	_assert(blocker_ids.has("acceptance_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("acceptance_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("acceptance_not_ready"), "Missing manifest reports acceptance not ready")
	_assert(blocker_ids.has("recapture_not_review_ready"), "Missing manifest reports recapture gate issue")
	_assert(blocker_ids.has("window_screenshot_missing"), "Missing manifest reports screenshot missing")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot is still read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_ready_acceptance_builds_visual_findings() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_acceptance_manifest(), _manual_review_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_849")
	_assert(String(snapshot.get("task_id", "")) == "TASK_849", "Snapshot task id matches TASK_849")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_848", "Snapshot links TASK_848")
	_assert(String(snapshot.get("source_recapture_task_id", "")) == "TASK_845", "Snapshot links TASK_845")
	_assert(String(snapshot.get("source_visibility_task_id", "")) == "TASK_847", "Snapshot links TASK_847")
	_assert(String(snapshot.get("source_exchange_task_id", "")) == "TASK_844", "Snapshot links TASK_844")
	_assert(bool(snapshot.get("acceptance_schema_ok", false)), "Snapshot accepts TASK_848 schema")
	_assert(String(snapshot.get("acceptance_status", "")) == "ready_for_manual_acceptance", "Snapshot accepts TASK_848 status")
	_assert(String(snapshot.get("recapture_gate", "")) == "review_ready", "Snapshot accepts review_ready recapture")
	_assert(bool(snapshot.get("window_screenshot_written", false)), "Snapshot records window screenshot")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Good acceptance has no blockers")
	_assert(String(snapshot.get("status", "")) == "ready_for_polish", "Manual notes produce ready_for_polish")
	_assert(String(snapshot.get("observed_window_state", "")) == "WORLD_LINES_AND_START_OVERLAY_DOMINATE", "Snapshot records observed state")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 3, "Snapshot records positive findings")
	_assert(issue_ids.has("start_overlay_competes_with_combat"), "Snapshot records start overlay issue")
	_assert(issue_ids.has("world_lines_dominate_exchange"), "Snapshot records world line issue")
	_assert(issue_ids.has("fire_trace_or_impact_not_readable"), "Snapshot records trace/impact issue")
	_assert(issue_ids.has("hud_contact_fire_not_confirmed"), "Snapshot records HUD confirmation issue")
	_assert(String(snapshot.get("primary_issue_id", "")) == "start_overlay_competes_with_combat", "Start overlay is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_850")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_optional_actual_acceptance_manifest() -> void:
	if not FileAccess.file_exists(ACCEPTANCE_PATH):
		_assert(true, "TASK_848 acceptance manifest is optional before local acceptance")
		return
	var manifest: Dictionary = _read_json_dict(ACCEPTANCE_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _manual_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual acceptance builds TASK_849 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_848", "Actual acceptance links TASK_848")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual acceptance keeps TASK_850 recommendation")
	_assert(bool(snapshot.get("read_only", false)), "Actual acceptance snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual acceptance snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual acceptance snapshot updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(ACCEPTANCE_PATH) if FileAccess.file_exists(ACCEPTANCE_PATH) else _good_acceptance_manifest()
	var snapshot: Dictionary = Findings.build_snapshot(source_manifest, _manual_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_849 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_849", "Roundtrip manifest keeps task id")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip manifest keeps next task")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "start_overlay_competes_with_combat", "Roundtrip manifest keeps primary issue")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip manifest keeps read-only boundary")


func _good_acceptance_manifest() -> Dictionary:
	return {
		"schema": ACCEPTANCE_SCHEMA,
		"task_id": "TASK_848",
		"status": "ready_for_manual_acceptance",
		"recapture_gate": "review_ready",
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_exchange_real_window.png",
		"desktop_screenshot_path": "tmp/release_first_exchange_real_window_desktop.png",
	}


func _manual_review_notes() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"observed_window_state": "WORLD_LINES_AND_START_OVERLAY_DOMINATE",
		"terrain_context_readable": true,
		"unit_cluster_visible": true,
		"start_overlay_competes_with_combat": true,
		"world_lines_dominate_exchange": true,
		"fire_trace_or_impact_not_readable": true,
		"hud_contact_fire_not_confirmed": true,
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
