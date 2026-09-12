extends RefCounted
## Authored composition plus deterministic geological dressing on an open plane.
const Geo = preload("res://scripts/world/world_geometry.gd")

static func build(parent: Node3D, region: String) -> void:
	if region == "station":
		_station(parent)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 812 if region == "base" else 901
	_ground(parent, rng)
	if region == "base":
		# Keep the complete crew/workshop/shuttle route open. Rocks form the horizon.
		for data in [Vector4(-10,14,8,6),Vector4(-7,-20,10,8),Vector4(19,-10,8,10)]:
			_mesa(parent,Vector2(data.x,data.y),data.z,data.w,rng)
		for data in [Vector4(-30,-24,15,15), Vector4(-13,-32,11,19), Vector4(6,-37,15,13), Vector4(26,-31,12,17), Vector4(45,-19,15,21), Vector4(-40,5,15,12), Vector4(-28,24,12,9), Vector4(35,30,14,10), Vector4(52,9,10,9)]:
			_mesa(parent, Vector2(data.x,data.y), data.z, data.w, rng)
		for data in [Vector4(-62,-65,27,24), Vector4(-20,-76,24,33), Vector4(25,-73,23,27), Vector4(65,-55,23,30), Vector4(-66,30,19,22)]:
			_mesa(parent, Vector2(data.x,data.y), data.z, data.w, rng, true)
		_trail(parent,Vector2(12,14),Vector2(5,30))
	else:
		for data in [Vector4(12,-33,9,8),Vector4(47,-18,9,11),Vector4(20,8,9,5),Vector4(-64,21,10,8),Vector4(-40,8,9,7)]:
			_mesa(parent,Vector2(data.x,data.y),data.z,data.w,rng)
		for data in [Vector4(-75,-25,19,19), Vector4(-28,-57,23,26), Vector4(19,-62,17,22), Vector4(66,-35,24,27), Vector4(75,20,22,23), Vector4(20,65,20,13), Vector4(-63,63,19,18), Vector4(-90,20,19,25)]:
			_mesa(parent, Vector2(data.x,data.y), data.z, data.w, rng)
		for data in [Vector4(-115,-95,35,36), Vector4(-43,-108,28,41), Vector4(43,-105,40,33), Vector4(115,-76,28,42)]:
			_mesa(parent, Vector2(data.x,data.y), data.z, data.w, rng, true)
		# The old impact scar is a shallow visual stain, not a blocking crater.
		var scar := Geo.cylinder(parent, Vector3(24,0.012,-15), 11.0, 0.025, Color("79513f"), 11)
		scar.scale.z = 0.62
		_trail(parent,Vector2(-40,28),Vector2(12,-8))
	for i in range(95):
		var point := Vector2(rng.randf_range(-95,95), rng.randf_range(-95,95))
		if (region == "base" and point.length() < 25) or (region == "rust" and _near_route(point)):
			continue
		var size := rng.randf_range(0.3,1.35)
		var rock := Geo.cylinder(parent, Vector3(point.x,size*0.3,point.y), size, size*0.6, Color("bd8861"), 5)
		rock.rotation.y = rng.randf_range(0,TAU)
		rock.scale.z = rng.randf_range(0.6,1.1)
		# A compact dark foot keeps every small rock firmly grounded.
		Geo.cylinder(parent, Vector3(point.x,0.016,point.y), size*1.08,0.025,Color("93644c"),6)

static func _near_route(point: Vector2) -> bool:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, Vector2(-45,32), Vector2(22,-15))) < 12

static func _trail(parent: Node3D, from: Vector2, to: Vector2) -> void:
	var direction := (to-from).normalized()
	var normal := Vector2(-direction.y,direction.x)
	var length := from.distance_to(to)
	for i in range(int(length/3.0)):
		for side in [-0.7,0.7]:
			var at: Vector2 = from+direction*(i*3.0)+normal*side
			var rut := Geo.box(parent,Vector3(at.x,0.025,at.y),Vector3(0.14,0.018,2.7),Color("a57050"))
			rut.rotation.y = atan2(direction.x,direction.y)

