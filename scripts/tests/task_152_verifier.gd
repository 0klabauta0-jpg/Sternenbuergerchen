extends SceneTree

const COVER_PLACEMENT_LAB_SCRIPT: GDScript = preload("res://scripts/terrain/cover_placement_lab.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_152 Seeded Cover Placement Lab Verifier ===")
	_test_same_seed_is_reproducible()
	_test_minimum_distance_and_walkability()
	_test_los_threat_score_changes_candidate_order()
	_test_patch_output_and_cover_aware_metrics()
	_test_docs_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_same_seed_is_reproducible() -> void:
	var registry: Node = _make_registry(8, 4)
	var lab = COVER_PLACEMENT_LAB_SCRIPT.new()
	var options: Dictionary = {
		"seed": 152,
		"max_count": 5,
		"min_grid_distance": 2,
		"threat_grids": [Vector2i(0, 1)],
		"objective_grids": [Vector2i(7, 2)],
		"approach_grids": [Vector2i(4, 2)],
	}
	var first: Dictionary = Dictionary(lab.call("generate_cover_patches", registry, options))
	var second: Dictionary = Dictionary(lab.call("generate_cover_patches", registry, options))
	_assert(Array(first.get("selected_grids", [])) == Array(second.get("selected_grids", [])), "Same seed returns the same selected grids")
	_assert(Array(first.get("patches", [])) == Array(second.get("patches", [])), "Same seed returns the same patch payload")
	_assert(int(first.get("selected_count", 0)) == 5, "Lab respects max cover count")
	registry.queue_free()


func _test_minimum_distance_and_walkability() -> void:
	var blocked: Dictionary = {Vector2i(2, 2): true, Vector2i(3, 2): true}
	var registry: Node = _make_registry(7, 5, blocked)
	var lab = COVER_PLACEMENT_LAB_SCRIPT.new()
	var result: Dictionary = Dictionary(lab.call("generate_cover_patches", registry, {
		"seed": 9,
		"max_count": 6,
		"min_grid_distance": 2,
		"threat_grids": [Vector2i(0, 2)],
		"objective_grids": [Vector2i(6, 2)],
		"emit_walkable": true,
	}))
	var selected_grids: Array = Array(result.get("selected_grids", []))
	for grid_variant in selected_grids:
		var grid: Vector2i = Vector2i(grid_variant)
		_assert(bool(registry.call("is_walkable", grid)), "Selected cover grid is walkable: %s" % [grid])
	_assert(not selected_grids.has(Vector2i(2, 2)) and not selected_grids.has(Vector2i(3, 2)), "Non-walkable tiles are skipped")
	_assert(_minimum_grid_distance(selected_grids) >= 2.0, "Selected cover grids respect minimum distance")
	for patch_variant in Array(result.get("patches", [])):
		_assert(bool(Dictionary(patch_variant).get("walkable", false)), "Patch can explicitly preserve walkable=true when requested")
	registry.queue_free()


func _test_los_threat_score_changes_candidate_order() -> void:
	var registry: Node = _make_registry(6, 5, {}, {Vector2i(3, 2): true})
	var lab = COVER_PLACEMENT_LAB_SCRIPT.new()
	var options: Dictionary = {
		"threat_grids": [Vector2i(0, 2)],
		"objective_weight": 0.0,
		"approach_weight": 0.0,
	}
	var visible_score: Dictionary = Dictionary(lab.call("score_grid", Vector2i(2, 2), registry, options))
	var blocked_score: Dictionary = Dictionary(lab.call("score_grid", Vector2i(4, 2), registry, options))
	_assert(bool(visible_score.get("threat_visible", false)), "Visible candidate sees the threat")
	_assert(not bool(blocked_score.get("threat_visible", true)), "LOS-blocked candidate does not see the threat")
	_assert(float(visible_score.get("score", 0.0)) > float(blocked_score.get("score", 0.0)), "Threat/LOS score ranks exposed useful cover higher")
	registry.queue_free()


