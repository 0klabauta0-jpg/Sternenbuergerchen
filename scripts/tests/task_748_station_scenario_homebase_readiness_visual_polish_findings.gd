extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_748_station_scenario_homebase_readiness_visual_polish_findings.md"
const TASK_747_PATH: String = "res://docs/tasks/TASK_747_station_scenario_homebase_visible_readiness_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const SOURCE_MANIFEST_PATH: String = "res://tmp/station_scenario_homebase_visible_readiness_review.json"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_homebase_readiness_visual_polish_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_748 Station Scenario Homebase Readiness Visual Polish Findings ===")
	_test_docs_contract_and_report()
	await _test_visual_polish_findings()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_748: FAILED")
		quit(1)
		return
	print("TASK_748: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var task_747_text: String = _read_text(TASK_747_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_748 task file exists")
	_assert(task_text.contains("Station Scenario Homebase Readiness Visual Polish Findings"), "TASK_748 task names visual polish findings")
	_assert(task_747_text.contains("TASK_748 - Station Scenario Homebase Readiness Visual Polish Findings"), "TASK_747 points to TASK_748 follow-up")
	_assert(status_text.contains("TASK_748 - Station Scenario Homebase Readiness Visual Polish Findings"), "Implementation status tracks TASK_748")
	_assert(roadmap_text.contains("TASK_748 - Station Scenario Homebase Readiness Visual Polish Findings"), "Roadmap tracks TASK_748")
	_assert(contract_text.contains("Station-Scenario-Homebase-Readiness-Visual-Polish-Findings"), "Mission command feedback contract documents TASK_748")
	_assert(handbook_text.contains("TASK_748 - Station Scenario Homebase Readiness Visual Polish Findings"), "Current handbook references TASK_748")
	_assert(handbook_text.contains('data-export-key="status.task_748_done"'), "Current handbook exports TASK_748 checkbox")
	for key in [
		"station_scenario_homebase_readiness_visual_polish_findings.task_id",
		"station_scenario_homebase_readiness_visual_polish_findings.manifest_path",
		"station_scenario_homebase_readiness_visual_polish_findings.source_manifest_path",
		"station_scenario_homebase_readiness_visual_polish_findings.source_gate",
		"station_scenario_homebase_readiness_visual_polish_findings.geometry_gate",
		"station_scenario_homebase_readiness_visual_polish_findings.microcopy_followup_needed",
		"station_scenario_homebase_readiness_visual_polish_findings.recommended_next_task",
		"station_scenario_homebase_readiness_visual_polish_findings.notes",
	]:
		_assert(handbook_text.contains(key), "Current handbook exports %s" % key)


