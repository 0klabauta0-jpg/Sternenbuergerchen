extends SceneTree
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const DOORS = preload("res://scripts/mission/mission_interaction_door_runtime_collision_los.gd")
const CHUNK_CACHE = preload("res://scripts/terrain/terrain_chunk_resource_cache.gd")
const FLOOR_BOUNDARY = preload("res://scripts/terrain/station_floor_boundary.gd")
var passed := 0
var failed := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS " if ok else "FAIL ", label)

func add(view: Node, map: RefCounted, cell: Vector2i) -> Node3D:
	var tile = map.get_tile_at_grid(cell)
	check(view.call("_add_asset_model_visual", tile, float(tile.height_level) * 0.5, String(tile.object_type_id), true), "actual imported wall/door " + str(cell))
	return view.get("_map_root").get_child(view.get("_map_root").get_child_count() - 1)

func interval(node: Node, axis: Vector3, parent: Transform3D = Transform3D.IDENTITY) -> Vector2:
	var frame: Transform3D = parent * node.transform if node is Node3D else parent
	var bounds := Vector2(INF, -INF)
	if node is MeshInstance3D and node.mesh != null:
		for surface in range(node.mesh.get_surface_count()):
			for point: Vector3 in node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var projection: float = (frame * point).dot(axis)
				bounds.x = minf(bounds.x, projection)
				bounds.y = maxf(bounds.y, projection)
	for child: Node in node.get_children():
		var part: Vector2 = interval(child, axis, frame)
		bounds.x = minf(bounds.x, part.x)
		bounds.y = maxf(bounds.y, part.y)
	return bounds

func first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.mesh != null: return node
	for child: Node in node.get_children():
		var found: MeshInstance3D = first_mesh(child)
		if found != null: return found
	return null