func _test_patch_output_and_cover_aware_metrics() -> void:
	var registry: Node = _make_registry(7, 3)
	var lab = COVER_PLACEMENT_LAB_SCRIPT.new()
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var path: Array = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1)]
	var score_options: Dictionary = {"cover_aware_enabled": true, "hazard_grids": [Vector2i(0, 1)], "exposure_max_grid_distance": 8.0}
	var before: Dictionary = Dictionary(pathfinder.call("score_path", path, registry, score_options))
	var result: Dictionary = Dictionary(lab.call("generate_cover_patches", registry, {
		"seed": 44,
		"max_count": 3,
		"min_grid_distance": 2,
		"threat_grids": [Vector2i(0, 1)],
		"objective_grids": [Vector2i(6, 1)],
		"approach_grids": [Vector2i(3, 1)],
		"cover_value": 60,
		"emit_blocks_los": true,
	}))
	var patches: Array = Array(result.get("patches", []))
	_assert(not patches.is_empty(), "Lab emits terrain patch dictionaries")
	for patch_variant in patches:
		var patch: Dictionary = Dictionary(patch_variant)
		_assert(patch.has("grid_position") and patch.has("cover_value"), "Patch contains grid_position and cover_value")
	_apply_patches(registry, patches)
	var after: Dictionary = Dictionary(pathfinder.call("score_path", path, registry, score_options))
	_assert(float(after.get("cover_sum", 0.0)) > float(before.get("cover_sum", 0.0)), "Applying generated patches improves cover-aware path cover metric")
	_assert(float(after.get("mean_exposure", 0.0)) <= float(before.get("mean_exposure", 0.0)) + 0.001, "Generated cover patches do not worsen mean exposure metric")
	registry.queue_free()


func _test_docs_status() -> void:
	var task_text: String = _read_text("res://docs/tasks/TASK_152_seeded_cover_placement_lab.md")
	var status_text: String = _read_text("res://docs/IMPLEMENTATION_STATUS.md")
	var roadmap_text: String = _read_text("res://docs/TASK_ROADMAP.md")
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_152 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_152 - Seeded Cover Placement Lab") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_152 implemented")
	_assert(roadmap_text.contains("TASK_152 - Seeded Cover Placement Lab (implementiert)"), "Roadmap marks TASK_152 implemented")


func _make_registry(width: int, height: int, blocked_grids: Dictionary = {}, los_blockers: Dictionary = {}) -> Node:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(width):
		for y in range(height):
			var grid := Vector2i(x, y)
			var blocked: bool = bool(blocked_grids.get(grid, false))
			registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
				"tile_id": "%d_%d" % [grid.x, grid.y],
				"type_id": "ground_flat" if not blocked else "rock_large",
				"grid_position": grid,
				"world_position": registry.grid_to_world(grid),
				"walkable": not blocked,
				"surface_type": "ground",
				"blocks_los": bool(los_blockers.get(grid, false)),
				"object_height": 1 if bool(los_blockers.get(grid, false)) else 0,
				"cover_value": 0,
			}))
	root.add_child(registry)
	return registry


func _apply_patches(registry: Node, patches: Array) -> void:
	for patch_variant in patches:
		var patch: Dictionary = Dictionary(patch_variant)
		var tile_data = registry.call("get_tile_at_grid", Vector2i(patch.get("grid_position", Vector2i.ZERO)))
		if tile_data == null:
			continue
		tile_data.cover_value = int(patch.get("cover_value", tile_data.cover_value))
		if patch.has("blocks_los"):
			tile_data.blocks_los = bool(patch.get("blocks_los", tile_data.blocks_los))


func _minimum_grid_distance(grids: Array) -> float:
	if grids.size() < 2:
		return INF
	var minimum_distance: float = INF
	for index_a in range(grids.size()):
		for index_b in range(index_a + 1, grids.size()):
			var delta: Vector2i = Vector2i(grids[index_a]) - Vector2i(grids[index_b])
			minimum_distance = minf(minimum_distance, maxf(absf(float(delta.x)), absf(float(delta.y))))
	return minimum_distance


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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
