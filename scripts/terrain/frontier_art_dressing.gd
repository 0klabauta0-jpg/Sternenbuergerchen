extends Node3D
## One-time authored visual groups. The preview applies returned blocking facts.
var _materials: Dictionary = {}
var _footprints: Array[Rect2] = []
var _path_layers: Dictionary = {}
const GROUND_SHADER = preload("res://shaders/terrain/frontier_ground.gdshader")
const ACCESS = preload("res://scripts/terrain/frontier_access_anchors.gd")
var _access: Dictionary = {}
var _paths: Array = []
var _entrance_ramps: Array = []
var _apron_rect := Rect2()
var _cutaway_thresholds: Array[Node3D] = []
var _homebase_paths: bool = false

func build_homebase_paths(layout: Dictionary, profile: RefCounted) -> void:
	# Read-only, low dressing on existing walkable ground. No footprint or
	# collision is registered: ankle-sized gravel does not invent blockers.
	_homebase_paths = true
	var doors: Dictionary = {}
	var built: Dictionary = {}
	for asset: Dictionary in layout.get("assets", []):
		built[String(asset.id)] = bool(asset.get("built", true))
	for interior: Dictionary in layout.get("interiors", []):
		if not built.get(String(interior.id), true): continue
		var raw: Array = interior.get("door_grid", [])
		if raw.size() != 2: continue
		var plane: Vector3 = preload("res://scripts/meta/base_interior_navigation.gd").plane_at_grid(Vector2i(int(raw[0]), int(raw[1])))
		doors[String(interior.id)] = Vector2(plane.x, plane.z + 0.18)
	if not doors.has("habitat_cutaway_01") or not doors.has("freihafen_hall_01"): return
	var habitat: Vector2 = doors.habitat_cutaway_01
	var hall: Vector2 = doors.freihafen_hall_01
	var spine_z := maxf(habitat.y, hall.y) + 2.4
	var built_pads: Array[Dictionary] = []
	var spine_end := hall.x - 1.0
	for pad: Dictionary in layout.get("landing_pads", []):
		if not bool(pad.get("built",true)): continue
		var center: Array = pad.plane
		var size_value: Array = pad["size"]
		var front := Vector2(float(center[0]),float(center[1])-float(size_value[1])*0.5)
		if front.x < habitat.x or front.x > hall.x + 8.0: continue
		built_pads.append({"id":String(pad.id),"front":front})
		spine_end = maxf(spine_end,front.x-1.0)
	# The main lane leaves the real doorway and turns gradually into the
	# frontage. Branches merge tangentially; no rectangular right-angle caps.
	_path([habitat,habitat+Vector2(0,0.8),Vector2(habitat.x+0.2,spine_z-0.7),Vector2(habitat.x+1.0,spine_z-0.1),Vector2(habitat.x+2.0,spine_z),Vector2(spine_end-1.0,spine_z),Vector2(spine_end,spine_z)],1.10,true,"home_spine")
	_path([hall,hall+Vector2(0,0.8),Vector2(hall.x-0.2,spine_z-0.7),Vector2(hall.x-1.0,spine_z),Vector2(hall.x-2.0,spine_z)],1.10,false,"home_hall")
	for pad: Dictionary in built_pads:
		var front: Vector2 = pad.front
		_path([front,front+Vector2(0,-0.6),Vector2(front.x-0.2,spine_z+0.55),Vector2(front.x-1.0,spine_z),Vector2(front.x-2.0,spine_z)],1.10,false,"home_"+pad.id)
	_finish_paths()
	_add_path_guides()
	var transforms: Array[Transform3D] = []
	for path: Dictionary in _paths:
		var samples: PackedVector2Array = path.samples
		for index in range(4,samples.size()-4,9):
			var direction := (samples[index+1]-samples[index-1]).normalized()
			var normal := Vector2(-direction.y,direction.x)
			for side in [-1.0,1.0]:
				var point: Vector2 = samples[index]+normal*(float(path.width)*0.5+0.12+0.04*sin(float(index)))*side
				if not _guide_clear(point,path): continue
				var scale_value := Vector3(0.75+0.20*sin(float(index)),0.42,0.64)
				transforms.append(Transform3D(Basis(Vector3.UP,float(index)*0.74).scaled(scale_value),Vector3(point.x,0.0,point.y)))
	if not transforms.is_empty():
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = _boulder_mesh(0.15,37)
		multi.instance_count = transforms.size()
		for index in range(transforms.size()): multi.set_instance_transform(index,transforms[index])
		var stones := MultiMeshInstance3D.new()
		stones.name = "LowPathShoulderStones"
		stones.multimesh = multi
		stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stones.material_override = profile.material_for(Color("b56b46"),true)
		add_child(stones)
	set_meta("homebase_path_count",_paths.size())
	set_meta("path_shoulder_stone_count",transforms.size())
	set_meta("visual_only",true)

