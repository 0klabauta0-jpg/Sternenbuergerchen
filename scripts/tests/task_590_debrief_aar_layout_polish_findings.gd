extends SceneTree

const DEBRIEF_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_590_debrief_aar_layout_polish_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const DEBRIEF_SCREEN_PATH: String = "res://scripts/meta/debrief_screen.gd"
const TASK_589_TEST_PATH: String = "res://scripts/tests/task_589_debrief_aar_f6_visual_evidence_pass.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_590 Debrief AAR Layout Polish Findings ===")
	_test_docs_and_wiring()
	await _test_debrief_aar_layout_polish_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_590: FAILED")
		quit(1)
		return
	print("TASK_590: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var debrief_text: String = _read_text(DEBRIEF_SCREEN_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_590 task file exists")
	_assert(task_text.contains("Debrief AAR Layout Polish Findings"), "TASK_590 task file names the task")
	_assert(status_text.contains("TASK_590 - Debrief AAR Layout Polish Findings"), "Implementation status tracks TASK_590")
	_assert(roadmap_text.contains("TASK_590 - Debrief AAR Layout Polish Findings (implementiert)"), "Roadmap marks TASK_590 implemented")
	_assert(roadmap_text.contains("TASK_591 - Debrief AAR Player Review Notes Pass"), "Roadmap names TASK_591 follow-up")
	_assert(report_text.contains("TASK_590 - Debrief AAR Layout Polish Findings"), "Review workbench tracks TASK_590")
	_assert(report_text.contains("TASK_591 - Debrief AAR Player Review Notes Pass"), "Review workbench names TASK_591 follow-up")
	_assert(contract_text.contains("Debrief-AAR-Layout-Polish"), "Mission feedback contract documents TASK_590")
	_assert(debrief_text.contains("get_debrief_aar_layout_polish_snapshot"), "Debrief screen exposes TASK_590 snapshot")
	_assert(debrief_text.contains("_format_aar_summary_text"), "Debrief screen normalizes AAR summary text")
	_assert(FileAccess.file_exists(TASK_589_TEST_PATH), "TASK_589 visual evidence verifier remains available")


func _test_debrief_aar_layout_polish_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var debrief: Node = DEBRIEF_SCENE.instantiate()
	root.add_child(debrief)
	debrief.set("visible", true)
	await _wait_frames(8)
	var mission_result: Dictionary = _build_base_mission_result()
	mission_result["mini_aar_debrief"] = _build_mini_aar_debrief_payload()
	debrief.call("set_mission_result", mission_result)
	await _wait_frames(12)

	var bridge_snapshot: Dictionary = Dictionary(debrief.call("get_debrief_aar_data_bridge_snapshot"))
	var visual_snapshot: Dictionary = Dictionary(debrief.call("get_debrief_aar_visual_evidence_snapshot"))
	var polish_snapshot: Dictionary = Dictionary(debrief.call("get_debrief_aar_layout_polish_snapshot"))
	var summary_text: String = String(polish_snapshot.get("aar_summary_text", ""))
	var style_ids: Dictionary = Dictionary(polish_snapshot.get("style_ids", {}))
	_assert(String(bridge_snapshot.get("gate", "")) == "pass", "TASK_588 AAR bridge stays green")
	_assert(String(visual_snapshot.get("gate", "")) == "pass", "TASK_589 AAR visual evidence stays green")
	_assert(String(polish_snapshot.get("schema", "")) == "sternenbuergerchen.debrief_aar_layout_polish.v1", "TASK_590 layout polish reports stable schema")
	_assert(String(polish_snapshot.get("gate", "")) == "pass", "TASK_590 layout polish gate passes")
	_assert(bool(polish_snapshot.get("read_only", false)), "TASK_590 layout polish snapshot is read-only")
	_assert(not bool(polish_snapshot.get("ui_sets_gameplay_truth", true)), "TASK_590 layout polish does not set gameplay truth")
	_assert(summary_text.begins_with("AAR | FIRE"), "AAR summary keeps one compact prefix")
	_assert(not summary_text.contains("AAR: AAR"), "AAR summary does not duplicate prefix")
	_assert(not bool(polish_snapshot.get("summary_has_duplicate_prefix", true)), "AAR duplicate-prefix flag stays false")
	_assert(int(polish_snapshot.get("summary_length", 999)) <= 96, "AAR summary length remains compact")
	_assert(int(polish_snapshot.get("rows_length", 999)) <= 180, "AAR rows length remains compact")
	_assert(int(polish_snapshot.get("limit_length", 999)) <= 120, "AAR limit length remains compact")
	_assert(String(style_ids.get("layout", "")) == "debrief_aar_layout_polish_v1", "AAR layout style id is stable")
	_assert(String(style_ids.get("summary", "")) == "debrief_aar_summary_v2", "AAR summary style id is applied")
	_assert(String(style_ids.get("rows", "")) == "debrief_aar_rows_v2", "AAR rows style id is applied")
	_assert(String(style_ids.get("limit", "")) == "debrief_aar_limit_v2", "AAR limit style id is applied")
	_assert(int(style_ids.get("chip_styled_count", 0)) >= 5, "AAR chips remain styled")
	_assert(_check_passed(polish_snapshot, "summary_prefix_clean"), "AAR summary prefix-clean check passes")
	_assert(_check_passed(polish_snapshot, "visual_gate_pass"), "TASK_590 keeps TASK_589 gate green")
	_assert(_check_passed(polish_snapshot, "button_gap_preserved"), "TASK_590 preserves button gap")

	debrief.queue_free()
	await _wait_frames(2)


