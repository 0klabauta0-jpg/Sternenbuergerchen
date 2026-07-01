extends SceneTree

const POLISH_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_command_surface_polish.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_783_station_reentry_firefight_command_surface_polish.md"
const TASK_782_PATH: String = "res://docs/tasks/TASK_782_station_reentry_firefight_command_surface_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_command_surface_polish.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_783 Station Reentry Firefight Command Surface Polish ===")
	_test_docs_contract_and_report()
	_test_missing_findings_blocks()
	_test_open_review_blocks_to_visible_recapture()
	_test_clean_sources_build_polished_surface()
	_test_task_783_scope_issues_are_applied()
	_test_external_issue_routes_outside_task_783()
	_test_missing_interaction_blocks_gates()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_783: FAILED")
		quit(1)
		return
	print("TASK_783: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_783 task file exists")
	_assert(FileAccess.file_exists(TASK_782_PATH), "TASK_782 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Command Surface Polish"), "TASK_783 task names command surface polish")
	_assert(status_text.contains("TASK_783 - Station Reentry Firefight Command Surface Polish"), "Implementation status tracks TASK_783")
	_assert(roadmap_text.contains("TASK_783 - Station Reentry Firefight Command Surface Polish (implementiert)"), "Roadmap marks TASK_783 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Command-Surface-Polish"), "Mission command feedback contract documents TASK_783")
	_assert(report_text.contains("Aktueller Griff: TASK_793"), "Reentry handbook marks TASK_793 current")
	_assert(report_text.contains("station_reentry_firefight_command_surface_polish.json"), "Reentry handbook names TASK_783 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_command_surface_polish.style_ready"'), "Reentry handbook exports TASK_783 style readiness")


func _test_missing_findings_blocks() -> void:
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_command_surface_polish.v1", "TASK_783 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_command_surface_findings", "Missing TASK_782 findings blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_782"), "Missing findings recommends TASK_782")
	_assert(_snapshot_is_read_only(snapshot), "Missing-findings polish remains read-only")


func _test_open_review_blocks_to_visible_recapture() -> void:
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", {
		"command_surface_findings": _findings("needs_visible_command_surface_review"),
		"interaction_polish": _interaction(),
	}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_visible_command_surface_review", "Open visible review blocks TASK_783 polish")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_781"), "Open review routes to visible recapture")
	_assert(_snapshot_is_read_only(snapshot), "Open-review polish remains read-only")


func _test_clean_sources_build_polished_surface() -> void:
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", {
		"command_surface_findings": _findings("ready_for_next_station_firefight_iteration"),
		"interaction_polish": _interaction(),
	}))
	_assert(String(snapshot.get("status", "")) == "ready_for_command_surface_polish_review", "Clean sources build ready polish")
	_assert(bool(snapshot.get("ready_for_command_surface_polish_review", false)), "Ready flag is true")
	_assert(String(snapshot.get("command_surface_style_id", "")) == "task_783_firefight_command_surface_v1", "Style id is stable")
	_assert(String(snapshot.get("summary_line", "")).begins_with("NEXT HOLD"), "Summary line starts with primary action")
	_assert(String(snapshot.get("summary_line", "")).contains("HOLD FIRE"), "Summary line keeps Hold Fire visible")
	_assert(String(snapshot.get("guard_line", "")).contains("NO AUTO CMD"), "Guard line names no-auto-command")
	_assert(String(snapshot.get("guard_line", "")).contains("EXISTING BUTTONS"), "Guard line names existing buttons")
	_assert(int(snapshot.get("quick_action_count", 0)) >= 5, "Quick-action rail keeps all expected actions")
	_assert(int(snapshot.get("surface_row_count", 0)) == 4, "Surface exposes four stable rows")
	_assert(Array(snapshot.get("failed_gate_ids", [])).is_empty(), "Ready polish has no failed gates")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_784"), "Ready polish routes to refreshed playtest packet")
	_assert(_snapshot_is_read_only(snapshot), "Ready polish remains read-only")


