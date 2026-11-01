extends SceneTree
## Bounded synthetic checks for pass02 visual geometry and renderer ownership.
const GEO = preload("res://scripts/terrain/frontier_art_geology.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const PREVIEW = preload("res://scenes/tests/frontier_art_preview.tscn")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
var passed := 0
var failed := 0
var diagnostics: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		print("FAIL: ",label)

func run() -> void:
	_check_geology()
	_check_external_visual_owner()
	_check_flat_ground_owner()
	await _check_preview_obstacles()
	print("FRONTIER_PASS02 ",JSON.stringify({"passed":passed,"failed":failed,"synthetic_fixture":true,"diagnostics":diagnostics}))
	quit(1 if failed else 0)

func _check_geology() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	var profile = PROFILE.new()
	var first = GEO.new()
	var second = GEO.new()
	fixture.add_child(first)
	fixture.add_child(second)
	var first_footprints: Array = first.build(profile,Vector2(12.0,5.0))
	var second_footprints: Array = second.build(profile,Vector2(12.0,5.0))
	var first_data := _geometry_data(first)
	var second_data := _geometry_data(second)
	check(int(first_data["mesh_count"])>0 and int(first_data["vertex_count"])>0,"geology creates nonempty meshes")
	check(bool(first_data["finite"]),"all geology transforms, vertices and generated normals are finite")
	check(int(first_data["cap_vertices"])>0 and bool(first_data["caps_up"]),"SurfaceTool-generated geology cap normals point upward")
	check(int(first_data["wall_normals"])>0 and bool(first_data["walls_out"]),"SurfaceTool-generated vertical wall normals point outward")
	check(first_data["digest"]==second_data["digest"],"two fresh geology builds have identical mesh geometry and transforms")
	check(not first_footprints.is_empty() and first_footprints==second_footprints,"geology footprints are nonempty and deterministic")
	var finite_footprints := true
	for rect in first_footprints:
		finite_footprints = finite_footprints and rect.position.is_finite() and rect.size.is_finite() and rect.size.x>0.0 and rect.size.y>0.0
	check(finite_footprints,"geology returns finite positive footprint envelopes")
	diagnostics["geology"] = first_data
	fixture.free()

func _geometry_data(geology: Node3D) -> Dictionary:
	var entries: Array = []
	var vertex_count := 0
	var mesh_count := 0
	var finite := true
	var caps_up := true
	var cap_vertices := 0
	var walls_out := true
	var wall_normals := 0
	for mesh_variant in geology.find_children("*","MeshInstance3D",true,false):
		var instance := mesh_variant as MeshInstance3D
		mesh_count += 1
		var local_transform: Transform3D = geology.global_transform.affine_inverse()*instance.global_transform
		finite = finite and local_transform.origin.is_finite() and local_transform.basis.is_finite()
		for surface_index in range(instance.mesh.get_surface_count()):
			var arrays: Array = instance.mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			entries.append([local_transform,vertices,normals,arrays[Mesh.ARRAY_INDEX]])
			vertex_count += vertices.size()
			finite = finite and vertices.size()==normals.size()
			for index in range(vertices.size()):
				finite = finite and vertices[index].is_finite()
				if index>=normals.size():
					continue
				var normal := normals[index]
				finite = finite and normal.is_finite()
				if surface_index==instance.mesh.get_surface_count()-1:
					cap_vertices += 1
					caps_up = caps_up and normal.y>0.95
				elif absf(normal.y)<0.8:
					# Mesa vertices are local to their individual column, not the scene.
					var radial := Vector3(vertices[index].x,0.0,vertices[index].z).normalized()
					walls_out = walls_out and normal.dot(radial)>-0.03
					wall_normals += 1
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(var_to_bytes(entries))
	return {"mesh_count":mesh_count,"vertex_count":vertex_count,"finite":finite,"caps_up":caps_up,"cap_vertices":cap_vertices,"walls_out":walls_out,"wall_normals":wall_normals,"digest":hasher.finish().hex_encode()}

func _check_external_visual_owner() -> void:
	var data = MAP.create_empty("pass02_owner",Vector2i(5,5),Vector2.ZERO,64.0,32.0,3,"hex_axial_v1")
	var grid := Vector2i(2,2)
	var tile = data.get_tile_at_grid(grid)
	tile.walkable = false
	tile.blocks_los = true
	tile.object_height = 4
	var registry = REGISTRY.new()
	root.add_child(registry)
	registry.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
	for entry in data.get_tiles():
		registry.register_tile(entry)
	var facts := _facts(data)
	var revision: int = registry.get_revision()
	var view = VIEW.new()
	root.add_child(view)
	view.set_frontier_art_enabled(true)
	view.configure_from_map(data)
	var baseline: Dictionary = view.get_render_snapshot()
	var fallback_count: int = int(baseline.get("missing_asset_mapping_count",0))
	check(fallback_count>0,"an explicitly tall blocker without a model has a fallback marker")
	var owner := MeshInstance3D.new()
	owner.name = "ExternalBlockerOwner"
	owner.mesh = BoxMesh.new()
	owner.position = view.call("_grid_to_3d_position",Vector2(grid),0.5)
	view.get_node("ViewportContainer/SubViewport/WorldRoot").add_child(owner)
	view.set_external_terrain_object_visuals({grid:owner})
	var owned: Dictionary = view.get_render_snapshot()
	check(int(owned.get("missing_asset_mapping_count",0))<fallback_count,"live external owner removes the duplicate fallback")
	check(int(owned.get("tile_count",0))==25,"external object ownership preserves ground rendering")
	check(_facts(data)==facts and registry.get_revision()==revision,"external visual registration changes no serialized map facts or registry revision")
	view.set_frontier_art_enabled(false)
	view.set_frontier_art_enabled(true)
	check(_facts(data)==facts and registry.get_revision()==revision,"profile toggles with external ownership remain read-only")
	owner.free()
	view.render_map()
	check(int(view.get_render_snapshot().get("missing_asset_mapping_count",0))==fallback_count,"freed weak owner restores its fallback on the next render")
	check(_facts(data)==facts and registry.get_revision()==revision,"owner destruction and fallback restore change no map facts")
	diagnostics["fallback_without_owner"] = fallback_count
	view.free()
	registry.free()

func _check_flat_ground_owner() -> void:
	var data = MAP.create_empty("pass02_flat_owner",Vector2i(4,4),Vector2.ZERO,64.0,32.0,3,"hex_axial_v1")
	data.get_tile_at_grid(Vector2i(3,3)).height_level = 1
	var facts := _facts(data)
	var view = VIEW.new()
	root.add_child(view)
	view.set_frontier_art_enabled(true)
	view.configure_from_map(data)
	check(int(view.get_render_snapshot().get("ground_multimesh_tile_count",0))==16,"without a flat owner every Hex ground column is rendered")
	var owner := MeshInstance3D.new()
	owner.name = "ExternalFlatGroundOwner"
	var plane := PlaneMesh.new()
	plane.size = Vector2(20.0,20.0)
	owner.mesh = plane
	owner.position.y = 0.0015
	view.get_node("ViewportContainer/SubViewport/WorldRoot").add_child(owner)
	view.set_flat_ground_visual_owner(owner)
	var snapshot: Dictionary = view.get_render_snapshot()
	check(int(snapshot.get("tile_count",0))==16,"flat visual ownership retains every source tile")
	check(int(snapshot.get("ground_multimesh_tile_count",0))==1,"flat owner suppresses only zero-height columns; elevated Hex remains rendered")
	var camera: Camera3D = view.get_node("ViewportContainer/SubViewport/WorldRoot/Camera3D")
	for grid in [Vector2i(0,0),Vector2i(3,3)]:
		var tile = data.get_tile_at_grid(grid)
		var position: Vector3 = view.call("_grid_to_3d_position",Vector2(grid),float(tile.height_level)*float(view.call("_get_3d_height_step")))
		check(view.screen_to_grid_position(camera.unproject_position(position))==grid,"flat ownership preserves flat/elevated source-cell picking")
	check(_facts(data)==facts,"flat visual ownership leaves map facts unchanged")
	owner.free()
	view.render_map()
	check(int(view.get_render_snapshot().get("ground_multimesh_tile_count",0))==16,"freed flat weak owner restores all ground columns on the next render")
	check(_facts(data)==facts,"restoring ground columns after owner destruction remains read-only")
	view.free()

func _check_preview_obstacles() -> void:
	var preview = PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.get("_sim").set_physics_process(false)
	var data = preview.get("_data")
	var registry = preview.get("_registry")
	var stage: Node3D = preview.get("_stage")
	var geology: Node3D = null
	var dressing: Node3D = null
	for child in stage.get_children():
		if child.get_script()==GEO:
			geology = child
		elif child.get_script()==preload("res://scripts/terrain/frontier_art_dressing.gd"):
			dressing = child
	check(geology!=null and dressing!=null,"native preview contains both pass02 visual groups")
	if geology==null or dressing==null:
		preview.free()
		return
	var geology_rects: Array = geology.get("_footprints")
	var dressing_rects: Array = dressing.get("_footprints")
	var geology_cells := 0
	var dressing_cells := 0
	var walkable_obstacles := 0
	var missing_cliff_los := 0
	for tile in data.get_tiles():
		var plane: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position))
		for rect in geology_rects:
			if rect.has_point(plane):
				geology_cells += 1
				if bool(tile.walkable) or registry.is_walkable(tile.grid_position):
					walkable_obstacles += 1
				if not bool(tile.blocks_los) or int(tile.object_height)<=0:
					missing_cliff_los += 1
				break
		for rect in dressing_rects:
			if rect.has_point(plane):
				dressing_cells += 1
				if bool(tile.walkable) or registry.is_walkable(tile.grid_position):
					walkable_obstacles += 1
				break
	check(geology_cells>0 and dressing_cells>0,"declared obstacle envelopes reserve actual source cells")
	check(walkable_obstacles==0,"declared cliff, rock and prop obstacles contain no walkable cell centers")
	check(missing_cliff_los==0,"cliff cells carry explicit blocker height and LOS facts")
	var facts := _facts(data)
	var revision: int = registry.get_revision()
	var view = preview.get("_view")
	view.set_hex_grid_visible(true)
	view.set_frontier_art_enabled(false)
	view.set_frontier_art_enabled(true)
	check(_facts(data)==facts and registry.get_revision()==revision,"full preview display rebuilds preserve authored obstacle facts")
	diagnostics["geology_reserved_cells"] = geology_cells
	diagnostics["dressing_reserved_cells"] = dressing_cells
	diagnostics["walkable_obstacle_centers"] = walkable_obstacles
	preview.free()
	await process_frame

func _facts(data) -> Array:
	var result: Array = []
	for tile in data.get_tiles():
		result.append(tile.to_dict())
	return result