func run() -> void:
	for map_id: String in ["station_outpost_64x64", "station_outpost_192x192"]:
		var map = MAP.load_from_file("res://maps/" + map_id + ".json")
		var shift := Vector2i(64, 64) if map_id.ends_with("192x192") else Vector2i.ZERO
		var original: PackedByteArray = var_to_bytes(map.get_tiles().map(func(tile): return tile.to_dict()))
		var view = VIEW.new()
		var models := Node3D.new()
		view.add_child(models)
		view.set("_map_root", models)
		view.set("_active_grid_topology", "hex_axial_v1")
		view.set("_terrain_map_data", map)
		var tile_size: Dictionary = map.get_tile_size()
		view.set("_half_tile_width", float(tile_size.half_width))
		view.set("_half_tile_height", float(tile_size.half_height))
		view.set("_grid_origin_world", map.get_grid_origin())
		view.call("_configure_arid_pebble_exclusions")
		var regions: Array = map.get_place_presentation().station_module_layout.regions
		check(regions.size() == (9 if map_id.ends_with("192x192") else 1), "actual authored map exposes every station ensemble " + map_id)
		for region: Dictionary in regions:
			var boundary: Array = region.floor_boundary
			var tile = null
			for candidate in map.get_tiles():
				var source_q: int = candidate.grid_position.x+floori(float(candidate.grid_position.y-int(region.row_anchor))*0.5)
				if candidate.object_type_id == "station_set_wall" and source_q == int(boundary[0]) and candidate.grid_position.y>int(boundary[1]) and candidate.grid_position.y<int(boundary[3]):
					tile=candidate; break
			check(tile != null and String(tile.object_type_id).begins_with("station_set_wall") and String(tile.type_id).begins_with("station_set_floor"), "actual outer wall has floor layer " + String(region.id))
			if tile == null: continue
			var cell: Vector2i = tile.grid_position
			var wall: Node3D = add(view, map, cell)
			var bounds: Rect2 = view.get("_station_module_projection").floor_bounds(map, cell, 1.0)
			check(bounds.has_area() and absf(wall.position.x-bounds.position.x)<0.00001, "material boundary lies on actual approved wall centerline " + String(region.id))
			check(view.call("_add_asset_model_visual", tile, float(tile.height_level)*0.5, String(tile.type_id), false), "actual floor is imported below its real boundary wall")
			var floor: Node3D = models.get_child(models.get_child_count()-1)
			var mesh: MeshInstance3D = first_mesh(floor)
			var material: Material = mesh.get_active_material(0)
			check(mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and first_mesh(wall).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "only the actual thin floor skin loses its caster; real wall retains shadow " + String(region.id))
			check(material is ShaderMaterial and material.shader == FLOOR_BOUNDARY.SHADER, "real floor material uses authored inside/outside boundary " + String(region.id))
			if material is ShaderMaterial:
				check(material.get_shader_parameter("floor_bounds") == Vector4(bounds.position.x,bounds.position.y,bounds.end.x,bounds.end.y), "actual GPU material receives exact wall hull")
			var mesh_before: Mesh = mesh.mesh
			var vertices_before: PackedByteArray = var_to_bytes(mesh.mesh.surface_get_arrays(0))
			var transform_before: Transform3D = floor.transform
			view.call("_apply_station_floor_boundary", floor.get_child(0), tile)
			check(mesh.mesh == mesh_before and var_to_bytes(mesh.mesh.surface_get_arrays(0)) == vertices_before and floor.transform == transform_before, "material-only split retains exact geometry and support height " + String(region.id))
			var builds: int = view.get("_station_floor_boundary").build_count
			for index in range(1000): view.call("_apply_station_floor_boundary", floor.get_child(0), tile)
			check(view.get("_station_floor_boundary").build_count == builds, "1000 stable floor reads allocate no materials or nodes " + String(region.id))
			check(view.call("_add_ground_model_visual", tile, float(tile.height_level)*0.5, String(tile.type_id)), "actual individual ground route imports same floor")
			var ground: Node3D = models.get_child(models.get_child_count()-1)
			var ground_material: Material = first_mesh(ground).get_active_material(0)
			check(first_mesh(ground).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "individual thin ground floor is a receiver without self-shadow")
			check(ground_material is ShaderMaterial and ground_material.get_shader_parameter("floor_bounds")==Vector4(bounds.position.x,bounds.position.y,bounds.end.x,bounds.end.y), "individual floor route shares exact authored boundary")
			view.set("_ground_batch_requests", {})
			check(view.call("_queue_ground_model_batch", tile, float(tile.height_level)*0.5, String(tile.type_id)), "actual batched ground route imports same floor")
			var ground_batches: Dictionary = view.get("_ground_batch_requests")
			var batch_material: Material = ground_batches.values()[0].source.material_override if not ground_batches.is_empty() else null
			check(batch_material is ShaderMaterial and batch_material.get_shader_parameter("floor_bounds")==Vector4(bounds.position.x,bounds.position.y,bounds.end.x,bounds.end.y), "batched floor route shares exact authored boundary")
			view.call("_flush_ground_model_batches")
			var floor_batch := models.get_child(models.get_child_count()-1) as MultiMeshInstance3D
			check(floor_batch != null and floor_batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "actual rendered thin floor MultiMesh has no self-shadow caster")
			if floor_batch != null: floor_batch.free()
			ground.free()
			wall.free(); floor.free()
		for cells: Array in [[Vector2i(28,25), Vector2i(29,25)], [Vector2i(27,26), Vector2i(26,27)]]:
			var a: Node3D = add(view, map, cells[0] + shift)
			var b: Node3D = add(view, map, cells[1] + shift)
			var direction: Vector3 = (b.position - a.position).normalized()
			var gap: float = interval(b, direction).x - interval(a, direction).y
			check(gap >= -0.00001 and gap <= 0.003, "actual imported straight wall seam is at most 3mm on approved warehouse axes " + map_id)
			a.free(); b.free()
		for spec: Array in [[Vector2i(27,25),270.0], [Vector2i(42,25),180.0], [Vector2i(21,38),0.0]]:
			var corner: Node3D = add(view, map, spec[0] + shift)
			var expected: Vector3 = Basis(Vector3.UP, deg_to_rad(spec[1])).x
			check(corner.basis.x.normalized().is_equal_approx(expected), "existing asymmetric L corner faces its two actual neighbor walls " + str(spec[0]))
			check(corner.get_child(0).position.is_equal_approx(Vector3(0.25,0,-0.25)), "source corner arm offsets are centered on real wall axes")
			corner.free()
		var frame: Node3D = add(view, map, Vector2i(39,31) + shift)
		var leaf: Node3D = add(view, map, Vector2i(40,31) + shift)
		check(Vector2(frame.position.x, frame.position.z).is_equal_approx(Vector2(leaf.position.x, leaf.position.z)) and frame.basis.x.normalized().is_equal_approx(leaf.basis.x.normalized()), "actual door leaf is in its own physical frame plane inside two-cell door union")
		var vertical_gap: float = interval(frame, Vector3.UP).x - interval(leaf, Vector3.UP).y
		check(absf(vertical_gap) < 0.001 and interval(frame, Vector3.UP).x > frame.position.y + 0.6, "actual source lintel retains authored elevation directly above the leaf")
		var registry = REGISTRY.new()
		registry.configure_iso_grid(map.get_grid_origin(), map.get_tile_size().half_width, map.get_tile_size().half_height, map.get_grid_topology())
		for tile in map.get_tiles(): registry.register_tile(tile)
		view.set_runtime_terrain_registry(registry)
		var door_cells: Array[Vector2i] = [Vector2i(39,31) + shift, Vector2i(40,31) + shift]
		var authored_cells: Array = door_cells.map(func(cell: Vector2i) -> Dictionary: return {"x":cell.x, "y":cell.y})
		var bindings: Array = [{"interaction_id":"actual_station_door", "interaction_type":"door", "marker_id":"station_entry_door", "door_cells":authored_cells}]
		var body: Node3D = leaf.get_child(0)
		var authored: Transform3D = body.transform
		for state: String in ["closed", "half", "open", "closed"]:
			var states: Dictionary = {"actual_station_door":{"state":"active" if state == "half" else state, "progress":0.5 if state == "half" else 0.0, "complete":state == "open"}}
			var snapshot: Dictionary = DOORS.build_runtime_snapshot(bindings, states, map, registry)
			check(snapshot.override_count == 2, "real Door producer owns frame and leaf cells " + state)
			registry.set_runtime_tile_overrides(snapshot.overrides)
			leaf.visible = false # Simulate an already hidden authoritative FoW parent.
			view.call("_refresh_station_door_visuals_if_needed")
			check(body.visible == (state != "open") and not leaf.visible, "leaf follows real Registry door state without revealing its FoW parent " + state)
			check(is_equal_approx(body.basis.x.length(), authored.basis.x.length() * (0.5 if state == "half" else 1.0)), "half-open leaf is a reversible visual projection " + state)
			check(registry.is_walkable(door_cells[0]) == (state == "open") and registry.is_walkable(door_cells[1]) == (state == "open"), "visual read does not alter physical two-cell Door truth " + state)
		var apply_count: int = view.get("_station_door_visual_apply_count")
		for index in range(1000): view.call("_refresh_station_door_visuals_if_needed")
		check(view.get("_station_door_visual_apply_count") == apply_count and body.transform == authored, "1000 unchanged door reads reuse node/mesh and closed transform")
		# A newly built streamed chunk is captured before applying its live door
		# state. Restoring it must not repeatedly halve already-halved geometry.
		leaf.free()
		var half_state: Dictionary = DOORS.build_runtime_snapshot(bindings, {"actual_station_door":{"state":"active", "progress":0.5, "complete":false}}, map, registry)
		registry.set_runtime_tile_overrides(half_state.overrides)
		var cold_leaf: Node3D = add(view, map, door_cells[1])
		check(cold_leaf.get_child(0).transform == authored, "static chunk construction preserves authored leaf despite live half-open owner")
		var cold_chunk := Node3D.new()
		cold_chunk.name = "TerrainChunk_0_0"
		models.remove_child(cold_leaf); cold_chunk.add_child(cold_leaf)
		var cache = CHUNK_CACHE.new()
		check(cache.begin_map({"map_id":map_id, "terrain_revision":"test", "art_revision":"test", "grid_revision":"hex"}, [Vector2i.ZERO], 32*1024*1024).ok and cache.capture_chunk(Vector2i.ZERO, cold_chunk).ok, "actual static resource cache captures authored door chunk")
		var restored: Node3D = cache.instantiate_chunk(Vector2i.ZERO)
		view.call("_register_restored_station_door_visuals", restored)
		view.call("_refresh_station_door_visuals_if_needed")
		var restored_body: Node3D = restored.get_child(0).get_child(0)
		check(is_equal_approx(restored_body.basis.x.length(), authored.basis.x.length()*0.5), "restored door applies current half-state exactly once")
		var closed_state: Dictionary = DOORS.build_runtime_snapshot(bindings, {"actual_station_door":{"state":"closed", "progress":0.0, "complete":false}}, map, registry)
		registry.set_runtime_tile_overrides(closed_state.overrides)
		view.call("_refresh_station_door_visuals_if_needed")
		check(restored_body.transform == authored, "restored door can close to original geometry after cachehandoff")
		restored.free(); cold_chunk.free(); cache.clear()
		var rock = null
		for tile in map.get_tiles():
			if tile.object_type_id in ["nature_rock_cover", "nature_tree_blocker"] and absi(tile.grid_position.x * 17389 + tile.grid_position.y * 7937 + 571) % 4 == 0:
				rock = tile
				break
		check(rock != null, "actual station has an eligible arid foot-dressing cell")
		if rock != null:
			view.set("_static_prop_batch_requests", {})
			view.call("_queue_arid_foot_pebbles", rock, float(rock.height_level) * 0.5)
			var requests: Dictionary = view.get("_static_prop_batch_requests")
			check(requests.size() == 1, "tiny rock dressing is one shared native mesh batch")
			if not requests.is_empty():
				var batch: Dictionary = requests.values()[0]
				var transforms: Array = batch.transforms.duplicate()
				check(transforms.size() >= 2 and transforms.size() <= 3, "sparse chosen cell has only two or three decorative pebbles")
				var valid := true
				var center: Vector3 = view.call("_grid_to_3d_position", Vector2(rock.grid_position), float(rock.height_level) * 0.5)
				for transform: Transform3D in transforms:
					valid = valid and Vector2(transform.origin.x-center.x, transform.origin.z-center.z).length() < 0.41 and transform.basis.x.length() < 0.1
				check(valid, "miniature decoration stays at the existing rock foot inside its original cell")
				view.set("_static_prop_batch_requests", {})
				view.call("_queue_arid_foot_pebbles", rock, float(rock.height_level) * 0.5)
				check(view.get("_static_prop_batch_requests").values()[0].transforms == transforms, "decorative scatter is coordinate deterministic without gameplay RNG")
		check_free_ground_pebbles(view, map)
		check(var_to_bytes(map.get_tiles().map(func(tile): return tile.to_dict())) == original, "wall joins/corners/door visual never mutate authored map facts " + map_id)
		registry.free()
		view.free()
	print("REVIEW_STATION_BUILDING passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func check_free_ground_pebbles(view: Node, map: RefCounted) -> void:
	view.set("_static_prop_batch_requests", {})
	var selected = null
	for tile in map.get_tiles():
		view.call("_queue_arid_ground_pebbles", tile, float(tile.height_level) * 0.5)
		if not view.get("_static_prop_batch_requests").is_empty():
			selected = tile
			break
	check(selected != null, "actual free arid ground receives sparse miniature stones")
	if selected == null: return
	check(selected.walkable and not selected.blocks_los and selected.cover_value == 0 and selected.object_height == 0 and String(selected.object_type_id).is_empty(), "tiny ground decoration has no physical obstacle or cover")
	var batch: Dictionary = view.get("_static_prop_batch_requests").values()[0]
	var transforms: Array = batch.transforms.duplicate()
	var mesh: Mesh = batch.source.mesh
	var material: Material = batch.source.material_override
	check(transforms.size() >= 1 and transforms.size() <= 2, "selected free cell has only one or two tiny stones")
	view.set("_static_prop_batch_requests", {})
	view.call("_queue_arid_ground_pebbles", selected, float(selected.height_level) * 0.5)
	var repeated: Dictionary = view.get("_static_prop_batch_requests").values()[0]
	check(repeated.transforms == transforms and repeated.source.mesh == mesh and repeated.source.material_override == material, "free-ground rebuild reuses exact deterministic transforms, shared mesh and material")
	for overrides: Dictionary in [{"walkable":false}, {"blocks_los":true}, {"cover_value":1}, {"object_height":1}, {"object_type_id":"nature_rock_cover"}, {"type_id":"station_set_floor_panel"}, {"surface_type":"road"}, {"surface_type":"water"}, {"edge_type":"slope"}, {"explicit_hex_ramps":true,"ramp_direction":0}, {"height_level":int(selected.height_level)+1}]:
		var facts: Dictionary = selected.to_dict()
		facts.merge(overrides, true)
		var candidate = preload("res://scripts/terrain/terrain_tile_data.gd").from_dict(facts)
		view.set("_static_prop_batch_requests", {})
		view.call("_queue_arid_ground_pebbles", candidate, float(candidate.height_level) * 0.5)
		check(view.get("_static_prop_batch_requests").is_empty(), "ground pebbles exclude " + str(overrides))
	map.set_marker_position("review_pebble_guard", selected.world_position)
	view.call("_configure_arid_pebble_exclusions")
	view.call("_queue_arid_ground_pebbles", selected, float(selected.height_level) * 0.5)
	check(view.get("_static_prop_batch_requests").is_empty(), "real marker and its neighboring cells remain clear")
	map.remove_marker("review_pebble_guard")
	view.call("_configure_arid_pebble_exclusions")
	var owner := Node3D.new()
	view.set("_external_terrain_object_visuals", {selected.grid_position:weakref(owner)})
	view.call("_queue_arid_ground_pebbles", selected, float(selected.height_level) * 0.5)
	check(view.get("_static_prop_batch_requests").is_empty(), "external authored building/pad cell remains clear")
	view.set("_external_terrain_object_visuals", {})
	owner.free()
	var original_presentation: Dictionary = map.get_place_presentation()
	var with_pad: Dictionary = original_presentation.duplicate(true)
	var center: Vector3 = view.call("_grid_to_3d_position", Vector2(selected.grid_position), 0.0)
	with_pad.pads = [{"center":[center.x,center.z], "size":[2.0,2.0]}]
	map.set_place_presentation(with_pad)
	view.call("_configure_arid_pebble_exclusions")
	view.call("_queue_arid_ground_pebbles", selected, float(selected.height_level) * 0.5)
	check(view.get("_static_prop_batch_requests").is_empty(), "painted pad presentation excludes tiny ground stones without a collider")
	map.set_place_presentation(original_presentation)
	view.call("_configure_arid_pebble_exclusions")