func _build_base_mission_result() -> Dictionary:
	return {
		"winning_team_id": "team_alpha",
		"mission_outcome": "completed",
		"result": "victory",
		"win_condition_type": "objective_capture",
		"objective_captured": true,
		"duration_seconds": 185.0,
		"team_states": [
			{"unit_id": "lead_alpha", "display_name": "Lead Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 100},
			{"unit_id": "rifle_alpha", "display_name": "Rifle Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 88},
			{"unit_id": "medic_alpha", "display_name": "Medic Alpha", "fireteam_id": "ft_alpha", "vital_state": "wounded", "health_points": 42},
		],
		"fireteam_tactical_debrief": [
			{"fireteam_id": "ft_alpha", "reaction_delay_seconds": 0.42, "plan_quality": 0.76, "tempo_modifier": 1.08, "contact_report_count": 3, "contact_report_quality": 0.72, "morale": 0.68, "frustration": 0.22},
		],
	}


func _build_mini_aar_debrief_payload() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mini_aar_debrief_screen_stub.v1",
		"task_id": "TASK_585",
		"source_schema": "sternenbuergerchen.mini_aar_combat_metrics.v1",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"summary_text": "AAR | FIRE 12 | HIT 7 | FF 1/2 | SUP 3 | WOUND 1 | EXT 2",
		"rows": [
			{"id": "fire", "label": "Fire", "value_text": "FIRE 12 | HIT 7", "read_only": true},
			{"id": "friendly_fire", "label": "Friendly Fire", "value_text": "FF 1 / Risk 2", "read_only": true},
			{"id": "suppress", "label": "Suppress", "value_text": "SUP x3", "read_only": true},
			{"id": "status", "label": "Status", "value_text": "WOUND 1 | DOWN 0 | EXT 2", "read_only": true},
		],
		"chips": [
			{"id": "shots", "label": "FIRE", "value_text": "12", "style_key": "neutral", "read_only": true},
			{"id": "hits", "label": "HIT", "value_text": "7", "style_key": "good", "read_only": true},
			{"id": "ff", "label": "FF", "value_text": "1/2", "style_key": "warn", "read_only": true},
			{"id": "sup", "label": "SUP", "value_text": "3", "style_key": "accent", "read_only": true},
			{"id": "wounded", "label": "WOUND", "value_text": "1", "style_key": "warn", "read_only": true},
			{"id": "extracted", "label": "EXT", "value_text": "2", "style_key": "neutral", "read_only": true},
		],
		"limit_text": "Keine XP, keine Ammo, keine echte Suppression - nur Debrief-Vorschau aus vorhandenen Metriken.",
		"gate": "pass",
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


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


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame
