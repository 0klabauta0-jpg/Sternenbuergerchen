extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_647_homebase_missionpanel_density_findings.md"
const TASK_646_PATH: String = "res://docs/tasks/TASK_646_homebase_missionpanel_density_playfeel_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const STATE_HANDBOOK_PATH: String = "res://docs/reports/project_state_handbook_2026_06_30.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/homebase_missionpanel_density_findings.json"
const DENSITY_FINDINGS_STYLE_ID: String = "task_647_homebase_density_findings_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_647 Homebase MissionPanel Density Findings ===")
	_test_docs_and_reports()
	await _test_density_findings_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_647: FAILED")
		quit(1)
		return
	print("TASK_647: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var task_646_text: String = _read_text(TASK_646_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var state_handbook_text: String = _read_text(STATE_HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_647 task file exists")
	_assert(task_text.contains("Homebase MissionPanel Density Findings"), "TASK_647 task names density findings")
	_assert(task_646_text.contains("separater Layout-Polish"), "TASK_647 follows TASK_646 warning path")
	_assert(status_text.contains("TASK_648 - Homebase Next Sortie Action Cue"), "Implementation status tracks TASK_647")
	_assert(roadmap_text.contains("TASK_648 - Homebase Next Sortie Action Cue (implementiert)"), "Roadmap marks TASK_647 implemented")
	_assert(contract_text.contains("Homebase-MissionPanel-Density-Findings"), "Mission feedback contract documents TASK_647")
	_assert(homebase_text.contains("HOMEBASE_POST_DEBRIEF_DENSITY_FINDINGS_STYLE_ID"), "Homebase exposes TASK_647 style id")
	_assert(report_text.contains("TASK_647 Homebase MissionPanel Density Findings"), "Rolling report tracks TASK_647")
	_assert(report_text.contains('latest_completed_task: "TASK_648 - Homebase Next Sortie Action Cue"'), "Rolling report marks TASK_647 latest completed")
	_assert(handbook_text.contains("TASK_648 - Homebase Next Sortie Action Cue"), "Status handbook tracks TASK_647")
	_assert(handbook_text.contains('current_task: "TASK_648 - Homebase Next Sortie Action Cue"'), "Status handbook current task is TASK_647")
	_assert(state_handbook_text.contains("TASK_648 - Homebase Next Sortie Action Cue"), "State handbook tracks TASK_647")
	for key in [
		"homebase_missionpanel_density_findings.task_id",
		"homebase_missionpanel_density_findings.manifest_path",
		"homebase_missionpanel_density_findings.gate",
		"homebase_missionpanel_density_findings.mission_summary_collapsed",
		"homebase_missionpanel_density_findings.visible_section_count",
		"homebase_missionpanel_density_findings.vertical_fill_ratio",
		"homebase_missionpanel_density_findings.total_visible_text_length",
		"homebase_missionpanel_density_findings.density_findings_style_id",
		"homebase_missionpanel_density_findings.read_only",
		"homebase_missionpanel_density_findings.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.homebase_missionpanel_density_findings"'), "Rolling report exports TASK_647 free note")
	_assert(handbook_text.contains('data-export-key="status.task_647_done"'), "Status handbook exports TASK_647 checkbox")


func _test_density_findings_snapshot() -> void:
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
	await _wait_frames(20)

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_homebase_missionpanel_density_playfeel_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.homebase_missionpanel_density_playfeel.v1", "TASK_647 reuses stable TASK_646 snapshot schema")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_647 density gate passes")
	_assert(bool(snapshot.get("briefing_panel_visible", false)), "Briefing section remains visible")
	_assert(bool(snapshot.get("readiness_panel_visible", false)), "Readiness section remains visible")
	_assert(bool(snapshot.get("followup_panel_visible", false)), "Follow-up section remains visible")
	_assert(not bool(snapshot.get("mission_summary_visible", true)), "Legacy MissionSummary is hidden while follow-up is active")
	_assert(bool(snapshot.get("mission_summary_collapsed", false)), "MissionSummary is marked collapsed")
	_assert(String(snapshot.get("density_findings_style_id", "")) == DENSITY_FINDINGS_STYLE_ID, "TASK_647 style id is present")
	_assert(int(snapshot.get("visible_section_count", 99)) <= 6, "Visible direct sections are reduced")
	_assert(float(snapshot.get("vertical_fill_ratio", 1.0)) <= 1.0, "Vertical density remains inside the hard panel bounds")
	_assert(int(snapshot.get("total_visible_text_length", 99999)) <= 1200, "Text density warning pressure is reduced")
	_assert(String(snapshot.get("key_section_order", "")) == "briefing_readiness_followup", "Key section order remains readable")
	_assert(_check_passed(snapshot, "density_findings_applied"), "Snapshot confirms TASK_647 density finding")
	_assert(_check_passed(snapshot, "density_warning_reduced"), "Snapshot confirms scan-pressure reduction")
	_assert(bool(snapshot.get("read_only", false)), "TASK_647 snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_647 snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_647 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_647 creates no command")

	var manifest: Dictionary = _build_manifest(snapshot)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_647 manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.homebase_missionpanel_density_findings_manifest.v1", "TASK_647 manifest schema is stable")
	_assert(String(manifest.get("gate", "")) == "pass", "TASK_647 manifest gate passes")
	_assert(bool(manifest.get("mission_summary_collapsed", false)), "TASK_647 manifest records collapsed summary")
	_assert(bool(manifest.get("read_only", false)), "TASK_647 manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "TASK_647 manifest does not set gameplay truth")

	scene.queue_free()
	await _wait_frames(2)


func _build_manifest(snapshot: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.homebase_missionpanel_density_findings_manifest.v1",
		"task_id": "TASK_647",
		"snapshot_schema": String(snapshot.get("schema", "")),
		"gate": String(snapshot.get("gate", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"visible_section_count": int(snapshot.get("visible_section_count", 0)),
		"visible_sections": Array(snapshot.get("visible_sections", [])).duplicate(true),
		"vertical_fill_ratio": float(snapshot.get("vertical_fill_ratio", 0.0)),
		"total_visible_text_length": int(snapshot.get("total_visible_text_length", 0)),
		"key_section_order": String(snapshot.get("key_section_order", "")),
		"mission_summary_collapsed": bool(snapshot.get("mission_summary_collapsed", false)),
		"density_findings_style_id": String(snapshot.get("density_findings_style_id", "")),
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


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_647 manifest for writing")
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
