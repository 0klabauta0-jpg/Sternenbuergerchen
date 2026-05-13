extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_374_objective_countdown_indicator.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const MISSION_OBJECTIVE_STATUS_VIEW_SCRIPT: GDScript = preload("res://scripts/tests/mission_objective_status_view.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_374 Objective Countdown Indicator ===")
	_test_objective_status_countdown_contract()
	_test_simulation_root_multiplayer_objective_timer_roundtrip()
	await _test_combat_driver_active_paused_and_expired_timers()
	await _test_objective_status_view_compact_hud_timer()
	_test_docs_status_and_roadmap()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_objective_status_countdown_contract() -> void:
	var objective = OBJECTIVE_STATUS_SCRIPT.new()
	objective.objective_id = "relay"
	objective.set_countdown(120.0, "active", "mission_time_limit", 300.0, "TIME")
	var snapshot: Dictionary = Dictionary(objective.call("get_countdown_snapshot"))
	var objective_dict: Dictionary = Dictionary(objective.call("to_dict"))
	_assert(bool(snapshot.get("visible", false)), "ObjectiveStatus exposes visible countdown when source is valid")
	_assert(is_equal_approx(float(snapshot.get("countdown_seconds", 0.0)), 120.0), "Countdown seconds are preserved")
	_assert(String(snapshot.get("timer_state", "")) == "active", "Timer state is active")
	_assert(String(snapshot.get("source", "")) == "mission_time_limit", "Timer source is exported")
	_assert(String(snapshot.get("urgency", "")) == "normal", "Timer urgency is normal above thresholds")
	_assert(objective_dict.has("countdown_seconds") and objective_dict.has("timer_state"), "Objective to_dict includes countdown contract fields")

	objective.set_countdown(20.0, "active", "mission_time_limit", 120.0, "TIME")
	_assert(String(Dictionary(objective.call("get_countdown_snapshot")).get("urgency", "")) == "warning", "Countdown urgency switches to warning")
	objective.set_countdown(5.0, "active", "mission_time_limit", 120.0, "TIME")
	_assert(String(Dictionary(objective.call("get_countdown_snapshot")).get("urgency", "")) == "critical", "Countdown urgency switches to critical")
	objective.set_countdown(0.0, "expired", "mission_time_limit", 120.0, "TIME")
	_assert(String(Dictionary(objective.call("get_countdown_snapshot")).get("urgency", "")) == "expired", "Countdown urgency marks expired timer")

	objective.clear_countdown()
	_assert(Dictionary(objective.call("get_countdown_snapshot")).is_empty(), "Cleared ObjectiveStatus has no countdown")
	_assert(not Dictionary(objective.call("to_dict")).has("countdown_seconds"), "Objective to_dict omits timer fields without valid source")


func _test_simulation_root_multiplayer_objective_timer_roundtrip() -> void:
	var host = SIMULATION_ROOT_SCRIPT.new()
	host.name = "HostSimulationRoot"
	root.add_child(host)
	var objective = OBJECTIVE_STATUS_SCRIPT.new()
	objective.objective_id = "relay"
	objective.position = Vector2(64.0, 96.0)
	objective.capture_radius = 72.0
	objective.set_countdown(45.0, "active", "mission_time_limit", 120.0, "TIME")
	host.call("set_objective_status", objective)
	host.set("tick_counter", 7)
	var snapshot: Dictionary = Dictionary(host.call("build_multiplayer_snapshot"))
	var objective_snapshot: Dictionary = Dictionary(snapshot.get("objective", {}))
	_assert(String(objective_snapshot.get("timer_state", "")) == "active", "SimulationRoot snapshot keeps objective timer state")
	_assert(String(objective_snapshot.get("timer_source", "")) == "mission_time_limit", "SimulationRoot snapshot keeps objective timer source")
	_assert(is_equal_approx(float(objective_snapshot.get("countdown_seconds", 0.0)), 45.0), "SimulationRoot snapshot keeps countdown seconds")

	var client = SIMULATION_ROOT_SCRIPT.new()
	client.name = "ClientSimulationRoot"
	root.add_child(client)
	var apply_result: Dictionary = Dictionary(client.call("apply_multiplayer_snapshot", snapshot))
	var client_objective = client.call("get_objective_status")
	var client_countdown: Dictionary = Dictionary(client_objective.call("get_countdown_snapshot")) if client_objective != null else {}
	_assert(bool(apply_result.get("accepted", false)), "Client accepts objective timer multiplayer snapshot")
	_assert(String(client_countdown.get("timer_state", "")) == "active", "Client applies objective timer state")
	_assert(String(client_countdown.get("source", "")) == "mission_time_limit", "Client applies objective timer source")

	objective.clear_countdown()
	host.call("set_objective_status", objective)
	host.set("tick_counter", 8)
	var no_timer_snapshot: Dictionary = Dictionary(host.call("build_multiplayer_snapshot"))
	var no_timer_objective: Dictionary = Dictionary(no_timer_snapshot.get("objective", {}))
	_assert(not no_timer_objective.has("countdown_seconds"), "Objective snapshot omits timer without valid source")
	host.queue_free()
	client.queue_free()


