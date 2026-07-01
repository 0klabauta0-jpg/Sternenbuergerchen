extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_763_station_reentry_fireteam_staging_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_fireteam_staging_polish.json"

const EXPECTED_STYLE_ID: String = "task_763_station_reentry_fireteam_staging_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_763 Station Reentry Fireteam Staging Polish ===")
	_test_docs_contract_and_report()
	await _test_fireteam_staging_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_763: FAILED")
		quit(1)
		return
	print("TASK_763: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_763 task file exists")
	_assert(task_text.contains("Station Reentry Fireteam Staging Polish"), "TASK_763 task names fireteam staging polish")
	_assert(status_text.contains("TASK_763 - Station Reentry Fireteam Staging Polish"), "Implementation status tracks TASK_763")
	_assert(roadmap_text.contains("TASK_763 - Station Reentry Fireteam Staging Polish (implementiert)"), "Roadmap marks TASK_763 implemented")
	_assert(contract_text.contains("Station-Reentry-Fireteam-Staging-Polish (TASK_763)"), "Contract documents TASK_763")
	_assert(handbook_text.contains("TASK_763 - Station Reentry Fireteam Staging Polish"), "Current handbook references TASK_763")
	_assert(handbook_text.contains('data-export-key="station_reentry_fireteam_staging_polish.staging_line"'), "Current handbook exports TASK_763 staging line")
	_assert(workbench_text.contains("TASK_763"), "Station workbench references TASK_763")
	_assert(homebase_text.contains(EXPECTED_STYLE_ID), "Homebase exposes TASK_763 style id")
	_assert(homebase_text.contains("StationReentryFireteamStagingLabel"), "Homebase exposes TASK_763 label")


func _test_fireteam_staging_polish() -> void:
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
	await _wait_frames(12)

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_station_homebase_return_panel_polish_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_homebase_return_panel_polish.v1", "Return panel snapshot keeps existing schema")
	_assert(String(snapshot.get("gate", "")) == "pass", "Return panel gate remains pass")
	_assert(String(snapshot.get("reentry_fireteam_staging_style_id", "")) == EXPECTED_STYLE_ID, "Fireteam staging style id is stable")
	_assert(bool(snapshot.get("reentry_fireteam_staging_visible", false)), "Fireteam staging line is visible")
	_assert(bool(snapshot.get("reentry_fireteam_staging_read_only", false)), "Fireteam staging line is read-only")
	_assert(String(snapshot.get("reentry_fireteam_staging_text", "")) == String(snapshot.get("reentry_fireteam_staging_expected_text", "")), "Rendered staging line matches staging snapshot")
	_assert(String(snapshot.get("reentry_fireteam_staging_text", "")).contains("Fireteam"), "Staging line names Fireteam")
	_assert(String(snapshot.get("reentry_fireteam_staging_text", "")).contains("Operatoren"), "Staging line names operators")
	_assert(_check_passed(snapshot, "reentry_fireteam_staging_visible"), "Fireteam staging visible check passes")
	_assert(_check_passed(snapshot, "reentry_fireteam_staging_style_id"), "Fireteam staging style check passes")
	_assert(_check_passed(snapshot, "reentry_fireteam_staging_mentions_fireteam"), "Fireteam staging context check passes")
	_assert(_check_passed(snapshot, "reentry_fireteam_staging_inside_followup_panel"), "Fireteam staging stays inside followup panel")
	_assert(bool(snapshot.get("read_only", false)), "TASK_763 remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_763 does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_763 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_763 creates no command")

	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_reentry_fireteam_staging_polish.v1",
		"task_id": "TASK_763",
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"reentry_fireteam_staging_style_id": String(snapshot.get("reentry_fireteam_staging_style_id", "")),
		"staging_line": String(snapshot.get("reentry_fireteam_staging_text", "")),
		"selected_fireteam_count": int(snapshot.get("reentry_selected_fireteam_count", 0)),
		"selected_operator_count": int(snapshot.get("reentry_selected_operator_count", 0)),
		"payload_fireteam_count": int(snapshot.get("reentry_payload_fireteam_count", 0)),
		"payload_operator_count": int(snapshot.get("reentry_payload_operator_count", 0)),
		"boarded_operator_count": int(snapshot.get("reentry_boarded_operator_count", 0)),
		"return_panel_gate": String(snapshot.get("gate", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_764 - Station Reentry Loadout Bridge Polish oder echter Reentry-Playtest",
	}
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_763 manifest is written")

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
		"selected_unit_ids": PackedStringArray(["anna_kade", "pavel_moro", "kenzo_rhee", "leon_voss"]),
		"selected_fireteam_ids": PackedStringArray(["ft_alpha"]),
		"team_states": [
			{"unit_id": "anna_kade", "display_name": "Anna Kade", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 100},
			{"unit_id": "pavel_moro", "display_name": "Pavel Moro", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 91},
			{"unit_id": "kenzo_rhee", "display_name": "Kenzo Rhee", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 87},
			{"unit_id": "leon_voss", "display_name": "Leon Voss", "fireteam_id": "ft_alpha", "vital_state": "wounded", "health_points": 68},
		],
		"mini_aar_payload": {
			"shots_fired": 42,
			"enemies_spotted": 3,
			"commands_ignored": 0,
			"friendly_fire_risk_events": 0,
			"wounded_count": 1,
			"extracted_count": 4,
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
		_assert(false, "Can open TASK_763 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


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


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame
