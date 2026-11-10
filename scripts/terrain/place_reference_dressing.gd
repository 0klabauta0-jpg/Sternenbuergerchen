extends RefCounted
## Reuses the existing reviewed closed exterior family. Cold visual build only.
const SHELL = preload("res://scripts/terrain/frontier_closed_buildings.gd")
const PAD = preload("res://scripts/terrain/frontier_outpost_pad.gd")
static func build(parent: Node3D, presentation: Dictionary) -> Dictionary:
	var root:=Node3D.new(); root.name="PlaceReferenceDressing"; parent.add_child(root)
	var blockers: Array=[]
	for spec: Dictionary in Array(presentation.get("structures",[])):
		var center: Array=spec.get("center",[0,0])
		var dimensions: Array=spec.get("size",[4,1.5,3])
		var size:=Vector3(float(dimensions[0]),float(dimensions[1]),float(dimensions[2]))
		var bounds:=AABB(Vector3(float(center[0])-size.x*.5,0,float(center[1])-size.z*.5),size)
		var shell: Node3D=SHELL.new(); shell.name=String(spec.get("id","Building")); root.add_child(shell)
		shell.call("build",bounds,bool(spec.get("hall",false)))
		var label: Label3D=shell.get_node_or_null("ExteriorIdentification")
		if label!=null: label.text=String(spec.get("name",""))
		blockers.append(mesh_bounds(shell,root))
	for spec: Dictionary in Array(presentation.get("props",[])):
		var path:=String(spec.get("path",""))
		if not ResourceLoader.exists(path): continue
		var scene: PackedScene=load(path)
		var prop: Node3D=scene.instantiate(); root.add_child(prop)
		var position: Array=spec.get("center",[0,0])
		prop.position=Vector3(float(position[0]),0,float(position[1]))
		prop.scale=Vector3.ONE*float(spec.get("scale",1.0))
		blockers.append(mesh_bounds(prop,root))
	for spec: Dictionary in Array(presentation.get("pads",[])):
		var pad: Node3D=PAD.new(); root.add_child(pad)
		var center: Array=spec.get("center",[0,0]); var size: Array=spec.get("size",[5,4])
		pad.call("build",Vector2(float(center[0]),float(center[1])),Vector2(float(size[0]),float(size[1])),String(spec.get("name","PAD")))
		# Ground-painted apron: no raised platform or invented navigation surface.
		pad.scale.y=.1; pad.position.y=.025
	return {"root":root,"blockers":blockers}
static func mesh_bounds(node: Node3D, root: Node3D) -> AABB:
	var bounds:=AABB(); var initialized:=false
	var stack: Array[Node]=[node]
	while not stack.is_empty():
		var current: Node=stack.pop_back()
		if current is MeshInstance3D and current.mesh!=null:
			var box: AABB=current.mesh.get_aabb()
			var transform: Transform3D=root.global_transform.affine_inverse()*current.global_transform
			for corner in range(8):
				var point: Vector3=transform*box.get_endpoint(corner)
				if not initialized: bounds=AABB(point,Vector3.ZERO); initialized=true
				else: bounds=bounds.expand(point)
		for child in current.get_children(): stack.append(child)
	return bounds
