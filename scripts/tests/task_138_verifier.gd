extends SceneTree

const COMMAND_TRANSLATOR_SCRIPT: GDScript = preload("res://scripts/command/command_to_ftltask_translator.gd")
const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const LINE_OF_SIGHT_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const MAP_FLOOR_SLOT_SCRIPT: GDScript = preload("res://scripts/terrain/map_floor_slot.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")

var _passed: int = 0
var _failed: int = 0
var _terrain_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_138 2.5D Multi-Floor Foundation Verifier ===")
	_test_floor_slot_data_model_roundtrip()
	_test_map_data_keeps_same_grid_floor_slots_separate()
	_test_registry_resolves_grid_and_floor_slots()
	_test_floor_path_requires_explicit_link()
	_test_los_reads_floor_specific_heights()
	_test_command_contract_carries_target_floor_index()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_floor_slot_data_model_roundtrip() -> void:
	var tile_data = _make_tile(Vector2i(2, 3), 1, 3.0, [{
		"target_grid_position": Vector2i(2, 3),
		"target_floor_index": 0,
		"link_type": "stairs",
		"bidirectional": true,
	}])
	var slot = MAP_FLOOR_SLOT_SCRIPT.call("from_tile_data", tile_data)
	var serialized: Dictionary = Dictionary(slot.call("to_dict")) if slot != null else {}
	var link: Dictionary = Dictionary(Array(serialized.get("floor_links", []))[0]) if not Array(serialized.get("floor_links", [])).is_empty() else {}
	_assert(slot != null and bool(slot.call("is_valid")), "MapFloorSlot can be built from TerrainTileData")
	_assert(int(serialized.get("floor_index", -1)) == 1 and is_equal_approx(float(serialized.get("floor_height", 0.0)), 3.0), "MapFloorSlot preserves floor index and height")
	_assert(Vector2i(link.get("target_grid_position", Vector2i.ZERO)) == Vector2i(2, 3) and int(link.get("target_floor_index", -1)) == 0, "MapFloorSlot preserves explicit floor link")


func _test_map_data_keeps_same_grid_floor_slots_separate() -> void:
	var temp_path: String = "user://task_138_multifloor_map.json"
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_138_map", Vector2i(1, 1), Vector2.ZERO)
	var roof_tile = _make_tile(Vector2i(0, 0), 1, 3.0)
	map_data.call("add_tile", roof_tile)
	var save_error: Error = map_data.call("save_to_file", temp_path)
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", temp_path)
	var ground_tile = reloaded.call("get_tile_at_grid_floor", Vector2i(0, 0), 0) if reloaded != null else null
	var reloaded_roof = reloaded.call("get_tile_at_grid_floor", Vector2i(0, 0), 1) if reloaded != null else null
	_assert(save_error == OK, "TerrainMapData saves floor-indexed slots")
	_assert(ground_tile != null and int(ground_tile.floor_index) == 0, "TerrainMapData keeps ground floor at default lookup")
	_assert(reloaded_roof != null and int(reloaded_roof.floor_index) == 1 and is_equal_approx(float(reloaded_roof.floor_height), 3.0), "TerrainMapData roundtrip keeps roof slot at same grid")


func _test_registry_resolves_grid_and_floor_slots() -> void:
	var registry = _make_multifloor_registry(true)
	var ground_slot = registry.call("get_floor_slot_at_grid", Vector2i(0, 0), 0)
	var roof_slot = registry.call("get_floor_slot_at_grid", Vector2i(0, 0), 1)
	var slots: Array = Array(registry.call("get_floor_slots_at_grid", Vector2i(0, 0)))
	var ground_profile: Dictionary = Dictionary(registry.call("get_height_profile_at_grid_floor", Vector2i(0, 0), 0))
	var roof_profile: Dictionary = Dictionary(registry.call("get_height_profile_at_grid_floor", Vector2i(0, 0), 1))
	_assert(ground_slot != null and roof_slot != null and slots.size() == 2, "TerrainRegistry resolves two slots at one grid coordinate")
	_assert(int(ground_profile.get("floor_index", -1)) == 0 and int(roof_profile.get("floor_index", -1)) == 1, "Height profiles are floor-index aware")
	_assert(float(roof_profile.get("floor_height", 0.0)) > float(ground_profile.get("floor_height", 0.0)), "Floor-specific lookup preserves separate floor heights")
	registry.free()


