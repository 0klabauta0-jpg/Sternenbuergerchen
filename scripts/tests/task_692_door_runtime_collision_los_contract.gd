extends SceneTree

const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const LINE_OF_SIGHT_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const OBJECT_REACTION_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_object_reaction.gd")
const DOOR_RUNTIME_COLLISION_LOS_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_door_runtime_collision_los.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_692_door_runtime_collision_los_contract.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/door_runtime_collision_los_contract.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_692 Door Runtime Collision/LOS Contract ===")
	_test_docs()
	_test_door_runtime_override_contract()
	_test_effective_registry_pathfinder_and_los()
	_write_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_692: FAILED")
		quit(1)
		return
	print("TASK_692: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_692 task file exists")
	_assert(task_text.contains("Door Runtime Collision/LOS Contract"), "Task documents door runtime collision and LOS")
	_assert(contract_text.contains("Door Runtime Collision/LOS"), "Interaction contract documents door collision/LOS overrides")
	_assert(status_text.contains("TASK_692 - Door Runtime Collision/LOS Contract"), "Implementation status tracks TASK_692")
	_assert(roadmap_text.contains("TASK_692 - Door Runtime Collision/LOS Contract (implementiert)"), "Roadmap marks TASK_692 implemented")
	_assert(handbook_text.contains("TASK_692 - Door Runtime Collision/LOS Contract"), "Current handbook references TASK_692")
	_assert(handbook_text.contains('data-export-key="mission_interaction_door_runtime_collision_los.manifest_path"'), "Current handbook exports TASK_692 manifest path")


func _test_door_runtime_override_contract() -> void:
	var reaction_snapshot: Dictionary = Dictionary(OBJECT_REACTION_SCRIPT.call("build_snapshot", {
		"schema": "test.visual_state",
		"entries": [
			_visual_entry("door_open", "complete", 1.0, Vector2i(1, 0)),
			_visual_entry("door_half", "in_progress", 0.5, Vector2i(3, 0)),
			_visual_entry("door_closed", "blocked", 0.0, Vector2i(5, 0)),
		],
	}))
	var snapshot: Dictionary = Dictionary(DOOR_RUNTIME_COLLISION_LOS_SCRIPT.call("build_snapshot", reaction_snapshot))
	_assert(_snapshot_is_read_only(snapshot), "Door runtime collision/LOS snapshot remains read-only")
	_assert(not bool(snapshot.get("terrain_map_data_mutated", true)), "Door snapshot declares no TerrainMapData mutation")
	_assert(int(snapshot.get("door_count", 0)) == 3, "Door snapshot exports all three door states")
	_assert(int(snapshot.get("override_count", 0)) == 3, "Door snapshot exports grid overrides")
	var overrides: Array = Array(snapshot.get("overrides", []))
	_assert(_override_bool(overrides, Vector2i(1, 0), "walkable_override"), "Open door override is walkable")
	_assert(not _override_bool(overrides, Vector2i(1, 0), "blocks_los_override"), "Open door override clears LOS")
	_assert(_override_int(overrides, Vector2i(1, 0), "object_height_override") == 0, "Open door override clears object height")
	_assert(not _override_bool(overrides, Vector2i(3, 0), "walkable_override"), "Half door remains blocked for movement")
	_assert(_override_bool(overrides, Vector2i(3, 0), "blocks_los_override"), "Half door blocks LOS")
	_assert(not _override_bool(overrides, Vector2i(5, 0), "walkable_override"), "Closed door remains blocked for movement")
	_assert(_override_bool(overrides, Vector2i(5, 0), "blocks_los_override"), "Closed door blocks LOS")


