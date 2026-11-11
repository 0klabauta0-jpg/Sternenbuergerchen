extends Node3D
## Cold-built visual candidate. All deck, navigation and services remain in MapData.
## Geometry is batched by material; no process loop, collision or dynamic light.
const HULL := "c9cfc8"
const STEEL := "83918e"
const DECK := "52656b"
const INSET := "475960"
const DARK := "1c2e38"
const YELLOW := "d4ac4f"
const CYAN := "70c7c5"
const GLASS := "365c68"
var _batches: Dictionary = {}
var _materials: Dictionary = {}
var _triangle_count := 0
var _box_count := 0

func _ready() -> void:
	if get_child_count() > 0: return
	name = "PolisaStationVisual"
	_build_hull()
	_build_hall()
	_build_pad(Vector2(-21.5,0),Vector2(13,10),"01")
	_build_pad(Vector2(21.5,0),Vector2(13,10),"02")
	_build_pad(Vector2(0,21.5),Vector2(10,13),"03")
	_build_rings()
	_flush()
	set_meta("polisa_visual_metrics",{"triangles":_triangle_count,"mesh_nodes":_batches.size(),"primitive_boxes":_box_count,"collision_nodes":0,"dynamic_lights":0})

func _build_hull() -> void:
	# Every visible walking plane keeps the original position and dimensions.
	_box(Vector3(18,.20,16),Vector3(0,-.09,0),DECK)
	_chamfered_shell(Vector2(18.8,16.8),.9,-.22,-2.55,Vector2.ZERO,HULL)
	_chamfered_shell(Vector2(14.4,12.6),1.6,-2.55,-4.1,Vector2.ZERO,DARK)
	_box(Vector3(46,1.15,2.8),Vector3(0,-1.1,0),DARK)
	_box(Vector3(34,.18,3.2),Vector3(0,-.08,0),DECK)
	_box(Vector3(3.2,.18,14),Vector3(0,-.08,12),DECK)
	_box(Vector3(2.8,1.0,18),Vector3(0,-.85,14),DARK)
	for side: float in [-1.0,1.0]:
		_beam(Vector3(side*7,-3.3,0),Vector3(side*21,-1.25,0),.75,DARK)
		_box(Vector3(7.0,.38,3.6),Vector3(side*12.5,-.40,0),HULL)
		for z: float in [-1.46,1.46]:
			_box(Vector3(6.4,.028,.1),Vector3(side*12.1,.03,z),YELLOW)
		for z: float in [-1.80,1.80]:
			_box(Vector3(6.0,.10,.10),Vector3(side*12.0,.78,z),HULL)
			for station_x: float in [9.4,12.0,14.6]:
				_box(Vector3(.12,.74,.12),Vector3(side*station_x,.39,z),STEEL)
		for x: float in [-6.0,-3.0,0.0,3.0,6.0]:
			_box(Vector3(1.65,.68,.12),Vector3(x,-1.12,side*8.12),INSET)
			_box(Vector3(1.25,.075,.15),Vector3(x,-.75,side*8.16),STEEL)
	_beam(Vector3(0,-3.5,5),Vector3(0,-1.2,21),.85,DARK)
	for x: float in [-1.46,1.46]:
		_box(Vector3(.1,.028,7.6),Vector3(x,.03,12.1),YELLOW)
	for x: float in [-1.80,1.80]:
		_box(Vector3(.10,.10,6.2),Vector3(x,.78,11.6),HULL)
		for z: float in [8.6,11.6,14.6]:
			_box(Vector3(.12,.74,.12),Vector3(x,.39,z),STEEL)
	# The hub's compact lower machinery anchors the rings and all three arms.
	_cylinder(3.35,2.55,4.8,Vector3(0,-5.75,0),DARK,12)
	_cylinder(3.55,3.55,.55,Vector3(0,-4.05,0),STEEL,12)
	_cylinder(2.8,2.8,.65,Vector3(0,-7.65,0),HULL,12)
	_cylinder(1.3,1.3,16.2,Vector3(0,-7.45,0),DARK,12,Vector3(0,0,PI*.5))
	for side: float in [-1.0,1.0]:
		_cylinder(1.65,1.65,.5,Vector3(side*8.2,-7.45,0),HULL,12,Vector3(0,0,PI*.5))
		_cylinder(1.18,1.18,.55,Vector3(side*8.55,-7.45,0),INSET,12,Vector3(0,0,PI*.5))
	for x: float in [-1.55,1.55]:
		_box(Vector3(.55,2.7,1.6),Vector3(x,-5.8,2.9),STEEL)
		_box(Vector3(.30,1.45,.08),Vector3(x,-5.6,3.74),YELLOW)

