extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_755_station_homebase_return_panel_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_homebase_return_panel_polish.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_755 Station Homebase Return Panel Polish ===")
	_test_docs_contract_and_report()
	await _test_return_panel_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_755: FAILED")
		quit(1)
		return
	print("TASK_755: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_755 task file exists")
	_assert(task_text.contains("Station Homebase Return Panel Polish"), "TASK_755 task names return panel polish")
	_assert(status_text.contains("TASK_755 - Station Homebase Return Panel Polish"), "Implementation status tracks TASK_755")
	_assert(roadmap_text.contains("TASK_755 - Station Homebase Return Panel Polish"), "Roadmap tracks TASK_755")
	_assert(contract_text.contains("Station-Homebase-Return-Panel-Polish (TASK_755)"), "Mission command feedback contract documents TASK_755")
	_assert(homebase_text.contains("get_station_homebase_return_panel_polish_snapshot"), "Homebase exposes TASK_755 snapshot")
	_assert(homebase_text.contains("task_755_station_homebase_return_panel_v1"), "Homebase exposes TASK_755 style id")
	_assert(handbook_text.contains("TASK_755 - Station Homebase Return Panel Polish"), "Current handbook references TASK_755")
	_assert(handbook_text.contains('data-export-key="status.task_755_done"'), "Current handbook exports TASK_755 checkbox")
	for key in [
		"station_homebase_return_panel_polish.task_id",
		"station_homebase_return_panel_polish.manifest_path",
		"station_homebase_return_panel_polish.return_panel_style_id",
		"station_homebase_return_panel_polish.return_panel_title_text",
		"station_homebase_return_panel_polish.return_panel_action_text",
		"station_homebase_return_panel_polish.return_panel_chip_count",
		"station_homebase_return_panel_polish.return_panel_primary_step_id",
		"station_homebase_return_panel_polish.recommended_next_task",
		"station_homebase_return_panel_polish.notes",
	]:
		_assert(handbook_text.contains(key), "Current handbook exports %s" % key)


func _test_return_panel_polish() -> void:
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
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_homebase_return_panel_polish.v1", "TASK_755 snapshot schema is stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_755 return panel gate passes")
	_assert(String(snapshot.get("return_panel_style_id", "")) == "task_755_station_homebase_return_panel_v1", "Return panel carries TASK_755 style id")
	_assert(String(snapshot.get("return_panel_title_text", "")) == "Rueckkehr abgeschlossen", "Return panel title is clear")
	_assert(String(snapshot.get("return_panel_action_text", "")).contains("Naechster Auftrag"), "Return panel action names next order")
	_assert(String(snapshot.get("return_panel_action_text", "")).contains("Fireteam bereitstellen"), "Return panel action names current station step")
	_assert(int(snapshot.get("return_panel_chip_count", 0)) >= 5, "Return panel shows all step chips")
	_assert(String(snapshot.get("return_panel_primary_step_id", "")) == "stage_fireteam", "Return panel preserves current actionable step")
	_assert(_chip_exists(snapshot, "review_roster_gains", "Auswertung ansehen"), "Return panel has roster chip")
	_assert(_chip_exists(snapshot, "stage_fireteam", "Fireteam bereitstellen"), "Return panel has fireteam chip")
	_assert(_chip_exists(snapshot, "assign_loadout", "Loadout pruefen"), "Return panel has loadout chip")
	_assert(_chip_exists(snapshot, "prepare_transport", "Dropship beladen"), "Return panel has dropship chip")
	_assert(_chip_exists(snapshot, "start_next_sortie", "Start freigeben"), "Return panel has start chip")
	_assert(_chip_state(snapshot, "stage_fireteam") == "current", "Return panel marks current chip")
	_assert(_check_passed(snapshot, "inside_followup_panel"), "Return panel content stays inside FollowupPanel")
	_assert(_check_passed(snapshot, "inside_mission_panel"), "Return panel stays inside MissionPanel")
	_assert(bool(snapshot.get("return_panel_polish_ready", false)), "Return panel polish ready flag is green")
	_assert(bool(snapshot.get("manual_review_required", false)), "TASK_755 still requires real visible review")
	_assert(not bool(snapshot.get("manual_review_done", true)), "TASK_755 does not claim manual review done")
	_assert(bool(snapshot.get("read_only", false)), "TASK_755 is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_755 does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_755 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_755 creates no command")

	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_homebase_return_panel_polish_manifest.v1",
		"task_id": "TASK_755",
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"gate": String(snapshot.get("gate", "")),
		"return_panel_style_id": String(snapshot.get("return_panel_style_id", "")),
		"return_panel_title_text": String(snapshot.get("return_panel_title_text", "")),
		"return_panel_action_text": String(snapshot.get("return_panel_action_text", "")),
		"return_panel_chip_count": int(snapshot.get("return_panel_chip_count", 0)),
		"return_panel_primary_step_id": String(snapshot.get("return_panel_primary_step_id", "")),
		"readiness_line": String(snapshot.get("readiness_line", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_756 - Station Homebase Real Window Recapture",
	}
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_755 manifest is written")

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


func _chip_exists(snapshot: Dictionary, step_id: String, label: String) -> bool:
	for chip_variant in Array(snapshot.get("return_panel_step_chips", [])):
		var chip: Dictionary = Dictionary(chip_variant)
		if String(chip.get("id", "")) == step_id and String(chip.get("label", "")) == label:
			return true
	return false


func _chip_state(snapshot: Dictionary, step_id: String) -> String:
	for chip_variant in Array(snapshot.get("return_panel_step_chips", [])):
		var chip: Dictionary = Dictionary(chip_variant)
		if String(chip.get("id", "")) == step_id:
			return String(chip.get("state", ""))
	return ""


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_755 manifest for writing")
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
