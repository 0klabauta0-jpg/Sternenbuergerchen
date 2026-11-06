extends SceneTree
## Component evidence only. Root owns the separate native two-camera GPU gate.
const HELPER_PATH := "res://scripts/terrain/frontier_reference_dressing.gd"
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const LAYOUT = preload("res://scripts/terrain/frontier_gm01_layout.gd")
var passed := 0
var failed := 0


class CountingMap extends RefCounted:
	var tiles: Array = []
	var tile_array_reads := 0
	var linear_point_reads := 0
	var layout_id := "gm01_frontier_outpost_v1"
	var topology := "hex_axial_v1"
	func get_tiles() -> Array:
		tile_array_reads += 1
		return tiles.duplicate()
	func get_tile_at_grid(_grid: Vector2i):
		linear_point_reads += 1
		return null
	func get_authored_visual_layout_id() -> String:
		return layout_id
	func get_grid_topology() -> String:
		return topology


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func run() -> void:
	# Dynamic loading makes the intended pre-product RED explicit and readable.
	check(FileAccess.file_exists(HELPER_PATH), "R3 bounded dressing helper exists")
	if not FileAccess.file_exists(HELPER_PATH):
		_finish()
		return
	var helper: GDScript = load(HELPER_PATH)
	check(helper != null and helper.can_instantiate(), "Dressing helper parses")
	if helper == null or not helper.can_instantiate():
		_finish()
		return
	var fixture := _fixture_map()
	var context := _fixture_context()
	var original_context: Dictionary = context.duplicate(true)
	var before := _tile_snapshot(fixture.tiles)
	var plan: Dictionary = helper.call("build_plan", fixture, context, 61106)
	check(not Array(plan.get("placements", [])).is_empty(), "Real source-cell plan produces clustered decoration")
	check(fixture.tile_array_reads == 1 and fixture.linear_point_reads == 0, "One cold tile collection; zero per-instance linear MapData searches")
	check(int(plan.get("candidate_checks", 99999)) <= 512, "Candidate validation stays within the 512-cell bound")
	var reversed := _fixture_map()
	reversed.tiles.reverse()
	var reversed_plan: Dictionary = helper.call("build_plan", reversed, context, 61106)
	check(plan == reversed_plan, "Map array order cannot move, renumber or reroll the visual plan")
	var permuted_context: Dictionary = context.duplicate(true)
	permuted_context["cluster_centers"].reverse()
	var original_permutation: Dictionary = permuted_context.duplicate(true)
	var center_permutation_plan: Dictionary = helper.call("build_plan", fixture, permuted_context, 61106)
	check(plan == center_permutation_plan, "A permutation of the same semantic cluster centers cannot reroll a seeded plan")
	check(context == original_context and permuted_context == original_permutation, "Planning preserves both source contexts and their original center-array order")
	var another_seed: Dictionary = helper.call("build_plan", reversed, context, 61107)
	check(plan != another_seed and plan.get("placements", []) != another_seed.get("placements", []), "A different seed changes placement variants without wall-clock randomness")
	check(before == _tile_snapshot(fixture.tiles), "Pure planning preserves every source TileData value")
	_assert_plan_cells(plan, fixture.tiles, context)
	var unsupported := _fixture_map()
	unsupported.topology = "square8"
	check(Array(helper.call("build_plan", unsupported, context, 61106).get("placements", [])).is_empty(), "Unsupported topology fails closed")
	unsupported.topology = "hex_axial_v1"
	unsupported.layout_id = "another_map"
	check(Array(helper.call("build_plan", unsupported, context, 61106).get("placements", [])).is_empty(), "Other maps do not inherit GM01 decoration")
	_test_install_and_cell_visibility(helper, plan)
	_test_real_map_read_only(helper)
	_finish()


func _fixture_map() -> CountingMap:
	var fixture := CountingMap.new()
	for q in range(-14, 33):
		for r in range(-12, 27):
			var grid := Vector2i(q, r)
			var data := TILE.new({"tile_id": "fixture_%d_%d" % [q, r], "type_id": "ground_flat", "grid_position": grid, "walkable": true, "height_level": 0, "surface_type": "sand"})
			# Forbidden variants interspersed through every cluster, including negatives.
			match posmod(q * 7 + r * 11, 13):
				0: data.height_level = 1
				1: data.surface_type = "road"
				2: data.walkable = false
				3: data.object_type_id = "frontier_scene_solid"
			fixture.tiles.append(data)
	return fixture