func _build_hall() -> void:
	# Floor panels and a directional cross are flush paint, never new obstacles.
	for x: float in [-4.7,4.7]:
		_box(Vector3(7.2,.02,12.6),Vector3(x,.021,0),INSET)
		for z: float in [-5.8,-2.9,2.9,5.8]:
			_box(Vector3(6.3,.022,.045),Vector3(x,.037,z),STEEL)
	_box(Vector3(3.0,.026,14.0),Vector3(0,.027,0),STEEL)
	_box(Vector3(16.4,.028,2.45),Vector3(0,.030,0),STEEL)
	for x: float in [-1.7,1.7]:
		_box(Vector3(.08,.025,11.8),Vector3(x,.038,0),YELLOW)
	for x: float in [-5.5,5.5]:
		# Rear panels sit on the already blocked rear wall. Front stays cut away.
		_box(Vector3(7,.9,.4),Vector3(x,.45,7.5),HULL)
		_box(Vector3(7,2.5,.40),Vector3(x,1.25,-7.5),HULL)
		_box(Vector3(6.4,1.25,.08),Vector3(x,1.35,-7.24),GLASS)
		_box(Vector3(6.4,.11,.10),Vector3(x,2.09,-7.18),CYAN)
		_box(Vector3(7.4,.35,2.0),Vector3(x,2.72,-7.1),HULL)
		_box(Vector3(6.8,.10,.24),Vector3(x,2.50,-6.18),DARK)
	for x: float in [-8.7,8.7]:
		for z: float in [-4.5,4.5]:
			_box(Vector3(.4,.9,5),Vector3(x,.45,z),HULL)
			_box(Vector3(.46,.13,4.9),Vector3(x,.96,z),YELLOW)
		_box(Vector3(.58,2.9,.55),Vector3(x,1.45,-7.5),HULL)
		_box(Vector3(.18,1.2,.10),Vector3(x,1.65,-7.18),CYAN)
		for z: float in [-5.2,5.2]:
			_cylinder(.24,.30,1.15,Vector3(signf(x)*9.16,.65,z),STEEL,8)
			_cylinder(.29,.29,.12,Vector3(signf(x)*9.16,1.24,z),YELLOW,8)
	# A roof header reads as a hall without hiding the playable floor.
	_box(Vector3(18.0,.42,.75),Vector3(0,3.12,-7.45),HULL)
	_box(Vector3(5.0,.95,.22),Vector3(0,2.95,-7.00),DARK)
	_label("POLISA",Vector3(0,3.0,-6.83),.032,false,false)
	for entrance: Vector3 in [Vector3(-8.7,0,0),Vector3(8.7,0,0),Vector3(0,0,7.5)]:
		var side := Vector3(0,0,1.8) if absf(entrance.x)>1 else Vector3(1.8,0,0)
		for sign_value: float in [-1.0,1.0]:
			_box(Vector3(.38,1.5,.38),entrance+side*sign_value+Vector3(0,.75,0),HULL)
			_box(Vector3(.16,.5,.16),entrance+side*sign_value+Vector3(0,1.0,0),CYAN)
	for spec: Array in [[Vector3(-5,0,-4.7),"HANDWAFFEN",CYAN],[Vector3(5,0,-4.7),"RUESTUNG",YELLOW],[Vector3(-5,0,4.6),"SCHIFFE",CYAN],[Vector3(5,0,4.6),"WAREN",YELLOW]]:
		_counter(spec[0],String(spec[1]),String(spec[2]))
	# Same original service pedestal footprint; the faceted globe is decorative.
	_cylinder(.65,.8,.8,Vector3(0,.4,0),DARK,8)
	_cylinder(.74,.74,.10,Vector3(0,.86,0),HULL,8)
	_cylinder(.55,.55,.04,Vector3(0,.94,0),CYAN,12)
	var globe := SphereMesh.new()
	globe.radius=.48;globe.height=.96;globe.radial_segments=12;globe.rings=6
	_append(globe,Vector3(0,1.57,0),GLASS)
	_box(Vector3(.06,1.0,.06),Vector3(0,1.2,0),CYAN)

