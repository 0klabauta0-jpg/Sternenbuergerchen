extends Node3D
## One-time authored use groups and soil contacts, no civilian simulation.
const CONTACT = preload("res://shaders/terrain/frontier_contact_paint.gdshader")
var footprints: Array[Rect2] = []
var source_facts: Array = []
var _materials: Dictionary = {}
var gravel_count := 0
var use_groups: Array[String] = []

func build() -> Array[Rect2]:
	_contact_surface()
	_use_group("HabitatArrival",Vector2(10.2,8.05))
	_prop("space_station","table-display",Vector2(10.2,8.1),0.50,-65.0)
	_box("TerminalPedestal",Vector3(0.18,0.24,0.18),Vector3(10.68,0.12,8.08),"748477")
	_prop("space_station","computer",Vector2(10.68,8.08),0.25,-65.0,0.24)
	_box("BenchSupply",Vector3(0.22,0.13,0.19),Vector3(10.14,0.065,7.53),"ae854d")
	footprints.append(Rect2(10.02,7.43,0.25,0.20))
	# A small arrival/service island: shelter side, parcels and a grounded bench.
	_box("ArrivalBench",Vector3(0.55,0.055,0.20),Vector3(9.45,0.23,7.78),"a69b72")
	for x in [9.24,9.66]:
		_box("BenchLeg",Vector3(0.045,0.23,0.16),Vector3(x,0.115,7.75),"57675d")
	footprints.append(Rect2(9.13,7.62,0.64,0.32))
	_use_group("FreihafenDelivery",Vector2(15.3,7.6))
	_prop("space_station","container-wide",Vector2(15.30,7.18),0.43,9.0)
	_pallet(Vector2(15.35,8.05))
	_hose([Vector3(14.85,0.022,8.65),Vector3(15.15,0.022,8.85),Vector3(15.6,0.022,8.96),Vector3(16.0,0.18,8.7)])
	_box("DeliveryMarker",Vector3(0.05,0.34,0.05),Vector3(15.86,0.17,7.38),"d0a35d")
	_use_group("SupplyService",Vector2(17.1,8.4))
	_box("UtilityToolbox",Vector3(0.26,0.19,0.20),Vector3(17.15,0.095,8.60),"aa793f")
	_box("UtilityLid",Vector3(0.28,0.035,0.22),Vector3(17.15,0.203,8.60),"d0c9ad")
	footprints.append(Rect2(16.96,8.43,0.38,0.34))
	_gravel()
	return footprints.duplicate()

func _use_group(label: String,center: Vector2) -> void:
	use_groups.append(label)
	var marker := Node3D.new()
	marker.name = label
	marker.position = Vector3(center.x,0.0,center.y)
	add_child(marker)

func _contact_surface() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "DustBanksAndCompactedApproaches"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(35.0,26.0)
	ground.mesh = mesh
	ground.position = Vector3(12.0,0.004,7.0)
	var material := ShaderMaterial.new()
	material.shader = CONTACT
	ground.material_override = material
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)

func _prop(pack: String,model: String,plane: Vector2,scale_value: float,yaw: float,support_height: float = 0.0) -> void:
	var path := "res://Assets/curated/kenney/"+pack+"/models/"+model+".glb"
	var visual: Node3D = load(path).instantiate()
	visual.name = "Working_"+model
	visual.scale = Vector3.ONE*scale_value
	visual.position = Vector3(plane.x,0.0,plane.y)
	visual.rotation_degrees.y = yaw
	add_child(visual)
	var bounds := _bounds(visual)
	visual.position.y += support_height-bounds.position.y
	bounds = _bounds(visual)
	footprints.append(Rect2(Vector2(bounds.position.x,bounds.position.z)-Vector2.ONE*0.06,Vector2(bounds.size.x,bounds.size.z)+Vector2.ONE*0.12))
	for mesh in visual.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.get_active_material(surface)
			if original is StandardMaterial3D:
				var tinted: StandardMaterial3D = original.duplicate()
				tinted.albedo_color *= Color("e2d5b9")
				tinted.roughness = 0.93
				mesh.set_surface_override_material(surface,tinted)
	var license_path := "res://Assets/curated/kenney/"+pack+"/License.txt"
	var atlas_path := "res://Assets/curated/kenney/"+pack+"/models/Textures/colormap.png"
	source_facts.append({"id":"working_"+model,"path":path,"source_sha256":FileAccess.get_sha256(path),"scale":scale_value,"yaw":yaw,"support_height":support_height,"grounded_bounds":str(bounds),"material_route":"instance-duplicated warm tint, original textures and UV unchanged","license":"Kenney Space Station CC0; original GLB and atlas unchanged","license_path":license_path,"license_sha256":FileAccess.get_sha256(license_path),"atlas_path":atlas_path,"atlas_sha256":FileAccess.get_sha256(atlas_path)})

