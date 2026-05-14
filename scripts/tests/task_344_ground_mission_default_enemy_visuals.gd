extends SceneTree

const MAP_PATH: String = "res://maps/Ground_Mission01_32x32.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/ground_mission01_default.json"
const TASK_PATH: String = "res://docs/tasks/TASK_344_ground_mission_default_enemy_visuals.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const META_FLOW_PATH: String = "res://scripts/meta/meta_layer_flow.gd"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const COMBAT_DRIVER_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_344 Ground Mission Default Enemy Visuals ===")
	_test_ground_map_and_scenario_authoring()
	await _test_default_mission_scene_spawns_scenario_enemy_slots()
	await _test_fire_event_drives_facing_aim_pose_and_muzzle_vfx()
	_test_source_contracts_and_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_ground_map_and_scenario_authoring() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(map_data != null, "Ground mission map loads")
	if map_data == null:
		return
	_assert(Vector2i(map_data.call("get_grid_size")) == Vector2i(32, 32), "Ground mission is a 32x32 map")
	for marker_id in ["spawn_alpha", "spawn_bravo", "spawn_enemy_patrol", "spawn_enemy_defense", "objective_point"]:
		_assert(bool(map_data.call("has_marker", marker_id)), "Ground map has marker: %s" % marker_id)
	_assert(Array(map_data.call("get_patrol_path", "ground_patrol_route")).size() == 4, "Ground map carries a four-point patrol route")
	_assert(String(Dictionary(map_data.call("get_enemy_team_config", "ground_patrol_team")).get("profile_id", "")) == "patrol_probe", "Map carries patrol tactics config")
	_assert(String(Dictionary(map_data.call("get_enemy_team_config", "ground_objective_defense")).get("profile_id", "")) == "defensive_cover", "Map carries defense tactics config")

	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Ground mission scenario loads")
	if scenario == null:
		return
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Ground mission scenario validates: %s" % str(validation.get("errors", [])))
	var enemy_groups: Array = Array(scenario.get("enemy_groups"))
	_assert(enemy_groups.size() == 2, "Scenario has two enemy fireteam groups")
	for group_variant in enemy_groups:
		var group: Dictionary = Dictionary(group_variant)
		_assert(Array(group.get("enemy_ids", [])).size() == 4, "%s has four enemy NPCs" % String(group.get("group_id", "")))
	_assert(PackedStringArray(scenario.call("get_enemy_ids")).size() == 8, "Scenario exposes eight enemy IDs")
	_assert(String(Dictionary(scenario.call("get_enemy_tactics_for_unit", "ground_patrol_01", map_data)).get("profile_id", "")) == "patrol_probe", "Patrol unit resolves patrol tactics")
	_assert(String(Dictionary(scenario.call("get_enemy_tactics_for_unit", "ground_defense_01", map_data)).get("profile_id", "")) == "defensive_cover", "Defense unit resolves defensive tactics")


func _test_default_mission_scene_spawns_scenario_enemy_slots() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
	root.add_child(scene)
	await _wait_frames(24)
	var setup: Node = scene.get_node("MissionSetup")
	var enemy_waves: Node = scene.get_node("EnemyWaveController")
	var combat_driver: Node = scene.get_node("CombatLoopDriver")
	var setup_snapshot: Dictionary = Dictionary(setup.call("get_expected_unit_presence_snapshot"))
	var enemy_ids: Array = Array(setup_snapshot.get("enemy_unit_ids", []))
	_assert(enemy_ids.size() == 8, "Mission setup expands scenario to eight enemy runtime IDs")
	_assert(enemy_ids.has("ground_patrol_01") and enemy_ids.has("ground_defense_04"), "Expanded enemy IDs cover patrol and defense fireteams")
	_assert(Array(enemy_waves.call("get_patrol_path_for_unit", "ground_patrol_01")).size() == 4, "Patrol fireteam receives the map patrol route")
	_assert(Array(enemy_waves.call("get_patrol_path_for_unit", "ground_defense_01")).is_empty(), "Defense fireteam does not inherit patrol route")
	_assert(String(Dictionary(enemy_waves.call("get_tactic_config_for_unit", "ground_defense_01")).get("security_mode", "")) == "cover_arc", "Defense fireteam receives cover-arc security")
	_assert(Array(combat_driver.get("enemy_unit_paths")).size() >= 8, "Combat loop receives all expanded enemy paths")
	scene.queue_free()
	await _wait_frames(2)


