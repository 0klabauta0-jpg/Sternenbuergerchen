extends Node3D
## Authored layout projection only. Static batches; no runtime truth or collisions.
const FACTS = "res://art/polisa_r03_20261111/layout_compiled.json"
const ARMOR = preload("res://scripts/terrain/personnel_armor_visual.gd")
const PERSON = preload("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb")
const HULL := "c9cfc8"
const STEEL := "83918e"
const DECK := "52656b"
const INSET := "475960"
const DARK := "1c2e38"
const YELLOW := "d4ac4f"
const CYAN := "70c7c5"
const GLASS := "365c68"
const SOLAR := "294763"
var _batches: Dictionary = {}
var _materials: Dictionary = {}
var _triangle_count := 0
var _box_count := 0
var _showcase_count := 0

func _ready() -> void:
	if get_child_count() > 0: return
	name = "PolisaR03Visual"
	var facts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FACTS))
	_build_structure(facts)
	for wall: Dictionary in facts.walls: _build_wall(wall)
	for room: Dictionary in facts.rooms: _build_room(room)
	for item: Dictionary in facts.furniture: _build_furniture(item)
	for pad: Dictionary in facts.pads: _build_pad(pad)
	_build_engineering(facts.engineering)
	_flush()
	set_meta("polisa_visual_metrics", {"static_triangles":_triangle_count,"static_mesh_nodes":_batches.size(),"primitive_boxes":_box_count,"showcase_rigs":_showcase_count,"collision_nodes":0,"dynamic_lights":0,"layout_sha256":facts.layout_sha256})

func _rect_center(r: Array) -> Vector2:
	return Vector2((float(r[0])+float(r[2]))*.5,(float(r[1])+float(r[3]))*.5)

func _rect_size(r: Array) -> Vector2:
	return Vector2(float(r[2])-float(r[0]),float(r[3])-float(r[1]))

func _build_structure(facts: Dictionary) -> void:
	for deck: Dictionary in facts.decks:
		var c := _rect_center(deck.rect)
		var s := _rect_size(deck.rect)
		_box(Vector3(s.x,.3,s.y),Vector3(c.x,-.14,c.y),DECK)
		if deck.kind == "bridge":
			_box(Vector3(s.x+.3,.55,s.y),Vector3(c.x,-.6,c.y),HULL)
			for sign_value: float in [-1.0,1.0]:
				var x := c.x+sign_value*(s.x*.5+.15)
				_box(Vector3(.13,.12,s.y),Vector3(x,.8,c.y),YELLOW)
				for z: float in [c.y-s.y*.4,c.y+s.y*.4]: _box(Vector3(.13,.8,.13),Vector3(x,.4,z),STEEL)
	_chamfered_shell(Vector2(68.8,24.8),2.3,-.30,-3.7,Vector2.ZERO,HULL)
	_chamfered_shell(Vector2(53,17),3.3,-3.7,-6.1,Vector2.ZERO,DARK)
	_box(Vector3(78,2.4,6.2),Vector3(0,-4.1,0),DARK)
	for sign_value: float in [-1.0,1.0]:
		for x: float in [-29,-21,-13,-5,5,13,21,29]:
			_box(Vector3(6.2,1.25,.18),Vector3(x,-1.8,sign_value*12.1),INSET)
			_box(Vector3(5.3,.15,.2),Vector3(x,-1.06,sign_value*12.25),STEEL)
			_box(Vector3(.26,2.1,.35),Vector3(x+3.3,-1.5,sign_value*11.9),HULL)
		for x: float in [-26,0,26]:
			_beam(Vector3(x,-4.5,sign_value*7),Vector3(x,-1.4,sign_value*(36 if x==0 else 24)),1.15,DARK)
	# Raised only in paint: the authoritative floor remains y=0.
	_box(Vector3(64,.02,5.2),Vector3(0,.022,0),STEEL)
	_box(Vector3(6.7,.022,23.4),Vector3(0,.023,0),STEEL)
	for sign_value: float in [-1.0,1.0]:
		_box(Vector3(60,.015,.12),Vector3(0,.045,sign_value*2.8),YELLOW)
		_box(Vector3(.12,.015,23),Vector3(sign_value*3.65,.045,0),YELLOW)
	_label("POLISA",Vector3(0,.045,0),.09,true,false)
	_label("HANDEL / TRANSIT",Vector3(0,.045,2),.027,true,false)