func _test_combat_driver_active_paused_and_expired_timers() -> void:
	var active_fixture: Dictionary = await _build_driver_fixture(60.0, Time.get_ticks_msec() - 40000, false)
	var active_driver: Node = active_fixture["driver"]
	var active_snapshot: Dictionary = Dictionary(active_driver.call("get_objective_countdown_snapshot"))
	_assert(String(active_snapshot.get("timer_state", "")) == "active", "Combat driver publishes active mission time limit timer")
	_assert(float(active_snapshot.get("countdown_seconds", 0.0)) <= 21.0 and float(active_snapshot.get("countdown_seconds", 0.0)) > 0.0, "Active timer reports remaining seconds")
	_assert(String(active_snapshot.get("urgency", "")) == "warning", "Active timer urgency is warning near threshold")
	_free_fixture(active_fixture)

	var paused_fixture: Dictionary = await _build_driver_fixture(60.0, 0, true)
	var paused_driver: Node = paused_fixture["driver"]
	var paused_snapshot: Dictionary = Dictionary(paused_driver.call("get_objective_countdown_snapshot"))
	_assert(String(paused_snapshot.get("timer_state", "")) == "paused", "Combat driver publishes paused timer before mission start")
	_assert(is_equal_approx(float(paused_snapshot.get("countdown_seconds", 0.0)), 60.0), "Paused timer keeps full duration")
	_free_fixture(paused_fixture)

	var expired_fixture: Dictionary = await _build_driver_fixture(60.0, Time.get_ticks_msec() - 65000, false)
	var expired_driver: Node = expired_fixture["driver"]
	var expired_snapshot: Dictionary = Dictionary(expired_driver.call("get_objective_countdown_snapshot"))
	_assert(String(expired_snapshot.get("timer_state", "")) == "expired", "Combat driver publishes expired timer")
	_assert(is_equal_approx(float(expired_snapshot.get("countdown_seconds", -1.0)), 0.0), "Expired timer clamps to zero")
	_free_fixture(expired_fixture)

	var missing_fixture: Dictionary = await _build_driver_fixture(0.0, 0, false)
	var missing_driver: Node = missing_fixture["driver"]
	var missing_snapshot: Dictionary = Dictionary(missing_driver.call("get_objective_countdown_snapshot"))
	_assert(missing_snapshot.is_empty(), "Combat driver publishes no timer when scenario has no time limit")
	_free_fixture(missing_fixture)


func _test_objective_status_view_compact_hud_timer() -> void:
	var container := Node.new()
	root.add_child(container)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	container.add_child(simulation_root)
	var objective = OBJECTIVE_STATUS_SCRIPT.new()
	objective.objective_id = "relay"
	objective.owning_team_id = "team_alpha"
	objective.capture_progress = 0.5
	objective.set_countdown(9.0, "active", "mission_time_limit", 120.0, "TIME")
	simulation_root.call("set_objective_status", objective)
	var marker := Marker2D.new()
	marker.name = "ObjectiveMarker"
	container.add_child(marker)
	var view = MISSION_OBJECTIVE_STATUS_VIEW_SCRIPT.new()
	view.name = "ObjectiveStatusView"
	view.simulation_root_path = NodePath("../SimulationRoot")
	view.objective_marker_path = NodePath("../ObjectiveMarker")
	container.add_child(view)
	await _wait_frames(3)
	var snapshot: Dictionary = Dictionary(view.call("get_objective_status_view_snapshot"))
	_assert(bool(snapshot.get("countdown_visible", false)), "Objective status view shows valid countdown")
	_assert(String(snapshot.get("text", "")).contains("TIME 00:09"), "Objective status view formats compact countdown text")
	_assert(String(snapshot.get("urgency", "")) == "critical", "Objective status view exposes timer urgency")
	_assert(int(snapshot.get("line_count", 0)) <= 2 and bool(snapshot.get("fixed_layout", false)), "Objective status view keeps fixed compact two-line layout")

	objective.clear_countdown()
	simulation_root.call("set_objective_status", objective)
	await _wait_frames(3)
	var no_timer_snapshot: Dictionary = Dictionary(view.call("get_objective_status_view_snapshot"))
	_assert(not bool(no_timer_snapshot.get("countdown_visible", true)), "Objective status view hides timer when source is missing")
	_assert(not String(no_timer_snapshot.get("text", "")).contains("TIME"), "Objective status view does not invent a timer")
	container.queue_free()
	await _wait_frames(2)


func _test_docs_status_and_roadmap() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_374 task file marks implementation complete")
	_assert(not task_text.contains("- [ ]"), "TASK_374 checklist is complete")
	_assert(status_text.contains("### TASK_374 - Objective Countdown Indicator") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_374 implemented")
	_assert(roadmap_text.contains("TASK_374 - Objective Countdown Indicator (implementiert)"), "Roadmap marks TASK_374 implemented")


func _build_driver_fixture(time_limit_seconds: float, started_at_msec: int, preview_mode: bool) -> Dictionary:
	var container := Node.new()
	root.add_child(container)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	container.add_child(simulation_root)
	var objective = OBJECTIVE_STATUS_SCRIPT.new()
	objective.objective_id = "relay"
	simulation_root.call("set_objective_status", objective)
	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.simulation_root_path = NodePath("../SimulationRoot")
	driver.mission_time_limit_seconds = time_limit_seconds
	driver.mission_timer_started_at_msec = started_at_msec
	driver.preview_mode = preview_mode
	container.add_child(driver)
	await _wait_frames(3)
	return {
		"container": container,
		"simulation_root": simulation_root,
		"driver": driver,
	}


func _free_fixture(fixture: Dictionary) -> void:
	var container := fixture.get("container", null) as Node
	if container != null:
		container.queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
