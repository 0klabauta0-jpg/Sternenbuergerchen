extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_738_station_scenario_identity_cue_visibility_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const MISSION_IDENTITY_BODY_LABEL_PATH: NodePath = NodePath("TacticalUI/MissionIdentityPanel/MissionIdentityMargin/MissionIdentityVBox/MissionIdentityBodyLabel")
const EXPECTED_CUE_LINE: String = "CUE AA: BLUE naeher ran | 3.9km"
const EXPECTED_DISPLAY_ROUTE_LINE: String = "ROUTE AA > DOOR > COM > CARGO | NEXT AA"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_738 Station Scenario Identity Cue Visibility Polish ===")
	_test_docs_contract_and_report()
	_test_direct_identity_body_display_policy()
	await _test_scene_identity_body_display_policy()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_738: FAILED")
		quit(1)
		return
	print("TASK_738: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text("res://scripts/tests/mission_tactical_sandbox_controller.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_738 task file exists")
	_assert(task_text.contains("Station Scenario Identity Cue Visibility Polish"), "Task documents identity cue visibility polish")
	_assert(contract_text.contains("Station Scenario Identity Cue Visibility Polish"), "Interaction contract documents TASK_738")
	_assert(status_text.contains("TASK_738 - Station Scenario Identity Cue Visibility Polish"), "Implementation status tracks TASK_738")
	_assert(roadmap_text.contains("TASK_738 - Station Scenario Identity Cue Visibility Polish (implementiert)"), "Roadmap marks TASK_738 implemented")
	_assert(roadmap_text.contains("TASK_740 - Scenario Harness Modernization"), "Roadmap keeps harness modernization as conditional follow-up")
	_assert(report_text.contains("TASK_738 - Station Scenario Identity Cue Visibility Polish"), "Current handbook references TASK_738")
	_assert(report_text.contains("station_scenario_identity_cue_visibility_polish"), "Current handbook exports TASK_738 fields")
	_assert(controller_text.contains("station_scenario_identity_route_body_v2"), "Controller exposes identity body v2 style")
	_assert(controller_text.contains("future_blocker_hidden_in_display"), "Controller exports future blocker display guard")


func _test_direct_identity_body_display_policy() -> void:
	var controller: Node = CONTROLLER_SCRIPT.new()
	var route_readout: Dictionary = {
		"active": true,
		"compact_line": "ROUTE AA READY > DOOR CLOSED > COM WAIT > CARGO BLOCK | NEXT AA",
		"aa_token": "AA READY",
		"door_token": "DOOR CLOSED",
		"computer_token": "COM WAIT",
		"cargo_token": "CARGO BLOCK",
		"next_token": "AA",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	var cue: Dictionary = {
		"active": true,
		"cue_line": EXPECTED_CUE_LINE,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	var snapshot: Dictionary = Dictionary(controller.call("build_station_scenario_identity_body_snapshot", route_readout, [
		"--review-role=host",
		"--peer-id=1",
		"--team=team_alpha",
	], cue))
	var text: String = String(snapshot.get("text", ""))
	_assert(_snapshot_is_read_only(snapshot), "Direct identity snapshot is read-only")
	_assert(String(snapshot.get("style_id", "")) == "station_scenario_identity_route_body_v2", "Direct identity snapshot uses v2 style")
	_assert(text.contains("HOST P1 ALPHA"), "Direct identity text keeps host badge")
	_assert(text.contains(EXPECTED_CUE_LINE), "Direct identity text fronts polished cue")
	_assert(text.contains(EXPECTED_DISPLAY_ROUTE_LINE), "Direct identity text keeps neutral route sequence")
	_assert(not _contains_future_cargo_blocker(text), "Direct identity text hides future cargo blocker")
	_assert(String(snapshot.get("route_line", "")).contains("CARGO BLOCK"), "Direct identity source route still carries cargo status")
	_assert(String(snapshot.get("display_route_line", "")) == EXPECTED_DISPLAY_ROUTE_LINE, "Direct identity display route is neutral")
	_assert(bool(snapshot.get("cue_visible", false)), "Direct identity snapshot marks cue visible")
	_assert(bool(snapshot.get("future_blocker_hidden_in_display", false)), "Direct identity snapshot marks future blocker hidden")
	controller.free()


func _test_scene_identity_body_display_policy() -> void:
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
	_assert(body_text.contains("CUE AA:"), "Visible body fronts station cue")
	_assert(body_text.contains("naeher ran") or body_text.contains("+ GO"), "Visible body contains player action language")
	_assert(body_text.contains("ROUTE AA > DOOR > COM > CARGO | NEXT AA"), "Visible body contains neutral route sequence")
	_assert(not _contains_future_cargo_blocker(body_text), "Visible body hides future cargo blocker")
	_assert(bool(body_label.get_meta("station_scenario_cue_visible", false)), "Visible label metadata marks cue visible")
	_assert(bool(body_label.get_meta("station_scenario_future_blocker_hidden_in_display", false)), "Visible label metadata marks future blocker hidden")
	_assert(String(body_label.get_meta("station_scenario_identity_polish_task", "")) == "TASK_738", "Visible label metadata records TASK_738")
	_assert(_snapshot_is_read_only(identity_body), "Command feedback identity body stays read-only")
	_assert(bool(command_feedback.get("station_scenario_identity_body_cue_visible", false)), "Command feedback exports cue-visible flag")
	_assert(bool(command_feedback.get("station_scenario_identity_body_future_blocker_hidden_in_display", false)), "Command feedback exports future blocker display guard")
	_assert(String(command_feedback.get("station_scenario_identity_body_display_route_line", "")) == EXPECTED_DISPLAY_ROUTE_LINE, "Command feedback exports neutral display route")
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


func _contains_future_cargo_blocker(text: String) -> bool:
	return text.contains("CARGO BLOCK") or text.contains("CARGO BLOCKED") or text.contains("CARGO blockiert")


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


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
