extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTROLLER_SOURCE_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

const EXPECTED_LIGHT_SCOPES: PackedStringArray = [
	"primary_block_labels_usec",
	"primary_command_feedback_usec",
	"primary_command_door_usec",
	"primary_command_route_usec",
	"primary_command_decision_usec",
	"primary_command_target_waypoint_usec",
	"primary_fireteam_status_usec",
	"primary_fireteam_tooltips_usec",
	"panel_fireteam_phase_usec",
	"panel_nav_identity_usec",
	"panel_nav_timer_usec",
	"panel_identity_usec",
	"panel_team_chip_usec",
	"panel_dropship_usec",
	"panel_event_log_usec",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1153 Mission HUD Light Path Snapshot Consolidation ===")
	_test_contract_is_present()
	await _test_light_path_exposes_granular_timing()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_contract_is_present() -> void:
	var source: String = FileAccess.get_file_as_string(CONTROLLER_SOURCE_PATH)
	for scope_name in EXPECTED_LIGHT_SCOPES:
		_assert(source.contains('scopes_usec["%s"]' % scope_name), "Controller records %s" % scope_name)


func _test_light_path_exposes_granular_timing() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission fixture exposes tactical controller")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	controller.call("_update_ui", false, false)
	var timing: Dictionary = Dictionary(controller.call("get_mission_ui_refresh_timing_debug_snapshot"))
	var scopes: Dictionary = Dictionary(timing.get("scopes_usec", {}))
	for scope_name in EXPECTED_LIGHT_SCOPES:
		_assert(scopes.has(scope_name), "Runtime light-path timing exposes %s" % scope_name)
	_assert(bool(timing.get("read_only", false)) and not bool(timing.get("ui_sets_gameplay_truth", true)), "Light-path timing remains read-only")
	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
