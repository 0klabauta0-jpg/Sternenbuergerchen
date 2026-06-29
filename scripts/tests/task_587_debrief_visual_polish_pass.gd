extends SceneTree

const DEBRIEF_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_587_debrief_visual_polish_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const DEBRIEF_SCREEN_PATH: String = "res://scripts/meta/debrief_screen.gd"
const TASK_586_TEST_PATH: String = "res://scripts/tests/task_586_debrief_return_homebase_handoff.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_587 Debrief Visual Polish Pass ===")
	_test_docs_and_wiring()
	await _test_debrief_visual_polish_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_587: FAILED")
		quit(1)
		return
	print("TASK_587: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var debrief_text: String = _read_text(DEBRIEF_SCREEN_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_587 task file exists")
	_assert(task_text.contains("Debrief Visual Polish Pass"), "TASK_587 task file names the task")
	_assert(status_text.contains("TASK_587 - Debrief Visual Polish Pass"), "Implementation status tracks TASK_587")
	_assert(status_text.contains("TASK_586 - Debrief Return To Homebase Handoff"), "Implementation status still tracks TASK_586")
	_assert(roadmap_text.contains("TASK_587 - Debrief Visual Polish Pass (implementiert)"), "Roadmap marks TASK_587 implemented")
	_assert(roadmap_text.contains("TASK_588 - Debrief AAR Data Bridge"), "Roadmap names TASK_588 follow-up")
	_assert(report_text.contains("TASK_587 - Debrief Visual Polish Pass"), "Review workbench tracks TASK_587")
	_assert(report_text.contains("TASK_588 - Debrief AAR Data Bridge"), "Review workbench names TASK_588 follow-up")
	_assert(contract_text.contains("Debrief-Visual-Polish"), "Mission feedback contract documents TASK_587")
	_assert(debrief_text.contains("get_debrief_visual_polish_snapshot"), "Debrief screen exposes TASK_587 visual polish snapshot")
	_assert(debrief_text.contains("SummaryStrip"), "Debrief screen builds compact summary strip")
	_assert(FileAccess.file_exists(TASK_586_TEST_PATH), "TASK_586 return handoff verifier remains available")


func _test_debrief_visual_polish_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var debrief: Node = DEBRIEF_SCENE.instantiate()
	root.add_child(debrief)
	await _wait_frames(8)
	debrief.call("set_mission_result", _build_test_mission_result())
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(debrief.call("get_debrief_visual_polish_snapshot"))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.debrief_visual_polish.v1", "Debrief visual polish reports stable schema")
	_assert(String(snapshot.get("gate", "")) == "pass", "Debrief visual polish gate passes")
	_assert(bool(snapshot.get("read_only", false)), "Debrief visual polish snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Debrief visual polish snapshot does not set gameplay truth")
	_assert(bool(snapshot.get("has_mission_result", false)), "Debrief visual polish uses a mission result")
	_assert(int(snapshot.get("summary_chip_count", 0)) >= 5, "Debrief visual polish exposes at least five summary chips")
	_assert(int(snapshot.get("result_text_length", 999)) <= 140, "Result text stays compact")
	_assert(int(snapshot.get("team_status_length", 999)) <= 180, "Team status stays compact")
	_assert(String(snapshot.get("primary_action_label", "")) == "Return to Homebase", "Homebase return is the primary action")
	_assert(String(snapshot.get("secondary_action_label", "")) == "Return to FOB", "FOB return remains secondary")
	_assert(String(snapshot.get("layout_key", "")) == "debrief_visual_polish_v1", "Debrief visual polish has stable layout key")
	_assert(_check_passed(snapshot, "summary_chips_visible"), "Summary chip check passes")
	_assert(_check_passed(snapshot, "homebase_primary_action"), "Primary action check passes")
	_assert(_check_passed(snapshot, "background_readability_policy"), "Background readability policy remains active")

	var chips: Array = Array(snapshot.get("summary_chips", []))
	var chip_text := _join_chip_text(chips)
	_assert(chip_text.contains("VICTORY"), "Summary chips show result")
	_assert(chip_text.contains("WIN TEAM_ALPHA"), "Summary chips show winning team")
	_assert(chip_text.contains("TIME 3:05"), "Summary chips show compact duration")
	_assert(String(snapshot.get("team_status_text", "")).contains("FIT 2"), "Team status shows fit count")
	_assert(String(snapshot.get("team_status_text", "")).contains("WOUNDED 1"), "Team status shows wounded count")

	debrief.queue_free()
	await _wait_frames(2)


func _build_test_mission_result() -> Dictionary:
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
			{
				"fireteam_id": "ft_alpha",
				"reaction_delay_seconds": 0.42,
				"plan_quality": 0.76,
				"tempo_modifier": 1.08,
				"contact_report_count": 3,
				"contact_report_quality": 0.72,
				"morale": 0.68,
				"frustration": 0.22,
			},
		],
	}


func _join_chip_text(chips: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		parts.append(String(chip.get("text", "")))
	return " | ".join(parts)


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