func _build_wall(w: Dictionary) -> void:
	var c := _rect_center(w.rect)
	var s := _rect_size(w.rect)
	var h := float(w.height)
	if bool(w.get("window",false)):
		_box(Vector3(s.x,.42,s.y),Vector3(c.x,.22,c.y),HULL)
		_box(Vector3(s.x,.66,s.y*.35),Vector3(c.x,.76,c.y),GLASS)
		_box(Vector3(s.x,.12,s.y),Vector3(c.x,1.15,c.y),STEEL)
		var count := maxi(1,ceili(s.x/3.2))
		for n in range(count+1):
			_box(Vector3(.12,1.15,s.y),Vector3(c.x-s.x*.5+s.x*float(n)/count,.59,c.y),HULL)
	else:
		_box(Vector3(s.x,h,s.y),Vector3(c.x,h*.5+.01,c.y),HULL)
		if s.x>s.y:
			_box(Vector3(maxf(.1,s.x-.5),h*.58,.035),Vector3(c.x,h*.51,c.y+.37),INSET)
		_box(Vector3(s.x+.08,.15,s.y+.08),Vector3(c.x,h+.03,c.y),STEEL)

func _build_room(room: Dictionary) -> void:
	var r: Array = room.rect
	var c := _rect_center(r)
	var s := _rect_size(r)
	var accent := CYAN if room.accent=="cyan" else YELLOW
	var side := signf(float(room.outer_z))
	_box(Vector3(s.x-.65,.018,s.y-.4),Vector3(c.x,.022,c.y),INSET)
	# Rear canopy gives the room a roof edge without concealing its interior.
	_box(Vector3(s.x+.6,.3,1.25),Vector3(c.x,3.4,float(room.outer_z)-side*.15),HULL)
	_box(Vector3(s.x-.2,.1,.14),Vector3(c.x,3.21,float(room.outer_z)-side*.85),CYAN)
	var door_x := float(room.door_x)
	for offset: float in [-2.05,2.05]:
		_box(Vector3(.24,2.85,.65),Vector3(door_x+offset,1.43,float(room.inner_z)),DARK)
		_box(Vector3(.10,1.7,.68),Vector3(door_x+offset,1.5,float(room.inner_z)),accent)
	_box(Vector3(4.35,.5,.67),Vector3(door_x,3.0,float(room.inner_z)),DARK)
	_label(String(room.title),Vector3(door_x,3.03,float(room.inner_z)-side*.55),.015,false,true)
	_box(Vector3(3.8,.015,1.0),Vector3(door_x,.045,float(room.inner_z)),accent)
	# Flat room identification remains below the actual hex overlay.
	_label(String(room.title),Vector3(c.x,.045,c.y),.025,true,false)

func _build_furniture(item: Dictionary) -> void:
	var c := _rect_center(item.rect)
	var s := _rect_size(item.rect)
	var h := float(item.height)
	var accent := CYAN if item.accent=="cyan" else YELLOW
	_box(Vector3(s.x,h,s.y),Vector3(c.x,h*.5+.01,c.y),DARK)
	_box(Vector3(s.x+.08,.10,s.y+.08),Vector3(c.x,h+.02,c.y),HULL)
	if item.kind=="counter":
		_box(Vector3(s.x-.35,.35,s.y+.015),Vector3(c.x,.49,c.y),STEEL)
		_box(Vector3(1.12,.5,.12),Vector3(c.x+.7,h+.32,c.y),DARK)
		_box(Vector3(.94,.34,.13),Vector3(c.x+.7,h+.35,c.y+.04),accent)
		_box(Vector3(.55,.18,.45),Vector3(c.x-1.1,h+.18,c.y),STEEL)
	elif item.kind=="goods":
		# Actual visible shelf goods, placed wholly in their shared blocker footprint.
		for y: float in [.5,1.2,1.8]:
			_box(Vector3(s.x,.1,s.y),Vector3(c.x,y,c.y),STEEL)
			for n in range(3):
				var x := c.x+(float(n)-1.0)*s.x*.28
				_box(Vector3(s.x*.19,.37,s.y*.62),Vector3(x,y+.23,c.y),accent if n==1 else HULL)
				_box(Vector3(s.x*.14,.08,.02),Vector3(x,y+.25,c.y+s.y*.33),DARK)
	elif item.kind=="armor":
		_box(Vector3(s.x-.2,.04,s.y-.2),Vector3(c.x,h+.095,c.y),accent)
		_box(Vector3(s.x,2.6,.15),Vector3(c.x,1.6,c.y-s.y*.48),INSET)
		for sign_value: float in [-1.0,1.0]:
			_box(Vector3(.08,2.7,.12),Vector3(c.x+sign_value*(s.x*.5-.1),1.6,c.y-s.y*.46),CYAN)
		var model: Node3D=PERSON.instantiate()
		model.name="Showcase_"+String(item.armor)
		model.position=Vector3(c.x,h+.13,c.y)
		model.scale=Vector3.ONE*.98
		add_child(model)
		ARMOR.apply_to_model(model,String(item.armor))
		for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):
			player.play("idle");player.advance(0);player.pause()
		model.process_mode=Node.PROCESS_MODE_DISABLED
		_showcase_count+=1
		_label({"light":"LEICHT","medium":"MITTEL","heavy":"SCHWER"}[String(item.armor)],Vector3(c.x,2.92,c.y-.25),.021,false,true)
	elif item.kind=="bench":
		_box(Vector3(s.x,.7,.22),Vector3(c.x,.88,c.y-s.y*.35),STEEL)

