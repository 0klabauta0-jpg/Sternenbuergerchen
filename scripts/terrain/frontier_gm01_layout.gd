extends RefCounted
## Concrete GM01 composition, built once during authoring or visual installation.
## Returned envelopes are descriptions, never writes to MapData or a Registry.
## Keep the root at the original world origin: paving/contact wear uses world XZ.

const LAYOUT_ID := "gm01_frontier_outpost_v1"
const GRID_SIZE := Vector2i(96, 98)
const OFFSET_ORIGIN := Vector2i(-24, -25)
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const GEOLOGY = preload("res://scripts/terrain/frontier_art_geology.gd")
const DRESSING = preload("res://scripts/terrain/frontier_art_dressing.gd")
const CLOSED_BUILDING = preload("res://scripts/terrain/frontier_closed_buildings.gd")
const WORKLIFE = preload("res://scripts/terrain/frontier_worklife.gd")
const ACCESS = preload("res://scripts/terrain/frontier_access_anchors.gd")
const REFERENCE_DRESSING = preload("res://scripts/terrain/frontier_reference_dressing.gd")
const ART_ROOT := "res://Assets/curated/frontier_illustrated_20261101/structures_pass04/"
const MODEL_SCALE := 0.35
const OBJECT_HEIGHT_STEP := 0.42


static func build(parent: Node3D, saved_ground_grids = null) -> Dictionary:
	assert(parent != null and parent.is_inside_tree(), "GM01 layout needs an in-tree parent for source bounds.")
	var root := Node3D.new()
	root.name = "FrontierGM01Outpost"
	root.set_meta("authored_visual_layout_id", LAYOUT_ID)
	parent.add_child(root)
	var profile := PROFILE.new()
	profile.quiet_tactical_surface=true
	var blockers: Array = []
	var assets: Array = []
	var anchors: Dictionary = {}
	var ground := _ground(root, profile, saved_ground_grids)

	for spec in [
		["habitat_cutaway_01", Vector2(8.3, 6.2)],
		["freihafen_hall_01", Vector2(13.2, 6.2)],
		["utility_fuel_01", Vector2(16.1, 8.2)],
	]:
		_add_structure(root, String(spec[0]), spec[1], blockers, anchors, assets)

	# These are paint/compacted ground, not the preview's 0.16 m raised decks.
	# The original pad centres retain all existing access and contact-wear anchors.
	_flat_apron(root, profile, Vector2(6.5, 10.9), Vector2(5.0, 4.4), "01")
	_flat_apron(root, profile, Vector2(19.2, 11.8), Vector2(4.2, 4.1), "02")
	anchors["pad01"] = ACCESS.pad(Vector2(6.5, 10.9), Vector2(5.0, 4.4), 1.0)
	anchors["pad02"] = ACCESS.pad(Vector2(19.2, 11.8), Vector2(4.2, 4.1), -1.0)
	_solar_array(root, blockers)

	var geology = GEOLOGY.new()
	geology.name = "FrontierErodedGeology"
	root.add_child(geology)
	var geological_envelopes: Array[Rect2] = geology.build(profile, Vector2(12.0, 5.0))
	var geology_groups: Array[Node] = geology.get_children()
	for index in range(geological_envelopes.size()):
		var group := geology_groups[index] as Node3D
		var bounds := _combined_bounds(group, root)
		_add_blocker(blockers, "geology_%02d" % index, geological_envelopes[index], true,
			_object_height(bounds.end.y), 75, "geology")

	# Continue the same eroded family around the larger square-map perimeter.
	# The service spine, eastern squad entry and raised yard (18..24,18..23) stay open.
	for spec in [
		["SouthwestRidge", Vector2(3.4, 24.5), Vector3(4.2, 1.65, 3.3), 1703],
		["SouthernBrokenRidge", Vector2(10.0, 29.3), Vector3(5.6, 2.1, 3.2), 1811],
		["SoutheastRidge", Vector2(28.6, 27.6), Vector3(4.0, 1.8, 3.3), 1907],
		["EasternShoulder", Vector2(30.4, 18.8), Vector3(3.2, 1.5, 3.8), 2017],
		["LandingMesa", Vector2(41.0, 42.0), Vector3(14.0, 3.8, 14.0), 2208],
	]:
		# Reuse the geology's actual erosion constructor, not a separate proxy mesh.
		geology._add_mesa(String(spec[0]), spec[1], spec[2], int(spec[3]))
		var group := geology.get_child(geology.get_child_count() - 1) as Node3D
		var bounds := _combined_bounds(group, root)
		_add_blocker(blockers, "edge_" + String(spec[0]), _xz_rect(bounds).grow(0.04),
			true, _object_height(bounds.end.y), 65, "geology")

	var dressing = DRESSING.new()
	dressing.name = "FrontierWorkingGround"
	root.add_child(dressing)
	var dressing_envelopes: Array[Rect2] = dressing.build(profile, anchors)
	dressing.set_buildings_closed(true)
	# Ordering follows the existing concrete builder: seven small rock groups,
	# three crates, three container stacks, then the open-frame radio-mast foot.
	for index in range(dressing_envelopes.size()):
		var kind := "small_rock" if index < 7 else "supply_crate"
		var height := 1
		var cover := 30
		var blocks_los := false
		if index >= 10 and index < 13:
			kind = "container_stack"
			height = 2 if index == 10 else 1
			cover = 55 if index == 10 else 35
		elif index == 13:
			kind = "mast_foot"
			cover = 10
		# Thin mast uprights are not a filled full-height LOS wall.
		_add_blocker(blockers, "dressing_%02d" % index, dressing_envelopes[index],
			blocks_los, height, cover, kind)
	var access_snapshot: Dictionary = dressing.get_access_snapshot()

	var worklife = WORKLIFE.new()
	worklife.name = "FrontierUseGroups"
	root.add_child(worklife)
	var worklife_envelopes: Array[Rect2] = worklife.build()
	for index in range(worklife_envelopes.size()):
		var kind := "working_container" if index == 4 else "working_furniture"
		_add_blocker(blockers, "worklife_%02d" % index, worklife_envelopes[index],
			false, 2 if index == 4 else 1, 40 if index == 4 else 20, kind)
	for fact in worklife.source_facts:
		_record_asset(assets, String(fact.get("path", "")))
		_record_asset(assets, String(fact.get("atlas_path", "")))
		_record_asset(assets, String(fact.get("license_path", "")))
	var paths: Array = access_snapshot.get("paths", []).duplicate(true)
	_extend_supply_country(root, profile, geology, blockers, paths, assets)

	var facts := {
		"root": root,
		"flat_ground": ground,
		"blockers": blockers,
		"paths": paths,
		"assets": assets,
		"layout_id": LAYOUT_ID,
		"grid_size": GRID_SIZE,
	}
	facts["reference_dressing_context"] = _reference_dressing_context(root, blockers, paths)
	var plant := dressing.find_child("DryAgave", true, false) as MeshInstance3D
	var gravel := worklife.get_node_or_null("ContactGravelBatch") as MultiMeshInstance3D
	if plant != null and gravel != null and gravel.multimesh != null:
		facts["reference_dressing_sources"] = {"agave_mesh": plant.mesh, "agave_material": plant.material_override,
			"gravel_mesh": gravel.multimesh.mesh, "gravel_material": gravel.material_override}
	return facts


