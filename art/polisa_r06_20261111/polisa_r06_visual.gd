extends Node3D
## Authored layout projection only. Static batches; no runtime truth or collisions.
const FACTS = "res://art/polisa_r06_20261111/layout_compiled.json"
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
const HOLO := "3c9ecc"
var _batches: Dictionary = {}
var _materials: Dictionary = {}
var _triangle_count := 0
var _box_count := 0
var _showcase_count := 0
var _showcase_sources: Dictionary = {}
var _showcase_copies: Array[Dictionary] = []

func _ready() -> void:
	if get_child_count()>0:return
	name="PolisaR06Visual"
	var facts:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FACTS))
	_build_structure(facts)
	set_meta("station_deck_owns_flat_ground",true) # Live, successfully built deck; root view owns cap/raster policy.
	for wall:Dictionary in facts.walls:_build_wall(wall)
	for room:Dictionary in facts.rooms:_build_room(room)
	for item:Dictionary in facts.furniture:_build_furniture(item)
	for pad:Dictionary in facts.pads:_build_pad(pad)
	_build_engineering(facts.engineering)
	for module:Dictionary in facts.technical_modules:_build_technical_module(module)
	call_deferred("_build_static_showcase_copies")
	_build_space_extent(facts)
	_flush()
	set_meta("polisa_visual_metrics",{"static_triangles":_triangle_count,"static_mesh_nodes":_batches.size(),"primitive_boxes":_box_count,"showcase_rigs":_showcase_count,"collision_nodes":0,"dynamic_lights":0,"layout_sha256":facts.layout_sha256})

func _rect_center(r:Array)->Vector2:
	return Vector2((float(r[0])+float(r[2]))*.5,(float(r[1])+float(r[3]))*.5)

func _rect_size(r:Array)->Vector2:
	return Vector2(float(r[2])-float(r[0]),float(r[3])-float(r[1]))

func _build_structure(facts:Dictionary)->void:
	for deck:Dictionary in facts.decks:
		var c:=_rect_center(deck.rect)
		var s:=_rect_size(deck.rect)
		_box(Vector3(s.x,.3,s.y),Vector3(c.x,-.14,c.y),INSET if deck.kind=="technical_zone" else DECK)
		if deck.kind in ["hub","room","technical_zone"]:
			_chamfered_shell(s+Vector2(.5,.5),1.8,-.3,-6.0,c,HULL)
		elif deck.kind=="bridge":
			_chamfered_shell(s+Vector2(.5,.5),1.1,-.3,-3.0,c,HULL)
	_box(Vector3(260,8,10),Vector3(0,-11,46),DARK)
	_box(Vector3(260,2.2,12),Vector3(0,-7.5,46),STEEL)
	for sector:Dictionary in facts.sectors:
		var x:=float(sector.center_x)
		_chamfered_shell(Vector2(112,72),5,-6,-17,Vector2(x,3),DARK)
		for dx:float in [-100,-60,-20,20,60,100]:
			_beam(Vector3(x+dx,-14,-35),Vector3(x+dx,-6,47),3,HULL)
			_box(Vector3(12,3,1),Vector3(x+dx,-9.5,53),INSET)
			_box(Vector3(8,.35,.15),Vector3(x+dx,-9.2,53.6),CYAN)
		for dx:float in [-80,-46,0,42,66]:
			_beam(Vector3(x+dx,-12,44),Vector3(x+dx,-2,80),2.5,DARK)
		_box(Vector3(65,.02,34),Vector3(x,.025,22),STEEL)
		for side:float in [-1,1]:_box(Vector3(.14,.015,39),Vector3(x+side*34,.045,22),YELLOW)
		for z:float in [43,51]:_box(Vector3(236,.015,.14),Vector3(x,.045,z),YELLOW)
		_label("POLISA",Vector3(x,.055,40),.15,true,false)
		_label("TRANSIT / SERVICES",Vector3(x,.055,37),.035,true,false)
		for dx:float in [-92,-66,-36,36,66,92]:
			_box(Vector3(17,3.5,4),Vector3(x+dx,-4.5,49),HULL)
			_box(Vector3(12,2.4,.35),Vector3(x+dx,-4.5,51.2),INSET)
			_box(Vector3(7,.35,.2),Vector3(x+dx,-4.5,51.5),CYAN)
			_beam(Vector3(x+dx-7,-15,40),Vector3(x+dx+7,-7,40),1.3,STEEL)
		for dx:float in [-28,28]:
			for dz:float in [18,36]:
				_cylinder(2.3,2.3,9,Vector3(x+dx,-13,dz),STEEL,12)
				_cylinder(2.35,2.35,1.2,Vector3(x+dx,-12,dz),YELLOW,12)
		_label("POLISA",Vector3(x,4.1,-28.2),.075,false,true)

func _beveled_ring(center:Vector3,outer:float,inner:float,width:float,segments:int)->void:
	var bevel:=.65
	var profile:Array[Vector2]=[Vector2(-width*.5+bevel,outer),Vector2(width*.5-bevel,outer),Vector2(width*.5,outer-bevel),Vector2(width*.5,inner+bevel),Vector2(width*.5-bevel,inner),Vector2(-width*.5+bevel,inner),Vector2(-width*.5,inner+bevel),Vector2(-width*.5,outer-bevel)]
	for i in range(segments):
		var a:=TAU*i/segments
		var b:=TAU*(i+1)/segments
		for j in range(profile.size()):
			var p:Vector2=profile[j]
			var q:Vector2=profile[(j+1)%profile.size()]
			_quad(center+Vector3(p.x,cos(a)*p.y,sin(a)*p.y),center+Vector3(q.x,cos(a)*q.y,sin(a)*q.y),center+Vector3(q.x,cos(b)*q.y,sin(b)*q.y),center+Vector3(p.x,cos(b)*p.y,sin(b)*p.y),STEEL if j%2 else HULL)

func _build_technical_module(spec:Dictionary)->void:
	var c:=_rect_center(spec.rect)
	var s:=_rect_size(spec.rect)
	var h:=float(spec.height)
	_chamfered_shell(s,2,h,.0,c,DARK)
	_box(Vector3(s.x-2,1,s.y-2),Vector3(c.x,h-.3,c.y),HULL)
	if spec.kind=="tank":
		for dx:float in [-s.x*.27,0,s.x*.27]:
			_cylinder(3.2,3.2,h-1,Vector3(c.x+dx,h*.5,c.y),STEEL,12)
			_cylinder(3.3,3.3,.8,Vector3(c.x+dx,h*.7,c.y),YELLOW,12)
	elif spec.kind=="reactor":
		_cylinder(6,7,3,Vector3(c.x,h+1.3,c.y),STEEL,12)
		_cylinder(4.7,4.7,.15,Vector3(c.x,h+2.9,c.y),DARK,12)
		for j in range(5):_box(Vector3(8,.14,.35),Vector3(c.x,h+3,c.y+(j-2)*1.4),CYAN)
	else:
		for j in range(5):
			_box(Vector3(s.x-5,.5,s.y*.15),Vector3(c.x,h+.6,c.y+(j-2)*s.y*.18),INSET)
	for side:float in [-1,1]:
		_box(Vector3(.9,h*.8,s.y*.7),Vector3(c.x+side*s.x*.5,h*.45,c.y),STEEL)
		_box(Vector3(5,.8,.15),Vector3(c.x+side*s.x*.28,h*.6,c.y+s.y*.5+.1),YELLOW)

func _build_wall(w:Dictionary)->void:
	var c:=_rect_center(w.rect)
	var s:=_rect_size(w.rect)
	var h:=float(w.height)
	if bool(w.get("window",false)):
		_box(Vector3(s.x,h*.38,s.y),Vector3(c.x,h*.19+.01,c.y),HULL)
		_box(Vector3(s.x,h*.48,s.y*.6),Vector3(c.x,h*.63,c.y),GLASS)
		_box(Vector3(s.x,.10,s.y),Vector3(c.x,h-.02,c.y),STEEL)
	else:
		_box(Vector3(s.x,h,s.y),Vector3(c.x,h*.5+.01,c.y),HULL)
		if s.x>s.y:
			_box(Vector3(maxf(.1,s.x-.5),h*.58,.04),Vector3(c.x,h*.52,c.y+.42),INSET)
		_box(Vector3(s.x+.08,.12,s.y+.08),Vector3(c.x,h+.03,c.y),STEEL)