func _build_pad(pad: Dictionary) -> void:
	var c := Vector2(float(pad.center[0]),float(pad.center[1]))
	var s := Vector2(float(pad.size[0]),float(pad.size[1]))
	_chamfered_shell(s+Vector2(.6,.6),1.0,-.30,-1.65,c,HULL)
	for sign_value: float in [-1.0,1.0]:
		_box(Vector3(s.x-1,.015,.16),Vector3(c.x,.045,c.y+sign_value*(s.y*.5-.65)),YELLOW)
		_box(Vector3(.16,.015,s.y-1),Vector3(c.x+sign_value*(s.x*.5-.65),.045,c.y),YELLOW)
		for other: float in [-1.0,1.0]:
			_box(Vector3(.6,.13,.6),Vector3(c.x+sign_value*(s.x*.5-.2),.07,c.y+other*(s.y*.5-.2)),CYAN)
		_box(Vector3(.18,.015,s.y*.5),Vector3(c.x+sign_value*(s.x*.25),.045,c.y),HULL)
		for n in range(5):
			_box(Vector3(.55,.014,.18),Vector3(c.x+(float(n)-2)*1.4,.045,c.y+sign_value*s.y*.25),HULL)
		# External equipment stays entirely outside the pad and the reserved envelope.
		var x := c.x+sign_value*(s.x*.5+1.1)
		_box(Vector3(1.6,.5,s.y*.55),Vector3(x,-.55,c.y),DARK)
		for z: float in [-s.y*.2,0,s.y*.2]:
			_box(Vector3(1.4,.45,2.1),Vector3(x,-.10,c.y+z),STEEL)
			_box(Vector3(1.45,.1,2.15),Vector3(x,.18,c.y+z),YELLOW)
	_label(String(pad.number)+" / "+String(pad["class"]),Vector3(c.x,.045,c.y),.105,true,false)
	_label("POLISA  /  DOCK",Vector3(c.x,.045,c.y+s.y*.5-1.5),.035,true,false)

func _build_engineering(spec: Dictionary) -> void:
	for x_value in spec.ring_x:
		var x := float(x_value)
		var c := Vector3(x,float(spec.ring_center_y),0)
		_ring(c,12,10.8,1.6,48)
		_ring(c,10.55,10.15,1.9,48,DARK)
		_cylinder(2.3,2.3,4.5,c,DARK,12,Vector3(0,0,PI*.5))
		_cylinder(2.55,2.55,.6,c+Vector3(signf(x)*2.1,0,0),HULL,12,Vector3(0,0,PI*.5))
		for index in range(6):
			var angle := TAU*float(index)/6
			_beam(c,c+Vector3(0,cos(angle)*10.4,sin(angle)*10.4),.6,STEEL)
			_box(Vector3(2.0,.6,1.15),c+Vector3(0,cos(angle)*11.4,sin(angle)*11.4),DARK)
		_beam(Vector3(signf(x)*31,-3.7,0),c,1.8,DARK)
		_beam(c,Vector3(signf(x)*58,-4,0),1.3,DARK)
	for x_value in spec.solar_x:
		var x := float(x_value)
		for z_value in spec.solar_z:
			var z := float(z_value)
			_beam(Vector3(x,-4,0),Vector3(x,-1.3,z),.7,STEEL)
			_box(Vector3(11.5,.4,18),Vector3(x,-1.2,z),DARK)
			for col in range(3):
				for row in range(5):
					var c := Vector3(x+(float(col)-1)*3.6,-.96,z+(float(row)-2)*3.45)
					_box(Vector3(3.35,.08,3.2),c,SOLAR)
					_box(Vector3(.07,.025,3.2),c+Vector3(0,.054,0),STEEL)
					_box(Vector3(3.35,.025,.06),c+Vector3(0,.054,0),STEEL)

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
		if color==GLASS:
			material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a=.38
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
	label.no_depth_test = not floor_label
	if floor_label: label.rotation_degrees.x=-90
	elif billboard: label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