func _test_task_783_scope_issues_are_applied() -> void:
	var findings: Dictionary = _findings("needs_targeted_command_surface_polish", ["quick_actions_hidden", "surface_too_dense"])
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", {
		"command_surface_findings": findings,
		"interaction_polish": _interaction(),
	}))
	_assert(String(snapshot.get("status", "")) == "ready_for_command_surface_polish_review", "TASK_783-scope issues are handled by polish surface")
	_assert(Array(snapshot.get("polished_issue_ids", [])).has("quick_actions_hidden"), "Quick-action issue is marked polished")
	_assert(Array(snapshot.get("polished_issue_ids", [])).has("surface_too_dense"), "Density issue is marked polished")
	_assert(bool(snapshot.get("applies_findings", false)), "Snapshot records that findings were applied")
	_assert(not bool(snapshot.get("requires_external_followup", true)), "In-scope issues do not require external followup")
	_assert(_snapshot_is_read_only(snapshot), "In-scope polish remains read-only")


func _test_external_issue_routes_outside_task_783() -> void:
	var findings: Dictionary = _findings("needs_targeted_command_surface_polish", ["host_client_surface_mismatch"])
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", {
		"command_surface_findings": findings,
		"interaction_polish": _interaction(),
	}))
	_assert(String(snapshot.get("status", "")) == "needs_external_command_surface_followup", "External issues route outside TASK_783")
	_assert(Array(snapshot.get("external_issue_ids", [])).has("host_client_surface_mismatch"), "Host/client issue is external")
	_assert(bool(snapshot.get("requires_external_followup", false)), "External followup flag is true")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_770"), "Host/client mismatch routes to TASK_770")
	_assert(_snapshot_is_read_only(snapshot), "External-followup snapshot remains read-only")


func _test_missing_interaction_blocks_gates() -> void:
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", {
		"command_surface_findings": _findings("ready_for_next_station_firefight_iteration"),
		"interaction_polish": {},
	}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_command_surface_polish_gates_green", "Missing interaction blocks polish gates")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("interaction_polish_ready"), "Missing interaction gate is failed")
	_assert(_snapshot_is_read_only(snapshot), "Missing-interaction snapshot remains read-only")


func _test_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var manifest: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", {
		"command_surface_findings": _findings("ready_for_next_station_firefight_iteration"),
		"interaction_polish": _interaction(),
		"manifest_path": "tmp/station_reentry_firefight_command_surface_polish.json",
	}))
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_783 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_783 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_783", "Manifest records TASK_783")
	_assert(String(parsed.get("status", "")) == "ready_for_command_surface_polish_review", "Manifest records ready polish")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _findings(status: String, active_issues: Array[String] = []) -> Dictionary:
	var flags: Array = []
	for id in [
		"interaction_line_missing",
		"primary_action_unclear",
		"quick_actions_hidden",
		"hold_fire_missing",
		"auto_command_commit_confusing",
		"selected_fireteam_panel_mismatch",
		"command_matrix_unreachable",
		"host_client_surface_mismatch",
		"surface_too_dense",
		"performance_stutter_visible",
	]:
		flags.append({"id": id, "active": active_issues.has(id), "read_only": true, "ui_sets_gameplay_truth": false})
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_command_surface_findings.v1",
		"task_id": "TASK_782",
		"status": status,
		"expected_interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"expected_primary_action_label": "HOLD",
		"expected_quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
		"expected_no_auto_command_commit": true,
		"expected_uses_existing_commands_only": true,
		"issue_flags": flags,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
	}


func _interaction() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_interaction_polish.v1",
		"task_id": "TASK_780",
		"status": "ready_for_firefight_interaction_playtest",
		"ready_for_firefight_interaction_playtest": true,
		"interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"primary_action": {"id": "hold_cover", "label": "HOLD", "reason": "Keep the team in cover.", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false},
		"quick_actions": [
			{"id": "hold_cover", "label": "HOLD", "reason": "Keep the team in cover.", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false},
			{"id": "flank", "label": "FLANK", "reason": "Shift angle.", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false},
			{"id": "hold_fire", "label": "HOLD FIRE", "reason": "Friendly-fire risk.", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false},
			{"id": "suppress", "label": "SUP", "reason": "Pin contact.", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false},
			{"id": "move_cover", "label": "MOVE", "reason": "Move to cover.", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false},
		],
		"uses_existing_commands_only": true,
		"no_auto_command_commit": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true))


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