static func refresh_reference_dressing(facts: Dictionary, map_data) -> Dictionary:
	var root := facts.get("root") as Node3D
	if not is_instance_valid(root):
		return {"installed": false, "reason": "no_authored_root"}
	var previous := root.get_node_or_null(REFERENCE_DRESSING.LAYER_NAME) as Node3D
	var previous_was_visible := previous != null and previous.visible
	if previous != null:
		previous.visible = false
	var plan: Dictionary = REFERENCE_DRESSING.build_plan(map_data, facts.get("reference_dressing_context", {}))
	var result: Dictionary = REFERENCE_DRESSING.install(root, plan, facts.get("reference_dressing_sources", {}))
	if bool(result.get("installed", false)) and bool(result.get("reused", false)) and is_instance_valid(previous):
		previous.visible = previous_was_visible
	if not bool(result.get("installed", false)) and is_instance_valid(previous):
		root.remove_child(previous)
		previous.free()
	facts["reference_dressing_layer"] = result.get("layer")
	return result


static func _reference_dressing_context(root: Node3D, blockers: Array, paths: Array) -> Dictionary:
	var centers: Array[Vector2] = []
	var pads: Array[Rect2] = []
	var doors: Array[Vector2] = []
	# Existing envelopes define only visual cluster centres, never new obstacles.
	for blocker in blockers:
		if String(blocker.get("kind", "")) in ["building", "working_container", "container_stack", "solar_array"]:
			var rect: Rect2 = blocker["rect"]
			centers.append(rect.position - Vector2.ONE * 0.9)
			centers.append(rect.end + Vector2.ONE * 0.9)
	# Cold own-root inspection only; no SceneTree scan or per-frame discovery.
	for child in root.get_children():
		if child.has_meta("access_anchor"):
			var anchor: Dictionary = child.get_meta("access_anchor")
			if anchor.get("ground") is Vector2:
				doors.append(anchor["ground"])
		if String(child.name).begins_with("PaintedLandingApron"):
			var pad := child.get_node_or_null("GroundLevelCompactedApron") as MeshInstance3D
			if pad != null:
				pads.append(_mesh_xz_bounds(pad, root))
		elif String(child.name) == "EasternOpenSupplyCourt" and child is MeshInstance3D:
			pads.append(_mesh_xz_bounds(child, root))
	return {"cluster_centers": centers, "blockers": blockers, "paths": paths, "pad_rects": pads, "door_points": doors}


