extends SceneTree
const DRESSING=preload("res://scripts/terrain/frontier_art_dressing.gd")
const PROFILE=preload("res://scripts/terrain/frontier_art_profile.gd")
const PREVIEW=preload("res://scenes/tests/frontier_art_preview.tscn")
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	if value:passed+=1
	else:
		failed+=1
		print("FAIL: ",label)
func run() -> void:
	var dressing=DRESSING.new()
	root.add_child(dressing)
	dressing.build(PROFILE.new())
	var roads:=0
	var upward:=true
	var min_normal_y:=1.0
	for node in dressing.find_children("*","MeshInstance3D",true,false):
		if node.has_meta("path_layer"):
			roads+=1
			for surface in range(node.mesh.get_surface_count()):
				var normals: PackedVector3Array=node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_NORMAL]
				for normal in normals:
					min_normal_y=minf(min_normal_y,normal.y)
					# ArrayMesh octahedral packing adds tiny XZ quantization to UP.
					upward=upward and normal.dot(Vector3.UP)>0.99999 and absf(normal.x)<0.0001 and absf(normal.z)<0.0001
	check(roads==3 and upward,"all three flat paving layers have upward normals within packed-mesh precision, including union slivers")
	check(dressing.has_method("get_access_snapshot"),"dressing exposes actual compiled access geometry for audit")
	if dressing.has_method("get_access_snapshot"):
		var snapshot: Dictionary=dressing.get_access_snapshot()
		var paths: Array=snapshot["paths"]
		check(paths.size()==4,"four authored connected approach paths")
		for path in paths:
			var samples: PackedVector2Array=path["samples"]
			var first: Vector2=path["points"][0]
			var next: Vector2=path["points"][1]
			var direction: Vector2=(next-first).normalized()
			var straight:=true
			for point in samples:
				var along: float=(point-first).dot(direction)
				if along>=0.0 and along<first.distance_to(next)-0.02:
					straight=straight and absf((point-first).cross(direction))<0.001
			check(straight,"approach starts straight at "+path["id"])
		var hall: Dictionary=snapshot["anchors"]["hall"]
		var hall_path: Dictionary=paths[2]
		check(is_equal_approx(float(hall_path["points"][0].x),float(hall["step_front"].x)),"hall approach aligns to actual offset portal center")
		var apron: Rect2=snapshot["apron"]
		check(is_equal_approx(hall_path["points"][0].y,apron.end.y),"hall lane meets apron edge without a coplanar overlap")
		check(snapshot["paving_height"]==0.014,"paving and ramp toe share one surface height")
		var ramps: Array=snapshot["entrance_ramps"]
		check(ramps.size()==2,"both entrances have a supported short access apron")
		for ramp in ramps:
			check(is_equal_approx(ramp["low"].y,0.014) and is_equal_approx(ramp["high"].y,0.057),"entrance ramp meets road and existing step heights")
	dressing.free()
	await process_frame
	await check_preview()
	print("FRONTIER_PASS07_PATHS ",JSON.stringify({"passed":passed,"failed":failed,"road_layers":roads,"min_normal_y":min_normal_y}))
	quit(1 if failed else 0)

func check_preview() -> void:
	var preview=PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.get("_sim").set_physics_process(false)
	var stage: Node3D=preview.get("_stage")
	var dressing: Node3D=stage.get_node("FrontierWorkingGround")
	var snapshot: Dictionary=dressing.get_access_snapshot()
	check(snapshot["anchors"]==preview.get("_access_anchors"),"actual measured preview anchors reach the compiled path builder")
	var facts_before: Array=[]
	for tile in preview.get("_data").get_tiles():facts_before.append(tile.to_dict())
	for spec in [["habitat","HabitatEntry","habitat_cutaway_01"],["hall","HallEntry","freihafen_hall_01"]]:
		var ramp: MeshInstance3D=dressing.get_node(spec[1]+"AccessApron")
		var bridge: MeshInstance3D=dressing.get_node(spec[1]+"CutawayThreshold")
		var anchor: Dictionary=snapshot["anchors"][spec[0]]
		var bounds: AABB=preview.call("_combined_bounds",stage.get_node(spec[2]))
		var high:=true
		var low:=true
		var facing:=true
		var high_count:=0
		var low_count:=0
		var arrays: Array=ramp.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		for i in range(vertices.size()):
			var p: Vector3=ramp.global_transform*vertices[i]
			if is_equal_approx(p.y,0.057):
				high_count+=1
				high=high and is_equal_approx(p.z,anchor["step_front"].y)
			elif is_equal_approx(p.y,0.014):
				low_count+=1
				low=low and is_equal_approx(p.z,anchor["ground"].y)
			else:high=false
			facing=facing and normals[i].y>0.95
		check(high_count==3 and low_count==3 and high and low and facing,"actual "+spec[0]+" ramp vertices meet the step and ground with upward normals")
		var bridge_bounds: AABB=bridge.global_transform*bridge.get_aabb()
		check(is_equal_approx(bridge_bounds.end.y,0.057) and is_equal_approx(bridge_bounds.end.z,anchor["step_front"].y) and bridge_bounds.position.z<bounds.end.z,"cutaway tread really bridges original GLB and upper ramp edge")
		preview.call("_set_buildings_closed",false)
		check(bridge.visible,"neutral access tread remains visible in cutaway mode")
		preview.call("_set_buildings_closed",true)
		check(not bridge.visible,"duplicate tread is hidden with closed shell to avoid coplanar faces")
	var facts_after: Array=[]
	for tile in preview.get("_data").get_tiles():facts_after.append(tile.to_dict())
	check(facts_before==facts_after,"both access presentations leave Hex and LOS facts unchanged")
	preview.free()
	await process_frame