func _build_room(room:Dictionary)->void:
	var c:=_rect_center(room.rect)
	var s:=_rect_size(room.rect)
	var accent:=YELLOW if room.accent=="yellow" else CYAN
	_box(Vector3(s.x-.8,.018,s.y-.8),Vector3(c.x,.029,c.y),INSET)
	# Back lintel only: all contents are visible from the single front camera.
	if room.door_side=="front":
		_box(Vector3(s.x+.4,.3,1.1),Vector3(c.x,3.48,float(room.rect[1])),HULL)
		_box(Vector3(s.x-.3,.10,.12),Vector3(c.x,3.28,float(room.rect[1])+.65),CYAN)
	var d:=Vector2(float(room.door[0]),float(room.door[1]))
	var transverse:=Vector2.RIGHT if room.door_side=="front" else Vector2(0,1)
	for sign_value:float in [-1,1]:
		var p:=d+transverse*sign_value*2.75
		_box(Vector3(.23,1.5,.23),Vector3(p.x,.76,p.y),DARK)
		_box(Vector3(.13,1.1,.25),Vector3(p.x,.84,p.y),accent)
	var threshold:=Vector3(5.2,.015,1.0) if room.door_side=="front" else Vector3(1,.015,5.2)
	_box(threshold,Vector3(d.x,.045,d.y),accent)
	_label(String(room.title),Vector3(c.x,.055,c.y+7.5),.048,true,false)
	# Small upright title at rear, never a front billboard wall.
	_label(String(room.title),Vector3(c.x,2.3,c.y-10.5),.026,false,true)

func _build_globe(item:Dictionary)->void:
	var c:=_rect_center(item.rect)
	_cylinder(2.15,2.2,.65,Vector3(c.x,.335,c.y),DARK,16)
	_cylinder(2.25,2.25,.12,Vector3(c.x,.69,c.y),HULL,16)
	_cylinder(1.45,1.45,.05,Vector3(c.x,.78,c.y),CYAN,20)
	var globe:=SphereMesh.new()
	globe.radius=1.05;globe.height=2.1;globe.radial_segments=24;globe.rings=12
	_append(globe,Vector3(c.x,1.85,c.y),HOLO)
	for angle:float in [0,PI*.5]:
		var band:=TorusMesh.new()
		band.inner_radius=1.055;band.outer_radius=1.08;band.rings=24;band.ring_segments=6
		_append(band,Vector3(c.x,1.85,c.y),CYAN,Vector3(PI*.5,angle,0))
	for index in range(4):
		var a:=TAU*index/4
		_box(Vector3(.55,.35,.45),Vector3(c.x+cos(a)*1.8,.92,c.y+sin(a)*1.8),STEEL)
		_box(Vector3(.42,.025,.30),Vector3(c.x+cos(a)*1.8,1.11,c.y+sin(a)*1.8),CYAN)
	for index in range(64):
		var a:=TAU*index/64
		var b:=TAU*(index+1)/64
		_quad(Vector3(c.x+cos(a)*5.5,.052,c.y+sin(a)*5.5),Vector3(c.x+cos(b)*5.5,.052,c.y+sin(b)*5.5),Vector3(c.x+cos(b)*5.65,.052,c.y+sin(b)*5.65),Vector3(c.x+cos(a)*5.65,.052,c.y+sin(a)*5.65),CYAN)

