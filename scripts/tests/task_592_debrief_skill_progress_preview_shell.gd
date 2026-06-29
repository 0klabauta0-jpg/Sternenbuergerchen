extends SceneTree

const DEBRIEF_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_592_debrief_skill_progress_preview_shell.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const DEBRIEF_SCREEN_PATH: String = "res://scripts/meta/debrief_screen.gd"
const TASK_590_TEST_PATH: String = "res://scripts/tests/task_590_debrief_aar_layout_polish_findings.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_592 Debrief Skill Progress Preview Shell ===")
	_test_docs_and_wiring()
	await _test_debrief_skill_progress_preview_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_592: FAILED")
		quit(1)
		return
	print("TASK_592: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var debrief_text: String = _read_text(DEBRIEF_SCREEN_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_592 task file exists")
	_assert(task_text.contains("Debrief Skill Progress Preview Shell"), "TASK_592 task file names the task")
	_assert(status_text.contains("TASK_592 - Debrief Skill Progress Preview Shell"), "Implementation status tracks TASK_592")
	_assert(status_text.contains("TASK_593 - Skill Progress Award Contract"), "Implementation status names TASK_593 follow-up")
	_assert(roadmap_text.contains("TASK_592 - Debrief Skill Progress Preview Shell (implementiert)"), "Roadmap marks TASK_592 implemented")
	_assert(roadmap_text.contains("TASK_593 - Skill Progress Award Contract"), "Roadmap names TASK_593 follow-up")
	_assert(report_text.contains("TASK_592 - Debrief Skill Progress Preview Shell"), "Review workbench tracks TASK_592")
	_assert(report_text.contains("TASK_593 - Skill Progress Award Contract"), "Review workbench names TASK_593 follow-up")
	_assert(report_text.contains("Skill Preview"), "Review workbench mentions Skill Preview")
	_assert(contract_text.contains("Debrief-Skill-Progress-Preview"), "Mission feedback contract documents TASK_592")
	_assert(debrief_text.contains("get_debrief_skill_progress_preview_snapshot"), "Debrief screen exposes TASK_592 snapshot")
	_assert(debrief_text.contains("_build_skill_progress_preview_entries"), "Debrief screen builds skill preview entries")
	_assert(debrief_text.contains("SkillProgressPreviewLabel"), "Debrief screen owns a skill preview label")
	_assert(FileAccess.file_exists(TASK_590_TEST_PATH), "TASK_590 layout polish verifier remains available")


func _test_debrief_skill_progress_preview_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var debrief: Node = DEBRIEF_SCENE.instantiate()
	root.add_child(debrief)
	debrief.set("visible", true)
	await _wait_frames(8)

	var mission_result: Dictionary = _build_base_mission_result()
	mission_result["mini_aar_debrief"] = _build_mini_aar_debrief_payload()
	debrief.call("set_mission_result", mission_result)
	await _wait_frames(12)

	var aar_snapshot: Dictionary = Dictionary(debrief.call("get_debrief_aar_layout_polish_snapshot"))
	var skill_snapshot: Dictionary = Dictionary(debrief.call("get_debrief_skill_progress_preview_snapshot"))
	var preview_text: String = String(skill_snapshot.get("preview_text", ""))
	var preview_entries: Array = Array(skill_snapshot.get("preview_entries", []))
	var result_copy: Dictionary = Dictionary(debrief.call("get_mission_result"))

	_assert(String(aar_snapshot.get("gate", "")) == "pass", "TASK_590 AAR layout gate stays green")
	_assert(String(skill_snapshot.get("schema", "")) == "sternenbuergerchen.debrief_skill_progress_preview.v1", "TASK_592 preview reports stable schema")
	_assert(String(skill_snapshot.get("task_id", "")) == "TASK_592", "TASK_592 preview reports task id")
	_assert(String(skill_snapshot.get("gate", "")) == "pass", "TASK_592 preview gate passes")
	_assert(bool(skill_snapshot.get("read_only", false)), "TASK_592 preview snapshot is read-only")
	_assert(not bool(skill_snapshot.get("ui_sets_gameplay_truth", true)), "TASK_592 preview does not set gameplay truth")
	_assert(String(skill_snapshot.get("layout_key", "")) == "debrief_skill_preview_v1", "TASK_592 preview layout key is stable")
	_assert(String(skill_snapshot.get("style_id", "")) == "debrief_skill_preview_v1", "TASK_592 preview style id is applied")
	_assert(String(skill_snapshot.get("aar_layout_gate", "")) == "pass", "TASK_592 preview keeps AAR layout gate green")
	_assert(bool(skill_snapshot.get("preview_visible", false)), "TASK_592 preview label is visible")
	_assert(preview_text.begins_with("Skill Preview:"), "Skill preview is explicitly named")
	_assert(preview_text.contains("Lead Alpha"), "Skill preview includes unit progress token")
	_assert(preview_text.contains("Medic Alpha"), "Skill preview includes wounded unit token")
	_assert(preview_text.contains("FT_ALPHA"), "Skill preview includes fireteam progress token")
	_assert(int(skill_snapshot.get("preview_length", 999)) <= 160, "Skill preview remains compact")
	_assert(int(skill_snapshot.get("preview_token_count", 0)) >= 2, "Skill preview exposes multiple tokens")
	_assert(preview_entries.size() >= 2, "Skill preview stores read-only entry data")
	_assert(_all_entries_read_only(preview_entries), "Skill preview entries are read-only")
	_assert(_check_passed(skill_snapshot, "skill_preview_visible"), "Visible check passes")
	_assert(_check_passed(skill_snapshot, "skill_preview_compact"), "Compact check passes")
	_assert(_check_passed(skill_snapshot, "skill_preview_named"), "Named check passes")
	_assert(_check_passed(skill_snapshot, "skill_preview_has_tokens"), "Token check passes")
	_assert(_check_passed(skill_snapshot, "skill_preview_style_applied"), "Style check passes")
	_assert(_check_passed(skill_snapshot, "aar_layout_still_green"), "AAR gate check passes")
	_assert(not result_copy.has("xp_awarded"), "Debrief result does not gain XP award state")
	_assert(not result_copy.has("skill_points_awarded"), "Debrief result does not gain skill point award state")
	_assert(not result_copy.has("skill_progress_committed"), "Debrief result does not commit skill progress")

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


func _all_entries_read_only(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if not bool(entry.get("read_only", false)):
			return false
	return true


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
