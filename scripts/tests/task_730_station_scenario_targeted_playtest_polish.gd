extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_730_station_scenario_targeted_playtest_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const MISSION_IDENTITY_BODY_LABEL_PATH: NodePath = NodePath("TacticalUI/MissionIdentityPanel/MissionIdentityMargin/MissionIdentityVBox/MissionIdentityBodyLabel")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_730 Station Scenario Targeted Playtest Polish ===")
	_test_docs_contract_and_report()
	_test_identity_body_snapshot_contract()
	await _test_visible_identity_body_uses_station_route()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_730: FAILED")
		quit(1)
		return
	print("TASK_730: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text("res://scripts/tests/mission_tactical_sandbox_controller.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_730 task file exists")
	_assert(task_text.contains("Station Scenario Targeted Playtest Polish"), "Task documents targeted polish")
	_assert(contract_text.contains("Station Scenario Targeted Playtest Polish"), "Interaction contract documents TASK_730")
	_assert(status_text.contains("TASK_730 - Station Scenario Targeted Playtest Polish"), "Implementation status tracks TASK_730")
	_assert(roadmap_text.contains("TASK_730 - Station Scenario Targeted Playtest Polish (implementiert)"), "Roadmap marks TASK_730 implemented")
	_assert(report_text.contains("TASK_730 - Station Scenario Targeted Playtest Polish"), "Current handbook references TASK_730")
	_assert(report_text.contains('data-export-key="station_scenario_targeted_polish.identity_body_route_visible"'), "Current handbook exports TASK_730 route visibility")
	_assert(report_text.contains("tmp/host_client_two_window_host_review.png"), "Current handbook records host crop path")
	_assert(report_text.contains("tmp/host_client_two_window_client_review.png"), "Current handbook records client crop path")
	_assert(controller_text.contains("build_station_scenario_identity_body_snapshot"), "Controller exposes identity body snapshot")
	_assert(controller_text.contains("station_scenario_identity_body_route_visible"), "Command feedback exports identity route visibility")


func _test_identity_body_snapshot_contract() -> void:
	var controller: Node = CONTROLLER_SCRIPT.new()
	var route_readout: Dictionary = {
		"active": true,
		"compact_line": "ROUTE AA READY > DOOR LOCK > COM WAIT > CARGO WAIT | NEXT AA",
		"next_token": "AA",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	var snapshot: Dictionary = Dictionary(controller.call("build_station_scenario_identity_body_snapshot", route_readout, [
		"--review-role=host",
		"--peer-id=1",
		"--team=team_alpha",
	]))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_scenario_identity_body.v1", "Identity body schema is stable")
	_assert(bool(snapshot.get("active", false)), "Identity body is active with station route")
	_assert(String(snapshot.get("text", "")).contains("HOST P1 ALPHA"), "Identity body keeps host badge")
	_assert(_line_contains_route_tokens(String(snapshot.get("text", ""))), "Identity body text names full station route")
	_assert(String(snapshot.get("route_next_token", "")) == "AA", "Identity body exports next token")
	_assert(bool(snapshot.get("read_only", false)), "Identity body snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Identity body does not set gameplay truth")
	_assert(bool(snapshot.get("line_within_limit", false)), "Identity body line stays within limit")
	controller.free()


func _test_visible_identity_body_uses_station_route() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(controller != null and combat_driver != null, "Mission scene exposes controller and driver")
	if controller == null or combat_driver == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures station scenario")
	controller.call("_update_ui")
	await _wait_frames(2)
	var body_label := scene.get_node_or_null(MISSION_IDENTITY_BODY_LABEL_PATH) as Label
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var identity_body: Dictionary = Dictionary(command_feedback.get("station_scenario_identity_body", {}))
	var body_text: String = body_label.text if body_label != null else ""
	_assert(body_label != null, "Mission identity body label exists")
	_assert(_line_contains_route_tokens(body_text), "Visible mission identity body contains station route")
	_assert(bool(body_label.get_meta("station_scenario_route_visible", false)), "Visible label metadata marks station route")
	_assert(String(body_label.get_meta("station_scenario_identity_task", "")) == "TASK_730", "Visible label metadata records TASK_730")
	_assert(bool(identity_body.get("active", false)), "Command feedback exports active identity body")
	_assert(String(command_feedback.get("station_scenario_identity_body_line", "")).contains("ROUTE"), "Command feedback exports body line")
	_assert(bool(command_feedback.get("station_scenario_identity_body_route_visible", false)), "Command feedback exports route-visible flag")
	_assert(bool(identity_body.get("read_only", false)) and not bool(identity_body.get("ui_sets_gameplay_truth", true)), "Command feedback identity body stays read-only")
	scene.queue_free()
	await _wait_frames(2)


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


func _line_contains_route_tokens(line: String) -> bool:
	return line.contains("ROUTE") and line.contains("AA ") and line.contains("DOOR ") and line.contains("COM ") and line.contains("CARGO ") and line.contains("NEXT ")


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