func _counter(position: Vector3,title: String,accent: String) -> void:
	_box(Vector3(3,.78,1.15),position+Vector3(0,.39,0),DARK)
	_box(Vector3(3.1,.09,1.22),position+Vector3(0,.82,0),HULL)
	_box(Vector3(2.5,.34,1.16),position+Vector3(0,.40,0),STEEL)
	var back := -1.0 if position.z<0 else 1.0
	_box(Vector3(1.9,.57,.12),position+Vector3(0,1.12,back*.42),DARK)
	_box(Vector3(1.64,.38,.13),position+Vector3(0,1.16,back*.39),accent)
	for x: float in [-1.12,1.12]:
		_box(Vector3(.28,.26,.38),position+Vector3(x,.99,0),STEEL)
	_label(title,position+Vector3(0,1.68,0),.017,false,true)

func _build_pad(center: Vector2,size: Vector2,id: String) -> void:
	_box(Vector3(size.x,.24,size.y),Vector3(center.x,-.11,center.y),DECK)
	_chamfered_shell(size+Vector2(.38,.38),.70,-.24,-1.55,center,HULL)
	_box(Vector3(size.x-1.5,.022,size.y-1.5),Vector3(center.x,.023,center.y),INSET)
	for sign_value: float in [-1.0,1.0]:
		_box(Vector3(size.x-.5,.025,.13),Vector3(center.x,.045,center.y+sign_value*(size.y*.5-.45)),YELLOW)
		_box(Vector3(.13,.025,size.y-.5),Vector3(center.x+sign_value*(size.x*.5-.45),.045,center.y),YELLOW)
		# Four corners stay at the original marker positions and 0.08m height.
		for edge: float in [-1.0,1.0]:
			_box(Vector3(.3,.08,.3),Vector3(center.x+sign_value*(size.x*.5-.2),.05,center.y+edge*(size.y*.5-.2)),CYAN)
		for lane: float in [-1.0,0.0,1.0]:
			_box(Vector3(.52,.026,.12),Vector3(center.x+lane*1.0,.052,center.y+sign_value*2.25),HULL)
		_box(Vector3(.14,.03,3.65),Vector3(center.x+sign_value*2.25,.053,center.y),HULL)
		for offset: float in [-2.6,2.6]:
			var a := center+Vector2(sign_value*(size.x*.5-.8),offset)
			_box(Vector3(.58,.026,.28),Vector3(a.x,.055,a.y),YELLOW)
	_label(id,Vector3(center.x,.058,center.y),.068,true,false)
	_label("POLISA",Vector3(center.x,.058,center.y+size.y*.5-1.0),.024,true,false)
	# Utilities are outside the existing pad footprint; tops read as machinery.
	if absf(center.x)>1:
		var side := signf(center.x)
		var edge_x := center.x+side*(size.x*.5+1.30)
		_box(Vector3(2.35,.4,9.2),Vector3(edge_x,-.65,center.y),DARK)
		for n: int in range(4):
			_box(Vector3(2.12,.10,1.70),Vector3(edge_x,-.39,center.y-3.1+n*2.05),GLASS)
			_box(Vector3(.08,.025,1.65),Vector3(edge_x,-.32,center.y-3.1+n*2.05),STEEL)
		for z: float in [-3.8,3.8]:
			_box(Vector3(1.0,.85,1.2),Vector3(edge_x,.01,z),STEEL)
			_box(Vector3(1.05,.10,1.25),Vector3(edge_x,.46,z),YELLOW)
	else:
		for x: float in [-3.9,3.9]:
			_box(Vector3(1.3,.85,1.1),Vector3(x,-.05,28.7),STEEL)
			_box(Vector3(1.35,.1,1.15),Vector3(x,.43,28.7),YELLOW)

func _build_rings() -> void:
	for x: float in [-5.3,5.3]:
		var center := Vector3(x,-7.8,0)
		_ring(center,7.35,6.50,.90,32)
		_ring(center,6.49,6.23,1.03,32,DARK)
		for angle: float in [PI*.22,PI*.78,PI*1.22,PI*1.78]:
			var rim := center+Vector3(0,cos(angle)*6.35,sin(angle)*6.35)
			_beam(center,rim,.46,STEEL)
		for z: float in [-4.0,4.0]:
			_beam(Vector3(x,-1.8,z),Vector3(x,-5.3,z*1.4),.55,DARK)

