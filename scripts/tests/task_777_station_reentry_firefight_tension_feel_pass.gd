extends SceneTree

const FEEL_PASS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_tension_feel_pass.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_777_station_reentry_firefight_tension_feel_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_777 Station Reentry Firefight Tension Feel Pass ===")
	_test_docs_contract_and_report()
	_test_missing_contact_pressure_blocks_firefight_tension()
	_test_complete_firefight_tension_feel_pass()
	_test_missing_fire_exchange_routes_to_engagement_polish()
	_test_missing_visual_routes_to_visual_polish()
	_test_missing_metrics_routes_to_metrics_polish()
	_test_missing_next_decision_routes_to_next_decision_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_777: FAILED")
		quit(1)
		return
	print("TASK_777: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_777 task file exists")
	_assert(task_text.contains("Station Reentry Firefight Tension Feel Pass"), "TASK_777 task names firefight tension feel pass")
	_assert(status_text.contains("TASK_777 - Station Reentry Firefight Tension Feel Pass"), "Implementation status tracks TASK_777")
	_assert(roadmap_text.contains("TASK_777 - Station Reentry Firefight Tension Feel Pass (implementiert)"), "Roadmap marks TASK_777 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Tension-Feel-Pass"), "Mission command feedback contract documents TASK_777")
	_assert(report_text.contains("Aktueller Griff: TASK_779"), "Reentry handbook advances to TASK_779 current")
	_assert(report_text.contains('data-export-key="reentry_firefight_tension.ready_for_firefight_tension_playtest"'), "Reentry handbook exports TASK_777 feel gate")


func _test_missing_contact_pressure_blocks_firefight_tension() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs.erase("contact_pressure")
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_tension_feel_pass.v1", "Firefight-tension schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_contact_pressure_ready", "Missing contact pressure blocks firefight tension")
	_assert(not bool(snapshot.get("ready_for_firefight_tension_playtest", true)), "Missing contact pressure is not ready")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("contact_pressure_ready"), "Missing contact-pressure gate is reported")
	_assert(_snapshot_is_read_only(snapshot), "Missing-contact-pressure snapshot remains read-only")


func _test_complete_firefight_tension_feel_pass() -> void:
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", _complete_inputs()))
	_assert(String(snapshot.get("status", "")) == "ready_for_firefight_tension_playtest", "Complete gates are ready for firefight tension playtest")
	_assert(bool(snapshot.get("ready_for_firefight_tension_playtest", false)), "Ready flag is true")
	_assert(Array(snapshot.get("failed_gate_ids", [])).is_empty(), "No gates fail in complete firefight tension pass")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_778"), "Ready pass routes to TASK_778")
	_assert(bool(Dictionary(snapshot.get("exchange_summary", {})).get("visible", false)), "Exchange summary is visible")
	_assert(bool(Dictionary(snapshot.get("visual_summary", {})).get("visible", false)), "Visual summary is visible")
	_assert(bool(Dictionary(snapshot.get("metrics_summary", {})).get("visible", false)), "Metrics summary is visible")
	_assert(bool(Dictionary(snapshot.get("tension_summary", {})).get("visible", false)), "Tension summary is visible")
	_assert(bool(Dictionary(snapshot.get("next_decision_summary", {})).get("visible", false)), "Next-decision summary is visible")
	_assert(_snapshot_is_read_only(snapshot), "Complete firefight-tension snapshot remains read-only")


func _test_missing_fire_exchange_routes_to_engagement_polish() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs["engagement"] = _read_only_source({"task_id": "TASK_543", "gate": "review"})
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_fire_exchange_readability", "Missing fire exchange routes to engagement polish")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("fire_exchange_visible"), "Missing fire-exchange gate is reported")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_543"), "Exchange failure recommends TASK_543")


func _test_missing_visual_routes_to_visual_polish() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs["fire_visuals"] = _read_only_source({
		"task_id": "TASK_544",
		"trace_visible": true,
		"impact_visible": false,
		"unit_badge_visible": true,
	})
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_fire_visual_polish", "Missing fire visual routes to visual polish")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("fire_visuals_visible"), "Missing fire-visual gate is reported")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_544"), "Visual failure recommends TASK_544")


func _test_missing_metrics_routes_to_metrics_polish() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs["combat_metrics"] = _read_only_source({
		"task_id": "TASK_584",
		"metrics": {
			"shots_fired": 0,
			"hit_count": 0,
			"wounded_count": 0,
			"down_count": 0,
			"friendly_fire_risk_count": 0,
		},
	})
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_combat_metrics_polish", "Missing combat metrics routes to metrics polish")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("combat_metrics_visible"), "Missing metrics gate is reported")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_584"), "Metrics failure recommends TASK_584")


func _test_missing_next_decision_routes_to_next_decision_polish() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs["hud_decision"] = _read_only_source({
		"task_id": "TASK_546",
		"compact_line": "FIRE HIT | LOS clear | COVER partial",
		"line_within_limit": true,
	})
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_next_decision_polish", "Missing next decision routes to next-decision polish")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("next_decision_visible"), "Missing next-decision gate is reported")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("next-decision"), "Next-decision failure recommends TASK_777 polish")


func _complete_inputs() -> Dictionary:
	return {
		"contact_pressure": _contact_pressure(),
		"engagement": _engagement(),
		"fire_visuals": _fire_visuals(),
		"combat_metrics": _combat_metrics(),
		"hud_decision": _hud_decision(),
	}


func _contact_pressure() -> Dictionary:
	return _read_only_source({
		"schema": "sternenbuergerchen.station_reentry_contact_pressure_feel_pass.v1",
		"task_id": "TASK_776",
		"status": "ready_for_contact_pressure_playtest",
		"ready_for_contact_pressure_playtest": true,
	})


func _engagement() -> Dictionary:
	return _read_only_source({
		"task_id": "TASK_543",
		"gate": "pass",
		"first_fire_event": {
			"event_id": "fire_001",
			"attacker_unit_id": "alpha_rifle_01",
			"target_unit_id": "bravo_rifle_02",
			"weapon_id": "rifle",
			"combat_outcome": "hit",
		},
		"contact_decision_diagnostics": {
			"status": "fired",
			"attacker_unit_id": "alpha_rifle_01",
			"target_unit_id": "bravo_rifle_02",
			"weapon_id": "rifle",
			"los_state": "clear",
			"cover_state": "partial",
		},
	})


func _fire_visuals() -> Dictionary:
	return _read_only_source({
		"task_id": "TASK_544",
		"trace_visible": true,
		"impact_visible": true,
		"unit_badge_visible": true,
		"primary_3d": {
			"weapon_fire_vfx_visual_count": 1,
			"unit_status_badge_visible_count": 3,
		},
		"first_fire_visual": {
			"trace_visible": true,
			"impact_visible": true,
			"target_focus_visible": true,
		},
	})


func _combat_metrics() -> Dictionary:
	return _read_only_source({
		"task_id": "TASK_584",
		"metrics": {
			"shots_fired": 3,
			"hit_count": 1,
			"friendly_fire_event_count": 0,
			"friendly_fire_risk_count": 1,
			"wounded_count": 1,
			"down_count": 0,
			"extracted_count": 0,
		},
	})


func _hud_decision() -> Dictionary:
	return _read_only_source({
		"task_id": "TASK_546",
		"compact_line": "FIRE HIT | RISKY | LOS clear | COVER partial | next: hold cover",
		"next_action": "hold cover",
		"line_within_limit": true,
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


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true))


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
