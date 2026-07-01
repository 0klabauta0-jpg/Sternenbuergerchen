extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_749_station_homebase_followup_microcopy_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_homebase_followup_microcopy_polish.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_749 Station Homebase Follow-up Microcopy Polish ===")
	_test_docs_contract_and_report()
	await _test_station_microcopy()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_749: FAILED")
		quit(1)
		return
	print("TASK_749: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var homebase_text: String = _read_text(HOMEBASE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_749 task file exists")
	_assert(task_text.contains("Station Homebase Follow-up Microcopy Polish"), "TASK_749 task names microcopy polish")
	_assert(status_text.contains("TASK_749 - Station Homebase Follow-up Microcopy Polish"), "Implementation status tracks TASK_749")
	_assert(roadmap_text.contains("TASK_749 - Station Homebase Follow-up Microcopy Polish"), "Roadmap tracks TASK_749")
	_assert(contract_text.contains("Station-Homebase-Follow-up-Microcopy-Polish"), "Mission command feedback contract documents TASK_749")
	_assert(handbook_text.contains("TASK_749 - Station Homebase Follow-up Microcopy Polish"), "Current handbook references TASK_749")
	_assert(handbook_text.contains('data-export-key="status.task_749_done"'), "Current handbook exports TASK_749 checkbox")
	_assert(homebase_text.contains("_build_station_next_sortie_readiness_line"), "Homebase has station-specific microcopy builder")
	for key in [
		"station_homebase_followup_microcopy_polish.task_id",
		"station_homebase_followup_microcopy_polish.manifest_path",
		"station_homebase_followup_microcopy_polish.readiness_line",
		"station_homebase_followup_microcopy_polish.old_debug_markers_removed",
		"station_homebase_followup_microcopy_polish.recommended_next_task",
		"station_homebase_followup_microcopy_polish.notes",
	]:
		_assert(handbook_text.contains(key), "Current handbook exports %s" % key)


func _test_station_microcopy() -> void:
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

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_station_scenario_homebase_next_sortie_readiness_snapshot")).duplicate(true)
	var line: String = String(snapshot.get("readiness_line", "")).strip_edges()
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_scenario_homebase_next_sortie_readiness.v1", "TASK_746 snapshot schema remains stable")
	_assert(String(snapshot.get("gate", "")) == "pass", "Station next-sortie readiness still passes")
	_assert(line.begins_with("Naechste Sortie:"), "Station line starts with German next-sortie microcopy")
	_assert(line.contains("Fireteam bereitstellen"), "Station line names actionable current step")
	_assert(line.contains("Loadout pruefen"), "Station line keeps loadout follow-up visible")
	_assert(line.contains("Dropship beladen"), "Station line keeps transport follow-up visible")
	_assert(line.length() <= 110, "Station line stays compact after microcopy polish")
	_assert(line.count("\n") == 0, "Station line stays one-line")
	_assert(String(snapshot.get("rendered_readiness_line", "")) == line, "Rendered station line matches snapshot")
	_assert(_old_debug_markers_removed(line), "Old English debug markers are removed from visible station line")
	_assert(_step_exists(snapshot, "review_roster_gains"), "Readiness steps still include roster gains")
	_assert(_step_exists(snapshot, "stage_fireteam"), "Readiness steps still include fireteam staging")
	_assert(_step_exists(snapshot, "assign_loadout"), "Readiness steps still include loadout")
	_assert(_step_exists(snapshot, "prepare_transport"), "Readiness steps still include transport")
	_assert(_step_exists(snapshot, "start_next_sortie"), "Readiness steps still include mission start")
	_assert(bool(snapshot.get("read_only", false)), "TASK_749 stays read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_749 does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "TASK_749 creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "TASK_749 creates no command")

	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_homebase_followup_microcopy_polish.v1",
		"task_id": "TASK_749",
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"readiness_line": line,
		"readiness_line_length": line.length(),
		"current_next_step_id": String(snapshot.get("current_next_step_id", "")),
		"old_debug_markers_removed": _old_debug_markers_removed(line),
		"readiness_steps_preserved": _step_exists(snapshot, "review_roster_gains") and _step_exists(snapshot, "stage_fireteam") and _step_exists(snapshot, "assign_loadout") and _step_exists(snapshot, "prepare_transport") and _step_exists(snapshot, "start_next_sortie"),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "Station Host/Client Homebase Recapture",
	}
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_749 microcopy manifest is written")

	scene.queue_free()
	await _wait_frames(2)


func _old_debug_markers_removed(line: String) -> bool:
	for marker in ["Next sortie", "Review gains", "Stage fireteam", "Assign loadout", "Load dropship", "Start next sortie"]:
		if line.contains(marker):
			return false
	return true


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


func _step_exists(snapshot: Dictionary, step_id: String) -> bool:
	for step_variant in Array(snapshot.get("readiness_steps", [])):
		var step: Dictionary = Dictionary(step_variant)
		if String(step.get("id", "")) == step_id:
			return true
	return false


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_749 manifest for writing")
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