func build(profile,access_anchors: Dictionary = {}) -> Array[Rect2]:
	_access = ACCESS.defaults().merged(access_anchors,true)
	_paths.clear()
	_entrance_ramps.clear()
	var hall: Dictionary = _access["hall"]
	var hall_bounds: AABB = hall["bounds"]
	_apron_rect = Rect2(Vector2(hall_bounds.get_center().x-2.175,hall_bounds.end.z-0.01625),Vector2(4.35,1.25))
	var first: Vector2 = _access["pad01"]["ground"]
	var last: Vector2 = _access["pad02"]["ground"]
	var hab: Vector2 = _access["habitat"]["ground"]
	var hall_entry := Vector2(hall["step_front"].x,_apron_rect.end.y)
	# A wide service spine with short building connections; clear turning space.
	_path([first,first+Vector2(0.76,0.0),Vector2(11.3,10.9),Vector2(14.6,10.9),last-Vector2(0.89,0.0),last],1.04,true,"service_spine")
	_path([hab,hab+Vector2(0.0,0.76),Vector2(8.6,9.65),Vector2(9.6,10.3),Vector2(10.3,10.9),Vector2(10.92,10.9)],0.68,false,"habitat")
	_path([hall_entry,hall_entry+Vector2(0.0,0.75),Vector2(hall_entry.x,10.15),Vector2(hall_entry.x,10.9)],0.84,false,"hall")
	_path([Vector2(16.1,8.73),Vector2(16.1,9.45),Vector2(16.1,10.25),Vector2(15.3,10.9),Vector2(14.3,10.9)],0.64,false,"utility")
	for center in [Vector2(4.6,5.0),Vector2(5.8,6.5),Vector2(6.5,14.5),Vector2(18.7,6.7),Vector2(21.8,9.0),Vector2(11.0,2.3),Vector2(19.4,2.6)]:
		_rock_group(center,profile)
	for center in [Vector2(6.5,7.2),Vector2(9.5,7.3),Vector2(10.7,7.5),Vector2(15.4,7.0),Vector2(18.0,7.6),Vector2(9.8,13.5),Vector2(17.0,13.8),Vector2(5.0,6.0),Vector2(20.7,8.7),Vector2(14.0,3.5)]:
		_plant_group(center)
	for spec in [Vector3(9.45,7.9,0.0),Vector3(14.8,7.6,0.3),Vector3(15.6,7.6,-0.2)]:
		_crate(Vector2(spec.x,spec.y),spec.z)
	for p in [Vector2(10.5,11.45),Vector2(11.6,9.85),Vector2(15.1,11.2),Vector2(13.8,8.6)]:
		_bollard(p)
	_finish_paths()
	_add_path_guides()
	_loading_yard()
	_add_entrance_ramp("HabitatEntry",_access["habitat"],0.68)
	_add_entrance_ramp("HallEntry",_access["hall"],float(_access["hall"]["step_width"]))
	_radio_mast(Vector2(10.7,3.25))
	return _footprints.duplicate()

func get_access_snapshot() -> Dictionary:
	return {"anchors":_access.duplicate(true),"paths":_paths.duplicate(true),"apron":_apron_rect,"entrance_ramps":_entrance_ramps.duplicate(true),"paving_height":ACCESS.PAVING_HEIGHT}

