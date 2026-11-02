extends SceneTree
## Tests actual relief topology/heights/normals and the geometric change vs P05.
const GEO = preload("res://scripts/terrain/frontier_art_geology.gd")
const BEFORE = preload("res://art/frontier_illustrated_20261101/environment/pass06/geology/source/frontier_art_geology_pass05.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		print("FAIL: ",label)

func key(v: Vector3) -> Vector3i:
	return Vector3i(roundi(v.x*100000.0),roundi(v.y*100000.0),roundi(v.z*100000.0))

func run() -> void:
	var geology = GEO.new()
	var before = BEFORE.new()
	root.add_child(geology)
	root.add_child(before)
	var profile = PROFILE.new()
	var footprints: Array = geology.build(profile,Vector2(12,5))
	var old_footprints: Array = before.build(profile,Vector2(12,5))
	check(footprints==old_footprints,"P06 returns the exact P05 locked envelopes")
	var relief_count := 0
	var terrain_up := true
	var finite := true
	var edge_grounded := true
	var one_loop := true
	var broad_nonflat := true
	var normals_match := true
	var minimum_height_span := INF
	var minimum_projected_area_ratio := INF
	var eroded_meshes := 0
	var detailed_rocks := 0
	var maximum_channels := 0
	var total_vertices := 0
	var minimum_normal_y := 1.0
	for group_index in range(geology.get_child_count()):
		var group: Node3D = geology.get_child(group_index)
		for child in group.get_children():
			var instance := child as MeshInstance3D
			if instance==null: continue
			var is_relief: bool = instance.get_meta("frontier_geology_kind","")=="talus_relief"
			if not is_relief:
				eroded_meshes += 1
				var channels: int = instance.get_meta("erosion_channel_count",0)
				maximum_channels = maxi(maximum_channels,channels)
				var previous := before.get_child(group_index).get_node_or_null(NodePath(instance.name)) as MeshInstance3D
				if previous!=null:
					var old_vertices := 0
					var new_vertices := 0
					for surface in range(previous.mesh.get_surface_count()): old_vertices += previous.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
					for surface in range(instance.mesh.get_surface_count()): new_vertices += instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
					if new_vertices>old_vertices+60: detailed_rocks += 1
			for surface in range(instance.mesh.get_surface_count()): total_vertices += instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
			if not is_relief: continue
			relief_count += 1
			var arrays: Array = instance.mesh.surface_get_arrays(0)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var edges: Dictionary = {}
			var boundary_vertices: Dictionary = {}
			var minimum := INF
			var maximum := -INF
			var area := 0.0
			for i in range(0,points.size(),3):
				var a: Vector3 = instance.global_transform*points[i]
				var b: Vector3 = instance.global_transform*points[i+1]
				var c: Vector3 = instance.global_transform*points[i+2]
				var expected := -(b-a).cross(c-a).normalized()
				area += absf((b-a).cross(c-a).y)*0.5
				for j in range(3):
					var p: Vector3 = instance.global_transform*points[i+j]
					minimum = minf(minimum,p.y)
					maximum = maxf(maximum,p.y)
					finite = finite and p.is_finite() and normals[i+j].is_finite()
					terrain_up = terrain_up and normals[i+j].y>0.45
					minimum_normal_y = minf(minimum_normal_y,normals[i+j].y)
					normals_match = normals_match and normals[i+j].dot(expected)>0.999
					var first := key(p)
					var second := key(instance.global_transform*points[i+(j+1)%3])
					var edge_key := str(first)+"/"+str(second) if str(first)<str(second) else str(second)+"/"+str(first)
					if not edges.has(edge_key): edges[edge_key] = {"count":0,"a":first,"b":second,"ay":p.y,"by":(instance.global_transform*points[i+(j+1)%3]).y}
					edges[edge_key]["count"] += 1
			var boundary_edges := 0
			for edge in edges.values():
				one_loop = one_loop and int(edge["count"])<=2
				if int(edge["count"])!=1: continue
				boundary_edges += 1
				edge_grounded = edge_grounded and float(edge["ay"])<=0.0015 and float(edge["by"])<=0.0015 and float(edge["ay"])>=-0.03 and float(edge["by"])>=-0.03
				for v in [edge["a"],edge["b"]]: boundary_vertices[v] = int(boundary_vertices.get(v,0))+1
			one_loop = one_loop and boundary_edges==24 and boundary_vertices.size()==24
			for degree in boundary_vertices.values(): one_loop = one_loop and int(degree)==2
			var span := maximum-minimum
			var ratio: float = area/(footprints[group_index].size.x*footprints[group_index].size.y)
			minimum_height_span = minf(minimum_height_span,span)
			minimum_projected_area_ratio = minf(minimum_projected_area_ratio,ratio)
			broad_nonflat = broad_nonflat and span>0.16 and ratio>0.50
	check(relief_count==14,"all fourteen blocked geology groups contain genuine ground relief")
	check(broad_nonflat,"each relief fan covers half its envelope and has over16cm real height span")
	check(one_loop,"each terrain fan is manifold inside and has one closed24edge outside boundary")
	check(edge_grounded,"every open terrain-boundary edge ends below flat ground, never suspended")
	check(terrain_up and normals_match,"relief normals are upward and match Godot clockwise triangle winding")
	check(finite,"all new terrain positions and normals are finite")
	check(eroded_meshes==54 and detailed_rocks>=12,"middle-scale channels add actual geometry to at least twelve retained rock bodies")
	check(maximum_channels<=5,"erosion density is bounded to at most five local channels per body")
	check(total_vertices<=60000,"complete erosion and relief stay within the explicit60k vertex budget")
	geology.free()
	before.free()
	await process_frame
	print("FRONTIER_PASS06_GEOLOGY ",JSON.stringify({"passed":passed,"failed":failed,"vertices":total_vertices,"relief_meshes":relief_count,"eroded_meshes":eroded_meshes,"detailed_rocks":detailed_rocks,"maximum_channels":maximum_channels,"minimum_relief_height_span_m":minimum_height_span,"minimum_relief_area_ratio":minimum_projected_area_ratio,"minimum_relief_normal_y":minimum_normal_y,"synthetic_fixture":true}))
	quit(1 if failed else 0)