func _test_fire_event_drives_facing_aim_pose_and_muzzle_vfx() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_344_aim_pose", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var attacker: Node2D = _make_unit("task_344_attacker", "team_bravo", Vector2(0.0, 128.0))
	var target: Node2D = _make_unit("task_344_target", "team_alpha", Vector2(192.0, 128.0))
	root.add_child(attacker)
	root.add_child(target)
	primary_view.call("set_unit_nodes", [attacker, target])
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"fire_event_dicts": [
			{
				"event_id": "task_344_fire",
				"event_type": "weapon_fire",
				"source": "standard",
				"tick": 1,
				"sequence": 1,
				"attacker_unit_id": "task_344_attacker",
				"attacker_team_id": "team_bravo",
				"target_unit_id": "task_344_target",
				"target_team_id": "team_alpha",
				"weapon_id": "rifle",
				"weapon_tile_range": 25,
				"weapon_range_world": 1800.0,
				"attacker_position": attacker.global_position,
				"target_position": target.global_position,
			}
		],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var proxy_state_by_id: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	var attacker_state: Dictionary = Dictionary(proxy_state_by_id.get("task_344_attacker", {}))
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) == 1, "Fire event creates one muzzle flash VFX")
	_assert(bool(attacker_state.get("unit_aim_pose_active", false)), "Attacker proxy enters aim pose while firing")
	_assert(bool(attacker_state.get("unit_aim_pose_weapon_node_available", false)), "Aim pose has a blaster visual node to pose")
	_assert(bool(attacker_state.get("unit_weapon_upper_body_pose_active", false)), "Aim pose applies the imported shoot upper-body pose")
	_assert(int(attacker_state.get("unit_weapon_upper_body_pose_bone_count", 0)) >= 8, "Aim pose drives enough upper-body bones for a visible raised weapon")
	_assert(String(attacker_state.get("unit_weapon_upper_body_pose_source_animation", "")) == "shoot", "Aim pose takes the upper-body posture from the imported shoot animation")
	_assert(String(attacker_state.get("unit_aim_pose_source_event_id", "")) == "task_344_fire", "Aim pose is tied to the fire event id")
	var attacker_proxy := _find_proxy_node_by_unit_id(primary_view, "task_344_attacker") as Node3D
	var attacker_forward: Vector2 = _get_unit_model_forward_xz(attacker_proxy)
	var target_forward: Vector2 = _world_direction_to_3d_xz(primary_view, attacker.global_position, target.global_position - attacker.global_position)
	_assert(attacker_forward.dot(target_forward) > 0.96, "Attacker proxy faces the fire target")
	_assert_weapon_root_stays_on_socket(attacker_proxy, "Enemy attacker keeps the weapon root on the hand socket while aimed")
	_assert_aim_pose_uses_imported_shoot_grip(attacker_proxy, "Enemy attacker uses the imported shoot grip while aimed")
	primary_view.queue_free()
	attacker.queue_free()
	target.queue_free()
	await _wait_frames(2)