func set_buildings_closed(closed: bool) -> void:
	# The closed shell already owns its tread. In cutaway mode a neutral tread
	# bridges the same entrance span; never render both coplanar top faces.
	for threshold in _cutaway_thresholds:threshold.visible=not closed

func _loading_yard() -> void:
	# Flat authored apron: decoration does not introduce a second floor height.
	var apron_center := _apron_rect.get_center()
	var apron := _box(self,"LoadingApron",Vector3(_apron_rect.size.x,0.014,_apron_rect.size.y),Vector3(apron_center.x,0.007,apron_center.y),"858b7c")
	apron.material_override = _paving_material("858b7c")
	for offset in [-0.74,0.74,1.45]:
		var x: float = _access["hall"]["step_front"].x+offset
		_box(self,"ApronBayStripe",Vector3(0.026,0.003,0.32),Vector3(x,0.0165,_apron_rect.end.y-0.22),"e0d2a0").material_override = _marking_material("e0d2a0")
	for center in [Vector2(15.8,5.0),Vector2(16.7,5.6),Vector2(15.8,6.25)]:
		_container(center,2 if center.y<5.5 else 1)

func _container(center: Vector2,levels: int) -> void:
	var group := Node3D.new()
	group.name = "FreihafenContainerGroup"
	group.position = Vector3(center.x,0.0,center.y)
	add_child(group)
	for level in range(levels):
		var floor_y := float(level)*0.43
		_box(group,"ContainerBody",Vector3(0.78,0.40,0.44),Vector3(0.0,floor_y+0.20,0.0),"aaa99a" if level==0 else "d2c5a2")
		_box(group,"OrangeHeader",Vector3(0.76,0.035,0.454),Vector3(0.0,floor_y+0.365,0.0),"c78b3e")
		for x in [-0.35,0.35]:
			_box(group,"CornerPost",Vector3(0.04,0.41,0.46),Vector3(x,floor_y+0.205,0.0),"53605b")
		_box(group,"DoorSeam",Vector3(0.02,0.28,0.015),Vector3(0.0,floor_y+0.16,0.23),"53605b")
	_footprints.append(Rect2(center-Vector2(0.48,0.32),Vector2(0.96,0.64)))

func _radio_mast(center: Vector2) -> void:
	var group := Node3D.new()
	group.name = "OutpostCommunicationsVisualOnly"
	group.position = Vector3(center.x,0.0,center.y)
	add_child(group)
	_box(group,"MastFoot",Vector3(0.5,0.08,0.5),Vector3(0.0,0.04,0.0),"9b9783")
	for x in [-0.13,0.13]:
		for z in [-0.10,0.10]:
			_box(group,"MastFrame",Vector3(0.027,1.10,0.027),Vector3(x,0.63,z),"747e71")
	for y in [0.28,0.58,0.88]:
		_box(group,"CrossFrame",Vector3(0.30,0.025,0.23),Vector3(0.0,y,0.0),"747e71")
	_box(group,"Antenna",Vector3(0.03,0.48,0.03),Vector3(-0.12,1.26,-0.10),"c78b3e")
	_box(group,"AntennaCap",Vector3(0.05,0.055,0.05),Vector3(-0.12,1.51,-0.10),"86bec0")
	var dish_root := Node3D.new()
	dish_root.name = "SatelliteDish"
	dish_root.position = Vector3(0.0,1.15,0.04)
	dish_root.rotation = Vector3(-0.30,0.35,0.0)
	group.add_child(dish_root)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(16):
		var a := TAU*float(index)/16.0
		var b := TAU*float(index+1)/16.0
		for vertex in [Vector3(0.0,0.0,-0.045),Vector3(cos(b)*0.26,sin(b)*0.26,0.0),Vector3(cos(a)*0.26,sin(a)*0.26,0.0)]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var dish := MeshInstance3D.new()
	dish.mesh = surface.commit()
	var material := _material("d5d1ba")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	dish.material_override = material
	dish_root.add_child(dish)
	_box(dish_root,"Feed",Vector3(0.022,0.022,0.14),Vector3(0.0,0.0,0.04),"52615c")
	_footprints.append(Rect2(center-Vector2.ONE*0.42,Vector2.ONE*0.84))