func _fixture_context() -> Dictionary:
	return {
		"cluster_centers": [Vector2(-3.0, 5.0), Vector2(4.0, 4.0), Vector2(12.0, 6.0), Vector2(19.0, 12.0)],
		"blockers": [{"id": "existing_building", "rect": Rect2(6.0, 3.0, 2.0, 3.0), "kind": "building"}],
		"paths": [
			{"id": "existing_service_lane", "width": 1.4, "samples": PackedVector2Array([Vector2(-9.0, 7.0), Vector2(27.0, 7.0)])},
			{"id": "existing_supply_approach", "width": 1.2, "points": [Vector2(20.0, -2.0), Vector2(20.0, 22.0)]},
		],
		"pad_rects": [Rect2(15.0, 10.0, 4.0, 3.0)],
		"door_points": [Vector2(7.0, 6.5)],
	}


func _assert_plan_cells(plan: Dictionary, tiles: Array, context: Dictionary) -> void:
	var source_by_grid := {}
	for tile in tiles:
		source_by_grid[tile.grid_position] = tile
	var ids := {}
	var allowed := true
	var grounded := true
	var footprints_clear := true
	var seen_negative := false
	var counts := {"agave": 0, "gravel": 0}
	for placement in Array(plan.get("placements", [])):
		var grid: Vector2i = placement.get("grid_position", Vector2i(9999, 9999))
		var source = source_by_grid.get(grid)
		var id := String(placement.get("id", ""))
		allowed = allowed and source != null and not id.is_empty() and not ids.has(id)
		ids[id] = true
		if source == null:
			continue
		allowed = allowed and source.walkable and source.height_level == 0 and source.object_type_id.is_empty() and source.surface_type in ["sand", "ground"] and placement.get("tile_id", "") == source.tile_id
		var point: Vector2 = placement.get("plane_position", Vector2.INF)
		var radius := float(placement.get("radius", 10.0))
		var height := float(placement.get("height", 10.0))
		grounded = grounded and point.is_finite() and float(placement.get("ground_y", -1.0)) == 0.0 and point.distance_to(HEX.axial_to_plane(Vector2(grid))) + radius <= 0.49 and radius > 0.0
		var kind := String(placement.get("kind", ""))
		counts[kind] = int(counts.get(kind, 0)) + 1
		grounded = grounded and height > 0.0 and height <= (0.42 if kind == "agave" else 0.12)
		seen_negative = seen_negative or grid.x < 0 or grid.y < 0
		for blocker in context.get("blockers", []):
			footprints_clear = footprints_clear and not Rect2(blocker["rect"]).grow(radius + 0.3).has_point(point)
		for pad in context.get("pad_rects", []):
			footprints_clear = footprints_clear and not Rect2(pad).grow(radius + 0.8).has_point(point)
		for door in context.get("door_points", []):
			footprints_clear = footprints_clear and point.distance_to(door) >= radius + 0.85
		for path in context.get("paths", []):
			var samples := PackedVector2Array(path.get("samples", path.get("points", [])))
			for i in range(1, samples.size()):
				var nearest := Geometry2D.get_closest_point_to_segment(point, samples[i - 1], samples[i])
				footprints_clear = footprints_clear and point.distance_to(nearest) >= float(path["width"]) * 0.5 + radius + 0.25
	check(allowed, "Every instance refers to a real allowed source cell with a unique semantic ID")
	check(grounded and seen_negative, "Whole props stay grounded inside their source Hex, also at negative axial coordinates")
	check(footprints_clear, "Whole footprints preserve actual buildings, service lanes, pads and door clearances")
	check(int(counts.get("agave", 0)) <= 160 and int(counts.get("gravel", 0)) <= 320 and ids.size() <= 480, "Both shape budgets remain bounded")


