extends RefCounted
## Authored modular locations. Blocking footprints come from the core catalog.
const Geo = preload("res://scripts/world/world_geometry.gd")
const Catalog = preload("res://scripts/core/catalog.gd")

static func build(parent: Node3D, region: String) -> void:
	match region:
		"bunker_surface": _surface(parent)
		"bunker_depths": _depths(parent)
		"distribution": _distribution(parent)
		"tradepost": _tradepost(parent)
	_build_obstacles(parent,region)
	_build_floors(parent)

static func _floor(parent: Node3D, center: Vector2, size: Vector2, color: Color) -> void:
	var layers: Array=parent.get_meta("floor_layers",[])
	layers.append({"rect":Rect2(center-size*0.5,size),"color":color})
	parent.set_meta("floor_layers",layers)
	# Single strips make readable lanes without hundreds of floor objects.
	for side in [-1.0,1.0]:
		Geo.box(parent,Vector3(center.x+side*(size.x/2-0.2),0.063,center.y),Vector3(0.14,0.012,size.y),Color("b6afa0"))

static func _build_floors(parent: Node3D) -> void:
	# Partition all axis-aligned plates into one colored mesh: intersections have
	# a single face, so approach roads and depot lanes cannot fight in depth.
	var layers: Array=parent.get_meta("floor_layers",[])
	if layers.is_empty(): return
	var xs: Array[float]=[]; var zs: Array[float]=[]
	for layer: Dictionary in layers:
		var rect: Rect2=layer.rect
		for x in [rect.position.x,rect.end.x]:
			if x not in xs: xs.append(x)
		for z in [rect.position.y,rect.end.y]:
			if z not in zs: zs.append(z)
	xs.sort(); zs.sort()
	var surface:=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for xi in range(xs.size()-1):
		for zi in range(zs.size()-1):
			var center:=Vector2((xs[xi]+xs[xi+1])*0.5,(zs[zi]+zs[zi+1])*0.5)
			var found:=false; var color:=Color.WHITE
			for layer: Dictionary in layers:
				if (layer.rect as Rect2).has_point(center): color=layer.color; found=true
			if not found: continue
			var a:=Vector3(xs[xi],0.05,zs[zi]); var b:=Vector3(xs[xi+1],0.05,zs[zi]); var c:=Vector3(xs[xi],0.05,zs[zi+1]); var d:=Vector3(xs[xi+1],0.05,zs[zi+1])
			for point in [a,b,c,b,d,c]:
				surface.set_normal(Vector3.UP); surface.set_color(color); surface.add_vertex(point)
	var mesh:=MeshInstance3D.new(); mesh.mesh=surface.commit(); mesh.name="UnifiedGroundFloors"
	var material:=Geo.material(Color.WHITE); material.vertex_color_use_as_albedo=true; material.vertex_color_is_srgb=true; material.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=material; parent.add_child(mesh)

static func _wall(parent: Node3D, center: Vector2, size: Vector2, height: float, transparent: bool) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position=Vector3(center.x,0,center.y)
	var body:=Geo.box(root,Vector3(0,height/2,0),Vector3(size.x,height,size.y),Color("718382"))
	if transparent: Geo.fade_asset(body,0.13)
	Geo.box(root,Vector3(0,0.13,0),Vector3(size.x,0.25,size.y),Color("455958"))
	Geo.box(root,Vector3(0,height,0),Vector3(size.x,0.16,size.y),Color("a8b4aa"))
	var along_z:=size.y>size.x
	var length:=size.y if along_z else size.x
	for i in range(maxi(1,int(length/8))):
		var at:=-length/2+4+i*8
		Geo.box(root,Vector3(0,height*0.5,at) if along_z else Vector3(at,height*0.5,0),Vector3(size.x+0.15,height,0.32) if along_z else Vector3(0.32,height,size.y+0.15),Color("899b93"))
	return root

