extends SceneTree

const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_loop_driver.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class RangeLOSStub:
	extends RefCounted

	var force_blocked: bool = false
	var call_count: int = 0
	var last_range: float = 0.0

	func has_line_of_sight_between_nodes(attacker, target, range_value: float, _terrain_registry = null) -> bool:
		call_count += 1
		last_range = range_value
		if force_blocked:
			return false
		if attacker is Node2D and target is Node2D:
			return (attacker as Node2D).global_position.distance_to((target as Node2D).global_position) <= range_value
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_202 Enemy Security Direction and LOS Patch ===")
	_test_enemy_security_controller_helpers()
	_test_directional_enemy_snapshot_and_watch_sector()
	_test_directional_enemy_can_be_flanked()
	_test_enemy_360_security_blocks_flank()
	_test_enemy_los_blocker_removes_watch()
	_test_enemy_weapon_range_limits_watch_sector()
	await _test_primary_map_renders_enemy_security_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_enemy_security_controller_helpers() -> void:
	var enemy = _make_unit("helper_enemy", "team_bravo", "rifle", Vector2.ZERO)
	var assignments: Array = Array(FIRETEAM_SECURITY_CONTROLLER_SCRIPT.call("build_enemy_member_assignments", [enemy], "directional", 0.0, null))
	_assert(assignments.size() == 1, "Enemy security helper builds member assignments for fit enemies")
	if assignments.size() == 1:
		var assignment: Dictionary = Dictionary(assignments[0])
		_assert(String(assignment.get("unit_id", "")) == "helper_enemy", "Enemy assignment carries unit identity")
		_assert(String(assignment.get("weapon_id", "")) == "rifle", "Enemy assignment carries active weapon identity")
		_assert(int(assignment.get("weapon_tile_range", 0)) == 25, "Enemy assignment carries TASK_201 tile range")
	_assert(String(FIRETEAM_SECURITY_CONTROLLER_SCRIPT.call("normalize_enemy_security_mode", "360")) == "360", "Enemy helper keeps explicit 360 security")
	_assert(String(FIRETEAM_SECURITY_CONTROLLER_SCRIPT.call("normalize_enemy_security_mode", "patrol")) == "directional", "Enemy helper normalizes non-360 security to directional")
	_cleanup_harness(enemy)


func _test_directional_enemy_snapshot_and_watch_sector() -> void:
	var context: Dictionary = _make_driver_context("directional_watch", "directional", "east", "rifle", Vector2.ZERO, Vector2(1000.0, 0.0))
	var driver: Node = context["driver"]
	driver.call("_update_enemy_security_state")
	var snapshot: Array = Array(driver.call("get_enemy_security_snapshot"))
	_assert(snapshot.size() == 1, "Combat loop exposes one enemy security snapshot per enemy group")
	if snapshot.size() == 1:
		var state: Dictionary = Dictionary(snapshot[0])
		_assert(String(state.get("security_mode", "")) == "directional", "Enemy snapshot preserves directional security mode")
		_assert(absf(float(state.get("facing_angle", 99.0))) < 0.001, "Enemy facing can be derived from authoring profile direction")
		_assert(absf(float(state.get("sector_width", 0.0)) - FIRETEAM_SECURITY_CONTROLLER_SCRIPT.DIRECTIONAL_ARC_WIDTH) < 0.001, "Directional enemy snapshot exposes sector width")
		_assert(_packed_has(PackedStringArray(state.get("watched_unit_ids", PackedStringArray())), "directional_watch_friendly"), "Directional enemy watches targets inside sector, LOS, and weapon range")
		_assert(String(state.get("watch_label", "")).begins_with("EN SEC"), "Enemy snapshot carries a compact map label")
	_cleanup_context(context)


func _test_directional_enemy_can_be_flanked() -> void:
	var context: Dictionary = _make_driver_context("directional_flank", "directional", "east", "rifle", Vector2.ZERO, Vector2(-120.0, 0.0))
	var driver: Node = context["driver"]
	driver.call("_update_enemy_security_state")
	var result: Dictionary = Dictionary(driver.call("resolve_flank_attack", context["friendly"], context["enemy"]))
	_assert(bool(result.get("is_flank", false)), "Directional enemy can be flanked from rear or side outside its security sector")
	_assert(String(result.get("direction_label", "")) == "rear", "Enemy flank result keeps rear direction label")
	_cleanup_context(context)


func _test_enemy_360_security_blocks_flank() -> void:
	var context: Dictionary = _make_driver_context("full_watch", "360", "east", "rifle", Vector2.ZERO, Vector2(-120.0, 0.0))
	var driver: Node = context["driver"]
	driver.call("_update_enemy_security_state")
	var state: Dictionary = Dictionary(driver.call("get_enemy_security_state_for_unit", "full_watch_enemy"))
	var result: Dictionary = Dictionary(driver.call("resolve_flank_attack", context["friendly"], context["enemy"]))
	_assert(String(state.get("security_mode", "")) == "360", "Enemy 360 security is explicit in the snapshot")
	_assert(result.is_empty(), "Enemy 360 security blocks flank vulnerability")
	_cleanup_context(context)