func _test_install_and_cell_visibility(helper: GDScript, plan: Dictionary) -> void:
	var host := Node3D.new()
	root.add_child(host)
	# Deliberately absolute-XZ prototype catches placement that forgets normalization.
	var vertices := PackedVector3Array([Vector3(8.0, 0.0, 4.0), Vector3(8.6, 0.0, 4.0), Vector3(8.3, 0.8, 4.4)])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var absolute_agave := ArrayMesh.new()
	absolute_agave.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var gravel := SphereMesh.new()
	gravel.radius = 0.06
	gravel.height = 0.09
	gravel.radial_segments = 5
	gravel.rings = 2
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("6d7950")
	var sources := {"agave_mesh": absolute_agave, "agave_material": material, "gravel_mesh": gravel, "gravel_material": material}
	var original_box := absolute_agave.get_aabb()
	var original_material_color := material.albedo_color
	var result: Dictionary = helper.call("install", host, plan, sources)
	var layer := result.get("layer") as Node3D
	check(bool(result.get("installed", false)) and is_instance_valid(layer), "A valid visual plan installs atomically")
	if not is_instance_valid(layer):
		host.free()
		return
	var snapshot: Dictionary = helper.call("get_snapshot", layer)
	check(int(snapshot.get("batch_count", 0)) == 2 and int(snapshot.get("instance_count", 0)) <= 480 and not layer.is_processing(), "Only two bounded static mesh batches are installed")
	check(not layer.visible and not bool(snapshot.get("visibility_initialized", true)) and int(snapshot.get("visible_count", -1)) == 0, "New layer stays hidden until actual terrain visibility is published")
	check(absolute_agave.get_aabb() == original_box and material.albedo_color == original_material_color, "Normalization and visibility do not mutate source geometry or shared materials")
	var reused := true
	var collision_free := true
	for child in layer.get_children():
		collision_free = collision_free and not child is CollisionObject3D
		if child is MultiMeshInstance3D:
			reused = reused and child.multimesh.mesh in [absolute_agave, gravel]
	check(reused and collision_free, "Batches reuse the source mesh resources without collision or gameplay nodes")
	_assert_cached_transforms(layer, sources)
	var states := {}
	var expected := 0
	var expected_explored := 0
	for placement in plan.get("placements", []):
		var id := String(placement["tile_id"])
		if not states.has(id):
			states[id] = "visible" if states.size() % 3 == 0 else ("explored" if states.size() % 3 == 1 else "unknown")
		if states[id] == "visible":
			expected += 1
		if states[id] == "explored":
			expected_explored += 1
	var visibility: Dictionary = helper.call("apply_visibility", layer, "unexplored_blackout", states)
	check(expected > 0 and expected_explored > 0 and int(visibility.get("visible_count", -1)) == expected + expected_explored, "Mixed unknown/current/explored slots in the same batch follow their own source-cell state")
	check(int(visibility.get("last_cell_lookups", 99999)) <= 480 and int(visibility.get("last_transform_writes", 99999)) <= 480, "A visibility publication stays within the per-slot lookup/write bound")
	visibility = helper.call("apply_visibility", layer, "unexplored_blackout", states)
	check(int(visibility.get("last_transform_writes", -1)) == 0, "Unchanged visibility performs no instance transform writes")
	visibility = helper.call("apply_visibility", layer, "known_terrain", {})
	check(int(visibility.get("visible_count", -1)) == int(snapshot.get("instance_count", 0)), "Known-terrain mode admits all static terrain decoration")
	var stale_known := {}
	for placement in plan.get("placements", []):
		stale_known[placement["tile_id"]] = "known"
	visibility = helper.call("apply_visibility", layer, "unexplored_blackout", stale_known)
	check(int(visibility.get("visible_count", -1)) == 0, "Blackout never admits stale known-mode cache values")
	visibility = helper.call("apply_visibility", layer, "off", {})
	check(int(visibility.get("visible_count", -1)) == int(snapshot.get("instance_count", 0)), "Off-mode transition restores static decoration without target data")
	visibility = helper.call("apply_visibility", layer, "unexplored_blackout", {})
	check(int(visibility.get("visible_count", -1)) == 0, "Team/context change with missing cell facts fails closed")
	var previous_layer: WeakRef = weakref(layer)
	var previous_snapshot: Dictionary = helper.call("get_snapshot", layer)
	var previous_batches: Array = Array(layer.get_meta("_reference_dressing_state")["batches"]).duplicate()
	var unchanged: Dictionary = helper.call("install", host, plan, sources)
	var unchanged_layer := unchanged.get("layer") as Node3D
	var previous_batches_alive := true
	for batch in previous_batches:
		previous_batches_alive = previous_batches_alive and is_instance_valid(batch)
	check(bool(unchanged.get("installed", false)) and bool(unchanged.get("reused", false)) and previous_layer.get_ref() == unchanged_layer and previous_batches_alive,
		"Unchanged plan and sources retain the existing layer and both actual MultiMesh resources")
	if not is_instance_valid(unchanged_layer):
		host.free()
		return
	layer = unchanged_layer
	check(helper.call("get_snapshot", layer) == previous_snapshot, "Unchanged installation preserves published visibility and performs no rebuild or transform work")
	var child_count := host.get_child_count()
	var broken: Dictionary = helper.call("install", host, plan, {"agave_mesh": absolute_agave})
	check(not bool(broken.get("installed", true)) and host.get_child_count() == child_count, "Missing source resources cannot leave a partial visual scene")
	var tampered_plan: Dictionary = plan.duplicate(true)
	tampered_plan["placements"][0]["rotation"] += 0.123
	var tampered: Dictionary = helper.call("install", host, tampered_plan, sources)
	check(not bool(tampered.get("installed", true)) and host.get_node("ReferenceGroundDressing") == layer, "A stale caller-supplied signature cannot admit changed placement records")
	var changed_mesh_sources: Dictionary = sources.duplicate()
	changed_mesh_sources["agave_mesh"] = absolute_agave.duplicate()
	var changed_mesh: Dictionary = helper.call("install", host, plan, changed_mesh_sources)
	check(bool(changed_mesh.get("installed", false)) and not bool(changed_mesh.get("reused", true)), "Same geometry in a different actual Mesh resource cannot reuse the old batch")
	var changed_material_sources: Dictionary = changed_mesh_sources.duplicate()
	changed_material_sources["agave_material"] = material.duplicate()
	var changed_material: Dictionary = helper.call("install", host, plan, changed_material_sources)
	check(bool(changed_material.get("installed", false)) and not bool(changed_material.get("reused", true)), "A changed actual Material identity cannot reuse the old batch")
	var replacement_plan: Dictionary = helper.call("build_plan", _fixture_map(), _fixture_context(), 61107)
	var replaced: Dictionary = helper.call("install", host, replacement_plan, sources)
	var replacement := replaced.get("layer") as Node3D
	check(bool(replaced.get("installed", false)) and is_instance_valid(replacement) and host.get_child_count() == 1, "Reinstallation replaces the old local layer instead of retaining stale slots")
	if is_instance_valid(replacement):
		check(not replacement.visible and int(helper.call("get_snapshot", replacement).get("visible_count", -1)) == 0, "Replacement starts hidden instead of inheriting the previous map's visibility")
	host.free()