func _test_source_contracts_and_docs() -> void:
	var meta_text: String = _read_text(META_FLOW_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	var combat_text: String = _read_text(COMBAT_DRIVER_PATH)
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(meta_text.contains(MAP_PATH) and meta_text.contains(SCENARIO_PATH), "Meta flow defaults to Ground map and scenario")
	_assert(terrain_text.contains("Color(0.02, 0.05, 0.06, 0.28)") and terrain_text.contains("Color(0.02, 0.04, 0.06, 0.62)"), "FoW dim colors are darker")
	_assert(combat_text.contains("_store_combat_attacker_facing") and combat_text.contains("attacker_facing_angle"), "Combat driver stores attacker facing on fire events")
	_assert(task_text.contains("## Status: IMPLEMENTIERT") and not task_text.contains("- [ ]"), "Task file marks TASK_344 implemented")
	_assert(status_text.contains("### TASK_344 - Ground Mission Default Enemy Visuals"), "Implementation status documents TASK_344")
	_assert(roadmap_text.contains("TASK_344 - Ground Mission Default Enemy Visuals (implementiert)"), "Roadmap marks TASK_344 implemented")


func _make_unit(unit_id: String, team_id: String, position_value: Vector2) -> Node2D:
	var unit: TestUnit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id.capitalize()
	unit.team_id = team_id
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	unit.global_position = position_value
	return unit


func _assert_weapon_root_stays_on_socket(proxy: Node3D, message: String) -> void:
	var weapon_node: Node3D = _find_unit_blaster_visual_node(proxy)
	if weapon_node == null:
		_assert(false, "%s has a weapon visual" % message)
		return
	var base_position: Vector3 = _get_vector3_meta(weapon_node, "unit_aim_pose_base_position", weapon_node.position)
	_assert(weapon_node.position.distance_to(base_position) <= 0.002, "%s (offset %.4f)" % [message, weapon_node.position.distance_to(base_position)])


func _assert_aim_pose_uses_imported_shoot_grip(proxy: Node3D, message: String) -> void:
	var skeleton := _find_skeleton3d(proxy)
	if skeleton == null:
		_assert(false, "%s has a Skeleton3D" % message)
		return
	var right_hand_index: int = skeleton.find_bone("RightHand")
	var left_hand_index: int = skeleton.find_bone("LeftHand")
	var chest_index: int = skeleton.find_bone("Chest")
	if right_hand_index < 0 or left_hand_index < 0 or chest_index < 0:
		_assert(false, "%s has RightHand, LeftHand and Chest bones" % message)
		return
	var right_hand: Vector3 = skeleton.get_bone_global_pose(right_hand_index).origin
	var left_hand: Vector3 = skeleton.get_bone_global_pose(left_hand_index).origin
	var hand_spread: float = absf(right_hand.x - left_hand.x)
	_assert(hand_spread <= 0.035, "%s keeps hands near the weapon instead of a T-pose (spread %.4f)" % [message, hand_spread])


func _find_unit_blaster_visual_node(node: Node) -> Node3D:
	if node == null:
		return null
	var node_3d := node as Node3D
	if node_3d != null and String(node.name).begins_with("BlasterVisual_"):
		return node_3d
	for child in node.get_children():
		var found: Node3D = _find_unit_blaster_visual_node(child)
		if found != null:
			return found
	return null


func _get_vector3_meta(node: Node, meta_name: String, fallback: Vector3) -> Vector3:
	if node == null or not node.has_meta(meta_name):
		return fallback
	var value: Variant = node.get_meta(meta_name)
	if typeof(value) == TYPE_VECTOR3:
		return Vector3(value)
	return fallback


func _get_unit_model_forward_xz(proxy: Node3D) -> Vector2:
	if proxy == null:
		return Vector2.ZERO
	var skeleton := _find_skeleton3d(proxy)
	if skeleton == null:
		return Vector2.ZERO
	var hips_bone: int = skeleton.find_bone("Hips")
	if hips_bone < 0:
		return Vector2.ZERO
	var hips_global: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(hips_bone)
	var forward := Vector2(hips_global.basis.z.x, hips_global.basis.z.z)
	return forward.normalized() if forward.length_squared() > 0.0001 else Vector2.ZERO


func _world_direction_to_3d_xz(primary_view: Node, origin_world: Vector2, direction: Vector2) -> Vector2:
	if primary_view == null or direction.length_squared() <= 0.0001:
		return Vector2.ZERO
	var origin_3d: Vector3 = Vector3(primary_view.call("_world_to_surface_3d_position", origin_world, 0.0))
	var tip_3d: Vector3 = Vector3(primary_view.call("_world_to_surface_3d_position", origin_world + direction.normalized(), 0.0))
	var delta: Vector3 = tip_3d - origin_3d
	var forward := Vector2(delta.x, delta.z)
	return forward.normalized() if forward.length_squared() > 0.0001 else Vector2.ZERO


func _find_proxy_node_by_unit_id(node: Node, unit_id: String) -> Node:
	if node == null:
		return null
	if String(node.get_meta("unit_id", "")).strip_edges().to_lower() == unit_id.strip_edges().to_lower():
		return node
	for child in node.get_children():
		var found := _find_proxy_node_by_unit_id(child, unit_id)
		if found != null:
			return found
	return null


func _find_skeleton3d(node: Node) -> Skeleton3D:
	if node == null:
		return null
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton3d(child)
		if found != null:
			return found
	return null


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
