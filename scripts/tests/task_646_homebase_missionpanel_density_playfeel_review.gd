extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_646_homebase_missionpanel_density_playfeel_review.md"
const TASK_645_PATH: String = "res://docs/tasks/TASK_645_frontier_probe_homebase_summary_next_sortie_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const STATE_HANDBOOK_PATH: String = "res://docs/reports/project_state_handbook_2026_06_30.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/homebase_missionpanel_density_playfeel_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_646 Homebase MissionPanel Density Playfeel Review ===")
	_test_docs_and_reports()
	await _test_density_playfeel_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_646: FAILED")
		quit(1)
		return
	print("TASK_646: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var task_645_text: String = _read_text(TASK_645_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var state_handbook_text: String = _read_text(STATE_HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_646 task file exists")
	_assert(task_text.contains("Homebase MissionPanel Density Playfeel Review"), "TASK_646 task names density review")
	_assert(task_645_text.contains("MissionPanel-Density-Pass"), "TASK_645 points to density follow-up")
	_assert(status_text.contains("TASK_646 - Homebase MissionPanel Density Playfeel Review"), "Implementation status tracks TASK_646")
	_assert(roadmap_text.contains("TASK_646 - Homebase MissionPanel Density Playfeel Review (implementiert)"), "Roadmap marks TASK_646 implemented")
	_assert(contract_text.contains("Homebase-MissionPanel-Density-Playfeel-Review"), "Mission feedback contract documents TASK_646")
	_assert(homebase_text.contains("get_homebase_missionpanel_density_playfeel_snapshot"), "Homebase exposes TASK_646 snapshot")
	_assert(report_text.contains("TASK_646 Homebase MissionPanel Density Playfeel Review"), "Rolling report tracks TASK_646")
	_assert(report_text.contains('latest_completed_task: "TASK_646 - Homebase MissionPanel Density Playfeel Review"'), "Rolling report marks TASK_646 latest completed")
	_assert(handbook_text.contains("TASK_646 - Homebase MissionPanel Density Playfeel Review"), "Status handbook tracks TASK_646")
	_assert(handbook_text.contains('current_task: "TASK_646 - Homebase MissionPanel Density Playfeel Review"'), "Status handbook current task is TASK_646")
	_assert(state_handbook_text.contains("TASK_646 - Homebase MissionPanel Density Playfeel Review"), "State handbook tracks TASK_646")
	for key in [
		"homebase_missionpanel_density_playfeel.task_id",
		"homebase_missionpanel_density_playfeel.manifest_path",
		"homebase_missionpanel_density_playfeel.gate",
		"homebase_missionpanel_density_playfeel.visible_section_count",
		"homebase_missionpanel_density_playfeel.vertical_fill_ratio",
		"homebase_missionpanel_density_playfeel.total_visible_text_length",
		"homebase_missionpanel_density_playfeel.key_section_order",
		"homebase_missionpanel_density_playfeel.read_only",
		"homebase_missionpanel_density_playfeel.recommended_next_task",
		"homebase_missionpanel_density_playfeel.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.homebase_missionpanel_density_playfeel"'), "Rolling report exports TASK_646 free note")
	_assert(handbook_text.contains('data-export-key="status.task_646_done"'), "Status handbook exports TASK_646 checkbox")


func _test_density_playfeel_snapshot() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.size = Vector2i(1920, 1080)
	var scene: Node = META_LAYER_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)

	var debrief_screen: Node = scene.get_node_or_null("DebriefScreen")
	var homebase_screen: Node = scene.get_node_or_null("HomebaseScreen")
	_assert(debrief_screen != null and homebase_screen != null, "Meta fixture exposes Debrief and Homebase screens")
	if debrief_screen == null or homebase_screen == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var mission_result: Dictionary = _build_frontier_probe_result()
	scene.set("_last_mission_result", mission_result.duplicate(true))
	debrief_screen.call("set_mission_result", mission_result.duplicate(true))
	scene.call("_show_debrief")
	await _wait_frames(4)
	scene.call("request_debrief_return_homebase_for_test")
	await _wait_frames(18)

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_homebase_missionpanel_density_playfeel_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.homebase_missionpanel_density_playfeel.v1", "TASK_646 snapshot schema is stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_646 density gate passes")
	_assert(String(snapshot.get("visible_readiness_gate", "")) == "pass", "TASK_646 builds on visible readiness gate")
	_assert(bool(snapshot.get("mission_panel_visible", false)), "MissionPanel is visible")
	_assert(bool(snapshot.get("briefing_panel_visible", false)), "Briefing section is visible")
	_assert(bool(snapshot.get("readiness_panel_visible", false)), "Readiness section is visible")
	_assert(bool(snapshot.get("followup_panel_visible", false)), "Follow-up section is visible")
	_assert(String(snapshot.get("key_section_order", "")) == "briefing_readiness_followup", "Key section order is readable")
	_assert(int(snapshot.get("visible_section_count", 0)) >= 4, "MissionPanel has visible sections")
	_assert(int(snapshot.get("visible_section_count", 0)) <= 8, "MissionPanel section count stays compact")
	_assert(float(snapshot.get("vertical_fill_ratio", 1.0)) <= 1.0, "MissionPanel density remains below hard overflow range")
	_assert(int(snapshot.get("total_visible_text_length", 99999)) <= 1400, "MissionPanel text remains inside hard review ceiling")
	_assert(String(snapshot.get("followup_panel_style_id", "")) == "task_645_homebase_followup_panel_v1", "TASK_645 follow-up style remains active")
	_assert(_check_passed(snapshot, "key_sections_visible"), "Snapshot confirms key sections are visible")
	_assert(_check_passed(snapshot, "key_sections_inside_panel"), "Snapshot confirms key sections stay inside panel")
	_assert(_check_passed(snapshot, "key_section_order"), "Snapshot confirms key section order")
	_assert(_check_passed(snapshot, "visible_section_budget"), "Snapshot confirms section budget")
	_assert(_check_exists(snapshot, "vertical_density_budget"), "Snapshot tracks vertical density warning budget")
	_assert(_check_exists(snapshot, "text_density_budget"), "Snapshot tracks text density warning budget")
	_assert(bool(snapshot.get("read_only", false)), "TASK_646 snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_646 snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_646 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_646 creates no command")

	var manifest: Dictionary = _build_manifest(snapshot)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_646 manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.homebase_missionpanel_density_playfeel_manifest.v1", "TASK_646 manifest schema is stable")
	_assert(String(manifest.get("gate", "")) == "pass", "TASK_646 manifest gate passes")
	_assert(bool(manifest.get("read_only", false)), "TASK_646 manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "TASK_646 manifest does not set gameplay truth")

	scene.queue_free()
	await _wait_frames(2)


func _build_manifest(snapshot: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.homebase_missionpanel_density_playfeel_manifest.v1",
		"task_id": "TASK_646",
		"snapshot_schema": String(snapshot.get("schema", "")),
		"gate": String(snapshot.get("gate", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"visible_readiness_gate": String(snapshot.get("visible_readiness_gate", "")),
		"visible_section_count": int(snapshot.get("visible_section_count", 0)),
		"visible_sections": Array(snapshot.get("visible_sections", [])).duplicate(true),
		"vertical_fill_ratio": float(snapshot.get("vertical_fill_ratio", 0.0)),
		"total_visible_text_length": int(snapshot.get("total_visible_text_length", 0)),
		"key_section_order": String(snapshot.get("key_section_order", "")),
		"followup_panel_style_id": String(snapshot.get("followup_panel_style_id", "")),
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": String(snapshot.get("recommended_next_task", "")),
	}


func _build_frontier_probe_result() -> Dictionary:
	return {
		"scenario_id": "frontier_probe_vertical_slice",
		"mission_id": "frontier_probe_vertical_slice",
		"scenario_file_path": "res://data/mission_scenarios/frontier_probe_vertical_slice.json",
		"route_id": "frontier_probe_aa_computer_cargo",
		"winning_team_id": "team_alpha",
		"mission_outcome": "completed",
		"result": "victory",
		"win_condition_type": "frontier_probe_cargo_extract",
		"objective_captured": true,
		"duration_seconds": 312.0,
		"selected_unit_ids": PackedStringArray(["lead_alpha", "rifle_alpha", "medic_alpha"]),
		"selected_fireteam_ids": PackedStringArray(["ft_alpha"]),
		"progression_award_summary": {
			"schema": "sternenbuergerchen.skill_progress_award_summary.v1",
			"authority": "MissionProgressionResolver",
			"source": "progression_unit_updates",
			"award_applied": true,
			"total_xp_delta": 18,
			"listed_awards": [
				{"unit_id": "lead_alpha", "xp_delta": 8, "skill_gain_count": 1, "ftl_tactical_gain": 0.015},
			],
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _check_exists(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return true
	return false


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_646 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


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