static func _mesh_xz_bounds(mesh: MeshInstance3D, space: Node3D) -> Rect2:
	var bounds := mesh.mesh.get_aabb()
	var transform := space.global_transform.affine_inverse() * mesh.global_transform
	var result := Rect2()
	for corner in range(8):
		var local := bounds.position + bounds.size * Vector3(float(corner & 1), float((corner >> 1) & 1), float((corner >> 2) & 1))
		var point: Vector3 = transform * local
		result = Rect2(Vector2(point.x, point.z), Vector2.ZERO) if corner == 0 else result.expand(Vector2(point.x, point.z))
	return result


static func get_authoring_grid_positions() -> Array[Vector2i]:
	# Offline coverage only. Runtime supplies the actual saved MapData cells.
	var grids: Array[Vector2i] = []
	var last_row := OFFSET_ORIGIN.y + GRID_SIZE.y - 1
	var first_q := OFFSET_ORIGIN.x - floori(float(last_row) * 0.5)
	var last_q := OFFSET_ORIGIN.x + GRID_SIZE.x - 1 - floori(float(OFFSET_ORIGIN.y) * 0.5)
	for q in range(first_q, last_q + 1):
		for row in range(OFFSET_ORIGIN.y, OFFSET_ORIGIN.y + GRID_SIZE.y):
			var column := q + floori(float(row) * 0.5)
			if column >= OFFSET_ORIGIN.x and column < OFFSET_ORIGIN.x + GRID_SIZE.x:
				grids.append(Vector2i(q, row))
	return grids


static func ground_grid_signature(grids: Array) -> String:
	var keys: PackedStringArray = []
	for grid in grids:
		keys.append("%d,%d" % [grid.x, grid.y])
	keys.sort()
	return "|".join(keys).sha256_text()


static func configure_ground_mesh(ground: MeshInstance3D, grids: Array, saved_source: bool) -> void:
	# The rendered surface is the union of real Hex polygons, including the
	# scalloped outer boundary. No decorative PlaneMesh extends past the cells.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	vertices.resize(grids.size() * 7)
	normals.resize(vertices.size())
	uvs.resize(vertices.size())
	indices.resize(grids.size() * 18)
	var corners: PackedVector2Array = HEX.corners()
	for cell_index in range(grids.size()):
		var center: Vector2 = HEX.axial_to_plane(Vector2(grids[cell_index]))
		var offset := cell_index * 7
		vertices[offset] = Vector3(center.x, 0.0015, center.y)
		normals[offset] = Vector3.UP
		uvs[offset] = center
		for corner_index in range(6):
			var point := center + corners[corner_index]
			vertices[offset + 1 + corner_index] = Vector3(point.x, 0.0015, point.y)
			normals[offset + 1 + corner_index] = Vector3.UP
			uvs[offset + 1 + corner_index] = point
			var triangle := cell_index * 18 + corner_index * 3
			indices[triangle] = offset
			# Godot front faces use clockwise winding, like the existing tile fill.
			indices[triangle + 1] = offset + 1 + corner_index
			indices[triangle + 2] = offset + 1 + (corner_index + 1) % 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	if not grids.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	ground.mesh = mesh
	ground.position = Vector3.ZERO
	ground.set_meta("ground_cell_count", grids.size())
	ground.set_meta("ground_vertex_count", vertices.size())
	ground.set_meta("ground_grid_signature", ground_grid_signature(grids))
	ground.set_meta("ground_coverage_source", "saved_map_tiles" if saved_source else "offline_authoring_coverage")


