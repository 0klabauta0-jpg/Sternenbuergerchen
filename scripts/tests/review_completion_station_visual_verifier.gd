extends SceneTree
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
var passed := 0
var failed := 0

func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func add_model(view: Node, type_id: String, cell: Vector2i, rotation: float) -> Node3D:
	var tile := TILE.new({"tile_id": "fixture", "type_id": type_id, "grid_position": cell, "object_rotation_degrees": rotation})
	check(view.call("_add_asset_model_visual", tile, 0.0, type_id, true), "actual imported module " + type_id)
	return view.get("_map_root").get_child(view.get("_map_root").get_child_count() - 1)

func run() -> void:
	var view := VIEW.new()
	var models := Node3D.new()
	view.add_child(models)
	view.set("_map_root", models)
	view.set("_active_grid_topology", "hex_axial_v1")
	var grid_material:ShaderMaterial=view.call("_make_hex_grid_material",false)
	check(grid_material.get_shader_parameter("line_color").a>=0.65 and float(grid_material.get_shader_parameter("minimum_pixel_width"))>=1.8 and float(grid_material.get_shader_parameter("distant_contrast_floor"))>=0.65,"normal tactical overview retains legible Hex coverage")
	for spec: Array in [[0.0, Vector2i(1, 0)], [90.0, Vector2i(0, -1)], [180.0, Vector2i(-1, 0)], [270.0, Vector2i(0, 1)]]:
		for kind: String in ["station_set_floor_panel", "station_set_wall", "station_set_wall_door"]:
			var a := add_model(view, kind, Vector2i.ZERO, spec[0])
			var b := add_model(view, kind, spec[1], spec[0])
			var center_delta: Vector3 = b.position - a.position
			# The real imported module is one metre along X. Compare its seam
			# against actual projected cell centers, not the implementation helper.
			var axis: Vector3 = a.basis.x
			var gap := (b.position - b.basis.x * 0.5) - (a.position + axis * 0.5)
			check(axis.normalized().is_equal_approx(center_delta.normalized()), kind + " row follows cell centers " + str(spec[0]))
			check(gap.cross(center_delta).length() < 0.00001, kind + " no lateral staircase at seam " + str(spec[0]))
			if kind.contains("floor"):
				var interval_a:=_project_mesh_bounds(a,center_delta.normalized())
				var interval_b:=_project_mesh_bounds(b,center_delta.normalized())
				var actual_gap:float=interval_b.x-interval_a.y
				check(actual_gap>=-0.00001 and actual_gap<0.01,"actual Hex floor footprints have thin continuous seam "+str(spec[0]))
			else:check(is_equal_approx(gap.length(),0.1),kind+" authored wall seam retained "+str(spec[0]))
			if not kind.contains("floor"):check(absf(a.basis.x.normalized().dot(a.basis.z.normalized()))<0.00001,kind+" original wall perspective is not sheared")
			var bounds: Dictionary = view.call("_get_local_visual_bounds", a)
			check(bounds.valid and Vector3(bounds.min).is_finite() and Vector3(bounds.max).is_finite() and Vector3(bounds.max).y > Vector3(bounds.min).y, kind + " finite positive native bounds")
			a.free()
			b.free()
	for kind: String in ["station_set_wall_corner", "station_set_door_single", "station_set_door_single_half", "station_set_door_single_closed", "station_set_door_double_closed", "modular_floor", "modular_wall", "modular_wall_corner", "modular_gate"]:
		var model := add_model(view, kind, Vector2i(3, 2), 90.0)
		var expected: Vector3 = Vector3(-0.5, 0.0, -sqrt(3.0) * 0.5)
		check(model.basis.x.normalized().is_equal_approx(expected), kind + " shares rotated axial module basis")
		check(model.basis.y.normalized().is_equal_approx(Vector3.UP) and model.basis.determinant() > 0.0, kind + " upright nonmirrored geometry")
		if not kind.contains("floor"):check(absf(model.basis.x.normalized().dot(model.basis.z.normalized()))<0.00001,kind+" retains orthogonal local body")
		model.free()
	for kind: String in ["frontier_utility_fuel_01", "station_set_chair_armrest", "station_set_computer_wide", "nature_tree_blocker", "fahrzeug_speeder"]:
		check(Basis(view.call("_get_cell_module_visual_basis", kind)).is_equal_approx(Basis.IDENTITY), kind + " standalone shape unchanged")
	for kind: String in ["station_wall", "station_wall_door", "wall_straight_ne", "wall_corner_sw", "spacekit_corridor_split", "spacekit_pipe_corner", "station_set_balcony_floor_center", "station_set_balcony_floor_corner"]:
		check(not Basis(view.call("_get_cell_module_visual_basis", kind)).is_equal_approx(Basis.IDENTITY), kind + " productive legacy module shares cell axes")
	view.set("_active_grid_topology", "square8")
	var legacy := add_model(view, "station_set_wall", Vector2i.ZERO, 90.0)
	check(legacy.basis.x.normalized().is_equal_approx(Vector3(0.0, 0.0, -1.0)), "legacy square module orientation unchanged")
	legacy.free()
	# Both imported ground routes must retain the same projected basis. The
	# floor batch reuses the same derived thin Hex mesh and immutable material.
	view.set("_active_grid_topology", "hex_axial_v1")
	var floor_tile := TILE.new({"tile_id": "floor", "type_id": "station_set_floor_panel", "grid_position": Vector2i.ZERO})
	check(view.call("_add_ground_model_visual", floor_tile, 0.0, "station_set_floor_panel"), "individual floor route")
	var individual: Node3D = models.get_child(models.get_child_count() - 1)
	check(individual.basis.z.normalized().is_equal_approx(Vector3(0.5, 0.0, sqrt(3.0) * 0.5)), "individual floor has axial seam axis")
	check(view.call("_queue_ground_model_batch", floor_tile, 0.0, "station_set_floor_panel"), "batched floor route")
	var batches: Dictionary = view.get("_ground_batch_requests")
	var batch: Dictionary = batches.values()[0]
	var root_transform: Transform3D = Transform3D(batch.transforms[0]) * Transform3D(batch.source.mesh_transform).affine_inverse()
	check(root_transform.is_equal_approx(individual.transform), "batch and individual floor transforms agree")
	for map_id: String in ["station_outpost_64x64", "station_outpost_192x192", "test_mission_32x32_slots8"]:
		var map = MAP.load_from_file("res://maps/" + map_id + ".json")
		var count := 0
		var before := JSON.stringify(map.get_tiles().map(func(tile): return tile.to_dict()))
		view.set("_terrain_map_data",map)
		if map_id.begins_with("station_outpost_"):
			check(view.call("_resolve_tile_asset_type_id","nature_tree_blocker","ground_flat")=="glut_sandstone_04",map_id+" desert trees use existing sandstone visual")
			check(view.call("_is_arid_station_stone","nature_rock_cover") and view.call("_is_arid_station_stone","glut_sandstone_04"),map_id+" white cover and former trees share arid material route")
			var a:Transform3D=view.call("_arid_stone_transform",Transform3D.IDENTITY,Vector2i(24,50))
			var b:Transform3D=view.call("_arid_stone_transform",Transform3D.IDENTITY,Vector2i(25,13))
			check(a==view.call("_arid_stone_transform",Transform3D.IDENTITY,Vector2i(24,50)) and a!=b,map_id+" coordinate dressing is deterministic and varies repeated silhouettes")
			check(a.origin.length()<0.12 and b.origin.length()<0.12 and a.basis.determinant()>0.0,map_id+" stone variation keeps each real obstacle inside its cell")
		for tile in map.get_tiles():
			for kind: String in [tile.type_id, tile.object_type_id]:
				if kind.begins_with("station_set_floor") or kind.begins_with("station_set_wall") or kind.begins_with("station_set_door"):
					count += 1
					if Basis(view.call("_get_cell_module_visual_basis", kind)).is_equal_approx(Basis.IDENTITY):
						check(false, map_id + " uncovered module " + kind)
		check(count >= 20, map_id + " authored station module families covered")
		check(before == JSON.stringify(map.get_tiles().map(func(tile): return tile.to_dict())), map_id + " terrain facts unchanged by projection")
	view.set("_terrain_map_data",MAP.load_from_file("res://maps/Ground_Mission02_128x128.json"))
	check(view.call("_resolve_tile_asset_type_id","nature_tree_blocker","ground_flat")=="nature_tree_blocker","temperate map keeps its original tree visuals")
	check(not view.call("_is_arid_station_stone","nature_rock_cover"),"temperate cover retains original palette")
	# Actual dual layer tile: the wall/prop must not consume its floor fallback.
	for object_id: String in ["station_set_wall", "station_set_computer_wide"]:
		var tile := TILE.new({"type_id":"station_set_floor_panel", "object_type_id":object_id, "grid_position":Vector2i(7,7), "height_level":1, "walkable":false, "blocks_los":true})
		var before_tile: PackedByteArray = var_to_bytes(tile.to_dict())
		view.call("_add_tile_visual", tile)
		check(models.get_node_or_null("Asset_station_set_floor_panel_7_7") != null and models.get_node_or_null("Asset_%s_7_7" % object_id) != null, "actual floor remains below " + object_id)
		check(var_to_bytes(tile.to_dict()) == before_tile, "dual-layer projection preserves exact terrain facts " + object_id)
		for child: Node in models.get_children(): child.free()
	var station = MAP.load_from_file("res://maps/station_outpost_64x64.json")
	view.set("_terrain_map_data", station)
	var patrol_root := Node3D.new()
	view.add_child(patrol_root)
	view.set("_patrol_root", patrol_root)
	view.call("_rebuild_patrol_visuals")
	check(patrol_root.get_child_count() > 0, "actual authored patrol remains available to editor")
	var patrol_before: Dictionary = station.get_patrol_paths().duplicate(true)
	view.call("set_authoring_markers_visible", false)
	check(patrol_root.get_child_count() == 0 and station.get_patrol_paths() == patrol_before, "runtime hides only green patrol authoring line without changing patrol owner data")
	view.call("set_authoring_markers_visible", true)
	check(patrol_root.get_child_count() > 0, "editor can restore authored patrol line")
	view.free()
	print("REVIEW_STATION_VISUAL passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _project_mesh_bounds(node:Node,axis:Vector3,transform:Transform3D=Transform3D.IDENTITY)->Vector2:
	var frame:Transform3D=transform*node.transform if node is Node3D else transform
	var result:=Vector2(INF,-INF)
	if node is MeshInstance3D and node.mesh!=null:
		for surface in range(node.mesh.get_surface_count()):
			for vertex in node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var projection:float=(frame*vertex).dot(axis)
				result.x=minf(result.x,projection);result.y=maxf(result.y,projection)
	for child in node.get_children():
		var child_bounds:=_project_mesh_bounds(child,axis,frame)
		result.x=minf(result.x,child_bounds.x);result.y=maxf(result.y,child_bounds.y)
	return result
