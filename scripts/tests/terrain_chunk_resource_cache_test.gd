extends SceneTree
const CACHE_PATH := "res://scripts/terrain/terrain_chunk_resource_cache.gd"
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var passed := 0
var failed := 0

func _init() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	passed += int(value)
	failed += int(not value)
	print("PASS: " if value else "FAIL: ", label)

func _run() -> void:
	if not ResourceLoader.exists(CACHE_PATH):
		_check(false, "Static terrain resource cache exists")
		_finish()
		return
	var cache = load(CACHE_PATH).new()
	var map = MAP.load_from_file("res://maps/trade_outpost.json")
	var view := VIEW.new()
	root.add_child(view)
	await process_frame
	view.configure_from_map(map)
	var candidates: Dictionary = view.get("_regional_chunk_nodes")
	var chosen: Array[Vector2i] = []
	for key: Vector2i in candidates:
		var chunk: Node3D = candidates[key]
		if chunk.find_children("*", "MeshInstance3D", true, false).is_empty(): continue
		if chunk.find_children("*", "MultiMeshInstance3D", true, false).is_empty(): continue
		chosen.append(key)
		if chosen.size() == 2: break
	_check(chosen.size() == 2, "Two actual map chunks contain meshes and instance buffers")
	if chosen.size() != 2:
		view.free()
		_finish()
		return
	var context := {"map_id": "trade_outpost", "terrain_revision": FileAccess.get_sha256("res://maps/trade_outpost.json"), "art_revision": "frontier_illustrated_v1", "grid_revision": "hex_axial_v1:8:.75"}
	var limit := 8 * 1024 * 1024
	_check(cache.begin_map(context, chosen, limit).ok, "Explicit map lifetime and expected chunk set")
	_check(not cache.is_ready(), "Missing resource chunks are not ready")
	var source: Node3D = candidates[chosen[0]]
	var custom := StandardMaterial3D.new()
	custom.albedo_color = Color("b27c52")
	var first: MeshInstance3D = source.find_children("*", "MeshInstance3D", true, false)[0]
	first.material_override = custom
	first.set_surface_override_material(0, custom)
	first.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	first.layers = 4
	first.extra_cull_margin = 0.25
	var original_mesh: Mesh = first.mesh
	var original_arrays := var_to_bytes(original_mesh.surface_get_arrays(0)).hex_encode().sha256_text()
	var before: String = cache.static_fingerprint(source)
	_check(cache.capture_chunk(chosen[0], source).ok, "Real static chunk resources captured")
	_check(not cache.is_ready() and cache.get_debug_snapshot().cached_chunks == 1, "Partial prefill exposes real progress")
	var snapshot: Dictionary = cache.get_chunk_descriptor(chosen[0])
	_check(not _contains_node(snapshot), "Cached descriptors contain no scene Nodes")
	var bytes_after_first: int = cache.get_debug_snapshot().retained_payload_bytes
	_check(bytes_after_first > 0 and bytes_after_first <= limit, "Measured resource/descriptor payload stays within the bound")
	_check(cache.capture_chunk(chosen[0], source).ok and cache.get_debug_snapshot().retained_payload_bytes == bytes_after_first, "Repeated capture is idempotent")
	_check(cache.capture_chunk(chosen[1], candidates[chosen[1]]).ok and cache.is_ready(), "Ready only after every expected chunk is captured")
	# The landing focus is authored and may contain only plateaus. Include a real
	# authored ramp chunk explicitly; never depend on camera/start-area composition.
	for tile in map.get_tiles():
		if tile.explicit_hex_ramps and tile.ramp_direction >= 0:
			var ramp_key := Vector2i(floori(float(tile.grid_position.x) / 8.0), floori(float(tile.grid_position.y) / 8.0))
			if not candidates.has(ramp_key): view.call("_build_regional_chunk", ramp_key)
			candidates = view.get("_regional_chunk_nodes")
			break
	var represented := {"ramp": false, "cliff": false, "grid": false}
	for chunk: Node3D in candidates.values():
		represented.ramp = represented.ramp or not chunk.find_children("RegionalRamps_*", "MeshInstance3D", true, false).is_empty()
		represented.cliff = represented.cliff or chunk.get_node_or_null("RegionalCliffFaces") != null
		represented.grid = represented.grid or chunk.get_node_or_null("TileGridLines3D") != null
	_check(represented.ramp and represented.cliff and represented.grid, "Real fixture includes ramp caps, cliff faces and hex grid geometry")
	var prop_key := Vector2i.ZERO
	var prop_found := false
	for tile in map.get_tiles():
		if tile.object_type_id == "spacekit_rock_large_a":
			prop_key = Vector2i(floori(float(tile.grid_position.x) / 8.0), floori(float(tile.grid_position.y) / 8.0))
			prop_found = true
			break
	if prop_found and not candidates.has(prop_key):
		view.call("_build_regional_chunk", prop_key)
		candidates = view.get("_regional_chunk_nodes")
	var prop_cache = load(CACHE_PATH).new()
	prop_cache.begin_map(context, [prop_key], limit)
	var prop_result: Dictionary = prop_cache.capture_chunk(prop_key, candidates[prop_key]) if prop_found else {"ok": false}
	print("TERRAIN_CACHE_PROP_RESULT ", prop_result)
	_check(prop_found and prop_result.ok, "Actual authored static rock prop chunk is captured")
	var prop_instance = prop_cache.instantiate_chunk(prop_key)
	if prop_instance != null:
		var props: Array = prop_instance.find_children("FrontierProp_*", "Node3D", true, false)
		_check(not props.is_empty() and props[0].get_meta("visual_family", "") == "frontier_reference_place_v1", "Allowlisted rendering metadata is retained on actual prop")
		_check(not _contains_node(prop_cache.get_chunk_descriptor(prop_key)), "Prop descriptors retain no source scene nodes or owners")
		var source_prop: Node3D = candidates[prop_key]
		if prop_cache.static_fingerprint(prop_instance) != prop_cache.static_fingerprint(source_prop):
			_dump_diff(prop_cache.call("_fingerprint_values", prop_cache.get_chunk_descriptor(prop_key)), prop_cache.call("_fingerprint_values", prop_cache.call("_describe", prop_instance, true).descriptor), "prop")
		_check(prop_cache.static_fingerprint(prop_instance) == prop_cache.static_fingerprint(source_prop), "Real prop mesh/material/transform fingerprint survives script-free restore")
		prop_instance.free()
	var bindings: Dictionary = view.get("_external_terrain_object_visuals")
	var owned_cell: Variant = bindings.keys()[0] if not bindings.is_empty() else null
	var owner: Node = bindings[owned_cell].get_ref() if owned_cell != null else null
	_check(owner != null and is_instance_valid(owner), "Actual multi-cell authored visual owner exists outside chunk cache")
	if owner != null:
		var owner_key := Vector2i(floori(float(owned_cell.x) / 8.0), floori(float(owned_cell.y) / 8.0))
		if not candidates.has(owner_key):
			view.call("_build_regional_chunk", owner_key)
			candidates = view.get("_regional_chunk_nodes")
		var owner_chunk_cache = load(CACHE_PATH).new()
		owner_chunk_cache.begin_map(context, [owner_key], limit)
		var owner_result: Dictionary = owner_chunk_cache.capture_chunk(owner_key, candidates[owner_key])
		_check(owner_result.ok and not _contains_node(owner_chunk_cache.get_chunk_descriptor(owner_key)), "Terrain resource cache excludes the actual multi-cell owner Node")
		var owner_restore = owner_chunk_cache.instantiate_chunk(owner_key)
		_check(owner_restore != null and bindings[owned_cell].get_ref() == owner and is_instance_valid(owner), "Chunk restore never replaces picking/interaction owner bindings")
		if owner_restore != null: owner_restore.free()
	var original_mm: MultiMesh = source.find_children("*", "MultiMeshInstance3D", true, false)[0].multimesh
	var cached_first = cache.instantiate_chunk(chosen[0])
	_check(cached_first != null and not cached_first.is_inside_tree() and not cached_first.visible, "Restored static chunk is off-tree and awaits existing FoW publication")
	_check(cache.static_fingerprint(cached_first) == before, "Static geometry/material/transform/flags fingerprint is preserved")
	var restored_mesh: MeshInstance3D = cached_first.find_children("*", "MeshInstance3D", true, false)[0]
	_check(restored_mesh.mesh == original_mesh and restored_mesh.material_override == custom and restored_mesh.get_surface_override_material(0) == custom, "Original Mesh and material resources are reused exactly")
	_check(restored_mesh.layers == 4 and restored_mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and is_equal_approx(restored_mesh.extra_cull_margin, 0.25), "Rendering flags and culling margin are restored")
	_check(cached_first.find_children("*", "MultiMeshInstance3D", true, false)[0].multimesh == original_mm, "MultiMesh buffer resource is reused rather than rebuilt")
	_check(var_to_bytes(restored_mesh.mesh.surface_get_arrays(0)).hex_encode().sha256_text() == original_arrays, "Actual original vertex/index arrays are unchanged")
	print("TERRAIN_CACHE_BUFFER_FLOATS ", original_mm.buffer.size())
	var all_expected := Array(view.get("_regional_tiles_by_chunk").keys())
	var whole_map = load(CACHE_PATH).new()
	whole_map.begin_map(context, all_expected, 256 * 1024 * 1024)
	whole_map.capture_chunk(chosen[0], source)
	_check(all_expected.size() == 2161 and not whole_map.is_ready() and whole_map.get_debug_snapshot().expected_chunks == 2161, "Actual whole-map expected set cannot report ready after one chunk")
	view.free()
	var repeated = cache.instantiate_chunk(chosen[0])
	_check(repeated != null and cache.static_fingerprint(repeated) == before, "Resources survive original chunk/view deletion")
	_check(repeated.find_children("*", "MeshInstance3D", true, false)[0].mesh == original_mesh, "Repeat restore still uses the same geometry resource")
	var rejected := Node3D.new()
	var dynamic := GDScript.new()
	dynamic.source_code = "extends Node3D\nvar gameplay_state := true\n"
	dynamic.reload()
	rejected.set_script(dynamic)
	var guard = load(CACHE_PATH).new()
	guard.begin_map(context, [Vector2i.ZERO], limit)
	_check(not guard.capture_chunk(Vector2i.ZERO, rejected).ok and not guard.is_ready(), "Script-bearing dynamic content is rejected without a partial entry")
	rejected.free()
	var fog := Node3D.new()
	fog.name = "FogOfWarOverlay"
	_check(not guard.capture_chunk(Vector2i.ZERO, fog).ok, "FoW projection is not captured as static geometry")
	fog.free()
	for owner_meta in ["visual_owner", "tile_owner", "interaction_id", "fog_visible"]:
		var owned := Node3D.new()
		owned.set_meta(owner_meta, "authoritative_owner")
		_check(not guard.capture_chunk(Vector2i.ZERO, owned).ok, "Owner/projection metadata is rejected: " + owner_meta)
		owned.free()
	var budgeted = load(CACHE_PATH).new()
	budgeted.begin_map(context, [Vector2i.ZERO], 1)
	_check(not budgeted.capture_chunk(Vector2i.ZERO, repeated).ok and budgeted.get_debug_snapshot().retained_payload_bytes == 0, "Oversized capture is rejected before retaining any resources")
	var last_context: String = cache.get_debug_snapshot().context_fingerprint
	var invalid_context: Dictionary = context.duplicate()
	var accidental_owner := Node.new()
	invalid_context.extra_node = accidental_owner
	_check(not cache.begin_map(invalid_context, chosen, limit).ok, "Map context rejects additional objects instead of retaining a Node")
	accidental_owner.free()
	_check(not cache.begin_map({}, chosen, limit).ok and cache.get_debug_snapshot().context_fingerprint == last_context, "Malformed lifetime request preserves a valid cache")
	for field in ["map_id", "terrain_revision", "art_revision", "grid_revision"]:
		var changed: Dictionary = context.duplicate()
		changed[field] += ":changed"
		cache.begin_map(changed, chosen, limit)
		_check(not cache.is_ready() and cache.get_debug_snapshot().cached_chunks == 0 and cache.instantiate_chunk(chosen[0]) == null, "Context invalidates old resources: " + field)
		cache.begin_map(context, chosen, limit)
		cache.capture_chunk(chosen[0], repeated)
	cache.clear()
	_check(cache.get_debug_snapshot().retained_payload_bytes == 0 and not cache.is_ready(), "Explicit lifetime end releases cache ownership")
	_check(is_instance_valid(repeated) and restored_mesh.mesh == original_mesh, "Cache clear never frees caller-owned instances")
	print("TERRAIN_CACHE_MEASURED ", bytes_after_first, " bytes first real chunk; budget=", limit)
	cached_first.free()
	repeated.free()
	_finish()

func _contains_node(value: Variant) -> bool:
	if value is Node: return true
	if value is Dictionary:
		for item in value.values():
			if _contains_node(item): return true
	if value is Array:
		for item in value:
			if _contains_node(item): return true
	return false

func _finish() -> void:
	print("TERRAIN_CHUNK_RESOURCE_CACHE %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _dump_diff(a: Variant, b: Variant, path: String) -> void:
	if a is Dictionary and b is Dictionary:
		for key: Variant in a:
			if b.has(key): _dump_diff(a[key], b[key], path + "." + String(key))
	elif a is Array and b is Array:
		for index in mini(a.size(), b.size()): _dump_diff(a[index], b[index], path + "[%d]" % index)
	elif a != b:
		print("TERRAIN_DESCRIPTOR_DIFF ", path, " ", a, " <> ", b)