static func _ground(root: Node3D, profile, saved_ground_grids) -> MeshInstance3D:
	var ground := MeshInstance3D.new()
	ground.name = "ContinuousFrontierGround"
	var grids: Array = get_authoring_grid_positions() if saved_ground_grids == null else saved_ground_grids
	configure_ground_mesh(ground, grids, saved_ground_grids != null)
	ground.material_override = profile.material_for(profile.surface_color("ground"))
	# This flat receiver cannot cast useful terrain shadows; self-shadowing the
	# coplanar hex triangles causes diagonal bands in Compatibility rendering.
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ground)
	return ground


static func _add_structure(root: Node3D, model: String, plane: Vector2,
		blockers: Array, anchors: Dictionary, assets: Array, placement_id: String = "",
		display_name: String = "") -> void:
	var path := ART_ROOT + model + ".glb"
	if not ResourceLoader.exists(path):
		push_error("Missing GM01 Frontier structure: " + path)
		return
	var scene := load(path) as PackedScene
	var visual := scene.instantiate() as Node3D
	visual.name = model if placement_id.is_empty() else placement_id
	visual.scale = Vector3.ONE * MODEL_SCALE
	visual.position = Vector3(plane.x, 0.0, plane.y)
	root.add_child(visual)
	_record_asset(assets, path)
	var bounds := _combined_bounds(visual, root)
	var solid_bounds := bounds
	if model in ["habitat_cutaway_01", "freihafen_hall_01"]:
		var hall := model == "freihafen_hall_01"
		var shell = CLOSED_BUILDING.new()
		shell.name = "ClosedExterior_" + (model if placement_id.is_empty() else placement_id)
		root.add_child(shell)
		shell.build(bounds, hall)
		if not display_name.is_empty():
			var label := shell.get_node_or_null("ExteriorIdentification") as Label3D
			if label != null:
				label.text = display_name
		anchors["hall" if hall else "habitat"] = shell.get_meta("access_anchor")
		visual.visible = false
		# Measure the visible closed hull, including its canopy/step and side modules.
		# Do not keep an unrelated rectangular proxy or the hidden cutaway bounds.
		solid_bounds = _combined_bounds(shell, root)
	_add_blocker(blockers, "structure_" + (model if placement_id.is_empty() else placement_id), _xz_rect(solid_bounds).grow(0.04),
		true, _object_height(solid_bounds.end.y), 80, "building")


static func _extend_supply_country(root: Node3D, profile, geology: Node3D,
		blockers: Array, paths: Array, assets: Array) -> void:
	# The first 43 original blockers and all wear-anchored groups stay untouched.
	# New ridges frame open traversable space; none closes the three supply probes
	# (35,27), (42,26), (43,30), or the original raised loading-yard contract.
	for spec in [
		["NortheastRidge", Vector2(40.5, 3.0), Vector3(7.0, 3.4, 5.0), 2113],
		["EasternEscarpment", Vector2(46.1, 12.5), Vector3(3.9, 2.9, 6.0), 2203],
		["EasternBrokenWall", Vector2(45.7, 20.7), Vector3(3.5, 2.2, 4.0), 2309],
		["SoutheastBoundary", Vector2(47.0, 35.4), Vector3(3.8, 2.3, 4.6), 2411],
		["SouthernEastCrown", Vector2(37.1, 38.4), Vector3(6.0, 2.2, 3.5), 2503],
		["SouthernLongRidge", Vector2(22.0, 38.0), Vector3(6.5, 2.4, 3.5), 2609],
		["SouthernLowShoulder", Vector2(15.3, 35.5), Vector3(4.5, 1.7, 3.2), 2707],
		["EasternInteriorSpur", Vector2(38.8, 18.7), Vector3(3.0, 1.5, 3.1), 2801],
		["NorthernEastButtress", Vector2(37.5, 10.4), Vector3(4.2, 2.0, 3.3), 2903],
	]:
		geology.call("_add_mesa", String(spec[0]), spec[1], spec[2], int(spec[3]))
		var group := geology.get_child(geology.get_child_count() - 1) as Node3D
		var bounds := _combined_bounds(group, root)
		_add_blocker(blockers, "extension_" + String(spec[0]), _xz_rect(bounds).grow(0.04),
			true, _object_height(bounds.end.y), 65, "geology")

	var supply_anchors: Dictionary = {}
	_add_structure(root, "freihafen_hall_01", Vector2(31.0, 23.0), blockers,
		supply_anchors, assets, "supply_hall_east", "VERSORGUNG  04")
	var apron := MeshInstance3D.new()
	apron.name = "EasternOpenSupplyCourt"
	var plane := PlaneMesh.new()
	plane.size = Vector2(6.2, 5.2)
	apron.mesh = plane
	apron.position = Vector3(35.1, 0.008, 25.6)
	apron.material_override = profile.surface_material_for("road")
	apron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(apron)
	var positions := [Vector2(28.0, 22.8), Vector2(33.5, 21.2), Vector2(33.5, 22.5)]
	for index in range(3):
		_supply_container(root, positions[index], index, blockers, assets)
	# Two independent approaches make the larger ground useful as a loop.
	# The southern approach skirts the existing (28.6,27.6) mesa instead of
	# painting a shortcut through its preserved massive body.
	_new_path(root, profile, paths, "east_supply_connection", [
		Vector2(21.8, 12.8), Vector2(27.8, 12.8), Vector2(34.6, 15.2),
		Vector2(35.5, 21.0), Vector2(35.5, 26.0)], 2.0)
	_new_path(root, profile, paths, "southern_supply_loop", [
		Vector2(18.0, 20.0), Vector2(18.0, 24.0), Vector2(24.0, 24.0),
		Vector2(24.0, 31.5), Vector2(34.5, 31.5), Vector2(35.5, 27.0)], 2.0)
	_new_path(root, profile, paths, "eastern_open_approach", [
		Vector2(35.5, 26.0), Vector2(42.0, 26.0), Vector2(43.0, 30.0)], 2.1)
	if supply_anchors.has("hall"):
		var entry: Vector2 = supply_anchors["hall"]["ground"]
		_new_path(root, profile, paths, "supply_hall_entrance", [entry,
			Vector2(32.7, 25.1), Vector2(35.5, 26.0)], 0.85)