func _assert_cached_transforms(layer: Node3D, sources: Dictionary) -> void:
	# CPU base transforms are the actual visual cache, not headless GPU readback.
	# This cold white-box check never turns a cache test into rendered evidence.
	var cache: Dictionary = layer.get_meta("_reference_dressing_state", {})
	var slots: Array = cache.get("slots", [])
	var correct := not slots.is_empty()
	for slot in slots:
		var source := sources.get(String(slot.get("kind", "")) + "_mesh") as Mesh
		if source == null or not slot.get("base_transform") is Transform3D:
			correct = false
			continue
		var transform: Transform3D = slot["base_transform"]
		var bounds := source.get_aabb()
		var min_y := INF
		var max_y := -INF
		var point: Vector2 = slot.get("plane_position", Vector2.INF)
		var ground_y := float(slot.get("ground_y", -1.0))
		for corner in range(8):
			var local := bounds.position + bounds.size * Vector3(float(corner & 1), float((corner >> 1) & 1), float((corner >> 2) & 1))
			var actual: Vector3 = transform * local
			min_y = minf(min_y, actual.y)
			max_y = maxf(max_y, actual.y)
			correct = correct and Vector2(actual.x, actual.z).distance_to(point) <= float(slot.get("radius", 0.0)) + 0.0001
		correct = correct and is_equal_approx(min_y, ground_y) and is_equal_approx(max_y - min_y, float(slot.get("height", -1.0)))
	check(correct, "Actual cached source transforms normalize absolute XZ and put every source AABB on the planned ground")


