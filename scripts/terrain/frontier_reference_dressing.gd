extends RefCounted
## Bounded visual dressing only. MapData/Registry remain the gameplay authority.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const FOG = preload("res://scripts/core/fog_of_war_mode_contract.gd")
const LAYOUT_ID := "gm01_frontier_outpost_v1"
const DEFAULT_SEED := 61106
const MAX_CANDIDATES := 512
const MAX_AGAVES := 160
const MAX_GRAVEL := 320
const LAYER_NAME := "ReferenceGroundDressing"
const CACHE_KEY := "_reference_dressing_state"


static func build_plan(map_data, context: Dictionary, seed: int = DEFAULT_SEED) -> Dictionary:
	var result := {"placements": [], "seed": seed, "candidate_checks": 0, "signature": "", "read_only": true, "sets_gameplay_truth": false}
	if map_data == null or not map_data.has_method("get_grid_topology") or not map_data.has_method("get_authored_visual_layout_id") or not map_data.has_method("get_tiles"):
		return result
	if map_data.call("get_grid_topology") != HEX.TOPOLOGY_ID or map_data.call("get_authored_visual_layout_id") != LAYOUT_ID:
		return result
	var centers: Array[Vector2] = []
	for center in context.get("cluster_centers", []):
		if center is Vector2 and Vector2(center).is_finite():
			centers.append(center)
	# Builder enumeration order is not part of a semantic cluster identity.
	# Sort only our finite local copy, preserving the producer's original array.
	centers.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x if a.x != b.x else a.y < b.y)
	if centers.is_empty():
		return result
	# One cold source read, then bounded indexed queries. Never call MapData's
	# linear get_tile_at_grid for each decorative instance.
	var by_grid := {}
	for tile in map_data.call("get_tiles"):
		if tile != null:
			by_grid[Vector2i(tile.grid_position)] = tile
	var placements: Array = []
	var used_ids := {}
	var counts := {"agave": 0, "gravel": 0}
	for candidate in range(MAX_CANDIDATES):
		result["candidate_checks"] = candidate + 1
		var center: Vector2 = centers[candidate % centers.size()]
		var angle := _sample(seed, candidate, 13) * TAU
		var distance := 0.8 + sqrt(_sample(seed, candidate, 29)) * 3.2
		var grid: Vector2i = HEX.round_axial(HEX.plane_to_axial(center + Vector2.from_angle(angle) * distance))
		var tile = by_grid.get(grid)
		if tile == null or not tile.walkable or tile.height_level != 0 or not String(tile.object_type_id).is_empty() or not String(tile.surface_type) in ["sand", "ground"]:
			continue
		var kind := "agave" if candidate % 3 == 0 else "gravel"
		if int(counts[kind]) >= (MAX_AGAVES if kind == "agave" else MAX_GRAVEL):
			continue
		var semantic_id := "r3:%s:%d:%d" % [kind, grid.x, grid.y]
		if used_ids.has(semantic_id):
			continue
		var salt := grid.x * 73856093 ^ grid.y * 19349663
		var radius := lerpf(0.22, 0.31, _sample(seed, salt, 31)) if kind == "agave" else lerpf(0.045, 0.085, _sample(seed, salt, 43))
		var jitter := Vector2.from_angle(_sample(seed, salt, 47) * TAU) * _sample(seed, salt, 53) * 0.13
		var point: Vector2 = HEX.axial_to_plane(Vector2(grid)) + jitter
		if not _footprint_clear(point, radius, context):
			continue
		var height := lerpf(0.28, 0.42, _sample(seed, salt, 61)) if kind == "agave" else lerpf(0.06, 0.12, _sample(seed, salt, 67))
		placements.append({"id": semantic_id, "kind": kind, "tile_id": String(tile.tile_id), "grid_position": grid,
			"plane_position": point, "ground_y": 0.0, "radius": radius, "height": height, "rotation": _sample(seed, salt, 71) * TAU})
		used_ids[semantic_id] = true
		counts[kind] = int(counts[kind]) + 1
	placements.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	result["placements"] = placements
	result["signature"] = var_to_str(placements).sha256_text()
	return result


static func _sample(seed: int, coordinate: int, salt: int) -> float:
	# Stable integer domain; no wall clock, shared RNG stream or instance ID.
	var value := (seed ^ coordinate ^ (salt * 83492791)) & 0x7fffffff
	value = ((value ^ (value >> 13)) * 1274126177) & 0x7fffffff
	return float(value) / 2147483647.0