static func _supply_container(root: Node3D, centre: Vector2, index: int,
		blockers: Array, assets: Array) -> void:
	var path := "res://Assets/curated/kenney/space_station/models/container-wide.glb"
	var scene := load(path) as PackedScene
	var visual := scene.instantiate() as Node3D
	visual.name = "SupplyContainer_%02d" % index
	visual.scale = Vector3.ONE * 0.43
	visual.position = Vector3(centre.x, 0.0, centre.y)
	visual.rotation_degrees.y = -8.0 if index == 0 else 9.0
	root.add_child(visual)
	var bounds := _combined_bounds(visual, root)
	visual.position.y -= bounds.position.y
	bounds = _combined_bounds(visual, root)
	for child in visual.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		for surface in range(instance.mesh.get_surface_count()):
			var original: Material = instance.get_active_material(surface)
			if original is StandardMaterial3D:
				var tinted: StandardMaterial3D = original.duplicate()
				tinted.albedo_color *= Color("e2d5b9")
				tinted.roughness = 0.93
				instance.set_surface_override_material(surface, tinted)
	_add_blocker(blockers, "supply_container_%02d" % index, _xz_rect(bounds).grow(0.06),
		false, _object_height(bounds.end.y), 40, "working_container")
	_record_asset(assets, path)


static func _new_path(root: Node3D, profile, paths: Array, id: String,
		points: Array, width: float) -> void:
	paths.append({"id": id, "points": points.duplicate(), "width": width, "service_lane": true})
	# Generic painterly road materials intentionally have no old-coordinate wear.
	_road_ribbon(root, profile.material_for(Color("b47b53")), id + "Shoulder", points, width + 0.18, 0.006)
	_road_ribbon(root, profile.surface_material_for("road"), id, points, width, 0.011)


static func _road_ribbon(root: Node3D, material: Material, id: String, points: Array,
		width: float, height: float) -> void:
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for index in range(points.size()):
		var previous: Vector2 = points[maxi(index - 1, 0)]
		var current: Vector2 = points[index]
		var next: Vector2 = points[mini(index + 1, points.size() - 1)]
		var before := (current - previous).normalized()
		var after := (next - current).normalized()
		if index == 0:
			before = after
		elif index == points.size() - 1:
			after = before
		var normal := Vector2(-(before + after).y, (before + after).x).normalized()
		var outgoing_normal := Vector2(-after.y, after.x)
		var offset := normal * (width * 0.5 / maxf(normal.dot(outgoing_normal), 0.35))
		left.append(Vector3(current.x + offset.x, height, current.y + offset.y))
		right.append(Vector3(current.x - offset.x, height, current.y - offset.y))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)
	for index in range(points.size() - 1):
		# Godot front faces use clockwise winding viewed from above.
		for vertex in [left[index], right[index + 1], left[index + 1],
			left[index], right[index], right[index + 1]]:
			surface.add_vertex(vertex)
	var instance := MeshInstance3D.new()
	instance.name = "SupplyRoad_" + id
	instance.mesh = surface.commit()
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)


