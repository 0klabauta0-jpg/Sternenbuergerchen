extends SceneTree

const POLISH_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_interaction_polish.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_780_station_reentry_firefight_interaction_polish.md"
const TASK_779_PATH: String = "res://docs/tasks/TASK_779_station_reentry_firefight_visual_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_interaction_polish.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_780 Station Reentry Firefight Interaction Polish ===")
	_test_docs_contract_and_report()
	_test_missing_visual_findings_blocks()
	_test_missing_firefight_tension_blocks()
	_test_ready_interaction_polish()
	_test_friendly_fire_adds_hold_fire()
	_test_casualty_pressure_prioritizes_retreat()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_780: FAILED")
		quit(1)
		return
	print("TASK_780: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_780 task file exists")
	_assert(FileAccess.file_exists(TASK_779_PATH), "TASK_779 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Interaction Polish"), "TASK_780 task names interaction polish")
	_assert(status_text.contains("TASK_780 - Station Reentry Firefight Interaction Polish"), "Implementation status tracks TASK_780")
	_assert(roadmap_text.contains("TASK_780 - Station Reentry Firefight Interaction Polish (implementiert)"), "Roadmap marks TASK_780 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Interaction-Polish"), "Mission command feedback contract documents TASK_780")
	_assert(report_text.contains("Aktueller Griff: TASK_793"), "Reentry handbook marks TASK_793 current")
	_assert(report_text.contains("station_reentry_firefight_interaction_polish.json"), "Reentry handbook names TASK_780 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_interaction.interaction_line"'), "Reentry handbook exports TASK_780 interaction line")


func _test_missing_visual_findings_blocks() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs.erase("visual_findings")
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_interaction_polish.v1", "TASK_780 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_visual_findings_ready", "Missing visual findings blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_779"), "Missing findings recommends TASK_779")
	_assert(_snapshot_is_read_only(snapshot), "Missing-findings snapshot remains read-only")


func _test_missing_firefight_tension_blocks() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs.erase("firefight_tension")
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "blocked_until_firefight_tension_ready", "Missing firefight tension blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_777"), "Missing tension recommends TASK_777")
	_assert(_snapshot_is_read_only(snapshot), "Missing-tension snapshot remains read-only")


func _test_ready_interaction_polish() -> void:
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", _complete_inputs()))
	_assert(String(snapshot.get("status", "")) == "ready_for_firefight_interaction_playtest", "Complete sources are ready for interaction playtest")
	_assert(bool(snapshot.get("ready_for_firefight_interaction_playtest", false)), "Ready flag is true")
	_assert(String(snapshot.get("interaction_line", "")).contains("NEXT"), "Interaction line names NEXT")
	_assert(int(snapshot.get("interaction_line", "").length()) <= int(snapshot.get("interaction_line_char_limit", 0)), "Interaction line fits limit")
	_assert(int(snapshot.get("quick_action_count", 0)) >= 3, "At least three quick actions are visible")
	_assert(String(Dictionary(snapshot.get("primary_action", {})).get("label", "")) == "HOLD", "Wounded pressure defaults to HOLD primary")
	_assert(bool(snapshot.get("uses_existing_commands_only", false)), "Polish uses existing command surface")
	_assert(bool(snapshot.get("no_auto_command_commit", false)), "Polish does not auto-commit commands")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_781"), "Ready polish recommends TASK_781 recapture")
	_assert(_snapshot_is_read_only(snapshot), "Ready snapshot remains read-only")


func _test_friendly_fire_adds_hold_fire() -> void:
	var inputs: Dictionary = _complete_inputs()
	var tension: Dictionary = Dictionary(inputs.get("firefight_tension", {})).duplicate(true)
	var metrics: Dictionary = Dictionary(tension.get("metrics_summary", {})).duplicate(true)
	metrics["friendly_fire_risk_count"] = 2
	tension["metrics_summary"] = metrics
	inputs["firefight_tension"] = tension
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", inputs))
	_assert(_has_action(snapshot, "hold_fire"), "Friendly-fire risk adds HOLD FIRE action")
	_assert(String(snapshot.get("interaction_line", "")).contains("FF2"), "Interaction line counts friendly-fire risk")


func _test_casualty_pressure_prioritizes_retreat() -> void:
	var inputs: Dictionary = _complete_inputs()
	var tension: Dictionary = Dictionary(inputs.get("firefight_tension", {})).duplicate(true)
	var metrics: Dictionary = Dictionary(tension.get("metrics_summary", {})).duplicate(true)
	var tension_summary: Dictionary = Dictionary(tension.get("tension_summary", {})).duplicate(true)
	metrics["down_count"] = 1
	tension_summary["tension_label"] = "casualty_pressure"
	tension["metrics_summary"] = metrics
	tension["tension_summary"] = tension_summary
	inputs["firefight_tension"] = tension
	var snapshot: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", inputs))
	_assert(String(Dictionary(snapshot.get("primary_action", {})).get("id", "")) == "retreat", "Casualty pressure prioritizes RETREAT")
	_assert(String(snapshot.get("interaction_line", "")).contains("RETREAT"), "Interaction line names RETREAT")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(POLISH_SCRIPT.call("build_snapshot", _complete_inputs()))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_780 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_780 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_780", "Manifest records TASK_780")
	_assert(String(parsed.get("status", "")) == "ready_for_firefight_interaction_playtest", "Manifest records ready status")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _complete_inputs() -> Dictionary:
	return {
		"visual_findings": _visual_findings(),
		"firefight_tension": _firefight_tension(),
	}


func _visual_findings() -> Dictionary:
	return _read_only_source({
		"schema": "sternenbuergerchen.station_reentry_firefight_visual_findings.v1",
		"task_id": "TASK_779",
		"status": "ready_for_next_station_firefight_iteration",
		"manual_review_done": true,
		"visible_playtest_done": true,
	})


func _firefight_tension() -> Dictionary:
	return _read_only_source({
		"schema": "sternenbuergerchen.station_reentry_firefight_tension_feel_pass.v1",
		"task_id": "TASK_777",
		"status": "ready_for_firefight_tension_playtest",
		"ready_for_firefight_tension_playtest": true,
		"tension_summary": {
			"visible": true,
			"tension_label": "wounded_pressure",
			"outcome": "hit",
		},
		"metrics_summary": {
			"visible": true,
			"shots_fired": 3,
			"hit_count": 1,
			"wounded_count": 1,
			"down_count": 0,
			"friendly_fire_risk_count": 1,
		},
		"next_decision_summary": {
			"visible": true,
			"compact_line": "FIRE HIT | RISKY | LOS clear | COVER partial | next: hold cover",
			"next_action": "hold cover",
			"line_within_limit": true,
		},
	})


func _read_only_source(values: Dictionary) -> Dictionary:
	var source: Dictionary = values.duplicate(true)
	source["read_only"] = bool(source.get("read_only", true))
	source["ui_sets_gameplay_truth"] = bool(source.get("ui_sets_gameplay_truth", false))
	source["creates_command"] = bool(source.get("creates_command", false))
	source["creates_navigation"] = bool(source.get("creates_navigation", false))
	source["creates_fire_event"] = bool(source.get("creates_fire_event", false))
	source["creates_damage_event"] = bool(source.get("creates_damage_event", false))
	return source


func _has_action(snapshot: Dictionary, action_id: String) -> bool:
	for action_variant in Array(snapshot.get("quick_actions", [])):
		if typeof(action_variant) == TYPE_DICTIONARY and String(Dictionary(action_variant).get("id", "")) == action_id:
			return true
	return false


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
