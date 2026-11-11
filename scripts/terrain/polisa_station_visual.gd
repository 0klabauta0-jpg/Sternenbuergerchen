extends Node3D
## Own cold-built station geometry. The saved deck map alone owns movement/LOS.
static var _materials: Dictionary = {}
const DECK := "596c72"
const HULL := "bfc8c3"
const DARK := "243944"
const ACCENT := "d9ac50"
func _ready() -> void:
	if get_child_count() > 0: return
	name = "PolisaStationVisual"
	# One compact concourse, three exterior pads, and narrow connected arms.
	_box(Vector3(18,.20,16),Vector3(0,-.09,0),DECK)
	_box(Vector3(13,.24,10),Vector3(-21.5,-.11,0),DECK)
	_box(Vector3(13,.24,10),Vector3(21.5,-.11,0),DECK)
	_box(Vector3(10,.24,13),Vector3(0,-.11,21.5),DECK)
	_box(Vector3(34,.18,3.2),Vector3(0,-.08,0),DECK)
	_box(Vector3(3.2,.18,14),Vector3(0,-.08,12),DECK)
	for pad in [[Vector2(-21.5,0),Vector2(13,10),"01"],[Vector2(21.5,0),Vector2(13,10),"02"],[Vector2(0,21.5),Vector2(10,13),"03"]]:
		_pad(pad[0],pad[1],String(pad[2]))
	# Open topped walls keep the interior usable from the isometric play camera.
	for x in [-5.5,5.5]:
		for z in [-7.5,7.5]: _box(Vector3(7,.9,.4),Vector3(x,.45,z),HULL)
	for x in [-8.7,8.7]:
		for z in [-4.5,4.5]: _box(Vector3(.4,.9,5),Vector3(x,.45,z),HULL)
	for entrance in [Vector3(-8.7,0,0),Vector3(8.7,0,0),Vector3(0,0,7.5)]:
		var side := Vector3(0,0,1.8) if absf(entrance.x)>1 else Vector3(1.8,0,0)
		for sign_value in [-1,1]:
			_box(Vector3(.38,1.5,.38),entrance+side*sign_value+Vector3(0,.75,0),HULL)
			_box(Vector3(.16,.5,.16),entrance+side*sign_value+Vector3(0,1.0,0),"75c5ca")
	for spec in [[Vector3(-5,.0,-4.7),"HANDWAFFEN"],[Vector3(5,.0,-4.7),"RUESTUNG"],[Vector3(-5,0,4.6),"SCHIFFE"],[Vector3(5,0,4.6),"WAREN"]]:
		var position: Vector3 = spec[0]
		_box(Vector3(3,.78,1.15),position+Vector3(0,.39,0),DARK)
		_box(Vector3(3.1,.09,1.22),position+Vector3(0,.82,0),HULL)
		_label(String(spec[1]),position+Vector3(0,1.35,0),.018)
		for i in range(3): _box(Vector3(.26,.08,.38),position+Vector3(-.75+i*.75,.92,0),ACCENT)
	_cylinder(.65,.8,.8,Vector3(0,.4,0),DARK)
	_box(Vector3(1.35,.1,1.35),Vector3(0,.86,0),HULL)
	_label("POLISA",Vector3(0,2.0,-.8),.04)
	# Olisar-like engineering hoops beneath the accessible deck: visual only.
	for x in [-3.5,3.5]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new(); torus.inner_radius=10.0; torus.outer_radius=10.4; torus.rings=40; torus.ring_segments=6
		ring.mesh=torus; ring.material_override=_material(HULL)
		ring.position=Vector3(x,-9.9,0); ring.rotation_degrees.z=90; add_child(ring)
		_box(Vector3(.65,5.0,1.0),Vector3(x,-2.6,-5.0),DARK)
	for z in [-5.7,5.7]:
		_box(Vector3(20,.45,.7),Vector3(0,-.8,z),DARK)
	for x in [-30.0,30.0]:
		_box(Vector3(2.8,.22,10),Vector3(x,-.6,0),DARK)
		for i in range(5): _box(Vector3(2.55,.025,1.55),Vector3(x,-.47,-4+i*2.0),"385568")
func _pad(center: Vector2,size: Vector2,id: String) -> void:
	for sign_value in [-1,1]:
		_box(Vector3(size.x-.5,.025,.13),Vector3(center.x,.025,center.y+sign_value*(size.y*.5-.45)),ACCENT)
		_box(Vector3(.13,.025,size.y-.5),Vector3(center.x+sign_value*(size.x*.5-.45),.025,center.y),ACCENT)
		for edge in [-1,1]: _box(Vector3(.3,.08,.3),Vector3(center.x+sign_value*(size.x*.5-.2),.05,center.y+edge*(size.y*.5-.2)),"74c6cc")
	_label("POLISA / "+id,Vector3(center.x,.055,center.y+size.y*.5-1.0),.035,true)
func _label(text: String,position: Vector3,pixel_size: float,floor_label: bool=false) -> void:
	var label := Label3D.new(); label.text=text; label.position=position; label.pixel_size=pixel_size; label.font_size=36; label.modulate=Color(HULL)
	if floor_label: label.rotation_degrees.x=-90
	else: label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
func _box(size: Vector3,position: Vector3,color: String) -> void:
	var mesh := BoxMesh.new(); mesh.size=size
	var part := MeshInstance3D.new(); part.mesh=mesh; part.position=position; part.material_override=_material(color); add_child(part)
func _cylinder(top: float,bottom: float,height: float,position: Vector3,color: String) -> void:
	var mesh := CylinderMesh.new(); mesh.top_radius=top; mesh.bottom_radius=bottom; mesh.height=height; mesh.radial_segments=12
	var part := MeshInstance3D.new(); part.mesh=mesh; part.position=position; part.material_override=_material(color); add_child(part)
static func _material(color: String) -> Material:
	if not _materials.has(color):
		var material := StandardMaterial3D.new(); material.albedo_color=Color(color); material.roughness=.84
		_materials[color]=material
	return _materials[color]
