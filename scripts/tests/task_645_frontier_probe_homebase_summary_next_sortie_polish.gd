extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_645_frontier_probe_homebase_summary_next_sortie_polish.md"
const TASK_644_PATH: String = "res://docs/tasks/TASK_644_frontier_probe_homebase_real_window_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const STATE_HANDBOOK_PATH: String = "res://docs/reports/project_state_handbook_2026_06_30.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_645 Frontier Probe Homebase Summary Next Sortie Polish ===")
	_test_docs_and_reports()
	await _test_homebase_followup_panel_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_645: FAILED")
		quit(1)
		return
	print("TASK_645: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var task_644_text: String = _read_text(TASK_644_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var state_handbook_text: String = _read_text(STATE_HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_645 task file exists")
	_assert(task_text.contains("Frontier Probe Homebase Summary Next Sortie Polish"), "TASK_645 task names summary/next-sortie polish")
	_assert(task_644_text.contains("Frontier Probe Homebase Real Window Review"), "TASK_644 source review remains available")
	_assert(status_text.contains("TASK_645 - Frontier Probe Homebase Summary Next Sortie Polish"), "Implementation status tracks TASK_645")
	_assert(roadmap_text.contains("TASK_645 - Frontier Probe Homebase Summary Next Sortie Polish (implementiert)"), "Roadmap marks TASK_645 implemented")
	_assert(contract_text.contains("Frontier-Probe-Homebase-Summary-Next-Sortie-Polish"), "Mission feedback contract documents TASK_645")
	_assert(homebase_text.contains("PostDebriefFollowupPanel"), "Homebase creates the follow-up panel")
	_assert(homebase_text.contains("HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID"), "Homebase exposes stable TASK_645 style id")
	_assert(report_text.contains("TASK_645 Frontier Probe Homebase Summary Next Sortie Polish"), "Rolling report tracks TASK_645")
	_assert(report_text.contains('latest_completed_task: "TASK_646 - Homebase MissionPanel Density Playfeel Review"'), "Rolling report advances latest completed beyond TASK_645")
	_assert(handbook_text.contains("TASK_645 - Frontier Probe Homebase Summary Next Sortie Polish"), "Status handbook tracks TASK_645")
	_assert(handbook_text.contains('current_task: "TASK_646 - Homebase MissionPanel Density Playfeel Review"'), "Status handbook current task advances beyond TASK_645")
	_assert(state_handbook_text.contains("TASK_645 - Frontier Probe Homebase Summary Next Sortie Polish"), "State handbook tracks TASK_645")
	for key in [
		"frontier_probe_homebase_summary_next_sortie_polish.task_id",
		"frontier_probe_homebase_summary_next_sortie_polish.followup_panel_visible",
		"frontier_probe_homebase_summary_next_sortie_polish.followup_panel_style_id",
		"frontier_probe_homebase_summary_next_sortie_polish.post_summary_font_size",
		"frontier_probe_homebase_summary_next_sortie_polish.next_sortie_font_size",
		"frontier_probe_homebase_summary_next_sortie_polish.read_only",
		"frontier_probe_homebase_summary_next_sortie_polish.recommended_next_task",
		"frontier_probe_homebase_summary_next_sortie_polish.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_homebase_summary_next_sortie_polish"'), "Rolling report exports TASK_645 free note")
	_assert(handbook_text.contains('data-export-key="status.task_645_done"'), "Status handbook exports TASK_645 checkbox")


func _test_homebase_followup_panel_polish() -> void:
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

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_frontier_probe_homebase_visible_readiness_review_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_homebase_visible_readiness_review.v1", "TASK_645 keeps visible readiness schema stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_645 visible readiness gate passes")
	_assert(bool(snapshot.get("followup_panel_visible", false)), "Follow-up panel is visible")
	_assert(String(snapshot.get("followup_panel_style_id", "")) == "task_645_homebase_followup_panel_v1", "Follow-up panel carries TASK_645 style id")
	_assert(float(snapshot.get("followup_panel_min_height", 0.0)) >= 70.0, "Follow-up panel has a stable minimum height")
	_assert(int(snapshot.get("post_summary_font_size", 0)) >= 12, "Post-Debrief summary uses larger font")
	_assert(int(snapshot.get("next_sortie_font_size", 0)) >= 12, "Next-sortie readiness uses larger font")
	_assert(bool(snapshot.get("post_summary_emphasis", false)), "Post-Debrief summary exposes emphasis metadata")
	_assert(bool(snapshot.get("next_sortie_emphasis", false)), "Next-sortie readiness exposes emphasis metadata")
	_assert(_check_passed(snapshot, "followup_panel_visible"), "Snapshot check confirms follow-up panel visibility")
	_assert(_check_passed(snapshot, "followup_panel_inside_mission_panel"), "Follow-up panel stays inside MissionPanel")
	_assert(_check_passed(snapshot, "labels_inside_followup_panel"), "Labels stay grouped inside follow-up panel")
	_assert(_check_passed(snapshot, "followup_panel_emphasis_style"), "Snapshot check confirms emphasis style")
	_assert(_check_passed(snapshot, "followup_label_emphasis"), "Snapshot check confirms larger label emphasis")
	_assert(_check_passed(snapshot, "mission_panel_no_overflow"), "MissionPanel does not overflow after polish")
	_assert(bool(snapshot.get("read_only", false)), "TASK_645 snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_645 snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_645 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_645 creates no command")

	scene.queue_free()
	await _wait_frames(2)


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
