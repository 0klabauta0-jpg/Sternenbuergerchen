extends RefCounted
## Reuses the existing reviewed closed exterior family. Cold visual build only.
const SHELL = preload("res://scripts/terrain/frontier_closed_buildings.gd")
const PAD = preload("res://scripts/terrain/frontier_outpost_pad.gd")
## Grafikpass R2 (user decision 14.11.2026): landing pads are low raised
## objects again, not ground paint. Visual height only; the view lifts grid
## lines, units and craft on the covered cells by the same amount. Terrain
## height, walkability and landing rules are unchanged.
const PAD_DECK_TOP := 0.12
static func build(parent: Node3D, presentation: Dictionary) -> Dictionary:
	var root:=Node3D.new(); root.name="PlaceReferenceDressing"; parent.add_child(root)
	var blockers: Array=[]
	for spec: Dictionary in Array(presentation.get("structures",[])):
		var center: Array=spec.get("center",[0,0])
		var dimensions: Array=spec.get("size",[4,1.5,3])
		var size:=Vector3(float(dimensions[0]),float(dimensions[1]),float(dimensions[2]))
		var elevation := float(spec.get("terrain_height_level", 0)) * float(presentation.get("height_step", 0.5))
		var bounds:=AABB(Vector3(float(center[0])-size.x*.5,elevation,float(center[1])-size.z*.5),size)
		# Optional own exterior model (14.11.2026, Freihafen kit): same footprint, front towards +Z.
		var model_path:=String(spec.get("model",""))
		if model_path!="" and ResourceLoader.exists(model_path):
			var model: Node3D=(load(model_path) as PackedScene).instantiate(); model.name=String(spec.get("id","Building")); root.add_child(model)
			model.position=Vector3(float(center[0]),elevation,float(center[1]))
			var sign:=Label3D.new(); sign.name="ExteriorIdentification"; sign.text=String(spec.get("name",""))
			sign.font_size=48; sign.pixel_size=size.x*0.00040; sign.outline_size=0; sign.modulate=Color("3a4a4c")
			sign.position=Vector3(0.0,float(spec.get("sign_height",size.y*0.9)),size.z*0.5+0.02); model.add_child(sign)
			blockers.append(mesh_bounds(model,root))
			continue
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
		prop.position=Vector3(float(position[0]),float(spec.get("elevation",0.0)),float(position[1]))
		prop.scale=Vector3.ONE*float(spec.get("scale",1.0))
		prop.rotation_degrees.y=float(spec.get("rotation_degrees",0.0))
		blockers.append(mesh_bounds(prop,root))
		if String(spec.get("asset",""))=="sat_wreck":
			var smoke: Node3D=load("res://scripts/terrain/wreck_smoke.gd").build("grey",load("res://scripts/terrain/wreck_smoke.gd").load_rules()); if smoke!=null: smoke.position=prop.position+Vector3(0,.4,0); root.add_child(smoke)
	for spec: Dictionary in Array(presentation.get("pads",[])):
		var pad: Node3D=PAD.new(); root.add_child(pad)
		var center: Array=spec.get("center",[0,0]); var size: Array=spec.get("size",[5,4])
		pad.call("build",Vector2(float(center[0]),float(center[1])),Vector2(float(size[0]),float(size[1])),String(spec.get("name","PAD")))
		pad.scale.y=PAD_DECK_TOP/PAD.DECK_HEIGHT; pad.position.y=0.0
		pad.call("use_raised_deck_shadows")
	for spec: Dictionary in presentation.get("cargo_lifts",[]):
		var lift=load("res://scripts/terrain/polisa_cargo_lift_visual.gd").new()
		lift.name=String(spec.get("id","CargoLift"));root.add_child(lift)
		var center:Array=spec.get("center",[0,0])
		lift.position=Vector3(float(center[0]),0.0,float(center[1]))
		lift.call("set_stationary_state",{}, {})
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
