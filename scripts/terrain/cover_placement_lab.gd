class_name CoverPlacementLab
extends RefCounted

const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")

const DEFAULT_SEED: int = 152
const DEFAULT_MIN_GRID_DISTANCE: int = 3
const DEFAULT_MAX_COUNT: int = 8
const DEFAULT_COVER_VALUE: int = 45
const DEFAULT_EXPOSURE_MAX_GRID_DISTANCE: float = 10.0

var _pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()


func generate_cover_patches(registry, options: Dictionary = {}) -> Dictionary:
	var seed: int = int(options.get("seed", DEFAULT_SEED))
	var max_count: int = maxi(int(options.get("max_count", DEFAULT_MAX_COUNT)), 0)
	var min_grid_distance: int = maxi(int(options.get("min_grid_distance", DEFAULT_MIN_GRID_DISTANCE)), 0)
	var cover_value: int = clampi(int(options.get("cover_value", DEFAULT_COVER_VALUE)), 0, 100)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var candidates: Array = _build_scored_candidates(registry, options, rng)
	var selected: Array = []
	var selected_grids: Array = []
	for candidate_variant in candidates:
		if selected.size() >= max_count:
			break
		var candidate: Dictionary = Dictionary(candidate_variant)
		var grid: Vector2i = Vector2i(candidate.get("grid_position", Vector2i.ZERO))
		if not _keeps_minimum_distance(grid, selected_grids, min_grid_distance):
			continue
		selected.append(candidate)
		selected_grids.append(grid)

	var patches: Array = []
	for selected_variant in selected:
		var selected_candidate: Dictionary = Dictionary(selected_variant)
		var patch: Dictionary = {
			"grid_position": Vector2i(selected_candidate.get("grid_position", Vector2i.ZERO)),
			"cover_value": cover_value,
			"score": float(selected_candidate.get("score", 0.0)),
			"source": "seeded_cover_placement_lab",
		}
		if bool(options.get("emit_blocks_los", false)):
			patch["blocks_los"] = bool(selected_candidate.get("threat_visible", false))
		if bool(options.get("emit_walkable", false)):
			patch["walkable"] = true
		patches.append(patch)

	return {
		"schema_version": 1,
		"lab_id": "seeded_cover_placement_lab_v1",
		"seed": seed,
		"max_count": max_count,
		"min_grid_distance": min_grid_distance,
		"cover_value": cover_value,
		"candidate_count": candidates.size(),
		"selected_count": selected.size(),
		"candidates": candidates,
		"selected": selected,
		"selected_grids": selected_grids,
		"patches": patches,
	}


func score_grid(grid_position: Vector2i, registry, options: Dictionary = {}) -> Dictionary:
	if registry == null or not registry.has_method("get_tile_at_grid") or not registry.has_method("is_walkable"):
		return {}
	var tile_data = registry.call("get_tile_at_grid", grid_position)
	if tile_data == null or not bool(registry.call("is_walkable", grid_position)):
		return {}
	return _score_tile(tile_data, registry, options, 0.0)


func build_patch_dictionary(grid_position: Vector2i, cover_value: int = DEFAULT_COVER_VALUE, blocks_los: bool = false) -> Dictionary:
	var patch: Dictionary = {
		"grid_position": grid_position,
		"cover_value": clampi(cover_value, 0, 100),
		"source": "seeded_cover_placement_lab",
	}
	if blocks_los:
		patch["blocks_los"] = true
	return patch