static func _ground(parent: Node3D, rng: RandomNumberGenerator) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sand := Color("98694f")
	for z in range(-160,160,8):
		for x in range(-160,160,8):
			var tint := sand.lightened(rng.randf_range(-0.012,0.012))
			for v in [Vector3(x,0,z),Vector3(x+8,0,z),Vector3(x,0,z+8),Vector3(x+8,0,z),Vector3(x+8,0,z+8),Vector3(x,0,z+8)]:
				st.set_color(tint)
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	var mat := Geo.material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = mat
	parent.add_child(node)
	Geo.collider(parent,"ground","ground",Vector3(320,0.2,320),Vector3(0,-0.2,0))

static func _mesa(parent: Node3D, point: Vector2, radius: float, height: float, rng: RandomNumberGenerator, distant: bool = false) -> void:
	var count := 9
	var angles: Array[float] = []
	var jitter: Array[float] = []
	for i in range(count):
		angles.append(TAU * i / count + rng.randf_range(-0.09,0.09))
		jitter.append(rng.randf_range(0.83,1.12))
	var scales := [1.0,1.04,0.86,0.9,0.77,0.79,0.61,0.60]
	var heights := [0.0,0.10,0.27,0.32,0.53,0.58,0.95,1.0]
	var colors := [Color("885643"),Color("ae7355"),Color("ce9366"),Color("a66b50"),Color("c28a61"),Color("a56d55"),Color("daa979")]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in range(scales.size()-1):
		var color: Color = colors[layer]
		if distant:
			color = color.lerp(Color("7a9298"),0.27)
		for i in range(count):
			var j := (i+1)%count
			var a := _vertex(angles[i],jitter[i],radius*scales[layer],height*heights[layer],point)
			var b := _vertex(angles[j],jitter[j],radius*scales[layer],height*heights[layer],point)
			var c := _vertex(angles[i],jitter[i],radius*scales[layer+1],height*heights[layer+1],point)
			var d := _vertex(angles[j],jitter[j],radius*scales[layer+1],height*heights[layer+1],point)
			for vertex in [a,b,c,b,d,c]:
				st.set_color(color.lightened(0.035 * sin(angles[i]*2)))
				st.add_vertex(vertex)
	for i in range(count):
		for vertex in [Vector3(point.x,height,point.y),_vertex(angles[i],jitter[i],radius*0.6,height,point),_vertex(angles[(i+1)%count],jitter[(i+1)%count],radius*0.6,height,point)]:
			st.set_color(Color("d3a273") if not distant else Color("a49b83"))
			st.add_vertex(vertex)
	st.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	var mat := Geo.material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = mat
	parent.add_child(instance)

static func _vertex(angle: float, jitter: float, radius: float, y: float, point: Vector2) -> Vector3:
	return Vector3(point.x+cos(angle)*radius*jitter,y,point.y+sin(angle)*radius*jitter*0.72)

static func _station(parent: Node3D) -> void:
	Geo.box(parent,Vector3(0,-0.8,0),Vector3(36,1.6,35),Color("344d59"),0.5)
	Geo.box(parent,Vector3(0,-0.03,0),Vector3(33,0.12,32),Color("637983"),0.4)
	Geo.collider(parent,"ground","ground",Vector3(36,0.2,35),Vector3(0,-0.2,0))
	for x in [-16.0,16.0]:
		Geo.box(parent,Vector3(x,0.05,0),Vector3(0.16,0.12,32),Color("72b9ba"))
	for z in [-15.5,15.5]:
		Geo.box(parent,Vector3(0,0.1,z),Vector3(32,0.2,0.22),Color("82bab9"))
	for x in [-14.0,14.0]:
		for z in [-12.0,-5.0,2.0,9.0]:
			Geo.box(parent,Vector3(x,1.0,z),Vector3(0.2,2.0,0.2),Color("314451"))
	# Remote structures and a planet sell the orbit without a menu backdrop.
	for x in [-70.0,55.0]:
		Geo.box(parent,Vector3(x,-12,-55),Vector3(8,13,30),Color("344858"))
		Geo.box(parent,Vector3(x,-5,-55),Vector3(30,0.5,20),Color("437582"))
	var planet := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 57
	sphere.height = 114
	planet.mesh = sphere
	planet.material_override = Geo.material(Color("bc8e69"))
	parent.add_child(planet)
	planet.position = Vector3(-110,-40,-130)
