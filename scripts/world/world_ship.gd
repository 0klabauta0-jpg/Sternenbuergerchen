extends RefCounted
## Physical model and turret are a projection of the shared ship profile and seats.
const Geo = preload("res://scripts/world/world_geometry.gd")
const Layout = preload("res://scripts/core/world_layout.gd")

static func build(root: Node3D, model: String) -> Node3D:
	var profile:=Layout.ship_profile(model)
	var craft:=Geo.asset(root,"geier" if model=="vulture" else "craft_cargoA",Vector3.ZERO,Vector3(profile.size[0],profile.height,profile.size[1]))
	craft.name="Craft"; root.set_meta("ship_model",model)
	var turret:=craft.find_child("TurretPivot",true,false) as Node3D
	if turret==null and model=="cutlass":
		# Curated models retain working roles and a separately rotating turret.
		turret=Node3D.new(); turret.name="TurretPivot"; craft.add_child(turret)
		turret.position=Vector3(profile.turret[0],profile.turret_height,profile.turret[1])
		Geo.cylinder(turret,Vector3.ZERO,0.65,0.40,Color("52696c"),10)
		for x in [-0.42,0.42]:Geo.box(turret,Vector3(x,0.2,-1),Vector3(0.16,0.18,1.5),Color("718684"),0.4)
		for x in [-2.0,2.0]:
			Geo.box(craft,Vector3(x,0.3,2.6),Vector3(0.22,0.6,0.22),Color("697779"))
			Geo.box(craft,Vector3(x,0.08,2.6),Vector3(0.65,0.16,0.9),Color("45565f"))
	var seats:=Node3D.new(); seats.name="CrewStations"; craft.add_child(seats)
	if turret!=null:
		craft.set_meta("turret",turret); turret.set_meta("rest_basis",turret.basis)
		var gunner:=Node3D.new(); gunner.name="Gunner"; turret.add_child(gunner)
		# A seated helmet sits within the turret hatch rather than above the hull.
		Geo.cylinder(gunner,Vector3(0,0.48,0.3),0.19,0.28,Color("e5e9df"),8)
		Geo.box(gunner,Vector3(0,0.49,0.12),Vector3(0.28,0.11,0.045),Color("355766"))
		gunner.visible=false; craft.set_meta("gunner",gunner)
	return craft

static func present(root: Node3D, ship: Dictionary, crew: Dictionary) -> void:
	var model:=str(ship.get("model","cutlass"))
	if str(root.get_meta("ship_model","cutlass"))!=model or not root.has_node("Craft"):
		var old:=root.get_node_or_null("Craft")
		if old!=null:root.remove_child(old);old.queue_free()
		build(root,model)
	var craft:=root.get_node("Craft") as Node3D
	craft.position.y=4.0 if str(ship.get("mode","landed"))=="flying" else 0.055
	craft.rotation.y=float(ship.get("yaw",0.0))
	var turret: Node3D=craft.get_meta("turret") if craft.has_meta("turret") else null
	if turret!=null:
		turret.basis=Basis(Vector3.UP,float(ship.get("turret_yaw",0.0))-craft.rotation.y)*(turret.get_meta("rest_basis") as Basis)
	var gunner: Node3D=craft.get_meta("gunner") if craft.has_meta("gunner") else null
	if gunner!=null:
		var id:=str(ship.get("seats",{}).get("gunner",""))
		gunner.visible=not id.is_empty() and str(crew.get(id,{}).get("assignment",""))=="aboard"
	var profile:=Layout.ship_profile(model)
	var shapes:=root.find_children("*","CollisionShape3D",true,false)
	if not shapes.is_empty():
		var shape:=shapes[0] as CollisionShape3D
		var box:=shape.shape as BoxShape3D
		box.size=Vector3(profile.size[0],profile.height,profile.size[1])
		shape.position=Vector3(0,craft.position.y+float(profile.height)/2,0)
		shape.rotation.y=craft.rotation.y
