extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_739_station_scenario_identity_cue_recapture_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const CAPTURE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const HOST_CROP_PATH: String = "res://tmp/host_client_two_window_host_review.png"
const CLIENT_CROP_PATH: String = "res://tmp/host_client_two_window_client_review.png"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_identity_cue_recapture_findings.json"
const EXPECTED_CUE_FRAGMENT: String = "CUE AA:"
const EXPECTED_ACTION_FRAGMENT: String = "naeher ran"
const EXPECTED_ROUTE_LINE: String = "ROUTE AA > DOOR > COM > CARGO | NEXT AA"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_739 Station Scenario Identity Cue Recapture Findings ===")
	_test_docs_contract_and_report()
	await _test_recapture_findings_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_739: FAILED")
		quit(1)
		return
	print("TASK_739: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_739 task file exists")
	_assert(task_text.contains("Station Scenario Identity Cue Recapture Findings"), "Task documents recapture findings")
	_assert(contract_text.contains("Station Scenario Identity Cue Recapture Findings"), "Interaction contract documents TASK_739")
	_assert(status_text.contains("TASK_739 - Station Scenario Identity Cue Recapture Findings"), "Implementation status tracks TASK_739")
	_assert(roadmap_text.contains("TASK_739 - Station Scenario Identity Cue Recapture Findings (implementiert)"), "Roadmap marks TASK_739 implemented")
	_assert(roadmap_text.contains("TASK_740 - Scenario Harness Modernization"), "Roadmap keeps harness modernization conditional")
	_assert(report_text.contains("TASK_739 - Station Scenario Identity Cue Recapture Findings"), "Current handbook references TASK_739")
	_assert(report_text.contains("station_scenario_identity_cue_recapture_findings"), "Current handbook exports TASK_739 fields")


func _test_recapture_findings_manifest() -> void:
	var capture: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	var identity: Dictionary = await _build_current_identity_body_snapshot()
	_assert(not capture.is_empty(), "Capture manifest exists")
	_assert(String(capture.get("schema", "")) == "sternenbuergerchen.host_client_two_window_real_run_review.v1", "Capture manifest schema is stable")
	_assert(bool(capture.get("real_run_done", false)), "Capture manifest records real run done")
	_assert(bool(capture.get("host_screenshot_written", false)), "Capture manifest records host crop")
	_assert(bool(capture.get("client_screenshot_written", false)), "Capture manifest records client crop")
	_assert(FileAccess.file_exists(HOST_CROP_PATH), "Host crop file exists")
	_assert(FileAccess.file_exists(CLIENT_CROP_PATH), "Client crop file exists")
	_assert(_snapshot_is_read_only(identity), "Identity snapshot stays read-only")
	_assert(bool(identity.get("cue_visible", false)), "Identity snapshot marks cue visible")
	_assert(String(identity.get("text", "")).contains(EXPECTED_CUE_FRAGMENT), "Identity text contains cue")
	_assert(String(identity.get("text", "")).contains(EXPECTED_ACTION_FRAGMENT), "Identity text contains action language")
	_assert(String(identity.get("display_route_line", "")) == EXPECTED_ROUTE_LINE, "Identity display route is neutral")
	_assert(bool(identity.get("future_blocker_hidden_in_display", false)), "Identity hides future cargo blocker in display")
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_scenario_identity_cue_recapture_findings.v1",
		"task_id": "TASK_739",
		"source_capture_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"host_crop_path": "tmp/host_client_two_window_host_review.png",
		"client_crop_path": "tmp/host_client_two_window_client_review.png",
		"real_run_done": bool(capture.get("real_run_done", false)),
		"host_crop_ready": FileAccess.file_exists(HOST_CROP_PATH),
		"client_crop_ready": FileAccess.file_exists(CLIENT_CROP_PATH),
		"identity_style_id": String(identity.get("style_id", "")),
		"identity_text": String(identity.get("text", "")),
		"cue_visible": bool(identity.get("cue_visible", false)),
		"display_route_line": String(identity.get("display_route_line", "")),
		"future_blocker_hidden_in_display": bool(identity.get("future_blocker_hidden_in_display", false)),
		"status": "ready_for_task_727_workbench_export",
		"manual_review_required": true,
		"manual_review_done": false,
		"recommended_next_task": "TASK_727 - fill visible station scenario playtest workbench",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_739 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_739", "Manifest records TASK_739")
	_assert(String(parsed.get("status", "")) == "ready_for_task_727_workbench_export", "Manifest routes to TASK_727 workbench")
	_assert(_snapshot_is_read_only(parsed), "Manifest stays read-only")
	_assert(not bool(parsed.get("manual_review_done", true)), "Manifest does not fake human review")


func _build_current_identity_body_snapshot() -> Dictionary:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var identity: Dictionary = {}
	if controller != null and combat_driver != null:
		combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
		controller.call("_update_ui")
		await _wait_frames(2)
		var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
		identity = Dictionary(feedback.get("station_scenario_identity_body", {})).duplicate(true)
	scene.queue_free()
	await _wait_frames(2)
	return identity


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _write_manifest(manifest: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_739 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
