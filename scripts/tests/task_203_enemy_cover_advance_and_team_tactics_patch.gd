extends SceneTree

const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_loop_driver.gd")
const LOCAL_AVOIDANCE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/local_avoidance_resolver.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends Node

	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		commands.append(command_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_203 Enemy Cover Advance and Team Tactics Patch ===")
	_test_cover_team_takes_distinct_walkable_slots()
	_test_push_team_moves_multiple_units_over_multiple_tiles()
	_test_hold_team_stays_and_keeps_security_snapshot()
	_test_minimum_spacing_targets_survive_contact_tactics()
	await _test_primary_map_renders_enemy_tactics_labels()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_cover_team_takes_distinct_walkable_slots() -> void:
	var context: Dictionary = _make_driver_context("cover", "defensive_cover", _cover_tile_specs(), ["rifle", "rail_gun", "sniper"], [Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)], Vector2i(5, 2))
	var driver: Node = context["driver"]
	driver.call("_update_enemy_team_tactics_state")
	var state: Dictionary = _first_tactics_state(driver)
	var targets: Dictionary = Dictionary(state.get("target_positions_by_unit_id", {}))
	var unique_targets: Array = _unique_positions(targets.values())
	_assert(String(state.get("advance_style", "")) == "bounding", "Defensive cover profile normalizes to a bounding-style enemy tactic")
	_assert(unique_targets.size() >= 2, "Enemy cover selection assigns multiple distinct cover slots")
	_assert(_all_targets_are_walkable_cover(context["terrain_registry"], unique_targets), "Enemy cover slots are walkable cover tiles")
	_assert(Dictionary(state.get("role_by_unit_id", {})).size() == 3, "Enemy team roles are exposed as small data labels")
	_assert(String(state.get("tactic_label", "")).begins_with("BND"), "Enemy cover tactic exposes a compact BND status label")
	_cleanup_context(context)


func _test_push_team_moves_multiple_units_over_multiple_tiles() -> void:
	var context: Dictionary = _make_driver_context("push", "aggressive_push", [], ["smg", "rifle", "rail_gun"], [Vector2.ZERO, Vector2(0.0, 48.0), Vector2(0.0, 96.0)], Vector2(500.0, 48.0))
	var driver: Node = context["driver"]
	var simulation := SimulationStub.new()
	driver.call("_update_enemy_team_tactics_state")
	driver.call("_advance_enemy_units", simulation)
	var state: Dictionary = _first_tactics_state(driver)
	var moving_ids: PackedStringArray = PackedStringArray(state.get("moving_unit_ids", PackedStringArray()))
	_assert(String(state.get("advance_style", "")) == "push", "Aggressive push profile normalizes to push")
	_assert(moving_ids.size() >= 2, "Push profile marks multiple enemy units as moving")
	_assert(simulation.commands.size() >= 2, "Push profile enqueues movement for multiple enemies")
	_assert(_commands_move_multiple_tiles(simulation.commands, context["enemies"], 100.0), "Push commands move enemies over multiple tile-scale distances")
	_cleanup_context(context)
	simulation.free()


func _test_hold_team_stays_and_keeps_security_snapshot() -> void:
	var context: Dictionary = _make_driver_context("hold", "guard_hold", [], ["rifle", "rifle"], [Vector2.ZERO, Vector2(0.0, 48.0)], Vector2(500.0, 0.0))
	var driver: Node = context["driver"]
	var simulation := SimulationStub.new()
	driver.call("_update_enemy_security_state")
	driver.call("_update_enemy_team_tactics_state")
	driver.call("_advance_enemy_units", simulation)
	var tactics_state: Dictionary = _first_tactics_state(driver)
	var security_snapshot: Array = Array(driver.call("get_enemy_security_snapshot"))
	_assert(String(tactics_state.get("advance_style", "")) == "hold", "Guard hold profile stays in hold tactic")
	_assert(PackedStringArray(tactics_state.get("moving_unit_ids", PackedStringArray())).is_empty(), "Hold profile has no moving enemy group")
	_assert(simulation.commands.is_empty(), "Hold profile does not enqueue objective-rush movement")
	_assert(not security_snapshot.is_empty(), "Hold profile still exposes enemy security state")
	_cleanup_context(context)
	simulation.free()