func _test_effective_registry_pathfinder_and_los() -> void:
	var registry: TerrainRegistry = _build_door_line_registry()
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var los_system = LINE_OF_SIGHT_SCRIPT.new()
	var source_world: Vector2 = registry.grid_to_world(Vector2i(0, 0))
	var target_world: Vector2 = registry.grid_to_world(Vector2i(2, 0))

	_assert(not bool(registry.is_walkable(Vector2i(1, 0))), "Closed static door tile starts non-walkable")
	_assert(bool(registry.get_tile_at_grid(Vector2i(1, 0)).blocks_los), "Closed static door tile starts as LOS blocker")
	_assert(pathfinder.find_path(Vector2i(0, 0), Vector2i(2, 0), registry).is_empty(), "Closed static door blocks path")
	_assert(not bool(los_system.has_line_of_sight_with_terrain(source_world, target_world, registry, 9999.0)), "Closed static door blocks LOS")

	var open_snapshot: Dictionary = Dictionary(DOOR_RUNTIME_COLLISION_LOS_SCRIPT.call("build_snapshot", {
		"schema": "test.object_reaction",
		"entries": [_door_reaction_entry("door_runtime", "open", Vector2i(1, 0))],
	}))
	registry.set_runtime_tile_overrides(Array(open_snapshot.get("overrides", [])))
	_assert(bool(registry.is_walkable(Vector2i(1, 0))), "Open runtime override makes door tile walkable")
	_assert(not bool(registry.blocks_los_at_grid(Vector2i(1, 0))), "Open runtime override clears door LOS blocker")
	_assert(int(registry.get_object_height_at_grid(Vector2i(1, 0))) == 0, "Open runtime override clears object height")
	_assert(not pathfinder.find_path(Vector2i(0, 0), Vector2i(2, 0), registry).is_empty(), "Open runtime override opens path")
	_assert(bool(los_system.has_line_of_sight_with_terrain(source_world, target_world, registry, 9999.0)), "Open runtime override opens LOS")
	_assert(not bool(registry.get_tile_at_grid(Vector2i(1, 0)).walkable), "Open override does not mutate stored tile walkability")
	_assert(bool(registry.get_tile_at_grid(Vector2i(1, 0)).blocks_los), "Open override does not mutate stored tile LOS")

	var closed_snapshot: Dictionary = Dictionary(DOOR_RUNTIME_COLLISION_LOS_SCRIPT.call("build_snapshot", {
		"schema": "test.object_reaction",
		"entries": [_door_reaction_entry("door_runtime", "closed", Vector2i(1, 0))],
	}))
	registry.set_runtime_tile_overrides(Array(closed_snapshot.get("overrides", [])))
	_assert(not bool(registry.is_walkable(Vector2i(1, 0))), "Closed runtime override blocks movement again")
	_assert(bool(registry.blocks_los_at_grid(Vector2i(1, 0))), "Closed runtime override blocks LOS again")
	_assert(pathfinder.find_path(Vector2i(0, 0), Vector2i(2, 0), registry).is_empty(), "Closed runtime override closes path again")
	_assert(not bool(los_system.has_line_of_sight_with_terrain(source_world, target_world, registry, 9999.0)), "Closed runtime override closes LOS again")


func _build_door_line_registry() -> TerrainRegistry:
	var registry: TerrainRegistry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	registry.register_tile(_tile(Vector2i(0, 0), true, false, 0))
	registry.register_tile(_tile(Vector2i(1, 0), false, true, 1))
	registry.register_tile(_tile(Vector2i(2, 0), true, false, 0))
	return registry


func _tile(grid_position: Vector2i, walkable: bool, blocks_los: bool, object_height: int):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
		"type_id": "station_floor",
		"object_type_id": "station_set_door_single_closed" if grid_position == Vector2i(1, 0) else "",
		"grid_position": grid_position,
		"world_position": Vector2(float(grid_position.x) * 64.0, float(grid_position.y) * 32.0),
		"walkable": walkable,
		"blocks_los": blocks_los,
		"cover_value": 20 if blocks_los else 0,
		"height_level": 0,
		"object_height": object_height,
		"surface_type": "ground",
		"edge_type": "none",
	})


func _visual_entry(interaction_id: String, status: String, progress: float, grid_position: Vector2i) -> Dictionary:
	return {
		"interaction_id": interaction_id,
		"interaction_type": "door",
		"token": "DOOR",
		"status": status,
		"progress": progress,
		"world_position": Vector2(float(grid_position.x) * 64.0, float(grid_position.y) * 32.0),
		"grid_position": grid_position,
		"is_next": false,
	}


func _door_reaction_entry(interaction_id: String, runtime_visual_state: String, grid_position: Vector2i) -> Dictionary:
	return {
		"interaction_id": interaction_id,
		"marker_id": interaction_id,
		"object_kind": "door",
		"runtime_visual_state": runtime_visual_state,
		"grid_position": grid_position,
		"world_position": Vector2(float(grid_position.x) * 64.0, float(grid_position.y) * 32.0),
	}


func _override_bool(overrides: Array, grid_position: Vector2i, field_name: String) -> bool:
	for override_variant in overrides:
		if typeof(override_variant) != TYPE_DICTIONARY:
			continue
		var override: Dictionary = Dictionary(override_variant)
		if Vector2i(override.get("grid_position", Vector2i.ZERO)) == grid_position:
			return bool(override.get(field_name, false))
	return false


func _override_int(overrides: Array, grid_position: Vector2i, field_name: String) -> int:
	for override_variant in overrides:
		if typeof(override_variant) != TYPE_DICTIONARY:
			continue
		var override: Dictionary = Dictionary(override_variant)
		if Vector2i(override.get("grid_position", Vector2i.ZERO)) == grid_position:
			return int(override.get(field_name, 0))
	return 0


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _write_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.door_runtime_collision_los_contract_manifest.v1",
		"task_id": "TASK_692",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"terrain_map_data_mutated": false,
		"registry_effective_override": true,
		"pathfinder_uses_effective_walkability": true,
		"los_uses_effective_blocks": true,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_692 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_692 manifest is written")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
