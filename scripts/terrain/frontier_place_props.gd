extends RefCounted
## Small prop presentation for the reference places; no interaction/state owner.
static var _materials: Dictionary={}
static func supports(id: String) -> bool:
	return id in ["station_computer","station_container_wide","deko_barrels_ne","spacekit_rock_large_a","spacekit_satellite_dish","spacekit_satellite_dish_detailed"]
static func build(parent: Node3D,id: String,profile: RefCounted,seed: int) -> Node3D:
	var root:=Node3D.new(); root.name="FrontierProp_"+id; parent.add_child(root)
	root.set_meta("visual_family","frontier_reference_place_v1")
	root.set_meta("replaces_legacy_visual",id)
	if id=="spacekit_rock_large_a":
		var geology: Node3D=load("res://scripts/terrain/frontier_art_geology.gd").new(); root.add_child(geology)
		geology.call("build_tile_rock",profile,seed)
		var bounds: AABB=load("res://scripts/terrain/place_reference_dressing.gd").mesh_bounds(geology,root)
		var factor: float=.68/maxf(maxf(bounds.size.x,bounds.size.z),.01)
		geology.scale=Vector3(factor,factor,factor)
		geology.position=Vector3(-bounds.get_center().x*factor,-bounds.position.y*factor,-bounds.get_center().z*factor)
	elif id.begins_with("spacekit_satellite_dish"):
		_cylinder(root,.25,.32,.12,Vector3(0,.06,0),"526b6c")
		_cylinder(root,.07,.09,.65,Vector3(0,.40,0),"c9c5ae")
		var dish:=MeshInstance3D.new(); root.add_child(dish)
		var surface:=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for ring in 5:
			for segment in 24:
				var points: Array[Vector3]=[]
				for pair in [[ring,segment],[ring+1,segment],[ring+1,segment+1],[ring,segment+1]]:
					var radius: float=float(pair[0])*.08; var angle: float=float(pair[1])*TAU/24.0
					points.append(Vector3(cos(angle)*radius,radius*radius*1.8,sin(angle)*radius))
				for index in [0,2,1,0,3,2]: surface.add_vertex(points[index])
		surface.generate_normals(); dish.mesh=surface.commit(); dish.material_override=_mat("ded5b8")
		dish.position=Vector3(0,.78,0); dish.rotation_degrees.x=-35
		_box(root,Vector3(.035,.40,.035),Vector3(0,.94,0),"416b70")
		_cylinder(root,.06,.06,.1,Vector3(0,1.17,0),"66b4bd")
	elif id=="station_computer":
		_cylinder(root,.20,.26,.58,Vector3(0,.29,0),"748884")
		_box(root,Vector3(.46,.10,.34),Vector3(0,.59,0),"c9c5ae")
		var bezel:=_box(root,Vector3(.44,.055,.33),Vector3(0,.68,0),"314f55"); bezel.rotation_degrees.x=-25
		var screen:=_box(root,Vector3(.32,.014,.21),Vector3(0,.713,0),"66b4bd"); screen.rotation_degrees.x=-25
		_box(root,Vector3(.12,.015,.025),Vector3(.12,.65,.16),"dfb65c")
	elif id=="deko_barrels_ne":
		for x in [-.18,.18]:
			_cylinder(root,.13,.16,.53,Vector3(x,.265,0),"c9c5ae")
			_cylinder(root,.161,.161,.065,Vector3(x,.18,0),"416b70")
			_cylinder(root,.09,.09,.025,Vector3(x,.54,0),"738b86")
	else:
		_box(root,Vector3(.67,.39,.50),Vector3(0,.195,0),"526b6c")
		_box(root,Vector3(.69,.035,.52),Vector3(0,.405,0),"c9c5ae")
		for x in [-.24,.24]: _box(root,Vector3(.055,.37,.515),Vector3(x,.20,0),"b0ae95")
	return root
static func _mat(color: String) -> Material:
	if not _materials.has(color):
		var material:=StandardMaterial3D.new(); material.albedo_color=Color(color); material.roughness=.84
		_materials[color]=material
	return _materials[color]
static func _box(root: Node3D,size: Vector3,position: Vector3,color: String) -> MeshInstance3D:
	var mesh:=BoxMesh.new(); mesh.size=size
	var item:=MeshInstance3D.new(); item.mesh=mesh; item.position=position; item.material_override=_mat(color); root.add_child(item); return item
static func _cylinder(root: Node3D,top: float,bottom: float,height: float,position: Vector3,color: String) -> void:
	var mesh:=CylinderMesh.new(); mesh.top_radius=top; mesh.bottom_radius=bottom; mesh.height=height; mesh.radial_segments=12
	var item:=MeshInstance3D.new(); item.mesh=mesh; item.position=position; item.material_override=_mat(color); root.add_child(item)
