extends SceneTree

const SCENARIO_PATH: String = "res://data/mission_scenarios/ground_mission01_default.json"
const TASK_PATH: String = "res://docs/tasks/TASK_345_npc_standard_movement_posture_policy.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_345 NPC Standard Movement Posture Policy ===")
	_test_profile_and_scenario_posture_defaults()
	_test_runtime_command_roundtrip_and_simulation_authority()
	_test_enemy_driver_emits_posture_commands()
	await _test_fire_event_and_terrain_view_read_posture()
	_test_source_contracts_and_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_profile_and_scenario_posture_defaults() -> void:
	var patrol: Dictionary = Dictionary(ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", {"profile_id": "patrol_probe"}))
	_assert(String(patrol.get("movement_posture_policy", "")) == "travel_until_threat", "Patrol profile defaults to travel-until-threat posture policy")
	_assert(is_equal_approx(float(patrol.get("travel_speed_factor", 0.0)), 0.55), "Patrol profile keeps faster travel speed")
	_assert(is_equal_approx(float(patrol.get("ready_speed_factor", 0.0)), 0.30), "Patrol profile keeps tactical ready speed")
	var defense: Dictionary = Dictionary(ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", {"profile_id": "defensive_cover"}))
	_assert(String(defense.get("movement_posture_policy", "")) == "hold_ready", "Defensive profile defaults to hold-ready posture policy")
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Ground mission scenario loads for posture verification")
	if scenario == null:
		return
	var patrol_tactics: Dictionary = Dictionary(scenario.call("get_enemy_tactics_for_unit", "ground_patrol_01", null))
	var defense_tactics: Dictionary = Dictionary(scenario.call("get_enemy_tactics_for_unit", "ground_defense_01", null))
	_assert(String(patrol_tactics.get("movement_posture_policy", "")) == "travel_until_threat", "Ground patrol fireteam carries travel posture policy")
	_assert(String(defense_tactics.get("movement_posture_policy", "")) == "hold_ready", "Ground defense fireteam carries hold-ready posture policy")


func _test_runtime_command_roundtrip_and_simulation_authority() -> void:
	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.call("from_dict", {
		"status": "pending_move",
		"move_speed_factor": 0.30,
		"movement_posture": "m-position",
		"weapon_posture": "ready-low",
		"posture_policy_id": "travel_until_threat",
	})
	_assert(bool(runtime_status.call("is_valid")), "RuntimeStatus accepts normalized movement and weapon posture")
	_assert(String(runtime_status.get("movement_posture")) == "tactical", "RuntimeStatus normalizes M-position to tactical")
	_assert(String(runtime_status.get("weapon_posture")) == "ready", "RuntimeStatus normalizes ready-low to ready")
	var command = UNIT_COMMAND_SCRIPT.call("from_dict", {
		"command_type": "move_to_position",
		"unit_id": "sim_enemy",
		"target_position": Vector2(96.0, 0.0),
		"move_speed_factor": 0.30,
		"movement_posture": "tactical",
		"weapon_posture": "ready",
		"posture_policy_id": "travel_until_threat",
	})
	_assert(bool(command.call("is_valid")), "UnitCommand accepts posture fields")

	var context: Dictionary = _make_context("sim", "patrol_probe", Vector2.ZERO, Vector2(2400.0, 0.0), Vector2(2400.0, 0.0))
	var simulation_root: Node = context["simulation_root"]
	var enemy: Node2D = context["enemy"]
	simulation_root.call("_apply_command", command.call("to_dict"), 0.25)
	var applied_status = enemy.call("get_runtime_status")
	_assert(String(applied_status.get("movement_posture")) == "tactical", "SimulationRoot applies command movement posture to unit runtime status")
	_assert(String(applied_status.get("weapon_posture")) == "ready", "SimulationRoot applies command weapon posture to unit runtime status")
	_assert(String(applied_status.get("posture_policy_id")) == "travel_until_threat", "SimulationRoot applies posture policy id to unit runtime status")
	_assert(enemy.global_position.x > 0.0, "SimulationRoot still moves the unit while applying posture")
	simulation_root.call("_apply_command", {
		"command_type": "hold_position",
		"unit_id": "sim_enemy",
		"move_speed_factor": 0.0,
		"movement_posture": "overwatch",
		"weapon_posture": "ready",
		"posture_policy_id": "hold_ready",
	}, 0.25)
	applied_status = enemy.call("get_runtime_status")
	_assert(String(applied_status.get("status")) == "holding", "Hold command updates runtime status through SimulationRoot")
	_assert(String(applied_status.get("movement_posture")) == "overwatch", "Hold command applies overwatch movement posture")
	_cleanup_context(context)


func _test_enemy_driver_emits_posture_commands() -> void:
	var context: Dictionary = _make_context("driver", "patrol_probe", Vector2.ZERO, Vector2(2400.0, 0.0), Vector2(2400.0, 0.0))
	var simulation_root: Node = context["simulation_root"]
	var driver: Node = context["driver"]
	var enemy: Node2D = context["enemy"]
	var friendly: Node2D = context["friendly"]
	driver.call("_update_enemy_team_tactics_state")
	driver.call("_advance_enemy_units", simulation_root)
	var travel_command: Dictionary = _first_queued_command(simulation_root)
	_assert(String(travel_command.get("movement_posture", "")) == "travel", "Patrol command far from threat uses travel posture")
	_assert(String(travel_command.get("weapon_posture", "")) == "lowered", "Patrol command far from threat keeps weapon lowered")
	_assert(is_equal_approx(float(travel_command.get("move_speed_factor", 0.0)), 0.55), "Travel command uses travel speed factor")

	simulation_root.command_queue.clear()
	friendly.global_position = Vector2(420.0, 0.0)
	driver.call("_update_enemy_team_tactics_state")
	driver.call("_advance_enemy_units", simulation_root)
	var ready_command: Dictionary = _first_queued_command(simulation_root)
	_assert(String(ready_command.get("movement_posture", "")) == "tactical", "Patrol command near threat switches to tactical posture")
	_assert(String(ready_command.get("weapon_posture", "")) == "ready", "Patrol command near threat raises weapon ready")
	_assert(is_equal_approx(float(ready_command.get("move_speed_factor", 0.0)), 0.30), "Ready command uses tactical speed factor")

	simulation_root.command_queue.clear()
	enemy.set_meta("enemy_tactics_config", {
		"group_id": "driver_red",
		"profile_id": "defensive_cover",
		"team_id": "team_bravo",
		"advance_style": "hold",
		"movement_posture_policy": "hold_ready",
	})
	driver.call("_update_enemy_team_tactics_state")
	driver.call("_advance_enemy_units", simulation_root)
	var hold_command: Dictionary = _first_queued_command(simulation_root)
	_assert(String(hold_command.get("command_type", "")) == "hold_position", "Hold-ready defense emits explicit hold posture command")
	_assert(String(hold_command.get("movement_posture", "")) == "overwatch", "Defense hold command uses overwatch movement posture")
	_assert(String(hold_command.get("weapon_posture", "")) == "ready", "Defense hold command keeps weapon ready")
	_cleanup_context(context)


func _test_fire_event_and_terrain_view_read_posture() -> void:
	var context: Dictionary = _make_context("fire", "patrol_probe", Vector2.ZERO, Vector2(320.0, 0.0), Vector2(2400.0, 0.0))
	var driver: Node = context["driver"]
	var enemy: Node2D = context["enemy"]
	var friendly: Node2D = context["friendly"]
	enemy.call("set_runtime_status", "pending_move", "move_to_position", 8, "fire_at_will", "enemy_team_tactics", 0.30, 0.0, 0.0, -1, Vector2(96.0, 0.0), "tactical", "ready", "travel_until_threat")
	driver.call("_store_combat_attacker_facing", enemy, friendly)
	var runtime_status = enemy.call("get_runtime_status")
	_assert(String(runtime_status.get("movement_posture")) == "engage", "Enemy fire event upgrades runtime movement posture to engage")
	_assert(String(runtime_status.get("weapon_posture")) == "aimed", "Enemy fire event upgrades runtime weapon posture to aimed")

	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_345_posture_view", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0, 2)
	var terrain_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(terrain_view)
	terrain_view.call("configure_from_map", map_data)
	enemy.call("set_runtime_status", "pending_move", "move_to_position", 8, "fire_at_will", "enemy_team_tactics", 0.30, 0.0, 0.0, -1, Vector2(96.0, 0.0), "tactical", "ready", "travel_until_threat")
	terrain_view.call("set_unit_nodes", [enemy, friendly])
	await _wait_frames(6)
	var ready_snapshot: Dictionary = Dictionary(terrain_view.call("get_render_snapshot"))
	var ready_state: Dictionary = Dictionary(Dictionary(ready_snapshot.get("unit_proxy_state_by_id", {})).get("fire_enemy", {}))
	_assert(bool(ready_state.get("unit_ready_pose_active", false)), "Terrain view reads ready weapon posture from runtime")
	_assert(String(ready_state.get("unit_weapon_posture", "")) == "ready", "Terrain view exposes runtime ready posture in snapshot")
	terrain_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"fire_event_dicts": [
			{
				"event_id": "task_345_fire",
				"event_type": "weapon_fire",
				"source": "standard",
				"attacker_unit_id": "fire_enemy",
				"attacker_team_id": "team_bravo",
				"target_unit_id": "fire_friendly",
				"target_team_id": "team_alpha",
				"weapon_id": "rifle",
				"attacker_position": enemy.global_position,
				"target_position": friendly.global_position,
			}
		],
	})
	await _wait_frames(6)
	var aim_snapshot: Dictionary = Dictionary(terrain_view.call("get_render_snapshot"))
	var aim_state: Dictionary = Dictionary(Dictionary(aim_snapshot.get("unit_proxy_state_by_id", {})).get("fire_enemy", {}))
	_assert(bool(aim_state.get("unit_aim_pose_active", false)), "Terrain view lets FireEvent override ready posture to aimed")
	_assert(String(aim_state.get("unit_posture_source", "")) == "fire_event", "Terrain view marks aimed posture source as fire_event")
	terrain_view.queue_free()
	await _wait_frames(2)
	_cleanup_context(context)


