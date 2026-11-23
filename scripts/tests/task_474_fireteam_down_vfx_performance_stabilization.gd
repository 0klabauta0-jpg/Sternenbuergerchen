extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_474_fireteam_down_vfx_performance_stabilization.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


class FakeTacticalController:
	extends Node

	var sync_count: int = 0
	var overlay_count: int = 0

	func _sync_primary_3d_order_visuals() -> void:
		sync_count += 1

	func refresh_contact_overlay() -> void:
		overlay_count += 1


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_474 Fireteam Down VFX Performance Stabilization ===")
	_test_down_state_lingers_before_bleedout_queue()
	await _test_respawning_unit_stays_in_down_pose()
	await _test_muzzle_flare_cross_is_visible_and_capped()
	_test_tactical_visual_refresh_is_throttled_and_flushed()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_down_state_lingers_before_bleedout_queue() -> void:
	var setup: Dictionary = _make_driver_setup()
	var scene_root: Node = setup.get("root")
	var simulation: Node = setup.get("simulation")
	var driver: Node = setup.get("driver")
	var enemy: Node = setup.get("enemy")
	enemy.call("apply_damage", 200, {"fire_event_id": "task474_down"})

	driver.call("_queue_bleedout_for_downed_enemy", simulation)
	_assert(Array(simulation.get("effects_queue")).is_empty(), "Freshly downed unit is not queued for bleedout immediately")

	var down_started: Dictionary = Dictionary(driver.get("_down_state_started_tick_by_unit_id")).duplicate(true)
	down_started["enemy_task474"] = int(driver.get("_current_tick")) - 300 # 5 s Spielzeit zurueckdatiert
	driver.set("_down_state_started_tick_by_unit_id", down_started)
	driver.call("_queue_bleedout_for_downed_enemy", simulation)

	var effects: Array = Array(simulation.get("effects_queue"))
	_assert(effects.size() == 1 and String(Dictionary(effects[0]).get("effect_type", "")) == "bleedout", "Down linger allows bleedout only after the readable minimum window")
	scene_root.queue_free()


func _test_respawning_unit_stays_in_down_pose() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task474_respawn_pose", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var enemy: Node2D = _make_unit("enemy_respawn_pose", "enemy_delta", "enemy", Vector2(160.0, 160.0))
	root.add_child(enemy)
	view.call("set_unit_nodes", [enemy])
	await _wait_frames(10)
	enemy.call("apply_damage", 200, {"fire_event_id": "task474_respawn_hit"})
	enemy.call("begin_respawn")
	await _wait_frames(10)

	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var state: Dictionary = Dictionary(Dictionary(snapshot.get("unit_proxy_state_by_id", {})).get("enemy_respawn_pose", {}))
	_assert(String(state.get("vital_state", "")) == "respawning", "Unit enters respawning state for the respawn countdown")
	_assert(bool(state.get("unit_down_pose_active", false)), "Respawning unit remains in a down-pose until the actual respawn effect")
	_assert(String(state.get("unit_status_badge_text", "")).begins_with("RESPAWN"), "Respawning unit keeps a readable respawn badge")
	view.queue_free()
	enemy.queue_free()
	await _wait_frames(2)


func _test_muzzle_flare_cross_is_visible_and_capped() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task474_muzzle", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var events: Array = []
	for index in range(8):
		events.append({
			"event_id": "task474_fire_%02d" % index,
			"event_type": "weapon_fire",
			"attacker_unit_id": "alpha_%02d" % index,
			"target_unit_id": "enemy_%02d" % index,
			"weapon_id": "rifle",
			"combat_outcome": "hit" if index == 7 else "miss",
			"damage_resolved": 35 if index == 7 else 0,
			"attacker_position": Vector2(96.0 + float(index), 128.0),
			"target_position": Vector2(240.0, 128.0 + float(index) * 3.0),
		})
	view.call("set_order_visual_payload", {"fire_event_dicts": events})
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var entry: Dictionary = _find_entry(entries, "event_id", "task474_fire_07")
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) == 3, "Weapon-fire VFX remains capped while showing the newest events")
	_assert(bool(entry.get("muzzle_flare_cross_visible", false)), "Muzzle flash has a visible local flare cross")
	_assert(float(entry.get("muzzle_flare_cross_width", 0.0)) <= 0.05, "Muzzle flare cross stays narrow enough for the perf baseline")
	_assert(float(entry.get("muzzle_bloom_radius", 0.0)) <= 0.12, "Muzzle bloom stays small and bounded")
	view.queue_free()
	await _wait_frames(2)


func _test_tactical_visual_refresh_is_throttled_and_flushed() -> void:
	var scene_root := Node.new()
	root.add_child(scene_root)
	var simulation = SIMULATION_ROOT_SCRIPT.new()
	simulation.name = "SimulationRoot"
	scene_root.add_child(simulation)
	var fake := FakeTacticalController.new()
	fake.name = "FakeTacticalController"
	scene_root.add_child(fake)
	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoop"
	driver.simulation_root_path = NodePath("../SimulationRoot")
	driver.tactical_controller_path = NodePath("../FakeTacticalController")
	scene_root.add_child(driver)

	driver.call("_refresh_tactical_combat_visuals", true)
	driver.call("_refresh_tactical_combat_visuals")
	driver.call("_refresh_tactical_combat_visuals")
	_assert(fake.sync_count == 1 and fake.overlay_count == 1, "Repeated combat visual refresh requests are throttled in the same interval")
	_assert(bool(driver.get("_tactical_combat_visual_refresh_pending")), "Suppressed refresh leaves one pending visual sync")
	driver.set("_last_tactical_combat_visual_refresh_msec", Time.get_ticks_msec() - 1000)
	driver.call("_flush_pending_tactical_combat_visuals")
	_assert(fake.sync_count == 2 and fake.overlay_count == 2, "Pending combat visual refresh is flushed once after the throttle interval")
	scene_root.queue_free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK 474") and task_text.contains("Down VFX Performance"), "TASK_474 task file exists")
	_assert(status_text.contains("TASK_474 - Fireteam Down VFX Performance Stabilization"), "Implementation status documents TASK_474")
	_assert(roadmap_text.contains("TASK_474 - Fireteam Down VFX Performance Stabilization"), "Roadmap lists TASK_474")


func _make_driver_setup() -> Dictionary:
	var scene_root := Node.new()
	root.add_child(scene_root)
	var registry = UNIT_REGISTRY_SCRIPT.new()
	registry.name = "UnitRegistry"
	scene_root.add_child(registry)
	var simulation = SIMULATION_ROOT_SCRIPT.new()
	simulation.name = "SimulationRoot"
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	scene_root.add_child(simulation)
	var enemy := _make_unit("enemy_task474", "enemy_delta", "enemy", Vector2(96.0, 0.0))
	scene_root.add_child(enemy)
	registry.call("register_unit", "enemy_task474", enemy)
	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoop"
	driver.simulation_root_path = NodePath("../SimulationRoot")
	var enemy_paths: Array[NodePath] = [NodePath("../enemy_task474")]
	driver.enemy_unit_paths = enemy_paths
	scene_root.add_child(driver)
	return {
		"root": scene_root,
		"simulation": simulation,
		"driver": driver,
		"enemy": enemy,
	}


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position_value: Vector2) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.display_name = unit_id
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "none"
	unit.global_position = position_value
	return unit


func _find_entry(entries: Array, key: String, value: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get(key, "")) == value:
			return entry
	return {}


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
