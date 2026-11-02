extends SceneTree
## Synthetic geometry/placement checks; native images remain the art evidence.
const GEO = preload("res://scripts/terrain/frontier_art_geology.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const ANCHORS: Array[Vector2] = [Vector2(-0.7,1.0),Vector2(5.1,-3.1),Vector2(12.8,-3.8),Vector2(21.2,-1.2),Vector2(26.0,5.2),Vector2(1.5,14.0),Vector2(23.0,16.1),Vector2(10.8,0.8),Vector2(19.4,2.4),Vector2(2.35,7.0),Vector2(2.4,-0.3),Vector2(18.3,0.3),Vector2(24.7,10.8),Vector2(4.2,13.4)]
# Captured from 7a37f5d9a on Godot 4.6.2. This is a footprint baseline, not an
# image-quality golden. One-time ArrayMesh AABB merges differ below two microns.
const PASS02_ENVELOPES: Array[Rect2] = [
	Rect2(-4.25824403762817,-1.28044652938843,6.89692783355713,4.93746423721313),
	Rect2(1.48465967178345,-5.56313800811768,7.30352640151978,5.12053537368774),
	Rect2(8.45168304443359,-6.78740835189819,9.24668598175049,6.04036569595337),
	Rect2(17.5459690093994,-3.64989352226257,8.19201755523682,5.05501651763916),
	Rect2(23.6288948059082,2.33895826339722,5.17353820800781,5.31611776351929),
	Rect2(-0.868521153926849,12.1262426376343,4.64594173431396,3.87051820755005),
	Rect2(20.1895389556885,14.063982963562,5.58388471603394,4.28820180892944),
	Rect2(7.42255210876465,-0.895326375961304,6.61554908752441,3.33852958679199),
	Rect2(17.1710815429688,0.891857445240021,4.58321046829224,2.83794355392456),
	Rect2(0.467762887477875,5.04762601852417,3.57646942138672,4.03924083709717),
	Rect2(1.54413604736328,-1.09900605678558,1.71640717983246,1.56920766830444),
	Rect2(17.4848785400391,-0.464856088161469,1.81504487991333,1.56187808513641),
	Rect2(23.904275894165,10.0914316177368,1.79514718055725,1.43406498432159),
	Rect2(3.34993815422058,12.6882629394531,1.66132795810699,1.54913151264191)]
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		print("FAIL: ",label)

func run() -> void:
	var first = GEO.new()
	var second = GEO.new()
	root.add_child(first)
	root.add_child(second)
	var profile = PROFILE.new()
	var footprints: Array = first.build(profile,Vector2(12.0,5.0))
	var other_footprints: Array = second.build(profile,Vector2(12.0,5.0))
	check(first.get_child_count()==14 and footprints.size()==14,"fourteen authored main groups and footprints remain")
	var anchors_match := first.get_child_count()==ANCHORS.size()
	for index in range(mini(first.get_child_count(),ANCHORS.size())):
		var position: Vector3 = first.get_child(index).position
		anchors_match = anchors_match and Vector2(position.x,position.z).is_equal_approx(ANCHORS[index])
	check(anchors_match,"all fourteen pass02 placement anchors remain unchanged")
	var max_envelope_delta := 0.0
	for index in range(mini(footprints.size(),PASS02_ENVELOPES.size())):
		max_envelope_delta = maxf(max_envelope_delta,footprints[index].position.distance_to(PASS02_ENVELOPES[index].position))
		max_envelope_delta = maxf(max_envelope_delta,footprints[index].size.distance_to(PASS02_ENVELOPES[index].size))
	check(footprints.size()==PASS02_ENVELOPES.size() and max_envelope_delta<0.000002,"conservative pass02 placement envelopes remain within float precision")
	var data := geometry(first,footprints)
	var other := geometry(second,other_footprints)
	check(int(data["vertices"])>0 and int(data["meshes"])>0,"geology is nonempty")
	check(bool(data["finite"]),"all mesh transforms, vertices and normals are finite")
	check(bool(data["caps_up"]),"generated upper cap normals point up")
	check(bool(data["walls_out"]),"generated wall normals point out from their individual block")
	check(int(data["degenerate_triangles"])==0,"new rock triangles have nonzero area")
	check(int(data["outside_footprint_vertices"])==0,"returned conservative footprints contain every new rock and debris vertex")
	check(int(data["terraced_groups"])>=10,"large plateaus include attached masses with unequal top heights")
	# Pass04 adds chipped strata within the identical placement envelopes.
	check(int(data["vertices"])<=30000,"chipped strata stay within the 30k authored-scene vertex budget")
	check(data["digest"]==other["digest"] and footprints==other_footprints,"fresh builds deterministically reproduce geometry and footprints")
	first.free()
	second.free()
	print("FRONTIER_PASS03_GEOLOGY ",JSON.stringify({"passed":passed,"failed":failed,"synthetic_fixture":true,"geometry":data,"footprint_digest":digest(footprints),"max_pass02_footprint_delta_m":max_envelope_delta}))
	quit(1 if failed else 0)

func geometry(geology: Node3D,footprints: Array) -> Dictionary:
	var entries: Array = []
	var finite := true
	var caps_up := true
	var walls_out := true
	var vertices_count := 0
	var meshes_count := 0
	var outside := 0
	var degenerate := 0
	var terraced_groups := 0
	for group_index in range(geology.get_child_count()):
		var group: Node3D = geology.get_child(group_index)
		var heights: Dictionary = {}
		for mesh_variant in group.find_children("*","MeshInstance3D",true,false):
			var instance := mesh_variant as MeshInstance3D
			meshes_count += 1
			var transform: Transform3D = geology.global_transform.affine_inverse()*instance.global_transform
			finite = finite and transform.origin.is_finite() and transform.basis.is_finite()
			var top := instance.mesh.get_aabb().end.y+instance.position.y
			heights[roundi(top*1000.0)] = true
			for surface in range(instance.mesh.get_surface_count()):
				var arrays: Array = instance.mesh.surface_get_arrays(surface)
				var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				vertices_count += points.size()
				entries.append([transform,points,normals])
				finite = finite and points.size()==normals.size()
				for index in range(points.size()):
					finite = finite and points[index].is_finite()
					var world: Vector3 = transform*points[index]
					if not footprints[group_index].grow(0.001).has_point(Vector2(world.x,world.z)):
						outside += 1
					if index>=normals.size():
						continue
					var normal := normals[index]
					finite = finite and normal.is_finite()
					if surface==instance.mesh.get_surface_count()-1:
						caps_up = caps_up and normal.y>0.95
					elif absf(normal.y)<0.8:
						var radial := Vector3(points[index].x,0.0,points[index].z).normalized()
						walls_out = walls_out and normal.dot(radial)>-0.03
				for index in range(0,points.size()-2,3):
					if (points[index+1]-points[index]).cross(points[index+2]-points[index]).length_squared()<0.000000000001:
						degenerate += 1
		if heights.size()>1:
			terraced_groups += 1
	return {"meshes":meshes_count,"vertices":vertices_count,"finite":finite,"caps_up":caps_up,"walls_out":walls_out,"outside_footprint_vertices":outside,"degenerate_triangles":degenerate,"terraced_groups":terraced_groups,"digest":digest(entries)}

func digest(value: Variant) -> String:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(var_to_bytes(value))
	return hasher.finish().hex_encode()
