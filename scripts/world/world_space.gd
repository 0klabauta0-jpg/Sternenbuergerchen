extends RefCounted
## Fixed X/Z space staging; no motion, damage or encounter decisions here.
const Catalog=preload("res://scripts/core/catalog.gd")
const Geo = preload("res://scripts/world/world_geometry.gd")

static func build(parent: Node3D, region: String) -> void:
	if region == "station":
		Geo.box(parent,Vector3(0,-1.6,0),Vector3(106,3.1,100),Color("344d59"),0.5)
		Geo.box(parent,Vector3(0,-0.03,0),Vector3(102,0.12,96),Color("566d78"),0.35)
		Geo.collider(parent,"ground","ground",Vector3(160,0.2,160),Vector3(0,-0.2,0))
		for x in [-49.0,49.0]:
			Geo.box(parent,Vector3(x,0.07,0),Vector3(0.2,0.16,95),Color("79c4bc"))
		for z in [-45.0,45.0]:
			Geo.box(parent,Vector3(0,0.07,z),Vector3(98,0.16,0.2),Color("79c4bc"))
		for x in [-63.0,63.0]:
			Geo.box(parent,Vector3(x,-2,-4),Vector3(25,3,19),Color("3f5868"),0.4)
			Geo.box(parent,Vector3(x,-1.8,-24),Vector3(21,0.3,16),Color("396473"),0.5)
			Geo.box(parent,Vector3(x,-1.8,19),Vector3(21,0.3,16),Color("396473"),0.5)
	else:
		# Faint navigation lattice gives planar point-and-click a stable reference.
		var half:=int(Catalog.bounds(region))
		for axis in range(-half,half+1,80):
			Geo.box(parent,Vector3(axis,-0.25,0),Vector3(0.06,0.025,half*2),Color("172c3b"))
			Geo.box(parent,Vector3(0,-0.25,axis),Vector3(half*2,0.025,0.06),Color("172c3b"))
		Geo.collider(parent,"ground","ground",Vector3(half*2,0.2,half*2),Vector3(0,-0.4,0))
	_planet(parent,region)
	if region=="orbit":
		Geo.label(parent,"ROSTWELT / ORBIT",Vector3(0,0,-18),Color("80a2b2"),24)
	var rng := RandomNumberGenerator.new()
	rng.seed=552
	var batch := MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	var star := SphereMesh.new()
	star.radius=0.45
	star.height=0.9
	star.radial_segments=6
	star.rings=3
	batch.mesh=star
	batch.instance_count=260
	for i in range(260):
		batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(rng.randf_range(-580,580),rng.randf_range(-95,-30),rng.randf_range(-620,560))))
	var stars := MultiMeshInstance3D.new()
	stars.multimesh=batch
	stars.material_override=Geo.material(Color("879eac"),0,0.65)
	stars.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(stars)

static func _planet(parent: Node3D, region: String) -> void:
	var planet := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius=90
	sphere.height=180
	sphere.radial_segments=32
	sphere.rings=16
	planet.mesh=sphere
	planet.material_override=Geo.material(Color("9b6952"))
	parent.add_child(planet)
	planet.position=Vector3(-150,-145,-140) if region=="station" else Vector3(-165,-135,-70) if region=="orbit" else Vector3(-270,-175,-310)

static func beam(parent: Node3D, from: Vector3, to: Vector3, color: Color) -> MeshInstance3D:
	var line := Geo.box(parent,(from+to)/2,Vector3(0.28,0.28,maxf(from.distance_to(to),0.01)),color)
	var direction:=to-from
	if direction.length_squared()>0.000001:
		var up:=Vector3.RIGHT if absf(direction.normalized().dot(Vector3.UP))>0.98 else Vector3.UP
		line.look_at(to,up)
	line.material_override=Geo.material(color,0,1.4)
	line.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return line
