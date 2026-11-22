extends RefCounted
## Reuses the reviewed current ship family; geometry has saved offline blockers.
static func build(site: Dictionary) -> Node3D:
	var root:=Node3D.new(); root.name=String(site.id)
	if site.kind=="wreck":
		var identity: Dictionary=load("res://scripts/terrain/frontier_ship_visuals.gd").get_for_role("dropship")
		var ship: Node3D=load(String(identity.model_path)).instantiate(); root.add_child(ship)
		ship.scale=Vector3.ONE*.42; ship.rotation=Vector3(.17,.6,.4); ship.position=Vector3(6.4,-.8,0)
		load("res://scripts/terrain/wreck_smoke.gd").attach_to(ship,root,"grey")
	else:
		for index in 7:
			var rock:=MeshInstance3D.new(); var mesh:=SphereMesh.new(); mesh.radial_segments=8; mesh.rings=4; mesh.radius=.32+index*.035; mesh.height=.55+index*.06
			rock.mesh=mesh; rock.position=Vector3(cos(index*2.4)*.6,.1,sin(index*2.4)*.6)
			var material:=StandardMaterial3D.new(); material.albedo_color=Color("a9b9b7") if index%2==0 else Color("6f7777"); material.roughness=.9; rock.material_override=material; root.add_child(rock)
	return root