static func _build_obstacles(parent: Node3D, region: String) -> void:
	for id in Catalog.obstacles(region):
		var spec: Dictionary=Catalog.obstacles(region)[id]
		var center:=Vector2(spec.center[0],spec.center[1])
		var size:=Vector2(spec.size[0],spec.size[1])
		var root: Node3D
		if region in ["bunker_surface","bunker_depths"]:
			root=_wall(parent,center,size,5.5 if region=="bunker_depths" else 6.0,str(id).contains("south") or str(id).contains("right") or str(id).begins_with("east"))
		elif minf(size.x,size.y)<=1.1:
			root=_wall(parent,center,size,5.4 if region=="tradepost" else 6.0 if str(id).begins_with("market") else 8.0,str(id).ends_with("side"))
		elif region=="rust":
			root=Node3D.new(); parent.add_child(root)
			root.position=Vector3(center.x,0,center.y)
			for layer in range(4):
				Geo.box(root,Vector3(0,0.6+layer*1.0,0),Vector3(size.x*(1-layer*0.09),1.15,size.y*(1-layer*0.08)),Color("ae7957") if layer%2==0 else Color("925f49"))
		else:
			root=Node3D.new(); parent.add_child(root)
			root.position=Vector3(center.x,0,center.y)
			var height:=12.0 if str(id).ends_with("_a") else 11.0 if str(id).ends_with("_c") else 9.0 if region=="distribution" else 4.0
			Geo.box(root,Vector3(0,height/2,0),Vector3(size.x,height,size.y),Color("5c7577"))
			Geo.box(root,Vector3(0,height+0.12,0),Vector3(size.x,0.25,size.y),Color("a3b0a6"))
			for x in range(int(-size.x/2)+1,int(size.x/2),3):
				Geo.box(root,Vector3(x,height/2,size.y/2+0.02),Vector3(0.13,height-0.4,0.10),Color("8b9f98"))
			Geo.box(root,Vector3(0,1.2,size.y/2+0.08),Vector3(size.x*0.7,0.65,0.12),Color("c7a168"))
		root.name="Blocker_"+str(id)
		root.set_meta("footprint",spec.duplicate(true))

static func _surface(parent: Node3D) -> void:
	_floor(parent,Vector2(0,-7),Vector2(48,44),Color("77837d"))
	_floor(parent,Vector2(0,32),Vector2(14,34),Color("a59173"))
	# An open portico gives the entry a roof silhouette without inventing walls.
	for x in [-19.0,19.0]:
		Geo.box(parent,Vector3(x,6.1,-7),Vector3(1.4,0.5,39),Color("82948c"))
	Geo.box(parent,Vector3(0,6.2,-22),Vector3(48,0.5,12),Color("8f9b8e"))
	Geo.box(parent,Vector3(0,6.4,10),Vector3(42,1.1,1.5),Color("a2afa2"))
	Geo.label(parent,"KARST / AUSSENANLAGE 09",Vector3(0,8,-28),Color("dce2c6"),31)
	Geo.label(parent,"01   LASTENAUFZUG",Vector3(0,0.4,20),Color("dbc590"),24)
	for x in [-18.0,18.0]:
		Geo.box(parent,Vector3(x,1.5,10),Vector3(0.28,3,0.28),Color("d5b77d"))
		_lamp(parent,Vector3(x,3,10))
	# Perimeter features are outside the approach; low cables imply infrastructure.
	for z in [-62.0,-74.0,-86.0]:
		Geo.cylinder(parent,Vector3(-40,1.5,z),3,3,Color("637677"),10)
		Geo.box(parent,Vector3(-40,0.2,z+6),Vector3(0.45,0.4,7),Color("566467"))
	_mast(parent,Vector3(-34,0,-36),10)

static func _depths(parent: Node3D) -> void:
	# These exact floor outlines also define the core's allowed underground area.
	Geo.box(parent,Vector3(0,-0.7,0),Vector3(128,1.0,128),Color("172b32"))
	_floor(parent,Vector2.ZERO,Vector2(16,96),Color("596e73"))
	_floor(parent,Vector2(-24,0),Vector2(32,48),Color("71817c"))
	_floor(parent,Vector2(24,0),Vector2(32,48),Color("667f80"))
	for x in [-40.0,40.0]: _wall(parent,Vector2(x,0),Vector2(1,48),6,x>0)
	for x in [-24.0,24.0]:
		_wall(parent,Vector2(x,-24),Vector2(32,1),6,false)
		_wall(parent,Vector2(x,24),Vector2(32,1),6,true)
	for z in [-36.0,36.0]:
		for x in [-8.0,8.0]: _wall(parent,Vector2(x,z),Vector2(1,24),6,x>0)
	for z in [-48.0,48.0]: _wall(parent,Vector2(0,z),Vector2(16,1),6,z>0)
	for x in [-8.0,8.0]:
		Geo.box(parent,Vector3(x,5.6,0),Vector3(1.3,0.4,6),Color("bdb799"))
		for z in [-3.0,3.0]: _lamp(parent,Vector3(x,3.8,z))
	for z in [-42.0,-18.0,6.0,30.0]:
		Geo.box(parent,Vector3(0,0.046,z),Vector3(3.4,0.02,0.25),Color("b8b283"))
		Geo.box(parent,Vector3(-6.6,0.05,z),Vector3(0.12,0.04,12),Color("80c4b9"))
		Geo.box(parent,Vector3(6.6,0.05,z),Vector3(0.12,0.04,12),Color("80c4b9"))
	Geo.label(parent,"01  AUFZUG / ZENTRALGANG",Vector3(0,0.3,23),Color("e2c89a"),23)
	Geo.label(parent,"02  FRACHTLAGER",Vector3(-24,0.3,15),Color("d7dbbb"),24)
	Geo.label(parent,"03  SICHERHEIT",Vector3(24,0.3,15),Color("b9ded8"),24)
	# Wall-mounted pipes and consoles keep the navigable floor physically clear.
	for z in [-16.0,-8.0,0.0,8.0,16.0]:
		Geo.box(parent,Vector3(-39.3,2.8,z),Vector3(0.18,0.8,5.5),Color("b1a47c"))
	for x in [-29.0,-19.0,19.0,29.0]: _lamp(parent,Vector3(x,5,-23.4))

