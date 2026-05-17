extends SceneTree

const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_457_fireteam_contact_engage_runtime_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"
const TACTICAL_CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_457 Fireteam Contact Engage Runtime Pass ===")
	_test_aim_readiness_changes_detection_delay()
	_test_fire_events_survive_manual_visibility_window()
	await _test_unit_proxy_snapshot_exposes_aim_readiness_diagnostics()
	_test_area_attack_go_prefers_pending_waypoint_before_next_area()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_aim_readiness_changes_detection_delay() -> void:
	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	var low_ready_unit = _make_unit("task457_low_ready", "drill", true, Vector2.ZERO)
	var high_ready_unit = _make_unit("task457_high_ready", "drill", false, Vector2.ZERO)
	low_ready_unit.awareness = 0.5
	high_ready_unit.awareness = 0.5
	low_ready_unit.call("assign_unit_command", UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA,
		"target_position": Vector2(96.0, 0.0),
		"contact_initiative_seconds": 0.0,
		"aim_readiness_percent": 30.0,
	}))
	high_ready_unit.call("assign_unit_command", UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA,
		"target_position": Vector2(96.0, 0.0),
		"contact_initiative_seconds": 0.0,
		"aim_readiness_percent": 75.0,
	}))
	var low_delay: int = int(driver.call("_get_detection_delay_ticks", low_ready_unit))
	var high_delay: int = int(driver.call("_get_detection_delay_ticks", high_ready_unit))
	_assert(high_delay < low_delay, "High aim readiness shortens first contact detection delay")
	driver.free()
	_cleanup_units([low_ready_unit, high_ready_unit])


func _test_fire_events_survive_manual_visibility_window() -> void:
	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.set("_current_tick", 100)
	var event_id: String = String(driver.call("_append_fire_event", {
		"event_id": "task457_fire",
		"event_type": "weapon_fire",
		"tick": 100,
		"attacker_unit_id": "task457_alpha",
		"target_unit_id": "task457_enemy",
		"weapon_id": "rifle",
		"attacker_position": Vector2.ZERO,
		"target_position": Vector2(128.0, 0.0),
	}))
	_assert(event_id == "task457_fire", "Fire event is accepted into the recent VFX buffer")
	driver.set("_current_tick", 110)
	driver.call("_prune_recent_fire_events")
	_assert(Array(driver.call("get_fire_event_snapshot")).size() == 1, "Fire event remains visible long enough for a manual muzzle-flash check")
	driver.set("_current_tick", 120)
	driver.call("_prune_recent_fire_events")
	_assert(Array(driver.call("get_fire_event_snapshot")).is_empty(), "Fire event still expires after the debug visibility window")
	driver.free()


func _test_unit_proxy_snapshot_exposes_aim_readiness_diagnostics() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task457_aim_diag", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var unit = _make_unit("task457_diag_unit", "drill", true, Vector2(128.0, 128.0))
	root.add_child(unit)
	unit.call("assign_unit_command", UNIT_COMMAND_SCRIPT.new({
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		"target_position": Vector2(192.0, 128.0),
		"movement_posture": UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_TRAVEL,
		"weapon_posture": UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_LOWERED,
		"aim_readiness_percent": 75.0,
	}))
	view.call("set_unit_nodes", [unit])
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var state_by_id: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	var state: Dictionary = Dictionary(state_by_id.get("task457_diag_unit", {}))
	_assert(absf(float(state.get("unit_aim_readiness_percent", 0.0)) - 75.0) < 0.001, "Unit proxy snapshot exposes aim readiness percent")
	_assert(bool(state.get("unit_aim_readiness_visible_override", false)), "Unit proxy snapshot exposes the aim-readiness visual override")
	view.queue_free()
	unit.queue_free()
	await _wait_frames(2)


func _test_area_attack_go_prefers_pending_waypoint_before_next_area() -> void:
	var source: String = _read_text(TACTICAL_CONTROLLER_PATH)
	var function_text: String = _extract_function_text(source, "func _try_continue_active_area_attack")
	var waypoint_index: int = function_text.find("_has_pending_waypoint_order")
	var next_area_index: int = function_text.find("_activate_next_attack_area_order")
	_assert(waypoint_index >= 0, "Area attack continue checks for a pending waypoint")
	_assert(next_area_index >= 0 and waypoint_index < next_area_index, "Pending waypoint wins before the next attack area is activated")


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_457 - Fireteam Contact Engage Runtime Pass"), "TASK_457 task file exists")
	_assert(status_text.contains("TASK_457 - Fireteam Contact Engage Runtime Pass"), "Implementation status documents TASK_457")
	_assert(roadmap_text.contains("TASK_457 - Fireteam Contact Engage Runtime Pass"), "Roadmap lists TASK_457")
	_assert(contract_text.contains("TASK_457 Contact-/Engage-Runtime"), "Behavior contract documents TASK_457 runtime hooks")


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.is_fireteam_lead = is_lead
	unit.global_position = position_value
	unit.skill_speed = 0.5
	unit.skill_toughness = 0.5
	unit.skill_accuracy = 0.5
	unit.weapon_1_id = "rifle"
	unit._ready()
	return unit


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit is Node:
			var node := unit as Node
			if node.is_inside_tree():
				node.queue_free()
			else:
				node.free()


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _extract_function_text(source: String, function_start: String) -> String:
	var start_index: int = source.find(function_start)
	if start_index < 0:
		return ""
	var next_index: int = source.find("\nfunc ", start_index + function_start.length())
	if next_index < 0:
		return source.substr(start_index)
	return source.substr(start_index, next_index - start_index)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("  FAIL: %s" % message)