func _test_real_map_read_only(helper: GDScript) -> void:
	var data = MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
	var tiles: Array = data.get_tiles()
	var before := _tile_snapshot(tiles)
	var registry := REGISTRY.new()
	root.add_child(registry)
	for tile in tiles:
		registry.register_tile(tile)
	var revision: int = registry.get_revision()
	var host := Node3D.new()
	root.add_child(host)
	# Existing builder remains the source of actual authored bounds and route widths.
	var facts: Dictionary = LAYOUT.build(host)
	var context := _fixture_context()
	context["blockers"] = facts.get("blockers", [])
	context["paths"] = facts.get("paths", [])
	var plan: Dictionary = helper.call("build_plan", data, context, 61106)
	check(tiles.size() == 9408 and not Array(plan.get("placements", [])).is_empty(), "Planner also consumes the actual saved 9408-cell GM01")
	check(before == _tile_snapshot(data.get_tiles()) and registry.get_revision() == revision, "Real map values and registry revision stay unchanged")
	var dressing: Node = facts["root"].get_node("FrontierWorkingGround")
	var worklife: Node = facts["root"].get_node("FrontierUseGroups")
	var plant := dressing.find_child("DryAgave", true, false) as MeshInstance3D
	var gravel := worklife.get_node("ContactGravelBatch") as MultiMeshInstance3D
	check(plant != null and gravel != null and gravel.multimesh != null, "Actual retained plant and gravel source meshes remain available")
	if plant != null and gravel != null and gravel.multimesh != null:
		var sources := {"agave_mesh": plant.mesh, "agave_material": plant.material_override, "gravel_mesh": gravel.multimesh.mesh, "gravel_material": gravel.material_override}
		var result: Dictionary = helper.call("install", facts["root"], plan, sources)
		check(bool(result.get("installed", false)), "Actual existing native source meshes can populate the visual layer")
		check(before == _tile_snapshot(data.get_tiles()) and registry.get_revision() == revision, "Installing actual source meshes preserves MapData and registry truth")
	# Exercise the public cold-layout wrapper as well as the lower-level installer.
	var first_wrapper: Dictionary = LAYOUT.refresh_reference_dressing(facts, data)
	var wrapper_layer := first_wrapper.get("layer") as Node3D
	check(bool(first_wrapper.get("installed", false)) and is_instance_valid(wrapper_layer), "Actual GM01 cold wrapper installs its real semantic plan")
	if is_instance_valid(wrapper_layer):
		helper.call("apply_visibility", wrapper_layer, "off", {})
		var wrapper_identity: WeakRef = weakref(wrapper_layer)
		var wrapper_snapshot: Dictionary = helper.call("get_snapshot", wrapper_layer)
		var wrapper_batches: Array = Array(wrapper_layer.get_meta("_reference_dressing_state")["batches"]).duplicate()
		var second_wrapper: Dictionary = LAYOUT.refresh_reference_dressing(facts, data)
		var refreshed_layer := second_wrapper.get("layer") as Node3D
		var wrapper_batches_alive := true
		for batch in wrapper_batches:
			wrapper_batches_alive = wrapper_batches_alive and is_instance_valid(batch)
		check(bool(second_wrapper.get("reused", false)) and wrapper_identity.get_ref() == refreshed_layer and wrapper_batches_alive,
			"Unchanged actual-map wrapper refresh preserves the existing layer and both batches")
		check(is_instance_valid(refreshed_layer) and refreshed_layer.visible and helper.call("get_snapshot", refreshed_layer) == wrapper_snapshot,
			"Unchanged actual-map wrapper refresh preserves the published visible property and complete visibility receipt")
	host.free()
	registry.free()


func _tile_snapshot(tiles: Array) -> Array:
	var result := []
	for tile in tiles:
		result.append(tile.to_dict())
	return result


func _finish() -> void:
	print("R3_WORLD_COMPONENT_RESULTS %d passed, %d failed; native GPU gate separate" % [passed, failed])
	print("REFERENCE_R3_WORLD_DRESSING_PASS" if failed == 0 else "REFERENCE_R3_WORLD_DRESSING_FAILED")
	quit(0 if failed == 0 else 1)
