extends SceneTree
## Small integration fixture: actual road mesh/support and direct/cache parity.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const ROAD = preload("res://scripts/terrain/frontier_road_deck.gd")
const PLACE = preload("res://scripts/terrain/place_reference_dressing.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const GROUND_SHADER = preload("res://shaders/terrain/frontier_ground.gdshader")
const FOG_SHADER = preload("res://shaders/terrain/regional_fog_overlay.gdshader")
var passed := 0
var failed := 0

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	var tiles: Array = []
	for r in range(8):
		for q in range(16):
			var tile := {"grid_position": {"x": q, "y": r}, "type_id": "ground_flat", "height_level": 1 if q >= 8 else 0,
				"surface_type": "road" if r == 2 and q >= 2 and q <= 12 else "ground", "walkable": true, "blocks_los": false}
			if q == 7: tile.ramp_direction = 0
			tiles.append(tile)
	var pad_center := HEX.axial_to_plane(Vector2(3, 6))
	var raw := {"map_name": "Grafikpass R123 Surface Fixture", "grid_topology": "hex_axial_v1", "tactical_grid_rules": "hex_tactical_v1",
		"regional_terrain_version": 3, "regional_height_step": 0.5, "terrain_height_rules": "explicit_hex_ramps_v1",
		"terrain_visual_theme_id": "frontier_illustrated_v1", "grid_size": {"x": 16, "y": 8}, "tiles": tiles,
		"place_presentation": {"pads": [{"center": [pad_center.x, pad_center.y], "size": [2.8, 2.4], "name": "TEST"}]}}
	var file := FileAccess.open("user://grafikpass_r123_surface_fixture.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(raw)); file.close()
	var map = MAP.load_from_file("user://grafikpass_r123_surface_fixture.json")
	var registry = REGISTRY.new()
	root.add_child(registry)
	registry.configure_iso_grid(map.get_grid_origin(), 64, 32, "hex_axial_v1")
	for tile in map.get_tiles(): registry.register_tile(tile)
	var truth := _terrain_stamp(map)
	var revision: int = registry.get_revision()
	var direct = _new_view(registry)
	await process_frame
	direct.configure_from_map(map); direct.set_process(false)
	_check(direct.call("_built_road_deck_applies"), "fixture exercises the actual arid road route")
	_test_support(direct, map)
	var direct_geometry := _chunk_geometry(direct)
	var direct_materials := _ground_materials(direct)
	_check(direct_geometry.size() == 2 and not direct_materials.is_empty(), "both regional chunks and actual ground shader materials are present")
	_check(_paint_is(direct_materials, 0.14), "direct ground keeps the faint road shoulder")
	var producer = _new_view(null)
	await process_frame
	producer.configure_terrain_resource_prefill(map)
	var deadline := Time.get_ticks_msec() + 15000
	while producer.get_terrain_resource_preparation_snapshot().status == "preparing_resources" and Time.get_ticks_msec() < deadline:
		await process_frame
	var cache: RefCounted = producer.get_prepared_terrain_resource_cache()
	_check(cache != null and producer.get_terrain_resource_preparation_snapshot().prepared_chunks == 2, "actual resource prefill finishes both chunks")
	_check(producer.get("_built_road_deck") == null, "prefill builds no separate live road object")
	if cache == null:
		direct.free(); producer.free(); registry.free(); _finish(); return
	producer.free()
	var restored = _new_view(registry)
	await process_frame
	restored.set_prepared_terrain_resource_cache(cache)
	restored.configure_from_map(map); restored.set_process(false)
	var state: Dictionary = restored.get_terrain_resource_preparation_snapshot()
	_check(state.ready and state.resource_restore_count == 2 and state.geometry_build_count == 0, "receiving view restores actual cached geometry without rebuilding chunks")
	var restored_materials := _ground_materials(restored)
	_check(_paint_is(restored_materials, 0.14), "restored ground retains the same faint road shoulder")
	_check(_material_stamps(direct_materials) == _material_stamps(restored_materials), "actual cached ground uniforms and surface-mask bytes equal the direct view")
	_check(_chunk_geometry(restored) == direct_geometry, "restored chunk and live grid geometry equal the direct view")
	_check(_geometry_stamp(restored.get("_built_road_deck")) == _geometry_stamp(direct.get("_built_road_deck")), "receiving view builds the identical road mesh")
	_test_support(restored, map)
	_check(_test_fow(direct, map) == _test_fow(restored, map), "direct and restored views publish identical actual FoW transforms, profiles, colors and states")
	_check(_terrain_stamp(map) == truth and registry.get_revision() == revision, "all visual builds and reads preserve terrain height, ramps, walkability, LOS and registry revision")
	direct.free(); restored.free(); registry.free()
	_finish()

func _new_view(registry: Node):
	var view = VIEW.new()
	root.add_child(view); view.hide(); view.set_authoring_markers_visible(false)
	if registry != null: view.set_runtime_terrain_registry(registry)
	return view

func _test_support(view: Node, map) -> void:
	var deck := view.get("_built_road_deck") as MeshInstance3D
	_check(deck != null and deck.mesh != null, "live view has a real built road mesh")
	if deck == null: return
	var actor := Node2D.new(); root.add_child(actor)
	actor.set_meta("hex_ground_moving", false); actor.set_meta("hex_ground_facing_angle", 0.0)
	var cases := {Vector2i(3, 2): ROAD.DECK_HEIGHT, Vector2i(7, 2): ROAD.DECK_HEIGHT + ROAD.GRADED_LIFT,
		Vector2i(7, 5): 0.0, Vector2i(3, 6): PLACE.PAD_DECK_TOP}
	for grid: Vector2i in cases:
		var tile = map.get_tile_at_grid(grid)
		var expected: float = cases[grid]
		var center: Vector3 = view.call("_grid_to_3d_position", Vector2(grid), 0.0)
		var world: Vector2 = view.call("_position_3d_to_world", center)
		var base: float = TILE.stand_height(tile) * float(view.call("_get_3d_height_step"))
		_check(is_equal_approx(float(view.call("_hex_grid_model_support_lift", tile)), expected), "correct flat road/ramp road/nonroad ramp/pad support " + str(grid))
		_check(is_equal_approx(float(view.call("_get_world_surface_y", world)), base + expected), "world surface includes only the visual support " + str(grid))
		actor.global_position = world; actor.set_meta("hex_ground_stand_height_logical", TILE.stand_height(tile))
		var motion: Dictionary = view.call("_get_hex_unit_motion_visual", actor)
		_check(not motion.is_empty() and is_equal_approx(Vector3(motion.position).y, base + expected + 0.06), "actual actor projection stands above its surface " + str(grid))
		var outline: PackedVector3Array = view.call("_hex_grid_outline_cached", tile, {})
		var clear := true
		var road_samples := 0
		if String(tile.surface_type) == "road":
			var mesh_top := _mesh_top_at(deck.mesh, Vector2(center.x, center.z))
			_check(is_finite(mesh_top) and is_equal_approx(mesh_top, base + expected), "actual asphalt triangles agree with actor support " + str(grid))
			for point: Vector3 in outline:
				var top := _mesh_top_at(deck.mesh, Vector2(point.x, point.z))
				if is_finite(top):
					road_samples += 1
					clear = clear and point.y > top + 0.0001
			_check(road_samples > 0 and clear, "drawn hex contour clears the actual raised road triangles " + str(grid))
		elif grid == Vector2i(3, 6):
			var bounds: Dictionary = view.call("_get_local_visual_bounds", view.get("_place_dressing_root"))
			for point: Vector3 in outline: clear = clear and point.y > Vector3(bounds.max).y
			_check(bool(bounds.valid) and clear, "pad contour clears actual raised pad geometry")
	actor.free()

func _test_fow(view: Node, map) -> Dictionary:
	var cases := {Vector2i(3, 2): ROAD.DECK_HEIGHT, Vector2i(7, 2): ROAD.DECK_HEIGHT + ROAD.GRADED_LIFT,
		Vector2i(7, 5): 0.0, Vector2i(3, 6): PLACE.PAD_DECK_TOP}
	var explored: Array[String] = []
	for grid: Vector2i in cases: explored.append(String(map.get_tile_at_grid(grid).tile_id))
	var visible_id: String = String(map.get_tile_at_grid(Vector2i(3, 2)).tile_id)
	var deck := view.get("_built_road_deck") as MeshInstance3D
	var result := {}
	for phase in ["known", "explored", "visible"]:
		view.call("set_fog_of_war_state", {"mode": "known_terrain" if phase == "known" else "unexplored_blackout", "team_id": "surface_fixture",
			"visible_tile_ids": [visible_id] if phase == "visible" else [], "explored_tile_ids": [] if phase == "known" else explored})
		for batch in range(8):
			if not bool(view.get("_fow_overlay_full_rebuild_pending")): break
			view.call("_process_pending_fow_overlay_full_rebuild")
		var multi := view.get("_fow_overlay_multimesh") as MultiMesh
		var instance := view.get("_fow_overlay_multimesh_instance") as MultiMeshInstance3D
		var material: ShaderMaterial = instance.material_override as ShaderMaterial if instance != null else null
		_check(multi != null and multi.use_custom_data and material != null
			and material.shader == FOG_SHADER and not bool(view.get("_fow_overlay_full_rebuild_pending")), "actual regional FoW mesh finishes " + phase)
		if multi == null: continue
		var slots: Dictionary = view.get("_fow_overlay_slot_by_tile_id")
		var states: Dictionary = view.get("_fow_overlay_tile_states_by_id")
		var arrays: Array = multi.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var step: float = view.call("_get_3d_height_step")
		for grid: Vector2i in cases:
			var tile = map.get_tile_at_grid(grid)
			var id: String = tile.tile_id
			_check(slots.has(id), "FoW slot exists " + phase + str(grid))
			if not slots.has(id): continue
			var slot: int = slots[id]
			var transform := multi.get_instance_transform(slot)
			var custom := multi.get_instance_custom_data(slot)
			var color := multi.get_instance_color(slot)
			result[phase + id] = [transform, custom, color, states.get(id)]
			if phase == "visible" and id == visible_id:
				_check(states.get(id) == "visible" and transform.origin.y < -90000.0 and is_zero_approx(color.a), "visible road still has no dimming overlay")
				continue
			var base: float = TILE.stand_height(tile) * step
			var expected: float = base + float(cases[grid]) + VIEW.FOW_OVERLAY_SURFACE_Y_OFFSET
			_check(states.get(id) == ("known" if phase == "known" else "explored") and color.a > 0.0
				and is_equal_approx(transform.origin.y, expected), "known/explored overlay origin follows raised surface " + phase + str(grid))
			var profile: PackedFloat32Array = view.call("_regional_surface_profile", tile)
			var profile_matches := true
			var clear := true
			var road_samples := 0
			for index in vertices.size():
				var sample: int = int(uvs[index].x)
				var rise := 0.0
				if sample < 12:
					# The real shader decodes three signed base-nine quarter steps
					# per INSTANCE_CUSTOM channel; its centre (UV 12) stays flat.
					var encoded: int = roundi(custom[int(sample / 3)] * 728.0)
					var place: int = [1, 9, 81][sample % 3]
					rise = step * 0.25 * float(floori(float(encoded) / float(place)) % 9 - 4)
				var point: Vector3 = transform * (vertices[index] + Vector3(0, rise, 0))
				var nominal: float = expected + (float(profile[sample]) * step if sample < 12 and not profile.is_empty() else 0.0)
				profile_matches = profile_matches and is_equal_approx(point.y, nominal)
				if String(tile.surface_type) == "road" and deck != null:
					var top := _mesh_top_at(deck.mesh, Vector2(point.x, point.z))
					if is_finite(top):
						road_samples += 1
						clear = clear and point.y > top + 0.0001
			_check(profile_matches, "regional shader slope is preserved above lifted origin " + phase + str(grid))
			if String(tile.surface_type) == "road": _check(road_samples > 0 and clear, "actual FoW samples clear raised asphalt " + phase + str(grid))
			elif grid == Vector2i(3, 6):
				var bounds: Dictionary = view.call("_get_local_visual_bounds", view.get("_place_dressing_root"))
				_check(bool(bounds.valid) and transform.origin.y > Vector3(bounds.max).y, "actual FoW samples clear raised pad " + phase)
		if phase != "known":
			var unknown_id: String = map.get_tile_at_grid(Vector2i.ZERO).tile_id
			_check(slots.has(unknown_id) and states.get(unknown_id) == "unknown", "unexplored terrain remains unknown " + phase)
			if slots.has(unknown_id):
				var unknown_slot: int = slots[unknown_id]
				_check(is_equal_approx(multi.get_instance_transform(unknown_slot).origin.y, float(view.get("_fow_overlay_blackout_y")))
					and multi.get_instance_color(unknown_slot) == VIEW.FOW_UNKNOWN_BLACK_COLOR, "unknown blackout keeps its separate cover and color " + phase)
	return result

func _mesh_top_at(mesh: Mesh, point: Vector2) -> float:
	var result := -INF
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var count: int = vertices.size() if indices.is_empty() else indices.size()
		for index in range(0, count - 2, 3):
			var a := vertices[index if indices.is_empty() else indices[index]]
			var b := vertices[index + 1 if indices.is_empty() else indices[index + 1]]
			var c := vertices[index + 2 if indices.is_empty() else indices[index + 2]]
			var denominator: float = (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
			if absf(denominator) < 0.000001: continue
			var wa: float = ((b.z - c.z) * (point.x - c.x) + (c.x - b.x) * (point.y - c.z)) / denominator
			var wb: float = ((c.z - a.z) * (point.x - c.x) + (a.x - c.x) * (point.y - c.z)) / denominator
			var wc: float = 1.0 - wa - wb
			if minf(wa, minf(wb, wc)) >= -0.00001: result = maxf(result, wa * a.y + wb * b.y + wc * c.y)
	return result

func _terrain_stamp(map) -> PackedByteArray:
	var values: Array = []
	for tile in map.get_tiles(): values.append(tile.to_dict())
	return var_to_bytes(values)

func _chunk_geometry(view: Node) -> Dictionary:
	var result := {}
	for key in view.get("_regional_chunk_nodes"):
		result[str(key)] = _geometry_stamp(view.get("_regional_chunk_nodes")[key])
	return result

func _geometry_stamp(node: Node) -> PackedStringArray:
	var values := PackedStringArray()
	_collect_geometry(node, Transform3D.IDENTITY, values)
	values.sort()
	return values

func _collect_geometry(node: Node, parent: Transform3D, values: PackedStringArray) -> void:
	var transform: Transform3D = parent * node.transform if node is Node3D else parent
	var mesh: Mesh
	var buffer := PackedFloat32Array()
	if node is MeshInstance3D: mesh = node.mesh
	elif node is MultiMeshInstance3D and node.multimesh != null:
		mesh = node.multimesh.mesh; buffer = node.multimesh.buffer
	if mesh != null:
		var arrays: Array = []
		for surface in mesh.get_surface_count(): arrays.append(mesh.surface_get_arrays(surface))
		values.append(var_to_bytes([transform, arrays, buffer]).hex_encode().sha256_text())
	for child in node.get_children(): _collect_geometry(child, transform, values)

func _ground_materials(view: Node) -> Array[ShaderMaterial]:
	var found := {}
	for chunk in view.get("_regional_chunk_nodes").values(): _collect_materials(chunk, found)
	var result: Array[ShaderMaterial] = []
	for material in found.values(): result.append(material)
	return result

func _collect_materials(node: Node, found: Dictionary) -> void:
	var mesh: Mesh
	if node is MeshInstance3D: mesh = node.mesh
	elif node is MultiMeshInstance3D and node.multimesh != null: mesh = node.multimesh.mesh
	if mesh != null:
		for index in mesh.get_surface_count():
			var material: Material = node.get_active_material(index) if node is MeshInstance3D else (node.material_override if node.material_override != null else mesh.surface_get_material(index))
			if material is ShaderMaterial and material.shader == GROUND_SHADER: found[material.get_instance_id()] = material
	for child in node.get_children(): _collect_materials(child, found)

func _paint_is(materials: Array[ShaderMaterial], value: float) -> bool:
	if materials.is_empty(): return false
	for material in materials:
		if not is_equal_approx(float(material.get_shader_parameter("road_paint_strength")), value): return false
	return true

func _material_stamps(materials: Array[ShaderMaterial]) -> PackedStringArray:
	var result := PackedStringArray()
	for material in materials:
		var values: Array = []
		for key in ["base_color", "rock_strata", "paved_surface", "slope_normal_softening", "authored_paving_wear", "homebase_palette", "quiet_tactical_surface", "trail_surface", "road_paint_strength", "surface_blending", "surface_bounds", "world_to_grid"]:
			values.append(material.get_shader_parameter(key))
		var mask := material.get_shader_parameter("surface_mask") as Texture2D
		values.append(mask.get_image().get_data() if mask != null else PackedByteArray())
		result.append(var_to_bytes(values).hex_encode().sha256_text())
	result.sort()
	return result

func _finish() -> void:
	print("GRAFIKPASS_R123_SURFACE ", JSON.stringify({"passed": passed, "failed": failed}))
	quit(0 if failed == 0 else 1)