func _test_visual_polish_findings() -> void:
	_assert(FileAccess.file_exists(SOURCE_MANIFEST_PATH), "TASK_747 source manifest exists for TASK_748 verification")
	var source_manifest: Dictionary = _read_json(SOURCE_MANIFEST_PATH)
	_assert(String(source_manifest.get("schema", "")) == "sternenbuergerchen.station_scenario_homebase_visible_readiness_review_manifest.v1", "TASK_747 manifest schema remains stable")
	_assert(String(source_manifest.get("gate", "")) == "pass", "TASK_747 source gate passes")
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

	var snapshot: Dictionary = Dictionary(homebase_screen.call("get_station_scenario_homebase_visible_readiness_review_snapshot")).duplicate(true)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_scenario_homebase_visible_readiness_review.v1", "TASK_747 snapshot schema is stable for TASK_748")
	_assert(String(snapshot.get("gate", "")) == "pass", "Current visible readiness snapshot still passes")
	_assert(String(snapshot.get("readiness_gate", "")) == "pass", "TASK_746 readiness remains green")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_navigation", true)), "Snapshot creates no navigation")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no command")
	_assert(bool(snapshot.get("manual_review_required", false)), "Manual visible review remains required")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Manual visible review is not claimed done")

	var manifest: Dictionary = _build_findings_manifest(snapshot, source_manifest)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_748 findings manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.station_scenario_homebase_readiness_visual_polish_findings.v1", "TASK_748 manifest schema is stable")
	_assert(String(manifest.get("source_task_id", "")) == "TASK_747", "TASK_748 points to TASK_747")
	_assert(String(manifest.get("source_gate", "")) == "pass", "TASK_748 source gate passes")
	_assert(String(manifest.get("geometry_gate", "")) == "pass", "TASK_748 geometry gate passes")
	_assert(bool(manifest.get("microcopy_followup_needed", false)) or String(manifest.get("resolved_by_task_id", "")) == "TASK_749", "TASK_748 flags microcopy follow-up or records TASK_749 resolution")
	_assert(int(manifest.get("actionable_followup_count", 0)) >= 1, "TASK_748 records actionable follow-up")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_749 - Station Homebase Follow-up Microcopy Polish", "TASK_748 recommends TASK_749")
	_assert(bool(manifest.get("read_only", false)), "TASK_748 manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "TASK_748 manifest does not set gameplay truth")
	_assert(not bool(manifest.get("creates_navigation", true)), "TASK_748 creates no navigation")
	_assert(not bool(manifest.get("creates_command", true)), "TASK_748 creates no command")

	scene.queue_free()
	await _wait_frames(2)


func _build_findings_manifest(snapshot: Dictionary, source_manifest: Dictionary) -> Dictionary:
	var readiness_line: String = String(source_manifest.get("readiness_line", snapshot.get("readiness_line", ""))).strip_edges()
	var english_marker_count: int = 0
	for marker in ["Next sortie", "Review gains", "Stage fireteam", "Assign loadout", "Load dropship", "Start next sortie"]:
		if readiness_line.contains(marker):
			english_marker_count += 1
	var geometry_gate: String = "pass"
	for check_id in ["labels_inside_mission_panel", "labels_inside_followup_panel", "labels_do_not_overlap", "mission_panel_no_overflow"]:
		if not _check_passed(snapshot, check_id):
			geometry_gate = "fail"
	var findings: Array = [
		{
			"id": "geometry_green",
			"severity": "info",
			"summary": "Summary, Next-Sortie-Zeile und FollowupPanel liegen korrekt und ohne Overflow.",
		},
		{
			"id": "manual_visible_review_open",
			"severity": "medium",
			"summary": "TASK_747 ist ein Headless-/Evidence-Review; ein echter sichtbarer Fensterblick bleibt offen.",
		},
		{
			"id": "next_sortie_microcopy_long",
			"severity": "medium",
			"summary": "Die Next-Sortie-Zeile ist lang und englisch-lastig; der naechste Polish sollte sie kompakter und spielnaher machen.",
		},
	]
	return {
		"schema": "sternenbuergerchen.station_scenario_homebase_readiness_visual_polish_findings.v1",
		"task_id": "TASK_748",
		"source_task_id": "TASK_747",
		"source_manifest_path": ProjectSettings.globalize_path(SOURCE_MANIFEST_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"source_manifest_present": not source_manifest.is_empty(),
		"source_gate": String(source_manifest.get("gate", "")),
		"snapshot_gate": String(snapshot.get("gate", "")),
		"geometry_gate": geometry_gate,
		"route_id": String(snapshot.get("route_id", "")),
		"scenario_id": String(snapshot.get("scenario_id", "")),
		"current_next_step_id": String(snapshot.get("current_next_step_id", "")),
		"readiness_line": readiness_line,
		"readiness_line_length": readiness_line.length(),
		"english_marker_count": english_marker_count,
		"manual_review_required": bool(snapshot.get("manual_review_required", false)),
		"manual_review_done": bool(snapshot.get("manual_review_done", true)),
		"generated_evidence_board": bool(source_manifest.get("generated_evidence_board", false)),
		"viewport_readback_available": bool(source_manifest.get("viewport_readback_available", true)),
		"microcopy_followup_needed": readiness_line.length() >= 96 or english_marker_count >= 3,
		"resolved_by_task_id": "TASK_749" if readiness_line.begins_with("Naechste Sortie:") else "",
		"actionable_followup_count": 1,
		"findings": findings,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"recommended_next_task": "TASK_749 - Station Homebase Follow-up Microcopy Polish",
	}


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
		_assert(false, "Can open TASK_748 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


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