func _build_engineering(spec:Dictionary)->void:
	var rz:=float(spec.ring_z)
	var radius:=float(spec.ring_radius)
	for x_value in spec.ring_x:
		var x:=float(x_value)
		var c:=Vector3(x,float(spec.ring_center_y),rz)
		# Four shared YZ planes. Never yawed for presentation.
		_beveled_ring(c,radius,radius-5,float(spec.ring_width),80)
		_ring(c,radius-5.2,radius-6.2,float(spec.ring_width)+.6,80,DARK,0)
		_cylinder(6.4,6.4,11,c,DARK,20,Vector3(0,0,PI*.5))
		for side:float in [-1,1]:
			_cylinder(6.8,6.8,1,c+Vector3(side*5.4,0,0),HULL,20,Vector3(0,0,PI*.5))
		# Upward spoke intentionally absent: no crossing of walkable concourse.
		for angle:float in [PI/3,PI*2/3,PI,PI*4/3,PI*5/3]:
			_beam(c,c+Vector3(0,cos(angle)*(radius-5),sin(angle)*(radius-5)),2.2,STEEL)
		for index in range(16):
			var a:=TAU*index/16
			var p:=c+Vector3(0,cos(a)*(radius-2.5),sin(a)*(radius-2.5))
			var panel:=BoxMesh.new()
			panel.size=Vector3(5.7,2.3,5.8)
			_append(panel,p,DARK,Vector3(a,0,0))
			var inset:=BoxMesh.new()
			inset.size=Vector3(5.9,.7,2.5)
			_append(inset,p+Vector3(0,cos(a)*.3,sin(a)*.3),CYAN if index%2==0 else YELLOW,Vector3(a,0,0))
		_beam(Vector3(x,-10,46),c,4,DARK)
	for x_value in spec.solar_x:
		var x:=float(x_value)
		_beam(Vector3(signf(x)*120,-11,46),Vector3(x,-11,46),6,DARK)
		for z_value in spec.solar_z:
			var z:=float(z_value)
			var w:=float(spec.solar_size[0])
			var d:=float(spec.solar_size[1])
			_beam(Vector3(x,-11,46),Vector3(x,-5,z),3,STEEL)
			_box(Vector3(w+1,1.3,d+1),Vector3(x,-5.4,z),DARK)
			for col in range(8):
				for row in range(6):
					var p:=Vector3(x+(col-3.5)*w/8,-4.6,z+(row-2.5)*d/6)
					_box(Vector3(w/8-.5,.15,d/6-.5),p,SOLAR)
					_box(Vector3(.10,.04,d/6-.5),p+Vector3(0,.1,0),STEEL)
	for port:Dictionary in spec.outer_ports:
		var p:=Vector3(float(port.center[0]),-8,float(port.center[1]))
		_beam(Vector3(float(port.arm_from[0]),-11,float(port.arm_from[1])),p,5,DARK)
		_box(Vector3(13,11,15),p,HULL)
		_box(Vector3(8,7,.9),p+Vector3(0,0,8),DARK)
		for sign_value:float in [-1,1]:
			_box(Vector3(2,5,24),p+Vector3(sign_value*7,-1,10),HULL)
			_box(Vector3(1.1,2.5,.5),p+Vector3(sign_value*7,-1,22.2),CYAN)
		_label("PORT / RESERVE",p+Vector3(0,7,0),.055,false,true)

func _build_space_extent(facts:Dictionary)->void:
	# A visual perimeter of declared map extent, not extra navigable tiles.
	var o:=Vector2(float(facts.origin_plane[0]),float(facts.origin_plane[1]))
	var r:Array=facts.space_bounds
	var lo:=Vector2(float(r[0]),float(r[1]))-o
	var hi:=Vector2(float(r[2]),float(r[3]))-o
	for z:float in [lo.y,hi.y]:_box(Vector3(hi.x-lo.x,.03,1.2),Vector3((lo.x+hi.x)*.5,-.25,z),CYAN)
	for x:float in [lo.x,hi.x]:_box(Vector3(1.2,.03,hi.y-lo.y),Vector3(x,-.25,(lo.y+hi.y)*.5),CYAN)
	_label("POLISA ORBIT / 512 x 256",Vector3(0,.02,hi.y+20),.16,true,false)
	for index in range(110):
		var x:=lo.x+4+fposmod(float(index*73),hi.x-lo.x-8)
		var z:=lo.y+4+fposmod(float(index*97),hi.y-lo.y-8)
		var size:=.12 if index%5 else .24
		_box(Vector3(size,.025,size),Vector3(x,-18,z),STEEL)


