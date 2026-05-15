extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_434_limboai_enemy_behavior_adapter_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

const ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_limbo_behavior_adapter.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends Node

	signal tick_processed(tick_number: int, tick_delta: float)

	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_434 LimboAI Enemy Behavior Adapter Smoke ===")
	_test_limboai_classes_and_behavior_tree_priority()
	_test_adapter_falls_through_to_contact_then_patrol()
	_test_driver_limbo_cover_contact_and_patrol_commands()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_limboai_classes_and_behavior_tree_priority() -> void:
	_assert(ClassDB.class_exists("BehaviorTree"), "LimboAI BehaviorTree class is available")
	_assert(ClassDB.class_exists("BTSelector"), "LimboAI BTSelector class is available")
	_assert(ClassDB.class_exists("BTSequence"), "LimboAI BTSequence class is available")
	_assert(ClassDB.class_exists("BTAction"), "LimboAI BTAction class is available")

	var adapter = ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(adapter.call("get_behavior_tree_snapshot"))
	var priority_order: PackedStringArray = PackedStringArray(snapshot.get("priority_order", PackedStringArray()))
	_assert(bool(snapshot.get("uses_limboai", false)), "Adapter reports LimboAI-backed tree usage")
	_assert(priority_order == PackedStringArray(["seek_cover", "contact_hold", "patrol"]), "BT priority is Cover before Contact before Patrol")

	var calls: Array = []
	var agent := Node2D.new()
	root.add_child(agent)
	var result: Dictionary = Dictionary(
		adapter.call(
			"evaluate",
			agent,
			{
				"unit_id": "priority_enemy",
				"should_seek_cover": true,
				"has_contact": true,
				"has_patrol": true,
				"seek_cover_action": Callable(self, "_record_action").bind(calls, "cover"),
				"contact_hold_action": Callable(self, "_record_action").bind(calls, "contact"),
				"patrol_action": Callable(self, "_record_action").bind(calls, "patrol"),
			},
			root,
			0.016
		)
	)
	_assert(bool(result.get("handled", false)), "BT evaluation handles an available high-priority branch")
	_assert(String(result.get("selected_action", "")) == "seek_cover", "BT picks cover when all branches are valid")
	_assert(calls == ["cover"], "BT executes only the selected high-priority action")
	agent.queue_free()


func _test_adapter_falls_through_to_contact_then_patrol() -> void:
	var adapter = ENEMY_LIMBO_BEHAVIOR_ADAPTER_SCRIPT.new()
	var agent := Node2D.new()
	root.add_child(agent)

	var contact_calls: Array = []
	var contact_result: Dictionary = Dictionary(
		adapter.call(
			"evaluate",
			agent,
			{
				"unit_id": "contact_enemy",
				"should_seek_cover": false,
				"has_contact": true,
				"has_patrol": true,
				"seek_cover_action": Callable(self, "_record_action").bind(contact_calls, "cover"),
				"contact_hold_action": Callable(self, "_record_action").bind(contact_calls, "contact"),
				"patrol_action": Callable(self, "_record_action").bind(contact_calls, "patrol"),
			},
			root,
			0.016
		)
	)
	_assert(String(contact_result.get("selected_action", "")) == "contact_hold", "BT falls through to contact hold when cover is unavailable")
	_assert(contact_calls == ["contact"], "Contact branch executes without also running patrol")

	var patrol_calls: Array = []
	var patrol_result: Dictionary = Dictionary(
		adapter.call(
			"evaluate",
			agent,
			{
				"unit_id": "patrol_enemy",
				"should_seek_cover": false,
				"has_contact": false,
				"has_patrol": true,
				"seek_cover_action": Callable(self, "_record_action").bind(patrol_calls, "cover"),
				"contact_hold_action": Callable(self, "_record_action").bind(patrol_calls, "contact"),
				"patrol_action": Callable(self, "_record_action").bind(patrol_calls, "patrol"),
			},
			root,
			0.016
		)
	)
	_assert(String(patrol_result.get("selected_action", "")) == "patrol", "BT falls through to patrol when no contact is active")
	_assert(patrol_calls == ["patrol"], "Patrol branch executes as the final fallback branch")
	agent.queue_free()