func _test_source_contracts_and_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT") and not task_text.contains("- [ ]"), "Task file marks TASK_345 implemented")
	_assert(status_text.contains("### TASK_345 - NPC Standard Movement Posture Policy"), "Implementation status documents TASK_345")
	_assert(roadmap_text.contains("TASK_345 - NPC Standard Movement Posture Policy (implementiert)"), "Roadmap marks TASK_345 implemented")


func _make_context(prefix: String, profile_id: String, enemy_position: Vector2, friendly_position: Vector2, objective_position: Vector2) -> Dictionary:
	var root_node := Node.new()
	root_node.name = "Task345_%s" % prefix
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root_node.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	root_node.add_child(simulation_root)
	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	objective_status.objective_id = "%s_objective" % prefix
	objective_status.position = objective_position
	objective_status.capture_radius = 96.0
	simulation_root.call("set_objective_status", objective_status)
	var friendly_id: String = "%s_friendly" % prefix
	var enemy_id: String = "%s_enemy" % prefix
	var friendly: Node2D = _make_unit(friendly_id, "team_alpha", friendly_position)
	var enemy: Node2D = _make_unit(enemy_id, "team_bravo", enemy_position)
	enemy.set_meta("enemy_tactics_config", {
		"group_id": "%s_red" % prefix,
		"profile_id": profile_id,
		"team_id": "team_bravo",
	})
	root_node.add_child(friendly)
	root_node.add_child(enemy)
	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "team_alpha"
	driver.preview_mode = true
	driver.simulation_root_path = NodePath("../SimulationRoot")
	var friendly_paths: Array[NodePath] = [NodePath("../%s" % friendly_id)]
	var enemy_paths: Array[NodePath] = [NodePath("../%s" % enemy_id)]
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	root_node.add_child(driver)
	root.add_child(root_node)
	unit_registry.call("register_unit", friendly_id, friendly)
	unit_registry.call("register_unit", enemy_id, enemy)
	simulation_root.call("register_known_unit", friendly_id, friendly)
	simulation_root.call("register_known_unit", enemy_id, enemy)
	return {
		"root": root_node,
		"simulation_root": simulation_root,
		"driver": driver,
		"friendly": friendly,
		"enemy": enemy,
	}


func _make_unit(unit_id: String, team_id: String, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = "blue" if team_id == "team_alpha" else "red"
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	unit.global_position = position_value
	unit._ready()
	return unit


func _first_queued_command(simulation_root: Node) -> Dictionary:
	var queue: Array = Array(simulation_root.get("command_queue"))
	if queue.is_empty() or typeof(queue[0]) != TYPE_DICTIONARY:
		return {}
	return Dictionary(queue[0])


func _cleanup_context(context: Dictionary) -> void:
	var root_node: Node = context.get("root", null)
	if root_node != null:
		root_node.queue_free()


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


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
	print("  FAIL: %s" % message)
