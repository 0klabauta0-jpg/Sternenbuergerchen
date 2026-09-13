extends SceneTree
const Geo=preload("res://scripts/world/world_geometry.gd")
const Landmarks=preload("res://scripts/world/world_landmarks.gd")
const Layout=preload("res://scripts/core/world_layout.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var report: Dictionary={}
	var checks:=0;var failures:=0
	for region in ["base","rust","bunker_surface","bunker_depths","distribution","tradepost"]:
		var map:=Node3D.new();root.add_child(map)
		var objects:=Landmarks.build(map,region,Layout.landmarks(region))
		for id in objects:
			if id=="aa_turret":continue # Enemy geometry has a separate snapshot projection.
			var key:="object_"+str(id)
			if not Layout.obstacles(region).has(key):continue
			var bounds:=_solid_bounds(objects[id],Transform3D.IDENTITY)
			var spec: Dictionary=Layout.obstacles(region)[key]
			var rect:=Rect2(Vector2(spec.center[0],spec.center[1])-Vector2(spec.size[0],spec.size[1])/2,Vector2(spec.size[0],spec.size[1]))
			var model:=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))
			report[region+"/"+str(id)]={"solid_xz":str(model),"nav_xz":str(rect),"contained_with_crew_margin":rect.grow(0.6).encloses(model)}
			checks+=1
			if not rect.grow(0.6).encloses(model):failures+=1;push_error("Footprint outside clearance: "+region+"/"+str(id))
		map.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/n4-world"))
	var file:=FileAccess.open("res://output/n4-world/footprints.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"objects":report},"  "))
	print("FOOTPRINT_CHECKS ",checks," failures ",failures);quit(0 if failures==0 else 1)
func _solid_bounds(node: Node3D,transform: Transform3D) -> AABB:
	var current:=transform*node.transform;var result:=AABB();var valid:=false
	if node is MeshInstance3D and node.visible:
		var mesh:=node as MeshInstance3D
		var mesh_bounds:=current*mesh.get_aabb()
		if mesh_bounds.end.y>0.3 and not mesh.mesh is TorusMesh:
			result=mesh_bounds;valid=true
	for child in node.get_children():
		if child is Node3D and child.visible:
			var bounds:=_solid_bounds(child,current)
			if bounds.size.length_squared()>0:result=result.merge(bounds) if valid else bounds;valid=true
	return result
