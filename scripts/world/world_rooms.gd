extends RefCounted
## Visible rooms and docking space. Walls are cutaway scenery, not navigation.
const Geo = preload("res://scripts/world/world_geometry.gd")
const Catalog = preload("res://scripts/core/catalog.gd")

static func base(parent: Node3D) -> void:
	Geo.box(parent,Vector3(0,-0.18,-4),Vector3(35,0.4,31),Color("38454a"))
	Geo.box(parent,Vector3(0,0.01,-4),Vector3(5,0.05,30),Color("829493"))
	for id in Catalog.rooms():
		var data: Dictionary = Catalog.rooms()[id]
		var center := Vector2(data.center[0],data.center[1])
		var size := Vector2(data.size[0],data.size[1])
		_room(parent,center,size,Vector2(data.door[0],data.door[1]),str(data.label),id in ["workshop","lounge"])
	# Short north/south connectors make the central passage read as one building.
	_wall(parent,Vector2(0,-18),4.0,false,false)
	Geo.box(parent,Vector3(0,0.03,10.5),Vector3(4,0.08,3),Color("b5a782"))
	for x in [-2.0,2.0]:
		Geo.box(parent,Vector3(x,1.45,10),Vector3(0.22,2.9,0.42),Color("b2c7bf"))
	Geo.box(parent,Vector3(0,2.9,10),Vector3(4.4,0.22,0.42),Color("b2c7bf"))
	Geo.label(parent,"ROSTGRENZE / 07",Vector3(0,3.9,-18),Color("d5e1d1"),28)
	# Furniture uses simple readable silhouettes around the actual interactive objects.
	Geo.box(parent,Vector3(11,0.8,-8.5),Vector3(3.5,0.18,1.6),Color("b29b73"))
	for x in [9.8,12.2]:
		for z in [-9.8,-7.2]:
			Geo.box(parent,Vector3(x,0.35,z),Vector3(0.8,0.7,0.8),Color("617c78"))
	for x in [-14.0,-10.0,-6.0]:
		Geo.asset(parent,"crate-small",Vector3(x,0.03,7),Vector3(1.1,0.8,1.2))
	for x in [-14.2,-5.6]:
		Geo.box(parent,Vector3(x,1.0,-9),Vector3(1.2,2,0.7),Color("758c8e"))
	# Solar array and service mast sit outside the playable room floor.
	for x in [-12.0,-7.0,-2.0]:
		Geo.box(parent,Vector3(x,1.3,-24),Vector3(0.25,2.6,0.25),Color("566c71"))
		var panel := Geo.box(parent,Vector3(x,2.8,-24),Vector3(4.5,0.18,5.5),Color("355b69"),0.4)
		panel.rotation.x = -0.18
	Geo.cylinder(parent,Vector3(-19,4,-18),0.13,8,Color("778b89"),8)
	Geo.box(parent,Vector3(-19,7.4,-18),Vector3(3,0.18,0.18),Color("b4cbc3"))
	# A broad open approach is intentionally scenery, with no fake blocking walls.
	var path := Geo.box(parent,Vector3(11,0.035,17),Vector3(30,0.055,4.5),Color("bba07c"))
	path.rotation.y = -0.5
	for x in [-30.0,-23.0]:
		Geo.box(parent,Vector3(x,0.18,18),Vector3(5.4,0.35,7),Color("827663"))
		Geo.asset(parent,"crate-wide",Vector3(x,0.36,18),Vector3(3.8,2.4,3.6))

static func _room(parent: Node3D, center: Vector2, size: Vector2, door: Vector2, title: String, east: bool) -> void:
	Geo.box(parent,Vector3(center.x,0.015,center.y),Vector3(size.x,0.07,size.y),Color("819496") if not east else Color("879a98"))
	for x in range(int(size.x/3)):
		for z in range(int(size.y/3)):
			Geo.asset(parent,"floor",Vector3(center.x-size.x/2+1.5+x*3,0.045,center.y-size.y/2+1.5+z*3),Vector3(2.98,0.08,2.98))
	_wall(parent,center+Vector2(0,-size.y/2),size.x,false,false)
	_wall(parent,center+Vector2(0,size.y/2),size.x,false,true)
	var outer_x := center.x+size.x/2 if east else center.x-size.x/2
	_wall(parent,Vector2(outer_x,center.y),size.y,true,east)
	var inner_x := center.x-size.x/2 if east else center.x+size.x/2
	var lower := center.y-size.y/2
	var upper := center.y+size.y/2
	var gap := 3.0
	for segment in [Vector2(lower,door.y-gap/2),Vector2(door.y+gap/2,upper)]:
		if segment.y-segment.x > 0.1:
			_wall(parent,Vector2(inner_x,(segment.x+segment.y)/2),segment.y-segment.x,true,not east)
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
	_room(parent,Vector2(-14,-10),Vector2(24,22),Vector2(-2,-5),"Handel / Ausrüstung",false)
	_room(parent,Vector2(14,-10),Vector2(24,22),Vector2(2,-5),"Fracht / Transit",true)
	Geo.box(parent,Vector3(0,0.01,8),Vector3(54,0.08,12),Color("788a92"))
	for x in [-24.0,24.0]:
		for z in [-17.0,-10.0,-3.0]:
			Geo.asset(parent,"crate-wide",Vector3(x,0.1,z),Vector3(2.8,1.7,2.2))
	Geo.label(parent,"MERIDIAN / FREIHAFEN",Vector3(0,6,-23),Color("b5e6dc"),36)
	Geo.label(parent,"DOCK 01",Vector3(0,0.25,19),Color("d4cbb0"),28)
	for x in [-34.0,34.0]:
		Geo.box(parent,Vector3(x,2,-4),Vector3(6,4,42),Color("415b68"),0.4)
		Geo.box(parent,Vector3(x,5,-4),Vector3(6.5,0.4,42),Color("6c8791"),0.4)
		for z in [-21.0,-7.0,7.0]:
			Geo.box(parent,Vector3(x,5.5,z),Vector3(7,0.6,1),Color("80c9c2"))