static func _footprint_clear(point: Vector2, radius: float, context: Dictionary) -> bool:
	for blocker in context.get("blockers", []):
		var rect: Rect2 = blocker.get("rect", Rect2())
		if rect.grow(radius + 0.3).has_point(point):
			return false
	for pad in context.get("pad_rects", []):
		if Rect2(pad).grow(radius + 0.8).has_point(point):
			return false
	for door in context.get("door_points", []):
		if point.distance_squared_to(door) < pow(radius + 0.85, 2.0):
			return false
	for path in context.get("paths", []):
		var samples := PackedVector2Array(path.get("samples", path.get("points", [])))
		var clearance := float(path.get("width", 0.0)) * 0.5 + radius + 0.25
		for index in range(1, samples.size()):
			if point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point, samples[index - 1], samples[index])) < clearance * clearance:
				return false
	return true


static func install(parent: Node3D, plan: Dictionary, sources: Dictionary) -> Dictionary:
	var rejected := {"installed": false, "layer": null, "reason": "invalid_source_or_plan"}
	var placements: Array = plan.get("placements", [])
	if parent == null or placements.is_empty() or placements.size() > MAX_AGAVES + MAX_GRAVEL:
		return rejected
	for kind in ["agave", "gravel"]:
		var mesh := sources.get(kind + "_mesh") as Mesh
		var material := sources.get(kind + "_material") as Material
		if mesh == null or material == null or mesh.get_aabb().size.y <= 0.00001 or Vector2(mesh.get_aabb().size.x, mesh.get_aabb().size.z).length() <= 0.00001:
			return rejected
	var by_kind := {"agave": [], "gravel": []}
	var semantic_ids := {}
	for placement in placements:
		if not placement is Dictionary:
			return rejected
		var kind := String(placement.get("kind", ""))
		if not by_kind.has(kind) or not placement.get("plane_position") is Vector2 or not placement.get("grid_position") is Vector2i:
			return rejected
		var point: Vector2 = placement["plane_position"]
		var grid: Vector2i = placement["grid_position"]
		var radius := float(placement.get("radius", 0.0))
		var height := float(placement.get("height", 0.0))
		var id := String(placement.get("id", ""))
		if not point.is_finite() or not is_finite(radius) or not is_finite(height) or radius <= 0.0 or height <= 0.0 or height > (0.42 if kind == "agave" else 0.12) or point.distance_to(HEX.axial_to_plane(Vector2(grid))) + radius > 0.49:
			return rejected
		if not is_finite(float(placement.get("rotation", NAN))) or float(placement.get("ground_y", -1.0)) != 0.0 or id.is_empty() or semantic_ids.has(id) or String(placement.get("tile_id", "")).is_empty():
			return rejected
		semantic_ids[id] = true
		by_kind[kind].append(placement)
	if by_kind["agave"].size() > MAX_AGAVES or by_kind["gravel"].size() > MAX_GRAVEL:
		return rejected
	# Recompute from validated records instead of trusting a caller's signature.
	# A cold map revalidation may find the same plan: keep existing GPU buffers,
	# published slot states and their resource owners intact in that case.
	var canonical_signature := var_to_str(placements).sha256_text()
	if String(plan.get("signature", "")) != canonical_signature:
		return rejected
	var previous := parent.get_node_or_null(NodePath(LAYER_NAME)) as Node3D
	if is_instance_valid(previous) and previous.has_meta(CACHE_KEY):
		var old_cache: Dictionary = previous.get_meta(CACHE_KEY)
		var old_sources: Dictionary = old_cache.get("sources", {})
		var same_sources := true
		for kind in ["agave", "gravel"]:
			same_sources = same_sources and old_sources.get(kind + "_mesh") == sources[kind + "_mesh"] and old_sources.get(kind + "_material") == sources[kind + "_material"]
		if String(old_cache.get("signature", "")) == canonical_signature and same_sources:
			return {"installed": true, "reused": true, "layer": previous, "reason": "unchanged", "read_only": true, "sets_gameplay_truth": false}
	# Build entirely off-tree. Even the first GPU upload contains hidden slots.
	var layer := Node3D.new()
	layer.name = LAYER_NAME
	layer.visible = false
	layer.set_process(false)
	var slots: Array = []
	var batches: Array = []
	for kind in ["agave", "gravel"]:
		var mesh: Mesh = sources[kind + "_mesh"]
		var batch := MultiMeshInstance3D.new()
		batch.name = "AgaveBatch" if kind == "agave" else "GravelBatch"
		batch.material_override = sources[kind + "_material"]
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = by_kind[kind].size()
		batch.multimesh = multi
		layer.add_child(batch)
		batches.append(batch)
		var first := true
		var batch_bounds := AABB()
		for index in range(by_kind[kind].size()):
			var placement: Dictionary = by_kind[kind][index]
			var transform := _source_transform(mesh.get_aabb(), placement)
			var slot: Dictionary = placement.duplicate()
			slot["base_transform"] = transform
			slot["batch"] = batch
			slot["index"] = index
			slot["visible"] = false
			slots.append(slot)
			multi.set_instance_transform(index, _hidden_transform(placement))
			var bounds: AABB = transform * mesh.get_aabb()
			batch_bounds = bounds if first else batch_bounds.merge(bounds)
			first = false
		multi.custom_aabb = batch_bounds
	var cache := {"slots": slots, "batches": batches, "sources": sources.duplicate(), "seed": int(plan.get("seed", DEFAULT_SEED)), "signature": canonical_signature,
		"candidate_checks": int(plan.get("candidate_checks", 0)), "mode": "", "visibility_initialized": false, "visible_count": 0,
		"last_cell_lookups": 0, "last_transform_writes": 0, "total_cell_lookups": 0, "total_transform_writes": 0, "visibility_publications": 0}
	layer.set_meta(CACHE_KEY, cache)
	if previous != null:
		parent.remove_child(previous)
		previous.free()
	parent.add_child(layer)
	return {"installed": true, "reused": false, "layer": layer, "reason": "installed", "read_only": true, "sets_gameplay_truth": false}


