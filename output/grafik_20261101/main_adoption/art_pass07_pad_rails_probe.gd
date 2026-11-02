extends SceneTree
const PAD = preload("res://scripts/terrain/frontier_outpost_pad.gd")
const BEFORE = preload("res://output/grafik_20261101/probe_pass07_pad_before.gd")
var passed := 0
var failed := 0
var rows: Array = []

func _initialize() -> void: call_deferred("run")

func check(value: bool,label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		print("FAIL: ",label)

func rails(pad: Node3D) -> Array:
	var result: Array = []
	for child in pad.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh and is_equal_approx(child.mesh.size.y,0.014) and is_equal_approx(child.mesh.size.z,0.035): result.append(child)
	return result

func non_rail_geometry(pad: Node3D) -> Array:
	var result: Array = []
	var excluded := rails(pad)
	for child in pad.get_children():
		if child is MeshInstance3D and not child in excluded:
			var arrays: Array = child.mesh.surface_get_arrays(0)
			result.append([child.transform,child.get_aabb(),arrays[Mesh.ARRAY_VERTEX],arrays[Mesh.ARRAY_NORMAL]])
	return result

func run() -> void:
	for spec in [{"size":Vector2(5.0,4.4),"side":1.0},{"size":Vector2(4.2,4.1),"side":-1.0},{"size":Vector2(5.0,4.4),"side":-1.0},{"size":Vector2(4.2,4.1),"side":1.0}]:
		var pad := PAD.new()
		var old := BEFORE.new()
		root.add_child(pad)
		root.add_child(old)
		var center := Vector2(-3.2,2.8)
		var footprint: Rect2 = pad.build(center,spec["size"],"QA",spec["side"])
		var old_footprint: Rect2 = old.build(center,spec["size"],"QA",spec["side"])
		check(footprint==old_footprint,"reservation unchanged "+str(spec))
		check(pad.position==old.position,"pad pivot unchanged "+str(spec))
		check(non_rail_geometry(pad)==non_rail_geometry(old),"all non-rail vertex/normal arrays unchanged "+str(spec))
		var ramp: MeshInstance3D = pad.get_node("AccessRamp")
		var bounds := ramp.get_aabb()
		var upper_x := bounds.position.x if float(spec["side"])>0.0 else bounds.end.x
		var lower_x := bounds.end.x if float(spec["side"])>0.0 else bounds.position.x
		var upper := Vector3(upper_x,bounds.end.y,0.0)
		var lower := Vector3(lower_x,bounds.position.y,0.0)
		var strip_nodes := rails(pad)
		check(strip_nodes.size()==2,"exactly two rails "+str(spec))
		for strip in strip_nodes:
			var axis_a: Vector3 = strip.transform*Vector3(-strip.mesh.size.x*0.5,0.0,0.0)
			var axis_b: Vector3 = strip.transform*Vector3(strip.mesh.size.x*0.5,0.0,0.0)
			var top: Vector3 = axis_a if axis_a.y>axis_b.y else axis_b
			var toe: Vector3 = axis_b if axis_a.y>axis_b.y else axis_a
			var expected_top := Vector3(upper.x,upper.y,strip.position.z)
			var expected_toe := Vector3(lower.x,lower.y,strip.position.z)
			var top_error := top.distance_to(expected_top)
			var toe_error := toe.distance_to(expected_toe)
			check(top_error<0.00001 and toe_error<0.00001,"rail centerline joins ramp endpoints "+str(spec))
			check(absf(strip.mesh.size.x-upper.distance_to(lower))<0.00001,"rail uses true ramp 3D length "+str(spec))
			check(strip.position.is_equal_approx((expected_top+expected_toe)*0.5),"rail uses true endpoint midpoint "+str(spec))
			var finite := true
			var max_envelope_overhang := 0.0
			for sx in [-1.0,1.0]:
				for sy in [-1.0,1.0]:
					for sz in [-1.0,1.0]:
						var vertex: Vector3 = pad.position+strip.transform*(strip.mesh.size*Vector3(sx,sy,sz)*0.5)
						finite = finite and vertex.is_finite()
						max_envelope_overhang = maxf(max_envelope_overhang,maxf(maxf(footprint.position.x-vertex.x,vertex.x-footprint.end.x),maxf(footprint.position.y-vertex.z,vertex.z-footprint.end.y)))
			check(finite,"rail transforms finite "+str(spec))
			# A tilted 14mm box can extend by half-thickness*sin(angle) in X.
			var permitted_projection: float = strip.mesh.size.y*0.5*absf(sin(strip.rotation.z))+0.00001
			check(max_envelope_overhang<=permitted_projection,"no added axis-length envelope overshoot "+str(spec))
			rows.append({"side":spec["side"],"pad_size":str(spec["size"]),"length":strip.mesh.size.x,"center":str(strip.position),"angle":strip.rotation.z,"top_error":top_error,"toe_error":toe_error,"box_half_thickness_projection":permitted_projection,"envelope_overhang":max_envelope_overhang})
		pad.free()
		old.free()
	var report := {"passed":passed,"failed":failed,"engine":Engine.get_version_info(),"source_sha256":FileAccess.get_sha256("res://scripts/terrain/frontier_outpost_pad.gd"),"rails":rows,"scope":"Centerlines match the existing ramp; returned reservation, pivot and all other mesh arrays unchanged. Existing 14mm box thickness produces at most ~1mm projection beyond centerline endpoints."}
	var file := FileAccess.open("res://output/grafik_20261101/main_adoption/pad_rails.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	await process_frame
	print("FRONTIER_PASS07_PAD_RAILS ",JSON.stringify({"passed":passed,"failed":failed}))
	quit(1 if failed else 0)