func _build_furniture(item: Dictionary) -> void:
	if item.kind=="globe":
		_build_globe(item)
		return
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
	elif item.kind=="cargo":
		for x: float in [-1.4,1.4]:
			for z: float in [-1.05,1.05]:
				_box(Vector3(1.25,1.05,1.5),Vector3(c.x+x,h+.6,c.y+z),YELLOW if x<0 else STEEL)
				_box(Vector3(.12,1.1,1.54),Vector3(c.x+x,h+.6,c.y+z),DARK)
				_box(Vector3(1.3,.12,1.54),Vector3(c.x+x,h+1.1,c.y+z),HULL)

	elif item.kind=="armor":
		_box(Vector3(s.x-.2,.04,s.y-.2),Vector3(c.x,h+.095,c.y),accent)
		_box(Vector3(s.x,2.6,.15),Vector3(c.x,1.6,c.y-s.y*.48),INSET)
		for sign_value: float in [-1.0,1.0]:
			_box(Vector3(.08,2.7,.12),Vector3(c.x+sign_value*(s.x*.5-.1),1.6,c.y-s.y*.46),CYAN)
		if String(item.get("sector","B"))!="B":
			_showcase_copies.append({"armor":String(item.armor),"position":Vector3(c.x,h+.13,c.y)})
			_label({"light":"LEICHT","medium":"MITTEL","heavy":"SCHWER"}[String(item.armor)],Vector3(c.x,2.92,c.y-.25),.021,false,true)
			return
		var model: Node3D=PERSON.instantiate()
		model.name="Showcase_"+String(item.armor)
		model.position=Vector3(c.x,h+.13,c.y)
		model.scale=Vector3.ONE*1.0
		add_child(model)
		ARMOR.apply_to_model(model,String(item.armor))
		for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):
			player.play("idle");player.advance(0);player.pause()
		model.process_mode=Node.PROCESS_MODE_DISABLED
		_showcase_count+=1
		_showcase_sources[String(item.armor)]=model
		_label({"light":"LEICHT","medium":"MITTEL","heavy":"SCHWER"}[String(item.armor)],Vector3(c.x,2.92,c.y-.25),.021,false,true)
	elif item.kind=="bench":
		_box(Vector3(s.x,.7,.22),Vector3(c.x,.88,c.y-s.y*.35),STEEL)

func _build_static_showcase_copies()->void:
	if _showcase_copies.is_empty():return
	# Only three original R07 rigs. Six other displays reuse the once-baked idle meshes.
	await get_tree().process_frame
	var baked:Dictionary={}
	for armor:String in _showcase_sources:
		var source:Node3D=_showcase_sources[armor]
		var parts:Array[Dictionary]=[]
		for part:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
			if not part.visible or part.mesh==null:continue
			var mesh:Mesh=part.bake_mesh_from_current_skeleton_pose() if part.skin!=null else part.mesh
			var materials:Array[Material]=[]
			for surface in range(part.mesh.get_surface_count()):materials.append(part.get_active_material(surface))
			parts.append({"mesh":mesh,"transform":source.global_transform.affine_inverse()*part.global_transform,"materials":materials})
		baked[armor]=parts
	for copy:Dictionary in _showcase_copies:
		var holder:=Node3D.new()
		holder.name="Showcase_Static_"+String(copy.armor)+"_"+str(int(Vector3(copy.position).x))
		holder.position=copy.position
		add_child(holder)
		for part:Dictionary in baked[String(copy.armor)]:
			var node:=MeshInstance3D.new()
			node.mesh=part.mesh;node.transform=part.transform
			for index in range(part.materials.size()):node.set_surface_override_material(index,part.materials[index])
			holder.add_child(node)

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


func _ring(center: Vector3,outer: float,inner: float,width: float,segments: int,color: String=HULL,yaw:float=0.0) -> void:
	for i: int in range(segments):
		var a := TAU*float(i)/segments
		var b := TAU*float(i+1)/segments
		var points := PackedVector3Array()
		for axis: float in [-width*.5,width*.5]:
			for radius: float in [outer,inner]:
				for angle: float in [a,b]:
					points.append(center+Basis(Vector3.UP,yaw)*Vector3(axis,cos(angle)*radius,sin(angle)*radius))
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
		if color==CYAN or color==HOLO:
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