static func _source_transform(bounds: AABB, placement: Dictionary) -> Transform3D:
	var horizontal_scale := float(placement["radius"]) / (Vector2(bounds.size.x, bounds.size.z).length() * 0.5)
	var vertical_scale := float(placement["height"]) / bounds.size.y
	var basis := Basis(Vector3.UP, float(placement["rotation"])).scaled(Vector3(horizontal_scale, vertical_scale, horizontal_scale))
	var point: Vector2 = placement["plane_position"]
	var source_origin := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	var target := Vector3(point.x, float(placement["ground_y"]), point.y)
	return Transform3D(basis, target - basis * source_origin)


static func _hidden_transform(placement: Dictionary) -> Transform3D:
	var point: Vector2 = placement["plane_position"]
	return Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3(point.x, float(placement["ground_y"]), point.y))


static func apply_visibility(layer: Node3D, mode: String, cell_states: Dictionary) -> Dictionary:
	if not is_instance_valid(layer) or not layer.has_meta(CACHE_KEY):
		return {}
	var cache: Dictionary = layer.get_meta(CACHE_KEY)
	var lookups := 0
	var writes := 0
	var visible_count := 0
	for slot in cache["slots"]:
		var admitted := mode == FOG.MODE_OFF or mode == FOG.MODE_KNOWN_TERRAIN
		if mode == FOG.MODE_UNEXPLORED_BLACKOUT:
			lookups += 1
			var state := String(cell_states.get(slot["tile_id"], "unknown"))
			admitted = state == "visible" or state == "explored"
		if admitted:
			visible_count += 1
		if admitted != bool(slot["visible"]):
			var batch: MultiMeshInstance3D = slot["batch"]
			batch.multimesh.set_instance_transform(int(slot["index"]), slot["base_transform"] if admitted else _hidden_transform(slot))
			slot["visible"] = admitted
			writes += 1
	cache["mode"] = mode
	cache["visibility_initialized"] = true
	cache["visible_count"] = visible_count
	cache["last_cell_lookups"] = lookups
	cache["last_transform_writes"] = writes
	cache["total_cell_lookups"] = int(cache["total_cell_lookups"]) + lookups
	cache["total_transform_writes"] = int(cache["total_transform_writes"]) + writes
	cache["visibility_publications"] = int(cache["visibility_publications"]) + 1
	layer.visible = true
	return get_snapshot(layer)


static func get_snapshot(layer: Node3D) -> Dictionary:
	if not is_instance_valid(layer) or not layer.has_meta(CACHE_KEY):
		return {"installed": false, "batch_count": 0, "instance_count": 0}
	var cache: Dictionary = layer.get_meta(CACHE_KEY)
	# Scalars only. Do not clone hundreds of slot records on HUD/debug reads.
	return {"installed": true, "batch_count": Array(cache["batches"]).size(), "instance_count": Array(cache["slots"]).size(),
		"seed": cache["seed"], "signature": cache["signature"], "candidate_checks": cache["candidate_checks"],
		"mode": cache["mode"], "visibility_initialized": cache["visibility_initialized"], "visible_count": cache["visible_count"],
		"last_cell_lookups": cache["last_cell_lookups"], "last_transform_writes": cache["last_transform_writes"],
		"total_cell_lookups": cache["total_cell_lookups"], "total_transform_writes": cache["total_transform_writes"],
		"visibility_publications": cache["visibility_publications"], "read_only": true, "sets_gameplay_truth": false}
