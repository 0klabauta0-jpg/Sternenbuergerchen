extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_640_frontier_probe_post_debrief_homebase_readability.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_post_debrief_homebase_readability.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_640 Frontier Probe Post Debrief Homebase Readability ===")
	_test_docs_and_reports()
	await _test_post_debrief_homebase_readability()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_640: FAILED")
		quit(1)
		return
	print("TASK_640: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	var meta_layer_text: String = _read_text(META_LAYER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_640 task file exists")
	_assert(task_text.contains("Frontier Probe Post Debrief Homebase Readability"), "TASK_640 task names post Debrief Homebase readability")
	_assert(status_text.contains("TASK_640 - Frontier Probe Post Debrief Homebase Readability"), "Implementation status tracks TASK_640")
	_assert(roadmap_text.contains("TASK_640 - Frontier Probe Post Debrief Homebase Readability (implementiert)"), "Roadmap marks TASK_640 implemented")
	_assert(contract_text.contains("Frontier-Probe-Post-Debrief-Homebase-Readability"), "Mission feedback contract documents TASK_640")
	_assert(homebase_text.contains("get_frontier_probe_post_debrief_homebase_readability_snapshot"), "Homebase exposes TASK_640 snapshot")
	_assert(meta_layer_text.contains("set_last_mission_result_summary"), "MetaLayerFlow forwards last mission result to Homebase")
	_assert(report_text.contains("TASK_640 Frontier Probe Post Debrief Homebase Readability"), "Rolling report tracks TASK_640")
	_assert(report_text.contains('latest_completed_task: "TASK_644 - Frontier Probe Homebase Real Window Review"'), "Rolling report advances latest completed beyond TASK_640")
	_assert(handbook_text.contains("TASK_640 - Frontier Probe Post Debrief Homebase Readability"), "Status handbook tracks TASK_640")
	_assert(handbook_text.contains('current_task: "TASK_644 - Frontier Probe Homebase Real Window Review"'), "Status handbook current task advances beyond TASK_640")
	for key in [
		"frontier_probe_post_debrief_homebase_readability.task_id",
		"frontier_probe_post_debrief_homebase_readability.manifest_path",
		"frontier_probe_post_debrief_homebase_readability.route_id",
		"frontier_probe_post_debrief_homebase_readability.summary_text",
		"frontier_probe_post_debrief_homebase_readability.next_step_text",
		"frontier_probe_post_debrief_homebase_readability.mission_result_preserved",
		"frontier_probe_post_debrief_homebase_readability.read_only",
		"frontier_probe_post_debrief_homebase_readability.recommended_next_task",
		"frontier_probe_post_debrief_homebase_readability.notes",
	]:
		_assert(report_text.contains(key), "Rolling report exports %s" % key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_post_debrief_homebase_readability"'), "Rolling report exports TASK_640 free note")
	_assert(handbook_text.contains('data-export-key="status.task_640_done"'), "Status handbook exports TASK_640 checkbox")


func _test_post_debrief_homebase_readability() -> void:
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
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_frontier_probe_post_debrief_homebase_readability_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_post_debrief_homebase_readability.v1", "TASK_640 snapshot schema is stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_640 gate passes")
	_assert(String(snapshot.get("route_id", "")) == "frontier_probe_aa_computer_cargo", "Route id is visible on Homebase")
	_assert(String(snapshot.get("scenario_id", "")) == "frontier_probe_vertical_slice", "Scenario id is visible on Homebase")
	_assert(bool(snapshot.get("frontier_probe_result_present", false)), "Frontier Probe result is present")
	_assert(bool(snapshot.get("summary_label_visible", false)), "Post-Debrief Homebase summary is visible")
	_assert(String(snapshot.get("summary_text", "")).contains("Debrief complete -> Homebase"), "Summary explains Debrief to Homebase return")
	_assert(String(snapshot.get("summary_text", "")).contains("Frontier Probe"), "Summary names Frontier Probe")
	_assert(String(snapshot.get("summary_text", "")).contains("Next:"), "Summary contains next step")
	_assert(String(snapshot.get("next_step_text", "")) == "review roster gains", "Next step points to roster gains when awards exist")
	_assert(bool(snapshot.get("mission_result_preserved", false)), "Mission result is preserved on Homebase")
	_assert(bool(snapshot.get("read_only", false)), "TASK_640 snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_640 snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_640 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_640 creates no command")
	_assert(_check_passed(snapshot, "summary_compact"), "Summary stays compact")

	var manifest: Dictionary = _build_manifest(snapshot)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_640 manifest is written")
	_assert(bool(manifest.get("summary_label_visible", false)), "Manifest records visible Homebase summary")

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
		"team_states": [
			{"unit_id": "lead_alpha", "display_name": "Lead Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 100},
			{"unit_id": "rifle_alpha", "display_name": "Rifle Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 88},
			{"unit_id": "medic_alpha", "display_name": "Medic Alpha", "fireteam_id": "ft_alpha", "vital_state": "wounded", "health_points": 42},
		],
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


func _build_manifest(snapshot: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.frontier_probe_post_debrief_homebase_readability_manifest.v1",
		"task_id": "TASK_640",
		"snapshot_schema": String(snapshot.get("schema", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"route_id": String(snapshot.get("route_id", "")),
		"scenario_id": String(snapshot.get("scenario_id", "")),
		"summary_label_visible": bool(snapshot.get("summary_label_visible", false)),
		"summary_text": String(snapshot.get("summary_text", "")),
		"result_text": String(snapshot.get("result_text", "")),
		"next_step_text": String(snapshot.get("next_step_text", "")),
		"mission_result_preserved": bool(snapshot.get("mission_result_preserved", false)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_641 - Frontier Probe Homebase Next Sortie Readiness",
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
		_assert(false, "Can open TASK_640 manifest for writing")
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
