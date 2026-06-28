extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_522_cargo_touchdown_visual_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_522 Cargo Touchdown Visual Polish ===")
	_test_docs_and_source_contract()
	await _test_cargo_touchdown_visuals()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_522: FAILED")
		quit(1)
		return
	print("TASK_522: ALL PASSED")
	quit(0)


func _test_docs_and_source_contract() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_522 task file exists")
	_assert(_read_text(TASK_PATH).contains("Cargo Touchdown Visual Polish"), "TASK_522 task file documents cargo visual polish")
	_assert(_read_text(STATUS_PATH).contains("TASK_522 - Cargo Touchdown Visual Polish"), "Implementation status tracks TASK_522")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_522 - Cargo Touchdown Visual Polish"), "Roadmap lists TASK_522")
	_assert(_read_text(REPORT_PATH).contains("TASK_522 - Cargo Touchdown Visual Polish"), "HTML workbench tracks TASK_522")
	var controller_source: String = _read_text(CONTROLLER_PATH)
	_assert(controller_source.contains("_build_mission_cargo_touchdown_visual_entry"), "Mission controller builds cargo touchdown visual entries")
	_assert(controller_source.contains("get_mission_cargo_touchdown_snapshot"), "Mission controller reads cargo bridge snapshot")
	_assert(controller_source.contains("\"ui_sets_gameplay_truth\": false"), "Cargo visual entry remains read-only")
	var view_source: String = _read_text(VIEW_PATH)
	_assert(view_source.contains("cargo_touchdown_visual_count"), "Primary view exposes cargo touchdown visual count")
	_assert(view_source.contains("_add_cargo_touchdown_status_label"), "Primary view renders cargo touchdown status labels")


func _test_cargo_touchdown_visuals() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(24)
	await _wait_physics_frames(4)
	var controller := scene.get_node_or_null("TacticalController")
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and combat_driver != null and primary_view != null, "Mission scene exposes controller, combat driver and Primary3DView")
	if controller == null or combat_driver == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures cargo scenario gates")
	controller.call("_refresh_world_overlays")
	await _wait_frames(4)
	var blocked_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(String(blocked_snapshot.get("cargo_touchdown_state", "")) == "blocked", "Blocked cargo state is visible in render snapshot")
	_assert(int(blocked_snapshot.get("cargo_touchdown_lz_marker_count", 0)) >= 1, "Blocked cargo shows touchdown marker")
	_assert(int(blocked_snapshot.get("cargo_touchdown_visual_count", 0)) == 0, "Blocked cargo does not show an inbound body yet")
	_assert(int(blocked_snapshot.get("cargo_touchdown_label_count", 0)) >= 1, "Blocked cargo shows a status label")

	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	combat_driver.call("set_mission_cargo_touchdown_state", "inbound", 0.0, 0.85)
	controller.call("_refresh_world_overlays")
	await _wait_frames(4)
	var inbound_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(String(inbound_snapshot.get("cargo_touchdown_state", "")) == "inbound", "Inbound cargo state is visible in render snapshot")
	_assert(int(inbound_snapshot.get("cargo_touchdown_visual_count", 0)) >= 1, "Inbound cargo shows an air visual")
	_assert(int(inbound_snapshot.get("cargo_touchdown_approach_line_count", 0)) >= 1, "Inbound cargo shows an approach line")
	_assert(int(inbound_snapshot.get("cargo_touchdown_label_count", 0)) >= 1, "Inbound cargo shows a status label")

	combat_driver.call("set_mission_cargo_touchdown_state", "landed", 12.0)
	controller.call("_refresh_world_overlays")
	await _wait_frames(4)
	var landed_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(String(landed_snapshot.get("cargo_touchdown_state", "")) == "landed", "Landed cargo state is visible in render snapshot")
	_assert(int(landed_snapshot.get("cargo_touchdown_visual_count", 0)) >= 1, "Landed cargo keeps the freighter visible")

	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	controller.call("_refresh_world_overlays")
	await _wait_frames(4)
	var departed_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(departed_snapshot.get("cargo_touchdown_visual_count", 0)) == 0, "Departed cargo removes cargo air visual")
	_assert(int(departed_snapshot.get("cargo_touchdown_lz_marker_count", 0)) == 0, "Departed cargo removes cargo touchdown marker")
	scene.queue_free()
	await _wait_frames(2)


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", true)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