func _ring(center: Vector3,outer: float,inner: float,width: float,segments: int,color: String=HULL) -> void:
	for i: int in range(segments):
		var a := TAU*float(i)/segments
		var b := TAU*float(i+1)/segments
		var points := PackedVector3Array()
		for axis: float in [-width*.5,width*.5]:
			for radius: float in [outer,inner]:
				for angle: float in [a,b]:
					points.append(center+Vector3(axis,cos(angle)*radius,sin(angle)*radius))
		var part_color := YELLOW if color==HULL and i%8==0 else color
		for face: Array in [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]:
			_quad(points[face[0]],points[face[3]],points[face[2]],points[face[1]],part_color)

func _chamfered_shell(size: Vector2,cut: float,top: float,bottom: float,center: Vector2,color: String) -> void:
	var hx := size.x*.5
	var hz := size.y*.5
	var shape := [Vector2(-hx+cut,-hz),Vector2(hx-cut,-hz),Vector2(hx,-hz+cut),Vector2(hx,hz-cut),Vector2(hx-cut,hz),Vector2(-hx+cut,hz),Vector2(-hx,hz-cut),Vector2(-hx,-hz+cut)]
	for i: int in range(8):
		var p: Vector2=shape[i]
		var n: Vector2=shape[(i+1)%8]
		_quad(Vector3(center.x+p.x,top,center.y+p.y),Vector3(center.x+n.x,top,center.y+n.y),Vector3(center.x+n.x*.88,bottom,center.y+n.y*.88),Vector3(center.x+p.x*.88,bottom,center.y+p.y*.88),color)
		_triangle(Vector3(center.x,bottom,center.y),Vector3(center.x+p.x*.88,bottom,center.y+p.y*.88),Vector3(center.x+n.x*.88,bottom,center.y+n.y*.88),DARK)

func _beam(a: Vector3,b: Vector3,width: float,color: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size=Vector3(width,a.distance_to(b),width)
	var transform := Transform3D(Basis(Quaternion(Vector3.UP,(b-a).normalized())),(a+b)*.5)
	_append_transform(mesh,color,transform)

func _box(size: Vector3,position: Vector3,color: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size=size
	_append(mesh,position,color)
	_box_count+=1

func _cylinder(top: float,bottom: float,height: float,position: Vector3,color: String,segments: int=12,rotation: Vector3=Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius=top;mesh.bottom_radius=bottom;mesh.height=height;mesh.radial_segments=segments
	_append(mesh,position,color,rotation)

func _append(mesh: Mesh,position: Vector3,color: String,rotation: Vector3=Vector3.ZERO) -> void:
	_append_transform(mesh,color,Transform3D(Basis.from_euler(rotation),position))

func _append_transform(mesh: Mesh,color: String,transform: Transform3D) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var surface := _surface(color)
	var count := indices.size() if not indices.is_empty() else vertices.size()
	for i: int in range(count):
		var vertex_id := indices[i] if not indices.is_empty() else i
		surface.set_normal((transform.basis*normals[vertex_id]).normalized())
		surface.set_uv(Vector2.ZERO)
		surface.add_vertex(transform*vertices[vertex_id])
	_triangle_count+=count/3

func _quad(a: Vector3,b: Vector3,c: Vector3,d: Vector3,color: String) -> void:
	_triangle(a,b,c,color)
	_triangle(a,c,d,color)

func _triangle(a: Vector3,b: Vector3,c: Vector3,color: String) -> void:
	var surface := _surface(color)
	var normal := (b-a).cross(c-a).normalized()
	for point: Vector3 in [a,b,c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2.ZERO)
		surface.add_vertex(point)
	_triangle_count+=1

func _surface(color: String) -> SurfaceTool:
	if not _batches.has(color):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[color]=surface
	return _batches[color]

func _flush() -> void:
	for color: String in _batches:
		var surface: SurfaceTool=_batches[color]
		var part := MeshInstance3D.new()
		part.name="PolisaBatch_"+color
		part.mesh=surface.commit()
		part.material_override=_material(color)
		add_child(part)

func _material(color: String) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color=Color(color)
		material.roughness=.78
		material.metallic=.14
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		if color==CYAN:
			material.emission_enabled=true
			material.emission=Color(color)
			material.emission_energy_multiplier=.42
		_materials[color]=material
	return _materials[color]

func _label(text: String,position: Vector3,pixel_size: float,floor_label: bool=false,billboard: bool=true) -> void:
	var label := Label3D.new()
	label.text=text;label.position=position;label.pixel_size=pixel_size;label.font_size=36
	label.modulate=Color(HULL);label.outline_size=3
	if floor_label: label.rotation_degrees.x=-90
	elif billboard: label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