static func _flat_apron(root: Node3D, profile, centre: Vector2,
		size: Vector2, designation: String) -> void:
	var group := Node3D.new()
	group.name = "PaintedLandingApron" + designation
	group.position = Vector3(centre.x, 0.0, centre.y)
	root.add_child(group)
	var mesh := PlaneMesh.new()
	mesh.size = size
	var apron := MeshInstance3D.new()
	apron.name = "GroundLevelCompactedApron"
	apron.mesh = mesh
	apron.position.y = 0.009
	apron.material_override = profile.material_for(Color("727b6d"), false, true)
	apron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	group.add_child(apron)
	var half := size * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var x: float = sx * (half.x - 0.50)
			var z: float = sz * (half.y - 0.50)
			_box(group, "LandingBracket", Vector3(0.58, 0.0015, 0.045),
				Vector3(x - sx * 0.26, 0.011, z), "d8ae62")
			_box(group, "LandingBracket", Vector3(0.045, 0.0015, 0.53),
				Vector3(x, 0.011, z - sz * 0.24), "d8ae62")
	for x in [-half.x * 0.40, half.x * 0.40]:
		_box(group, "WornJoint", Vector3(0.014, 0.001, size.y - 0.75),
			Vector3(x, 0.010, 0.0), "56695e")
	var label := Label3D.new()
	label.name = "PaintedPadDesignation"
	label.text = designation
	label.font_size = 64
	label.pixel_size = 0.004
	label.modulate = Color("c7c8ad")
	label.outline_size = 0
	label.rotation_degrees.x = -90.0
	label.position = Vector3(half.x - 0.56, 0.013, -0.15)
	group.add_child(label)


static func _solar_array(root: Node3D, blockers: Array) -> void:
	var group := Node3D.new()
	group.name = "SolarArray"
	group.position = Vector3(9.1, 0.0, 3.8)
	root.add_child(group)
	for index in range(3):
		var x := float(index) * 0.85 - 0.85
		_box(group, "PanelSupport", Vector3(0.07, 0.4, 0.07), Vector3(x, 0.2, 0.0), "505955")
		var panel := _box(group, "SolarPanel", Vector3(0.78, 0.04, 0.95), Vector3(x, 0.52, 0.0), "244d63")
		panel.rotation.x = deg_to_rad(-25.0)
		for z in [-0.40, 0.0, 0.40]:
			_box(panel, "PanelCellRow", Vector3(0.75, 0.008, 0.012), Vector3(0.0, 0.025, z), "9aa7a8")
	var bounds := _combined_bounds(group, root)
	_add_blocker(blockers, "solar_array", _xz_rect(bounds).grow(0.04), false,
		_object_height(bounds.end.y), 30, "solar_array")


static func _box(parent: Node3D, label: String, size: Vector3, position: Vector3,
		color: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = 0.94
	instance.material_override = material
	parent.add_child(instance)
	return instance


static func _combined_bounds(node: Node3D, space: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var to_local := space.global_transform.affine_inverse()
	# A one-time construction traversal, never a runtime update/SceneTree scan.
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		var bounds: AABB = (to_local * instance.global_transform) * instance.get_aabb()
		result = bounds if first else result.merge(bounds)
		first = false
	return result


static func _xz_rect(bounds: AABB) -> Rect2:
	return Rect2(Vector2(bounds.position.x, bounds.position.z), Vector2(bounds.size.x, bounds.size.z))


static func _object_height(height: float) -> int:
	# TerrainTileData's serialized object-height domain is 0..3, in 0.42 m steps.
	# Taller rocks remain class 3 instead of writing a value discarded on load.
	return clampi(ceili(height / OBJECT_HEIGHT_STEP), 1, 3)


static func _add_blocker(blockers: Array, id: String, rect: Rect2, blocks_los: bool,
		object_height: int, cover_value: int, kind: String) -> void:
	blockers.append({"id": id, "rect": rect, "blocks_los": blocks_los,
		"object_height": object_height, "cover_value": cover_value, "kind": kind})


static func _record_asset(assets: Array, path: String) -> void:
	if path.is_empty():
		return
	for entry in assets:
		if entry["path"] == path:
			return
	assets.append({"path": path, "sha256": FileAccess.get_sha256(path)})