func _test_minimum_spacing_targets_survive_contact_tactics() -> void:
	var context: Dictionary = _make_driver_context("spacing", "aggressive_push", [], ["rifle", "rifle", "rifle"], [Vector2.ZERO, Vector2(2.0, 0.0), Vector2(4.0, 0.0)], Vector2(500.0, 0.0))
	var driver: Node = context["driver"]
	driver.call("_update_enemy_team_tactics_state")
	var state: Dictionary = _first_tactics_state(driver)
	var targets: Dictionary = Dictionary(state.get("target_positions_by_unit_id", {}))
	var minimum_distance: float = _minimum_distance_between_positions(targets.values())
	_assert(minimum_distance >= LOCAL_AVOIDANCE_RESOLVER_SCRIPT.DEFAULT_MINIMUM_SPACING - 0.001, "Enemy tactic target slots keep TASK_187 minimum spacing")
	_cleanup_context(context)


func _test_primary_map_renders_enemy_tactics_labels() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task203_enemy_tactics", Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 2)
	var center_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	var center_position: Vector2 = Vector2(center_tile.world_position) if center_tile != null else Vector2.ZERO
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call(
		"set_order_visual_payload",
		{
			"phase_index": 1,
			"enemy_tactics_dicts": [
				{
					"security_group_id": "red_push",
					"advance_style": "push",
					"anchor_position": center_position,
					"moving_unit_ids": PackedStringArray(["red_a", "red_b"]),
					"covering_unit_ids": PackedStringArray(),
					"target_positions_by_unit_id": {
						"red_a": center_position + Vector2(96.0, 0.0),
						"red_b": center_position + Vector2(96.0, 48.0),
					},
					"role_by_unit_id": {"red_a": "point", "red_b": "cover"},
					"tactic_label": "PUSH M2",
				}
			],
		}
	)
	for _index in range(6):
		await process_frame
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("enemy_tactics_entries", []))
	_assert(int(snapshot.get("enemy_tactics_visual_count", 0)) == 1, "Mission map renders a compact enemy tactics label")
	_assert(entries.size() == 1 and String(Dictionary(entries[0]).get("tactic_label", "")) == "PUSH M2", "Mission map snapshot mirrors enemy tactic label")
	primary_view.queue_free()
	await process_frame


func _make_driver_context(prefix: String, profile_id: String, tile_specs: Array, enemy_weapons: Array, enemy_positions: Array, friendly_position_variant) -> Dictionary:
	var harness := Node.new()
	harness.name = "Task203Harness_%s" % prefix
	var terrain_registry = null
	if not tile_specs.is_empty():
		terrain_registry = _make_registry(tile_specs)
		terrain_registry.name = "TerrainRegistry"
		harness.add_child(terrain_registry)
	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "team_alpha"
	driver.enemy_advance_enabled = true
	driver.preview_mode = true
	if terrain_registry != null:
		driver.terrain_registry_path = NodePath("../TerrainRegistry")
	var friendly_position: Vector2 = _coerce_position(friendly_position_variant, terrain_registry)
	var friendly = _make_unit("%s_friendly" % prefix, "team_alpha", "rifle", friendly_position)
	harness.add_child(friendly)
	var friendly_paths: Array[NodePath] = [NodePath("../%s_friendly" % prefix)]
	var enemy_paths: Array[NodePath] = []
	var enemies: Array = []
	for index in range(enemy_weapons.size()):
		var enemy_id: String = "%s_enemy_%d" % [prefix, index]
		var enemy_position: Vector2 = _coerce_position(enemy_positions[index], terrain_registry)
		var enemy = _make_unit(enemy_id, "team_bravo", String(enemy_weapons[index]), enemy_position)
		enemy.set_meta("enemy_tactics_config", {
			"group_id": "%s_group" % prefix,
			"profile_id": profile_id,
			"security_mode": "directional",
			"facing": "east",
			"team_id": "team_bravo",
		})
		harness.add_child(enemy)
		enemies.append(enemy)
		enemy_paths.append(NodePath("../%s" % enemy_id))
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	harness.add_child(driver)
	return {
		"harness": harness,
		"terrain_registry": terrain_registry,
		"driver": driver,
		"friendly": friendly,
		"enemies": enemies,
	}