static func _distribution(parent: Node3D) -> void:
	_floor(parent,Vector2(5,-5),Vector2(220,180),Color("827d6b"))
	# Broad vehicle lanes divide small functional volumes, not one monumental box.
	_floor(parent,Vector2(-26,4),Vector2(25,140),Color("667c7a"))
	_floor(parent,Vector2(50,-17),Vector2(125,16),Color("627875"))
	_floor(parent,Vector2(-83,83),Vector2(20,75),Color("aa9475"))
	_canopy(parent,Vector2(-56,-35),Vector2(39,30),11,Color("a9b4a3"))
	_canopy(parent,Vector2(14,0),Vector2(37,45),12,Color("8ca8a2"))
	_canopy(parent,Vector2(57,31),Vector2(36,29),9,Color("b1b496"))
	_canopy(parent,Vector2(50,-44),Vector2(36,24),8,Color("849c96"))
	_canopy(parent,Vector2(-27,24),Vector2(26,18),6,Color("c2bca4"))
	Geo.label(parent,"MERIDIAN / DISTRIBUTION 04",Vector3(-25,14,-80),Color("e2dec4"),39)
	Geo.label(parent,"01  HANDEL",Vector3(-28,0.25,37),Color("e0d1ad"),25)
	Geo.label(parent,"02  UMSCHLAG",Vector3(-22,0.25,-45),Color("c6ded0"),26)
	Geo.label(parent,"03  SICHERHEIT",Vector3(49,0.25,-27),Color("a5d4ce"),25)
	Geo.label(parent,"04  BERGEDOCK",Vector3(88,0.25,41),Color("dfbd89"),26)
	for x in [-95.0,100.0]:
		for z in [-65.0,55.0]: _mast(parent,Vector3(x,0,z),8)
	# Long low road seams make the full landscape useful to read from a shuttle.
	_floor(parent,Vector2(-110,190),Vector2(20,105),Color("a38b6d"))
	_floor(parent,Vector2(180,-16),Vector2(125,14),Color("a38b6d"))

static func _tradepost(parent: Node3D) -> void:
	_floor(parent,Vector2(0,0),Vector2(55,45),Color("8a8877"))
	_floor(parent,Vector2(-24,28),Vector2(13,45),Color("b29975"))
	_canopy(parent,Vector2(-3,-2),Vector2(23,21),5.4,Color("b7b7a0"))
	_mast(parent,Vector3(-19,0,-18),9)
	Geo.label(parent,"SAUM / HANDELSPOSTEN",Vector3(0,7,-21),Color("ddd8b8"),30)
	for x in [-12.0,-6.0,0.0]:
		var solar:=Geo.box(parent,Vector3(x,2.5,-30),Vector3(5,0.18,8),Color("355d6c"),0.4)
		solar.rotation.x=-0.22
		Geo.box(parent,Vector3(x,1.2,-30),Vector3(0.3,2.4,0.3),Color("627a7c"))

static func _canopy(parent: Node3D, center: Vector2, size: Vector2, height: float, color: Color) -> void:
	# Elevated crossbeams leave all unblocked ground navigable. Cutaway roof bands
	# communicate a hall while retaining the player's view of crew and resources.
	for x in [-size.x/2,size.x/2]:
		Geo.box(parent,Vector3(center.x+x,height,center.y),Vector3(0.5,0.6,size.y),color)
	for z in [-size.y/2,0.0,size.y/2]:
		Geo.box(parent,Vector3(center.x,height,center.y+z),Vector3(size.x,0.6,0.45),color)
	var roof:=Geo.box(parent,Vector3(center.x,height+0.1,center.y-size.y*0.31),Vector3(size.x,0.2,size.y*0.38),color)
	Geo.fade_asset(roof,0.24)

static func _lamp(parent: Node3D, at: Vector3) -> void:
	var lamp:=Geo.box(parent,at,Vector3(0.24,0.25,1.8),Color("99e0d1"))
	lamp.material_override=Geo.material(Color("99e0d1"),0,1.1)

static func _mast(parent: Node3D, at: Vector3, height: float) -> void:
	Geo.box(parent,at+Vector3(0,height/2,0),Vector3(0.24,height,0.24),Color("8f9f92"))
	Geo.box(parent,at+Vector3(0,height,0),Vector3(4.2,0.25,0.6),Color("b1b69c"))
	_lamp(parent,at+Vector3(0,height,0))