func _material(color: String) -> StandardMaterial3D:
	if _materials.has(color): return _materials[color]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = 0.94
	_materials[color] = material
	return material

func _paving_material(color: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("base_color",Color(color))
	material.set_shader_parameter("paved_surface",true)
	material.set_shader_parameter("authored_paving_wear",not _homebase_paths)
	if not _homebase_paths and _paths.size()==4:
		for spec in [["wear_service_span",_paths[0]["points"][2],_paths[0]["points"][3]],["wear_hall_span",_paths[2]["points"][0],_paths[2]["points"].back()],["wear_utility_span",_paths[3]["points"][1],_paths[3]["points"][2]]]:
			material.set_shader_parameter(spec[0],Vector4(spec[1].x,spec[1].y,spec[2].x,spec[2].y))
	return material

func _marking_material(color: String) -> ShaderMaterial:
	var key := "worn_marking:"+color
	if _materials.has(key): return _materials[key]
	var material := _paving_material(color)
	material.set_shader_parameter("marking_surface",true)
	_materials[key] = material
	return material

func _box(parent: Node3D,label: String,size: Vector3,position: Vector3,color: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.set_meta("art_part",label)
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _path(points: Array,width: float,service_lane: bool = false,id: String = "path") -> void:
	var curve := Curve2D.new()
	curve.bake_interval = 0.10
	for index in range(points.size()):
		var tangent: Vector2 = (points[mini(index+1,points.size()-1)]-points[maxi(index-1,0)])*0.12
		if index<=1:tangent=(points[1]-points[0])*0.24
		elif index>=points.size()-2:tangent=(points.back()-points[points.size()-2])*0.24
		curve.add_point(points[index],-tangent,tangent)
	var samples := curve.get_baked_points()
	_paths.append({"id":id,"points":points.duplicate(),"samples":samples,"width":width,"service_lane":service_lane})
	# Grafikpass R2: tarred road. Pale kerb, worn edge line, dark matte asphalt;
	# same three joined layers and heights as before, colours match
	# frontier_road_deck.gd so authored and cell-built roads read as one family.
	_ribbon(samples,width+0.14,0.007,"b9b6aa")
	_ribbon(samples,width,0.010,"d98a2b")
	_ribbon(samples,width-0.10,ACCESS.PAVING_HEIGHT,"46484c")

func _add_path_guides() -> void:
	for path in _paths:
		_add_lane_guides(path)

func _guide_clear(point: Vector2,path: Dictionary) -> bool:
	if _apron_rect.grow(0.05).has_point(point):return false
	for other in _paths:
		if other["id"]==path["id"]:continue
		for sample in other["samples"]:
			if point.distance_squared_to(sample)<pow(float(other["width"])*0.5+0.05,2.0):return false
	return true

func _add_lane_guides(path: Dictionary) -> void:
	var samples: PackedVector2Array=path["samples"]
	var width: float=path["width"]
	for index in range(3,samples.size()-3,7):
		var a: Vector2 = samples[index]
		var direction: Vector2 = (samples[index+1]-samples[index-1]).normalized()
		var normal := Vector2(-direction.y,direction.x)
		for side in [-1.0,1.0]:
			var p: Vector2=a+normal*(width*0.5-0.06)*side
			if not _guide_clear(p,path):continue
			var marker := _box(self,"PathEdgeGuide",Vector3(0.024,0.003,0.24),Vector3(p.x,0.0165,p.y),"cbc6a5")
			marker.rotation.y = atan2(direction.x,direction.y)
			marker.material_override = _marking_material("cbc6a5")
		if path["service_lane"] and index%2==1 and _guide_clear(a,path):
			var center_mark := _box(self,"ServiceLaneGuide",Vector3(0.022,0.003,0.20),Vector3(a.x,0.0165,a.y),"d4af67")
			center_mark.rotation.y = atan2(direction.x,direction.y)
			center_mark.material_override = _marking_material("d4af67")

func _ribbon(points: PackedVector2Array,width: float,height: float,color: String) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for index in range(points.size()):
		var tangent := points[mini(index+1,points.size()-1)]-points[maxi(index-1,0)]
		var normal := Vector2(-tangent.y,tangent.x).normalized()*width*0.5
		left.append(points[index]-normal)
		right.append(points[index]+normal)
	right.reverse()
	left.append_array(right)
	if not _path_layers.has(color):
		_path_layers[color] = {"height":height,"polygons":[]}
	var polygons: Array = _path_layers[color]["polygons"]
	# Union every connected lane before meshing. Crossing coplanar ribbons flicker.
	var pending := left
	var index := 0
	while index<polygons.size():
		var merged := Geometry2D.merge_polygons(pending,polygons[index])
		if merged.size()==1:
			pending = merged[0]
			polygons.remove_at(index)
			index = 0
		else:
			index += 1
	polygons.append(pending)

func _finish_paths() -> void:
	for color in _path_layers:
		var layer: Dictionary = _path_layers[color]
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_normal(Vector3.UP)
		for polygon in layer["polygons"]:
			var indices := Geometry2D.triangulate_polygon(polygon)
			for offset in range(0,indices.size(),3):
				var a: Vector2=polygon[indices[offset]]
				var b: Vector2=polygon[indices[offset+1]]
				var c: Vector2=polygon[indices[offset+2]]
				if absf((b-a).cross(c-a))<0.00000001:continue
				if (b-a).cross(c-a)<0.0:
					var swap:=b
					b=c
					c=swap
				for point in [a,b,c]:surface.add_vertex(Vector3(point.x,float(layer["height"]),point.y))
		var instance := MeshInstance3D.new()
		instance.name = "JoinedServicePaths"
		instance.set_meta("path_layer",color)
		instance.mesh = surface.commit()
		instance.material_override = _paving_material(color)
		if _homebase_paths: instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)

func _add_entrance_ramp(label: String,anchor: Dictionary,width: float) -> void:
	var front: Vector2=anchor["step_front"]
	var foot: Vector2=anchor["ground"]
	var side := Vector2.RIGHT
	var high := Vector3(front.x,ACCESS.STEP_TOP,front.y)
	var low := Vector3(foot.x,ACCESS.PAVING_HEIGHT,foot.y)
	var near_width: float=anchor["step_width"]
	var a:=high+Vector3(side.x,0.0,side.y)*near_width*0.5
	var b:=low+Vector3(side.x,0.0,side.y)*width*0.5
	var c:=low-Vector3(side.x,0.0,side.y)*width*0.5
	var d:=high-Vector3(side.x,0.0,side.y)*near_width*0.5
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [a,b,c,a,c,d]:surface.add_vertex(v)
	surface.generate_normals()
	var ramp:=MeshInstance3D.new()
	ramp.name=label+"AccessApron"
	ramp.mesh=surface.commit()
	ramp.material_override=_paving_material("858b7c" if label=="HallEntry" else "989c85")
	add_child(ramp)
	var bridge_center:=Vector3(front.x,0.0345,front.y-0.135)
	var bridge:=_box(self,label+"CutawayThreshold",Vector3(near_width,0.045,0.27),bridge_center,"989c85")
	bridge.hide()
	_cutaway_thresholds.append(bridge)
	_entrance_ramps.append({"id":label,"high":high,"low":low,"width":width})

func _rock_group(center: Vector2,profile) -> void:
	var root := Node3D.new()
	root.name = "GroundRockGroup_%d"%get_child_count()
	root.position = Vector3(center.x,0.0,center.y)
	add_child(root)
	for index in range(6):
		var phase := float(index)*2.39996+center.x
		var radius := 0.25+float(index)*0.065
		var scale_value := 0.25 if index>2 else 0.50-float(index)*0.065
		var rock := MeshInstance3D.new()
		var mesh := _boulder_mesh(scale_value,index+int(center.x*31.0))
		rock.mesh = mesh
		rock.position = Vector3(cos(phase)*radius,0.0,sin(phase)*radius)
		rock.rotation.y = phase
		rock.scale.z = 0.7+float(index%3)*0.18
		rock.material_override = profile.material_for(Color("bd6b47").lightened(float(index%3)*0.04),true)
		root.add_child(rock)
	_footprints.append(Rect2(center-Vector2.ONE*0.85,Vector2.ONE*1.7))
	_plant_group(center+Vector2(0.62,0.25))

func _boulder_mesh(radius: float,seed_value: int) -> ArrayMesh:
	var rings: Array[PackedVector3Array] = []
	for level in range(4):
		var ring := PackedVector3Array()
		var level_radius: float = [0.67,1.0,0.82,0.46][level]
		var y: float = [0.0,0.20,0.72,0.93][level]*radius
		for sector in range(7):
			var angle := TAU*float(sector)/7.0+float(seed_value)*0.51
			var fracture := 0.88+0.11*sin(float(sector*17+seed_value)*2.7)
			ring.append(Vector3(cos(angle)*radius*level_radius*fracture,y,sin(angle)*radius*level_radius*fracture))
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for level in range(3):
		for sector in range(7):
			var next := (sector+1)%7
			for v in [rings[level][sector],rings[level][next],rings[level+1][next],rings[level][sector],rings[level+1][next],rings[level+1][sector]]:
				surface.add_vertex(v)
	for sector in range(7):
		for v in [Vector3(0.0,radius*0.93,0.0),rings[3][sector],rings[3][(sector+1)%7]]:
			surface.add_vertex(v)
	surface.generate_normals()
	return surface.commit()

func _plant_group(center: Vector2) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(9):
		var angle := float(index)*2.39996
		var length := 0.18+0.05*float(index%3)
		var direction := Vector2(cos(angle),sin(angle))
		var side := Vector2(-direction.y,direction.x)*0.045
		var base := Vector3(center.x,0.006,center.y)
		var tip := base+Vector3(direction.x*length,0.15+length*0.55,direction.y*length)
		var left := base+Vector3(side.x,0.0,side.y)
		var right := base-Vector3(side.x,0.0,side.y)
		for vertex in [left,tip,right,right,tip,left]: surface.add_vertex(vertex)
	surface.generate_normals()
	var plant := MeshInstance3D.new()
	plant.name = "DryAgave"
	plant.mesh = surface.commit()
	plant.material_override = _material("6d7950")
	add_child(plant)
	for index in range(3):
		var bush := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radial_segments = 7
		mesh.rings = 3
		mesh.radius = 0.12
		mesh.height = 0.19
		bush.mesh = mesh
		bush.position = Vector3(center.x+0.22+float(index)*0.10,0.075,center.y-0.10+float(index%2)*0.1)
		bush.material_override = _material("85815a" if index%2==0 else "66704b")
		add_child(bush)

func _crate(center: Vector2,angle: float) -> void:
	var root := Node3D.new()
	root.name = "SupplyCrate"
	root.position = Vector3(center.x,0.0,center.y)
	root.rotation.y = angle
	add_child(root)
	_box(root,"Body",Vector3(0.38,0.29,0.31),Vector3(0.0,0.145,0.0),"b39359")
	_box(root,"Lid",Vector3(0.40,0.035,0.33),Vector3(0.0,0.30,0.0),"cec7aa")
	for x in [-0.135,0.135]:
		_box(root,"Strap",Vector3(0.025,0.30,0.322),Vector3(x,0.15,0.0),"525b55")
	_footprints.append(Rect2(center-Vector2(0.30,0.28),Vector2(0.6,0.56)))

func _bollard(center: Vector2) -> void:
	_box(self,"PathLight",Vector3(0.065,0.28,0.065),Vector3(center.x,0.14,center.y),"525951")
	_box(self,"LightCap",Vector3(0.082,0.055,0.082),Vector3(center.x,0.29,center.y),"e8ddab")