func _test_driver_limbo_cover_contact_and_patrol_commands() -> void:
	var cover_context: Dictionary = _make_driver_context("cover", Vector2(96.0, 0.0), true)
	var cover_driver: Node = cover_context["driver"]
	var cover_simulation: Node = cover_context["simulation"]
	var cover_enemy: Node = cover_context["enemy"]
	_assert(bool(cover_driver.call("_try_enqueue_enemy_limbo_behavior", cover_simulation, cover_enemy)), "Driver BT hook handles a contact enemy that needs cover")
	var cover_command: Dictionary = _last_command(cover_simulation)
	_assert(String(cover_command.get("source_command_type", "")) == "enemy_limbo_cover", "Cover BT action enqueues through SimulationRoot command path")
	_assert(String(cover_command.get("enemy_bt_action", "")) == "seek_cover", "Cover command carries the selected BT action for diagnostics")
	_assert(cover_command.get("target_position", Vector2.INF) is Vector2, "Cover command carries a target position dictionary payload")
	_cleanup_context(cover_context)

	var contact_context: Dictionary = _make_driver_context("contact", Vector2(96.0, 0.0), false)
	var contact_driver: Node = contact_context["driver"]
	var contact_simulation: Node = contact_context["simulation"]
	var contact_enemy: Node = contact_context["enemy"]
	_assert(bool(contact_driver.call("_try_enqueue_enemy_limbo_behavior", contact_simulation, contact_enemy)), "Driver BT hook handles contact hold without terrain cover")
	var contact_command: Dictionary = _last_command(contact_simulation)
	_assert(String(contact_command.get("command_type", "")) == "hold_position", "Contact BT action emits a hold_position command")
	_assert(String(contact_command.get("source_command_type", "")) == "enemy_limbo_contact_hold", "Contact BT action keeps a narrow command source")
	_cleanup_context(contact_context)

	var patrol_context: Dictionary = _make_driver_context("patrol", Vector2(2200.0, 0.0), false)
	var patrol_driver: Node = patrol_context["driver"]
	var patrol_simulation: Node = patrol_context["simulation"]
	var patrol_enemy: Node = patrol_context["enemy"]
	var patrol_unit_id: String = String(patrol_enemy.call("get_unit_id"))
	patrol_driver.set("_enemy_patrol_paths_by_unit_id", {patrol_unit_id: [Vector2(160.0, 0.0)]})
	patrol_driver.set("_enemy_patrol_waypoint_index_by_unit_id", {patrol_unit_id: 0})
	patrol_driver.set("_enemy_patrol_contact_locked", {patrol_unit_id: false})
	_assert(bool(patrol_driver.call("_try_enqueue_enemy_limbo_behavior", patrol_simulation, patrol_enemy)), "Driver BT hook falls through to existing patrol action")
	var patrol_command: Dictionary = _last_command(patrol_simulation)
	_assert(String(patrol_command.get("source_command_type", "")) == "enemy_patrol", "Patrol BT action reuses the existing patrol command implementation")
	_cleanup_context(patrol_context)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("LimboAI Enemy Behavior Adapter Smoke"), "Task file documents the LimboAI enemy behavior smoke")
	_assert(task_text.contains("Enemy-Patrol") or task_text.contains("Patrol"), "Task file names the patrol/contact/cover scope")
	_assert(status_text.contains("TASK_434"), "Implementation status mentions TASK_434")
	_assert(roadmap_text.contains("TASK_434"), "Task roadmap includes TASK_434")


func _make_driver_context(prefix: String, friendly_position: Vector2, with_cover_terrain: bool) -> Dictionary:
	var harness := Node.new()
	harness.name = "Task434Harness_%s" % prefix
	root.add_child(harness)

	var simulation := SimulationStub.new()
	simulation.name = "SimulationRoot"
	harness.add_child(simulation)

	var terrain_registry = null
	if with_cover_terrain:
		terrain_registry = _make_cover_registry()
		terrain_registry.name = "TerrainRegistry"
		harness.add_child(terrain_registry)

	var friendly := _make_unit("%s_friendly" % prefix, "team_alpha", "rifle", friendly_position)
	var enemy := _make_unit("%s_enemy" % prefix, "team_bravo", "rifle", Vector2.ZERO)
	if terrain_registry != null:
		friendly.call("set_terrain_registry", terrain_registry)
		enemy.call("set_terrain_registry", terrain_registry)
	harness.add_child(friendly)
	harness.add_child(enemy)

	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "team_alpha"
	driver.preview_mode = true
	driver.enemy_limbo_behavior_smoke_enabled = true
	driver.enemy_limbo_cover_search_radius = 180.0
	driver.enemy_limbo_cover_min_distance = 12.0
	driver.enemy_limbo_cover_min_cover_score = 20
	var friendly_paths: Array[NodePath] = [NodePath("../%s_friendly" % prefix)]
	var enemy_paths: Array[NodePath] = [NodePath("../%s_enemy" % prefix)]
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	driver.simulation_root_path = NodePath("../SimulationRoot")
	if terrain_registry != null:
		driver.terrain_registry_path = NodePath("../TerrainRegistry")
	harness.add_child(driver)

	return {
		"harness": harness,
		"driver": driver,
		"simulation": simulation,
		"friendly": friendly,
		"enemy": enemy,
		"terrain_registry": terrain_registry,
	}


func _make_cover_registry():
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for grid_position in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]:
		var cover_value: int = 0
		if grid_position == Vector2i(2, 0):
			cover_value = 70
		elif grid_position == Vector2i(2, 1):
			cover_value = 45
		registry.register_tile(
			TERRAIN_TILE_DATA_SCRIPT.new(
				{
					"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
					"type_id": "ground_flat",
					"grid_position": grid_position,
					"world_position": registry.grid_to_world(grid_position),
					"walkable": true,
					"blocks_los": false,
					"cover_value": cover_value,
					"height_level": 0,
					"object_height": 0,
					"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND,
					"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE,
				}
			)
		)
	return registry


func _make_unit(unit_id: String, team_id: String, weapon_id: String, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = "blue" if team_id == "team_alpha" else "red"
	unit.weapon_1_id = weapon_id
	unit.weapon_2_id = weapon_id
	unit.skill_accuracy = 0.62
	unit.skill_speed = 0.54
	unit.skill_leadership = 0.35
	unit.skill_toughness = 0.5
	unit.global_position = position_value
	unit._ready()
	return unit


func _record_action(out: Array, action_id: String) -> bool:
	out.append(action_id)
	return true


func _last_command(simulation: Node) -> Dictionary:
	var commands: Array = Array(simulation.get("commands"))
	if commands.is_empty():
		return {}
	return Dictionary(commands[commands.size() - 1])


func _cleanup_context(context: Dictionary) -> void:
	var harness: Node = context.get("harness", null)
	if harness != null:
		harness.queue_free()


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
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