func _test_floor_path_requires_explicit_link() -> void:
	var linked_registry = _make_multifloor_registry(true)
	var blocked_registry = _make_multifloor_registry(false)
	var linked_path: Array = _terrain_pathfinder.call("find_floor_path", Vector2i(0, 0), 0, Vector2i(1, 0), 1, linked_registry)
	var reverse_linked_path: Array = _terrain_pathfinder.call("find_floor_path", Vector2i(1, 0), 1, Vector2i(0, 0), 0, linked_registry)
	var blocked_path: Array = _terrain_pathfinder.call("find_floor_path", Vector2i(0, 0), 0, Vector2i(1, 0), 1, blocked_registry)
	var transition_snapshot: Dictionary = Dictionary(_terrain_pathfinder.call("get_floor_step_traversal_snapshot", Vector2i(0, 0), 0, Vector2i(0, 0), 1, linked_registry))
	_assert(not linked_path.is_empty() and _floor_path_has(linked_path, Vector2i(0, 0), 1), "Floor path can use an explicit same-grid stair link")
	_assert(not reverse_linked_path.is_empty() and _floor_path_has(reverse_linked_path, Vector2i(0, 0), 1), "Bidirectional floor link can be used in reverse")
	_assert(blocked_path.is_empty(), "Floor path cannot change floors without an explicit link")
	_assert(bool(transition_snapshot.get("traversable", false)), "Floor transition snapshot reports allowed link")
	linked_registry.free()
	blocked_registry.free()


func _test_los_reads_floor_specific_heights() -> void:
	var registry = _make_multifloor_registry(true)
	var los_system = LINE_OF_SIGHT_SYSTEM_SCRIPT.new()
	var ground_snapshot: Dictionary = Dictionary(los_system.call("get_line_of_sight_floor_snapshot", Vector2i(0, 0), 0, Vector2i(1, 0), 0, registry, 999.0))
	var roof_snapshot: Dictionary = Dictionary(los_system.call("get_line_of_sight_floor_snapshot", Vector2i(0, 0), 1, Vector2i(1, 0), 1, registry, 999.0))
	_assert(bool(ground_snapshot.get("has_line_of_sight", false)) and bool(roof_snapshot.get("has_line_of_sight", false)), "Floor LOS snapshot works for ground and roof")
	_assert(float(roof_snapshot.get("source_eye_height", 0.0)) > float(ground_snapshot.get("source_eye_height", 0.0)), "Floor LOS reads roof source height from floor slot")
	_assert(int(roof_snapshot.get("source_floor_index", -1)) == 1 and int(roof_snapshot.get("target_floor_index", -1)) == 1, "Floor LOS snapshot exposes floor indices")
	registry.free()


func _test_command_contract_carries_target_floor_index() -> void:
	var command = COMMANDER_COMMAND_SCRIPT.new({
		"command_type": "move",
		"unit_id": "blue",
		"team_id": "team_alpha",
		"target_position": Vector2(64.0, 32.0),
		"target_floor_index": 1,
	})
	var translator = COMMAND_TRANSLATOR_SCRIPT.new()
	var task = translator.call("translate", command)
	var unit_command = UNIT_COMMAND_SCRIPT.new({
		"command_type": "move_to_position",
		"unit_id": "blue_1",
		"team_id": "team_alpha",
		"target_position": Vector2(64.0, 32.0),
		"target_floor_index": 1,
	})
	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.new({
		"status": "pending_move",
		"target_position": Vector2(64.0, 32.0),
		"target_floor_index": 1,
	})
	_assert(command.is_valid() and int(command.target_floor_index) == 1, "CommanderCommand accepts optional target_floor_index")
	_assert(task != null and int(task.get("target_floor_index")) == 1, "Command translator preserves target_floor_index")
	_assert(unit_command.is_valid() and int(unit_command.to_dict().get("target_floor_index", -1)) == 1, "UnitCommand roundtrip carries target_floor_index")
	_assert(runtime_status.is_valid() and int(runtime_status.to_dict().get("target_floor_index", -1)) == 1, "UnitRuntimeStatus roundtrip carries target_floor_index")


func _make_multifloor_registry(with_link: bool):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	var ground_links: Array = []
	if with_link:
		ground_links.append({
			"target_grid_position": Vector2i(0, 0),
			"target_floor_index": 1,
			"link_type": "stairs",
			"bidirectional": true,
		})
	registry.register_tile(_make_tile(Vector2i(0, 0), 0, 0.0, ground_links))
	registry.register_tile(_make_tile(Vector2i(1, 0), 0, 0.0))
	registry.register_tile(_make_tile(Vector2i(0, 0), 1, 3.0))
	registry.register_tile(_make_tile(Vector2i(1, 0), 1, 3.0))
	return registry


func _make_tile(grid_position: Vector2i, floor_index: int, floor_height: float, floor_links: Array = []):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "tile_%d_%d_f%d" % [grid_position.x, grid_position.y, floor_index],
		"type_id": "ground_flat",
		"grid_position": grid_position,
		"world_position": Vector2(float(grid_position.x - grid_position.y) * 64.0, float(grid_position.x + grid_position.y) * 32.0),
		"walkable": true,
		"floor_index": floor_index,
		"height_level": int(roundf(floor_height)),
		"floor_height": floor_height,
		"is_elevated_surface": floor_height > 0.0,
		"floor_links": floor_links,
	})


func _floor_path_has(path: Array, grid_position: Vector2i, floor_index: int) -> bool:
	for state_variant in path:
		var state: Dictionary = Dictionary(state_variant)
		if Vector2i(state.get("grid_position", Vector2i.ZERO)) == grid_position and int(state.get("floor_index", -1)) == floor_index:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
