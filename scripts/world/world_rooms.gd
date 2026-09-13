extends RefCounted
## Room projection follows the same shared layout used by authoritative navigation.
const Geo = preload("res://scripts/world/world_geometry.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const Layout = preload("res://scripts/core/world_layout.gd")

static func base(parent: Node3D) -> void:
	Geo.box(parent,Vector3(0,-0.18,-4),Vector3(35,0.4,31),Color("38454a"))
	Geo.box(parent,Vector3(0,0.01,-4),Vector3(5,0.05,30),Color("829493"))
	for id in Catalog.rooms():
		var data: Dictionary = Catalog.rooms()[id]
		var center := Vector2(data.center[0],data.center[1])
		var size := Vector2(data.size[0],data.size[1])
		_room(parent,center,size,Vector2(data.door[0],data.door[1]),str(data.label),id in ["workshop","lounge"])
	# Short north/south connectors make the central passage read as one building.
	_project_walls(parent,"base")
	Geo.box(parent,Vector3(0,0.03,10.5),Vector3(4,0.08,3),Color("b5a782"))
	for x in [-2.0,2.0]:
		Geo.box(parent,Vector3(x,1.45,10),Vector3(0.22,2.9,0.42),Color("b2c7bf"))
	Geo.box(parent,Vector3(0,2.9,10),Vector3(4.4,0.22,0.42),Color("b2c7bf"))
	Geo.label(parent,"ROSTGRENZE / 07",Vector3(0,3.9,-18),Color("d5e1d1"),28)
	# Furnishings are projected from WorldLayout by GroundSites, once per map.
	# The approach follows a gentle bend and shares no extra collision geometry.
	_path(parent,[Vector2(0,11),Vector2(3,15),Vector2(11,18),Vector2(20,23),Vector2(25,29)],3.0)

static func _path(parent: Node3D, points: Array, width: float) -> void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edges: Array[Vector2]=[]
	for i in range(points.size()):
		var before: Vector2=points[maxi(0,i-1)];var after: Vector2=points[mini(points.size()-1,i+1)]
		edges.append((after-before).normalized().orthogonal()*width/2)
	for i in range(points.size()-1):
		var a: Vector2=points[i];var b: Vector2=points[i+1];var na:=edges[i];var nb:=edges[i+1]
		for p: Vector2 in [a-na,a+na,b-nb,b-nb,a+na,b+nb]:
			surface.set_normal(Vector3.UP);surface.add_vertex(Vector3(p.x,0.04,p.y))
	var mesh:=MeshInstance3D.new();mesh.mesh=surface.commit();var material:=Geo.material(Color("b29a76"));material.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.material_override=material;parent.add_child(mesh)

static func _room(parent: Node3D, center: Vector2, size: Vector2, door: Vector2, title: String, east: bool) -> void:
	Geo.box(parent,Vector3(center.x,0.015,center.y),Vector3(size.x,0.07,size.y),Color("819496") if not east else Color("879a98"))
	for x in range(int(size.x/3)):
		for z in range(int(size.y/3)):
			Geo.asset(parent,"floor",Vector3(center.x-size.x/2+1.5+x*3,0.045,center.y-size.y/2+1.5+z*3),Vector3(2.98,0.08,2.98))
	var inner_x := center.x-size.x/2 if east else center.x+size.x/2
	var gap:=3.0
	for z in [door.y-gap/2,door.y+gap/2]:
		Geo.box(parent,Vector3(inner_x,1.5,z),Vector3(0.45,3.0,0.2),Color("a6bcb7"))
	Geo.box(parent,Vector3(inner_x,3.0,door.y),Vector3(0.45,0.2,gap+0.2),Color("a6bcb7"))
	Geo.label(parent,title.to_upper(),Vector3(center.x,0.5,center.y+size.y/2-1.0),Color("d4e0cd"),20)

static func _wall(parent: Node3D, at: Vector2, length: float, along_z: bool, transparent: bool) -> void:
	var count := maxi(1,int(ceil(length/3.0)))
	var segment := length/count
	for i in range(count):
		var offset := -length/2+segment*(i+0.5)
		var pos := Vector3(at.x,0.10,at.y)+Vector3(0,0,offset) if along_z else Vector3(at.x+offset,0.10,at.y)
		var wall := Geo.asset(parent,"wall",pos,Vector3(segment,3.05,0.42),PI/2 if along_z else 0.0)
		if transparent: Geo.fade_asset(wall,0.14)
	var dimensions := Vector3(0.25,0.17,length) if along_z else Vector3(length,0.17,0.25)
	Geo.box(parent,Vector3(at.x,0.18,at.y),dimensions,Color("577578"))
	Geo.box(parent,Vector3(at.x,3.16,at.y),dimensions,Color("527078"))

static func station(parent: Node3D) -> void:
	for spec: Dictionary in Layout.rooms("station").values():
		_room(parent,Vector2(spec.center[0],spec.center[1]),Vector2(spec.size[0],spec.size[1]),Vector2(spec.door[0],spec.door[1]),str(spec.label),float(spec.center[0])>0)
	_project_walls(parent,"station")
	Geo.box(parent,Vector3(0,0.01,8),Vector3(54,0.08,12),Color("788a92"))
	Geo.label(parent,"MERIDIAN / FREIHAFEN",Vector3(0,6,-23),Color("b5e6dc"),36)
	Geo.label(parent,"DOCK 01",Vector3(0,0.25,19),Color("d4cbb0"),28)
	for x in [-34.0,34.0]:
		Geo.box(parent,Vector3(x,2,-4),Vector3(6,4,42),Color("415b68"),0.4)
		Geo.box(parent,Vector3(x,5,-4),Vector3(6.5,0.4,42),Color("6c8791"),0.4)
		for z in [-21.0,-7.0,7.0]:
			Geo.box(parent,Vector3(x,5.5,z),Vector3(7,0.6,1),Color("80c9c2"))

static func _project_walls(parent: Node3D,region: String) -> void:
	for id in Layout.obstacles(region):
		var spec: Dictionary=Layout.obstacles(region)[id]
		if spec.get("category","")!="structure" or spec.get("kind","")!="wall":continue
		var root:=Node3D.new();root.name="Blocker_"+str(id);parent.add_child(root);root.set_meta("footprint",spec.duplicate(true))
		var along_z:=float(spec.size[1])>float(spec.size[0])
		_wall(root,Vector2(spec.center[0],spec.center[1]),maxf(spec.size[0],spec.size[1]),along_z,bool(spec.front))