func _bounds(visual: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for child in visual.find_children("*","MeshInstance3D",true,false):
		var box: AABB = child.global_transform*child.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds

func _pallet(center: Vector2) -> void:
	for z in [-0.16,0.0,0.16]:
		_box("PalletSlat",Vector3(0.69,0.045,0.12),Vector3(center.x,0.04,center.y+z),"a18f64")
	for x in [-0.24,0.24]:
		_box("PalletRunner",Vector3(0.085,0.04,0.46),Vector3(center.x+x,0.02,center.y),"6f7156")
	for offset in [Vector2(-0.16,0.0),Vector2(0.16,0.025)]:
		_box("DeliveredParcel",Vector3(0.27,0.25,0.29),Vector3(center.x+offset.x,0.19,center.y+offset.y),"b2a67f")
		_box("ParcelBand",Vector3(0.055,0.255,0.295),Vector3(center.x+offset.x,0.19,center.y+offset.y),"6a7765")
	footprints.append(Rect2(center-Vector2(0.40,0.30),Vector2(0.80,0.60)))

func _hose(points: Array[Vector3]) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()-1):
		var a := points[i]
		var b := points[i+1]
		var direction := (b-a).normalized()
		var side := direction.cross(Vector3.UP).normalized()*0.022
		var up := side.normalized().cross(direction)*0.022
		for segment in range(8):
			var u := TAU*float(segment)/8.0
			var v := TAU*float(segment+1)/8.0
			var p := side*cos(u)+up*sin(u)
			var q := side*cos(v)+up*sin(v)
			for vertex in [a+p,b+q,b+p,a+p,a+q,b+q]:surface.add_vertex(vertex)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = "GroundedServiceConduit"
	instance.mesh = surface.commit()
	instance.material_override = _material("475b52")
	add_child(instance)

func _gravel() -> void:
	var positions: Array[Vector3] = []
	for center in [Vector2(4.8,5.4),Vector2(5.8,7.0),Vector2(10.8,3.5),Vector2(17.4,4.0),Vector2(18.5,7.0),Vector2(21.7,9.0),Vector2(22.6,14.0),Vector2(5.6,14.2)]:
		for i in range(24):
			var angle: float = float(i)*2.39996+center.x
			var spread := 0.30+sqrt(float(i)/24.0)*0.92
			var p: Vector2 = center+Vector2(cos(angle)*spread,sin(angle)*spread*0.60)
			if _clear_ground(p): positions.append(Vector3(p.x,0.0,p.y))
	var mesh := SphereMesh.new()
	mesh.radial_segments = 5
	mesh.rings = 2
	mesh.radius = 0.06
	mesh.height = 0.09
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = positions.size()
	for i in range(positions.size()):
		var scale_value := 0.40+float(i%5)*0.20
		var basis := Basis(Vector3.UP,float(i)*2.39996).scaled(Vector3(scale_value,scale_value*0.6,scale_value*0.8))
		multimesh.set_instance_transform(i,Transform3D(basis,positions[i]+Vector3(0.0,0.028*scale_value,0.0)))
		multimesh.set_instance_color(i,Color.WHITE.darkened(float(i%4)*0.045))
	var instance := MultiMeshInstance3D.new()
	instance.name = "ContactGravelBatch"
	instance.multimesh = multimesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b6774d")
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	instance.material_override = material
	add_child(instance)
	gravel_count = positions.size()

func _clear_ground(p: Vector2) -> bool:
	for rect in [Rect2(3.8,8.4,6.4,5.0),Rect2(16.0,9.5,5.6,4.5),Rect2(7.7,7.2,3.4,3.9),Rect2(10.5,7.2,6.8,5.6),Rect2(7.0,4.7,7.8,2.8)]:
		if rect.has_point(p):return false
	return true

func _material(color: String) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(color)
		material.roughness = 0.92
		_materials[color] = material
	return _materials[color]

func _box(label: String,size: Vector3,center: Vector3,color: String) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = center
	instance.material_override = _material(color)
	add_child(instance)
