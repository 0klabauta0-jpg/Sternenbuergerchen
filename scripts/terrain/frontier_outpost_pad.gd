extends Node3D
## Authored visual-only outpost deck; the fixture owns the returned reservation.
const DECK_HEIGHT := 0.16
var footprint := Rect2()
var _materials: Dictionary = {}

func use_ground_painted_shadows() -> void:
	# The B/C producer flattens this pad into ground paint. Native caster/inset
	# A/B proves its thin layers cause self-shadow bands, not a depth conflict.
	# Keep receiving shadows from actual ships/buildings/terrain.
	for child in get_children():
		if child is MeshInstance3D:child.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func build(center: Vector2, size: Vector2, designation: String, access_side: float = 1.0) -> Rect2:
	position = Vector3(center.x,0.0,center.y)
	footprint = Rect2(center-size*0.5,size)
	var half := size*0.5
	_deck(size,0.10,0.025,"515c58")
	_deck(size-Vector2.ONE*0.08,0.035,DECK_HEIGHT-0.035,"737c73")
	# Inset fields and long joints read as a manufactured deck, without a toy H.
	_box("InsetDeck",Vector3(size.x-0.65,0.003,size.y-0.65),Vector3(0.0,DECK_HEIGHT+0.003,0.0),"626c65")
	for x in [-half.x*0.40,half.x*0.40]:
		_box("DeckJoint",Vector3(0.015,0.002,size.y-0.8),Vector3(x,DECK_HEIGHT+0.006,0.0),"4e5953")
	for z in [-half.y*0.48,half.y*0.48]:
		_box("DeckJoint",Vector3(size.x-0.8,0.002,0.015),Vector3(0.0,DECK_HEIGHT+0.006,z),"4e5953")
	# Four broad broken landing brackets and pale perimeter corner marks.
	for sx in [-1.0,1.0]:
		for sz in [-1.0,1.0]:
			var x: float = sx*(half.x-0.64)
			var z: float = sz*(half.y-0.64)
			_box("LandingBracket",Vector3(0.62,0.003,0.045),Vector3(x-sx*0.28,DECK_HEIGHT+0.010,z),"d8ae62")
			_box("LandingBracket",Vector3(0.045,0.003,0.56),Vector3(x,DECK_HEIGHT+0.010,z-sz*0.25),"d8ae62")
			_box("EdgeMark",Vector3(0.40,0.004,0.025),Vector3(sx*(half.x-0.57),DECK_HEIGHT+0.006,sz*(half.y-0.20)),"c7c8ad")
			_box("EdgeBeaconHousing",Vector3(0.12,0.08,0.18),Vector3(sx*(half.x-0.28),DECK_HEIGHT+0.01,sz*(half.y-0.28)),"46544d")
			_box("InsetBeacon",Vector3(0.055,0.014,0.11),Vector3(sx*(half.x-0.28),DECK_HEIGHT+0.057,sz*(half.y-0.28)),"d8e9d5")
	# Small asymmetrical service plates and restrained weathered panel variation.
	_box("AccessPlate",Vector3(0.38,0.008,0.29),Vector3(-half.x+0.57,DECK_HEIGHT+0.006,0.28),"879084")
	_box("ServiceSlot",Vector3(0.18,0.003,0.018),Vector3(-half.x+0.57,DECK_HEIGHT+0.012,0.28),"48564e")
	_box("DustPanel",Vector3(size.x*0.21,0.002,0.34),Vector3(0.2,DECK_HEIGHT+0.009,half.y-0.51),"7c8171")
	# East-side low wedge, as on the rectangular pads in the Thedus reference.
	_ramp(half.x,0.96,0.90,access_side)
	var label := Label3D.new()
	label.name = "PadDesignation"
	label.text = designation
	label.font_size = 64
	label.pixel_size = 0.004
	label.modulate = Color("c7c8ad")
	label.outline_size = 0
	label.rotation_degrees.x = -90.0
	label.position = Vector3(half.x-0.56,DECK_HEIGHT+0.018,-0.15)
	add_child(label)
	return Rect2(footprint.position-Vector2(0.96 if access_side<0.0 else 0.0,0.0),footprint.size+Vector2(0.96,0.0))

func _deck(size: Vector2, height: float, bottom: float, color: String) -> void:
	var x := size.x*0.5
	var z := size.y*0.5
	var c := 0.42
	var outline := PackedVector2Array([Vector2(-x+c,-z),Vector2(x-c,-z),Vector2(x,-z+c),Vector2(x,z-c),Vector2(x-c,z),Vector2(-x+c,z),Vector2(-x,z-c),Vector2(-x,-z+c)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in range(outline.size()):
		var a := outline[i]
		var b := outline[(i+1)%outline.size()]
		for v in [Vector3(0.0,bottom+height,0.0),Vector3(a.x,bottom+height,a.y),Vector3(b.x,bottom+height,b.y),Vector3(a.x,bottom,a.y),Vector3(b.x,bottom+height,b.y),Vector3(a.x,bottom+height,a.y),Vector3(a.x,bottom,a.y),Vector3(b.x,bottom,b.y),Vector3(b.x,bottom+height,b.y)]:
			surface.add_vertex(v)
	_mesh("ChamferedDeck",surface,color)

func _ramp(edge: float, length: float, width: float, side: float) -> void:
	edge *= side
	var a := Vector3(edge-side*0.05,DECK_HEIGHT, -width*0.5)
	var b := Vector3(edge+length*side,0.014,-width*0.5)
	var c := Vector3(edge+length*side,0.014,width*0.5)
	var d := Vector3(edge-side*0.05,DECK_HEIGHT,width*0.5)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in ([a,b,c,a,c,d] if side>0.0 else [a,c,b,a,d,c]): surface.add_vertex(v)
	_mesh("AccessRamp",surface,"929889")
	# Both rails follow the actual ramp endpoints, including its deck overlap.
	var span := b-a
	var rail_center := (a+b)*0.5
	var rail_angle := atan2(span.y,absf(span.x))*side
	for z in [-width*0.45,width*0.45]:
		var strip := _box("RampEdge",Vector3(span.length(),0.014,0.035),Vector3(rail_center.x,rail_center.y,z),"c7b879")
		strip.rotation.z = rail_angle

func _mesh(label: String,surface: SurfaceTool,color: String) -> void:
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = surface.commit()
	instance.material_override = _material(color)
	add_child(instance)

func _box(label: String,size: Vector3,center: Vector3,color: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = center
	instance.material_override = _material(color)
	add_child(instance)
	return instance

func _material(color: String) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(color)
		material.roughness = 0.96
		_materials[color] = material
	return _materials[color]