func _build_scored_candidates(registry, options: Dictionary, rng: RandomNumberGenerator) -> Array:
	var result: Array = []
	if registry == null or not registry.has_method("get_sorted_tiles") or not registry.has_method("is_walkable"):
		return result
	var respect_existing_cover: bool = bool(options.get("respect_existing_cover", true))
	for tile_data in Array(registry.call("get_sorted_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		if not bool(registry.call("is_walkable", grid)):
			continue
		if respect_existing_cover and int(tile_data.cover_value) > 0:
			continue
		var jitter: float = rng.randf() * 0.001
		var scored: Dictionary = _score_tile(tile_data, registry, options, jitter)
		if float(scored.get("score", 0.0)) <= 0.0:
			continue
		result.append(scored)
	result.sort_custom(_sort_scored_candidates)
	return result


func _score_tile(tile_data, registry, options: Dictionary, jitter: float) -> Dictionary:
	var grid: Vector2i = Vector2i(tile_data.grid_position)
	var threat_grids: Array = _normalize_grid_array(Array(options.get("threat_grids", [])))
	var objective_grids: Array = _normalize_grid_array(Array(options.get("objective_grids", [])))
	var approach_grids: Array = _normalize_grid_array(Array(options.get("approach_grids", [])))
	var exposure_options: Dictionary = {
		"cover_aware_enabled": true,
		"hazard_grids": threat_grids,
		"exposure_max_grid_distance": float(options.get("exposure_max_grid_distance", DEFAULT_EXPOSURE_MAX_GRID_DISTANCE)),
	}
	var exposure_score: float = _pathfinder.call("get_exposure_score", grid, registry, exposure_options)
	var threat_visible: bool = exposure_score > 0.0
	var objective_bonus: float = _nearest_bonus(grid, objective_grids, float(options.get("objective_bonus_distance", 8.0)))
	var approach_bonus: float = _nearest_bonus(grid, approach_grids, float(options.get("approach_bonus_distance", 8.0)))
	var existing_cover_penalty: float = clampf(float(tile_data.cover_value) / 100.0, 0.0, 1.0)
	var score: float = (
		exposure_score * float(options.get("threat_weight", 1.0))
		+ objective_bonus * float(options.get("objective_weight", 0.35))
		+ approach_bonus * float(options.get("approach_weight", 0.2))
		- existing_cover_penalty * float(options.get("existing_cover_penalty_weight", 0.5))
		+ jitter
	)
	return {
		"grid_position": grid,
		"score": score,
		"exposure_score": exposure_score,
		"threat_visible": threat_visible,
		"objective_bonus": objective_bonus,
		"approach_bonus": approach_bonus,
		"existing_cover_value": int(tile_data.cover_value),
	}


func _nearest_bonus(grid: Vector2i, anchors: Array, max_distance: float) -> float:
	if anchors.is_empty():
		return 0.0
	var resolved_max: float = maxf(max_distance, 0.001)
	var best: float = 0.0
	for anchor_variant in anchors:
		var anchor: Vector2i = Vector2i(anchor_variant)
		var distance: float = _grid_distance(grid, anchor)
		if distance > resolved_max:
			continue
		best = maxf(best, 1.0 - clampf(distance / resolved_max, 0.0, 1.0))
	return best


func _keeps_minimum_distance(grid: Vector2i, selected_grids: Array, min_grid_distance: int) -> bool:
	for selected_variant in selected_grids:
		if _grid_distance(grid, Vector2i(selected_variant)) < float(min_grid_distance):
			return false
	return true


func _grid_distance(a: Vector2i, b: Vector2i) -> float:
	var delta: Vector2i = a - b
	return maxf(absf(float(delta.x)), absf(float(delta.y)))


func _normalize_grid_array(values: Array) -> Array:
	var result: Array = []
	for value in values:
		var grid: Vector2i = Vector2i(value)
		if not result.has(grid):
			result.append(grid)
	return result


func _sort_scored_candidates(a: Dictionary, b: Dictionary) -> bool:
	var score_a: float = float(a.get("score", 0.0))
	var score_b: float = float(b.get("score", 0.0))
	if absf(score_a - score_b) > 0.000001:
		return score_a > score_b
	var grid_a: Vector2i = Vector2i(a.get("grid_position", Vector2i.ZERO))
	var grid_b: Vector2i = Vector2i(b.get("grid_position", Vector2i.ZERO))
	if grid_a.x == grid_b.x:
		return grid_a.y < grid_b.y
	return grid_a.x < grid_b.x