func _test_enemy_los_blocker_removes_watch() -> void:
	var los := RangeLOSStub.new()
	los.force_blocked = true
	var context: Dictionary = _make_driver_context("los_block", "directional", "east", "rifle", Vector2.ZERO, Vector2(1000.0, 0.0), los)
	var driver: Node = context["driver"]
	driver.call("_update_enemy_security_state")
	var state: Dictionary = Dictionary(driver.call("get_enemy_security_state_for_unit", "los_block_enemy"))
	_assert(los.call_count > 0, "Enemy security asks LOS before adding watched targets")
	_assert(PackedStringArray(state.get("watched_unit_ids", PackedStringArray())).is_empty(), "Blocked LOS removes friendly units from enemy watch sector")
	_cleanup_context(context)


func _test_enemy_weapon_range_limits_watch_sector() -> void:
	var rifle_context: Dictionary = _make_driver_context("range_rifle", "directional", "east", "rifle", Vector2.ZERO, Vector2(2200.0, 0.0))
	var rifle_driver: Node = rifle_context["driver"]
	rifle_driver.call("_update_enemy_security_state")
	var rifle_state: Dictionary = Dictionary(rifle_driver.call("get_enemy_security_state_for_unit", "range_rifle_enemy"))
	_assert(PackedStringArray(rifle_state.get("watched_unit_ids", PackedStringArray())).is_empty(), "Rifle enemy watch sector ends at weapon range")
	_cleanup_context(rifle_context)

	var sniper_context: Dictionary = _make_driver_context("range_sniper", "directional", "east", "sniper", Vector2.ZERO, Vector2(2200.0, 0.0))
	var sniper_driver: Node = sniper_context["driver"]
	sniper_driver.call("_update_enemy_security_state")
	var sniper_state: Dictionary = Dictionary(sniper_driver.call("get_enemy_security_state_for_unit", "range_sniper_enemy"))
	_assert(_packed_has(PackedStringArray(sniper_state.get("watched_unit_ids", PackedStringArray())), "range_sniper_friendly"), "Sniper enemy watch sector reaches the same long distance")
	_cleanup_context(sniper_context)


func _test_primary_map_renders_enemy_security_snapshot() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task202_enemy_security", Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 2)
	var center_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	var center_position: Vector2 = Vector2(center_tile.world_position) if center_tile != null else Vector2.ZERO
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call(
		"set_order_visual_payload",
		{
			"phase_index": 1,
			"enemy_security_dicts": [
				{
					"security_group_id": "red_map",
					"security_mode": "directional",
					"anchor_position": center_position,
					"direction_angle": 0.0,
					"sector_width": FIRETEAM_SECURITY_CONTROLLER_SCRIPT.DIRECTIONAL_ARC_WIDTH,
					"member_assignments": [{"unit_id": "map_enemy", "weapon_range_world": 1800.0}],
					"watched_unit_ids": PackedStringArray(["map_friendly"]),
					"watch_label": "EN SEC DIR W1",
				}
			],
		}
	)
	for _index in range(6):
		await process_frame
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("enemy_security_entries", []))
	_assert(int(snapshot.get("enemy_security_visual_count", 0)) == 1, "Mission map renders one compact enemy security visual")
	_assert(entries.size() == 1, "Mission map snapshot mirrors enemy security entries")
	if entries.size() == 1:
		var entry: Dictionary = Dictionary(entries[0])
		_assert(String(entry.get("security_group_id", "")) == "red_map", "Mission map enemy security entry keeps group identity")
		_assert(_packed_has(PackedStringArray(entry.get("watched_unit_ids", PackedStringArray())), "map_friendly"), "Mission map enemy security entry keeps watched target IDs")
	primary_view.queue_free()
	await process_frame


func _make_driver_context(prefix: String, security_mode: String, facing: String, enemy_weapon_id: String, enemy_position: Vector2, friendly_position: Vector2, los = null) -> Dictionary:
	var harness := Node.new()
	harness.name = "Task202Harness_%s" % prefix
	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "team_alpha"
	driver.enemy_advance_enabled = false
	driver.preview_mode = true
	var friendly_paths: Array[NodePath] = [NodePath("../%s_friendly" % prefix)]
	var enemy_paths: Array[NodePath] = [NodePath("../%s_enemy" % prefix)]
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	if los != null:
		driver.set("_los_system", los)
	var friendly = _make_unit("%s_friendly" % prefix, "team_alpha", "rifle", friendly_position)
	var enemy = _make_unit("%s_enemy" % prefix, "team_bravo", enemy_weapon_id, enemy_position)
	enemy.set_meta("enemy_tactics_config", {
		"group_id": "%s_group" % prefix,
		"profile_id": "guard_hold" if security_mode == "360" else "patrol_probe",
		"security_mode": security_mode,
		"facing": facing,
		"team_id": "team_bravo",
	})
	harness.add_child(friendly)
	harness.add_child(enemy)
	harness.add_child(driver)
	return {
		"harness": harness,
		"driver": driver,
		"friendly": friendly,
		"enemy": enemy,
	}


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
	unit.skill_speed = 0.5
	unit.skill_leadership = 0.35
	unit.skill_toughness = 0.5
	unit.position = position_value
	unit._ready()
	return unit


func _packed_has(values: PackedStringArray, target: String) -> bool:
	for value in values:
		if String(value) == target:
			return true
	return false


func _cleanup_context(context: Dictionary) -> void:
	var harness: Node = context.get("harness", null)
	if harness != null:
		harness.free()


func _cleanup_harness(node: Node) -> void:
	if node != null:
		node.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
