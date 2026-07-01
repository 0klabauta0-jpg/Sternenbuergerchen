extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_745_station_scenario_post_debrief_homebase_readability.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_post_debrief_homebase_readability.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_745 Station Scenario Post Debrief Homebase Readability ===")
	_test_docs_contract_and_report()
	await _test_post_debrief_homebase_readability()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_745: FAILED")
		quit(1)
		return
	print("TASK_745: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_745 task file exists")
	_assert(task_text.contains("Station Scenario Post Debrief Homebase Readability"), "Task documents Station post-Debrief Homebase readability")
	_assert(status_text.contains("TASK_745 - Station Scenario Post Debrief Homebase Readability"), "Implementation status tracks TASK_745")
	_assert(roadmap_text.contains("TASK_745 - Station Scenario Post Debrief Homebase Readability"), "Roadmap tracks TASK_745")
	_assert(contract_text.contains("Station-Scenario-Post-Debrief-Homebase-Readability"), "Mission command feedback contract documents TASK_745")
	_assert(homebase_text.contains("get_station_scenario_post_debrief_homebase_readability_snapshot"), "Homebase exposes TASK_745 snapshot")
	_assert(handbook_text.contains("TASK_745 - Station Scenario Post Debrief Homebase Readability"), "Current handbook references TASK_745")
	for key in [
		"station_scenario_post_debrief_homebase_readability.task_id",
		"station_scenario_post_debrief_homebase_readability.manifest_path",
		"station_scenario_post_debrief_homebase_readability.route_id",
		"station_scenario_post_debrief_homebase_readability.summary_text",
		"station_scenario_post_debrief_homebase_readability.next_step_text",
		"station_scenario_post_debrief_homebase_readability.mission_result_preserved",
		"station_scenario_post_debrief_homebase_readability.read_only",
		"station_scenario_post_debrief_homebase_readability.recommended_next_task",
		"station_scenario_post_debrief_homebase_readability.notes",
	]:
		_assert(handbook_text.contains(key), "Current handbook exports %s" % key)
	_assert(handbook_text.contains('data-export-key="status.task_745_done"'), "Current handbook exports TASK_745 checkbox")


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

	var mission_result: Dictionary = _build_station_result()
	scene.set("_last_mission_result", mission_result.duplicate(true))
	debrief_screen.call("set_mission_result", mission_result.duplicate(true))
	scene.call("_show_debrief")
	await _wait_frames(4)
	scene.call("request_debrief_return_homebase_for_test")
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_station_scenario_post_debrief_homebase_readability_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_scenario_post_debrief_homebase_readability.v1", "TASK_745 snapshot schema is stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_745 gate passes")
	_assert(String(snapshot.get("route_id", "")) == "station_route_aa_door_computer_cargo", "Route id is visible on Homebase")
	_assert(String(snapshot.get("scenario_id", "")) == "station_route_one_screen_multiplayer_drill", "Scenario id is visible on Homebase")
	_assert(bool(snapshot.get("station_result_present", false)), "Station result is present")
	_assert(bool(snapshot.get("summary_label_visible", false)), "Post-Debrief Homebase summary is visible")
	_assert(String(snapshot.get("summary_text", "")).contains("Debrief complete -> Homebase"), "Summary explains Debrief to Homebase return")
	_assert(String(snapshot.get("summary_text", "")).contains("Station Drill"), "Summary names Station Drill")
	_assert(String(snapshot.get("summary_text", "")).contains("Next:"), "Summary contains next step")
	_assert(String(snapshot.get("next_step_text", "")) == "prep next sortie", "Next step points to next sortie prep without awards")
	_assert(bool(snapshot.get("mission_result_preserved", false)), "Mission result is preserved on Homebase")
	_assert(bool(snapshot.get("read_only", false)), "TASK_745 snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_745 snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_745 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_745 creates no command")
	_assert(_check_passed(snapshot, "summary_compact"), "Summary stays compact")

	var manifest: Dictionary = _build_manifest(snapshot)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_745 manifest is written")
	_assert(bool(manifest.get("summary_label_visible", false)), "Manifest records visible Homebase summary")

	scene.queue_free()
	await _wait_frames(2)


func _build_station_result() -> Dictionary:
	return {
		"scenario_id": "station_route_one_screen_multiplayer_drill",
		"mission_id": "station_route_one_screen_multiplayer_drill",
		"scenario_file_path": "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"route_id": "station_route_aa_door_computer_cargo",
		"winning_team_id": "team_alpha",
		"mission_outcome": "completed",
		"result": "victory",
		"win_condition_type": "station_route_cargo_extract",
		"objective_captured": true,
		"duration_seconds": 386.0,
		"selected_unit_ids": PackedStringArray(["lead_alpha", "rifle_alpha", "medic_alpha", "support_alpha"]),
		"selected_fireteam_ids": PackedStringArray(["ft1"]),
		"team_states": [
			{"unit_id": "lead_alpha", "display_name": "Lead Alpha", "fireteam_id": "ft1", "vital_state": "fit", "health_points": 100},
			{"unit_id": "rifle_alpha", "display_name": "Rifle Alpha", "fireteam_id": "ft1", "vital_state": "fit", "health_points": 92},
			{"unit_id": "medic_alpha", "display_name": "Medic Alpha", "fireteam_id": "ft1", "vital_state": "fit", "health_points": 88},
			{"unit_id": "support_alpha", "display_name": "Support Alpha", "fireteam_id": "ft1", "vital_state": "wounded", "health_points": 61},
		],
		"mini_aar_debrief": {
			"schema": "sternenbuergerchen.mini_aar_debrief_screen_stub.v1",
			"summary_text": "FIRE 0 | SUP 0 | AA Door COM Cargo",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
	}


func _build_manifest(snapshot: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_scenario_post_debrief_homebase_readability_manifest.v1",
		"task_id": "TASK_745",
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
		"recommended_next_task": "TASK_746 - Station Scenario Homebase Next Sortie Readiness",
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _write_manifest(manifest: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_745 manifest for writing")
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
