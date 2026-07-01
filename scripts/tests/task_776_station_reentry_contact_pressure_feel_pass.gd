extends SceneTree

const FEEL_PASS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_contact_pressure_feel_pass.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_776_station_reentry_contact_pressure_feel_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_776 Station Reentry Contact Pressure Feel Pass ===")
	_test_docs_contract_and_report()
	_test_missing_interaction_blocks_contact_pressure()
	_test_complete_contact_pressure_feel_pass()
	_test_missing_contact_routes_to_contact_polish()
	_test_missing_threat_routes_to_threat_polish()
	_test_missing_hud_routes_to_hud_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_776: FAILED")
		quit(1)
		return
	print("TASK_776: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_776 task file exists")
	_assert(task_text.contains("Station Reentry Contact Pressure Feel Pass"), "TASK_776 task names contact pressure feel pass")
	_assert(status_text.contains("TASK_776 - Station Reentry Contact Pressure Feel Pass"), "Implementation status tracks TASK_776")
	_assert(roadmap_text.contains("TASK_776 - Station Reentry Contact Pressure Feel Pass (implementiert)"), "Roadmap marks TASK_776 implemented")
	_assert(contract_text.contains("Station-Reentry-Contact-Pressure-Feel-Pass"), "Mission command feedback contract documents TASK_776")
	_assert(report_text.contains("Aktueller Griff: TASK_792"), "Reentry handbook advances to TASK_792 current")
	_assert(report_text.contains('data-export-key="reentry_contact_pressure.ready_for_contact_pressure_playtest"'), "Reentry handbook exports TASK_776 feel gate")


func _test_missing_interaction_blocks_contact_pressure() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs.erase("interaction_feel")
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_contact_pressure_feel_pass.v1", "Contact-pressure schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_interaction_feel_ready", "Missing interaction feel blocks contact pressure")
	_assert(not bool(snapshot.get("ready_for_contact_pressure_playtest", true)), "Missing interaction feel is not ready")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("interaction_feel_ready"), "Missing interaction gate is reported")
	_assert(_snapshot_is_read_only(snapshot), "Missing-interaction snapshot remains read-only")


func _test_complete_contact_pressure_feel_pass() -> void:
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", _complete_inputs()))
	_assert(String(snapshot.get("status", "")) == "ready_for_contact_pressure_playtest", "Complete gates are ready for contact pressure playtest")
	_assert(bool(snapshot.get("ready_for_contact_pressure_playtest", false)), "Ready flag is true")
	_assert(Array(snapshot.get("failed_gate_ids", [])).is_empty(), "No gates fail in complete contact pressure pass")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_777"), "Ready pass routes to TASK_777")
	_assert(bool(Dictionary(snapshot.get("contact_summary", {})).get("visible", false)), "Contact summary is visible")
	_assert(bool(Dictionary(snapshot.get("threat_summary", {})).get("visible", false)), "Threat summary is visible")
	_assert(bool(Dictionary(snapshot.get("pressure_summary", {})).get("visible", false)), "Pressure summary is visible")
	_assert(bool(Dictionary(snapshot.get("hud_summary", {})).get("compact", false)), "HUD summary is compact")
	_assert(_snapshot_is_read_only(snapshot), "Complete contact-pressure snapshot remains read-only")


func _test_missing_contact_routes_to_contact_polish() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs["contact_report"] = {
		"task_id": "TASK_542",
		"gate": "review",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
	}
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_contact_report_polish", "Missing contact report routes to contact polish")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("contact_report_visible"), "Missing contact gate is reported")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("Contact Report"), "Contact failure recommends Contact Report polish")


func _test_missing_threat_routes_to_threat_polish() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs["threat_preview"] = {
		"task_id": "TASK_567",
		"risk_state": "risky",
		"risk_preview_text": "",
		"line_of_fire_entry_count": 2,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
	}
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_threat_reason_polish", "Missing threat text routes to threat polish")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("threat_reason_visible"), "Missing threat gate is reported")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("Threat Preview"), "Threat failure recommends Threat Preview polish")


func _test_missing_hud_routes_to_hud_polish() -> void:
	var inputs: Dictionary = _complete_inputs()
	inputs["combat_hud"] = {
		"task_id": "TASK_546",
		"compact_line": "CONTACT RISK",
		"line_within_limit": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
	}
	var snapshot: Dictionary = Dictionary(FEEL_PASS_SCRIPT.call("build_snapshot", inputs))
	_assert(String(snapshot.get("status", "")) == "needs_combat_hud_polish", "Missing LOS/Cover HUD context routes to HUD polish")
	_assert(Array(snapshot.get("failed_gate_ids", [])).has("combat_hud_compact"), "Missing HUD gate is reported")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("Combat HUD"), "HUD failure recommends Combat HUD polish")


func _complete_inputs() -> Dictionary:
	return {
		"interaction_feel": _interaction_feel(),
		"contact_report": _contact_report(),
		"threat_preview": _threat_preview(),
		"pressure_feedback": _pressure_feedback(),
		"combat_hud": _combat_hud(),
	}


func _interaction_feel() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_mission_interaction_feel_pass.v1",
		"task_id": "TASK_775",
		"status": "ready_for_mission_interaction_playtest",
		"ready_for_mission_interaction_playtest": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
	}


func _contact_report() -> Dictionary:
	return {
		"task_id": "TASK_542",
		"gate": "pass",
		"selected_contact_count": 2,
		"first_contact": {
			"enemy_type": "rifleman",
			"report_text": "2 Gegner, vermutlich Riflemen, zuletzt vor 8s gesehen.",
			"last_known_position": Vector2(960.0, 512.0),
			"confidence": 0.68,
			"last_seen_age_seconds": 8.0,
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
	}


func _threat_preview() -> Dictionary:
	return {
		"task_id": "TASK_567",
		"gate": "pass",
		"risk_state": "risky",
		"risk_preview_text": "RISKY: 2 enemy LOS, partial cover, no friendly-fire lane.",
		"risk_reason": "enemy_los_partial_cover",
		"line_of_fire_entry_count": 3,
		"enemy_exposure_count": 2,
		"friendly_fire_risk_count": 0,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
	}


func _pressure_feedback() -> Dictionary:
	return {
		"task_id": "TASK_543",
		"gate": "pass",
		"engagement_status": "waiting",
		"engagement_reason": "cooldown",
		"contact_decision_text": "CONTACT WAIT | LOS clear | COVER partial | Range medium",
		"contact_decision_diagnostics": {
			"status": "waiting",
			"reason": "cooldown",
			"cooldown_ticks_remaining": 4,
			"los_state": "clear",
			"cover_state": "partial",
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
	}


func _combat_hud() -> Dictionary:
	return {
		"task_id": "TASK_546",
		"compact_line": "CONTACT WAIT | RISKY | LOS clear | COVER partial",
		"mission_control_line": "CONTACT WAIT | RISKY | LOS clear | COVER partial",
		"selected_fireteam_line": "CONTACT WAIT | RISKY | LOS clear | COVER partial",
		"contains_los_context": true,
		"contains_cover_context": true,
		"line_within_limit": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true))


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