func _cover_tile_specs() -> Array:
	var specs: Array = []
	for x in range(0, 7):
		for y in range(0, 5):
			var grid_position := Vector2i(x, y)
			var cover_value: int = 0
			var walkable: bool = true
			if grid_position == Vector2i(2, 1):
				cover_value = 65
			elif grid_position == Vector2i(2, 2):
				cover_value = 85
			elif grid_position == Vector2i(2, 3):
				cover_value = 55
			elif grid_position == Vector2i(3, 3):
				cover_value = 95
				walkable = false
			specs.append({
				"grid_position": grid_position,
				"cover_value": cover_value,
				"walkable": walkable,
			})
	return specs


func _make_registry(tile_specs: Array):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for spec_variant in tile_specs:
		var spec: Dictionary = Dictionary(spec_variant)
		var grid_position: Vector2i = Vector2i(spec.get("grid_position", Vector2i.ZERO))
		registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
			"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
			"type_id": "ground_flat",
			"grid_position": grid_position,
			"world_position": registry.grid_to_world(grid_position),
			"walkable": bool(spec.get("walkable", true)),
			"blocks_los": bool(spec.get("blocks_los", false)),
			"cover_value": int(spec.get("cover_value", 0)),
			"height_level": int(spec.get("height_level", 0)),
			"object_height": int(spec.get("object_height", 0)),
			"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND,
			"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE,
		}))
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
	unit.position = position_value
	unit._ready()
	return unit


func _coerce_position(value, terrain_registry) -> Vector2:
	if typeof(value) == TYPE_VECTOR2I and terrain_registry != null:
		return Vector2(terrain_registry.call("grid_to_world", Vector2i(value)))
	if typeof(value) == TYPE_VECTOR2:
		return Vector2(value)
	return Vector2.ZERO


func _first_tactics_state(driver: Node) -> Dictionary:
	var snapshot: Array = Array(driver.call("get_enemy_team_tactics_snapshot"))
	if snapshot.is_empty():
		return {}
	return Dictionary(snapshot[0])


func _unique_positions(positions: Array) -> Array:
	var result: Array = []
	for position_variant in positions:
		if typeof(position_variant) != TYPE_VECTOR2:
			continue
		var position: Vector2 = Vector2(position_variant)
		var duplicate: bool = false
		for existing_variant in result:
			if position.distance_to(Vector2(existing_variant)) < 0.001:
				duplicate = true
				break
		if not duplicate:
			result.append(position)
	return result


func _all_targets_are_walkable_cover(terrain_registry, positions: Array) -> bool:
	if terrain_registry == null:
		return false
	for position_variant in positions:
		var position: Vector2 = Vector2(position_variant)
		var tile = terrain_registry.call("get_tile_at_world", position)
		if tile == null or not bool(tile.walkable) or int(tile.cover_value) <= 0:
			return false
	return true


func _commands_move_multiple_tiles(commands: Array, enemies: Array, minimum_distance: float) -> bool:
	var enemy_by_id: Dictionary = {}
	for enemy in enemies:
		enemy_by_id[String(enemy.call("get_unit_id"))] = enemy
	var moving_count: int = 0
	for command_variant in commands:
		var command: Dictionary = Dictionary(command_variant)
		var unit_id: String = String(command.get("unit_id", ""))
		if not enemy_by_id.has(unit_id) or typeof(command.get("target_position", null)) != TYPE_VECTOR2:
			continue
		var enemy: Node2D = enemy_by_id[unit_id]
		if enemy.global_position.distance_to(Vector2(command.get("target_position"))) >= minimum_distance:
			moving_count += 1
	return moving_count >= 2


func _minimum_distance_between_positions(positions: Array) -> float:
	var vector_positions: Array = []
	for position_variant in positions:
		if typeof(position_variant) == TYPE_VECTOR2:
			vector_positions.append(Vector2(position_variant))
	if vector_positions.size() < 2:
		return INF
	var minimum_distance: float = INF
	for index_a in range(vector_positions.size()):
		for index_b in range(index_a + 1, vector_positions.size()):
			minimum_distance = minf(minimum_distance, Vector2(vector_positions[index_a]).distance_to(Vector2(vector_positions[index_b])))
	return minimum_distance


func _cleanup_context(context: Dictionary) -> void:
	var harness: Node = context.get("harness", null)
	if harness != null:
		harness.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
