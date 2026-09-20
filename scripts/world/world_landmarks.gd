extends RefCounted
## Selectable station models and set dressing, keyed by the shared catalog IDs.
const Regions=preload("res://scripts/core/regions.gd")
const Geo = preload("res://scripts/world/world_geometry.gd")
const Ship = preload("res://scripts/world/world_ship.gd")
const Rooms = preload("res://scripts/world/world_rooms.gd")
const GroundSites = preload("res://scripts/world/world_ground_sites.gd")
const TITLES := {"workbench":"WERKBANK", "office":"BÜRO · CREW", "storage":"LAGER · HIER ENTLADEN", "contracts":"AUFTRÄGE", "shuttle":"ENTERSÄBEL · SHUTTLE", "market":"HANDEL", "satellite":"SATELLITENWRACK", "bed_ida":"IDA", "bed_jaro":"JARO", "kitchen":"KÜCHE / AUFENTHALT", "expansion_a":"MODULFLÄCHE A", "expansion_b":"MODULFLÄCHE B", "pirate":"FREIBEUTER"}

static func build(parent: Node3D, region: String, landmarks: Dictionary) -> Dictionary:
	var nodes := {}
	if region == "base":
		Rooms.base(parent)
	elif region == "station":
		Rooms.station(parent)
	GroundSites.build(parent,region)
	for id in landmarks:
		var at: Array = landmarks[id]
		var root := Node3D.new()
		root.name = str(id)
		parent.add_child(root)
		root.position = Vector3(at[0],0,at[1])
		var collision := Vector3(1.8,2,1.8)
		var label_height := 2.3
		match Regions.object_base(str(id)):
			"bed_ida", "bed_jaro", "bed_3", "bed_4", "bed_5", "bed_6":
				Geo.asset(root,"bed-single",Vector3(0,0.05,-0.2),Vector3(1.45,0.85,2.6),PI)
				collision = Vector3(1.5,0.9,2.6)
				label_height = 1.3
			"workbench":
				Geo.asset(root,"workbench",Vector3(0,0.05,-0.25),Vector3(2.5,1.55,1.3),PI)
				Geo.box(root,Vector3(0,0.055,0.6),Vector3(3.1,0.04,2.5),Color("435b5c"))
				collision = Vector3(2.8,1.8,2.1)
			"storage":
				Geo.asset(root,"crate-wide",Vector3(-0.5,0.05,-0.3),Vector3(1.8,0.9,1.5),PI/2)
				Geo.asset(root,"crate-small",Vector3(1.0,0.05,-0.2),Vector3(1.0,0.75,1.0))
				Geo.asset(root,"crate-small",Vector3(-0.6,0.95,-0.3),Vector3(0.9,0.6,0.9),0.15)
				collision = Vector3(3,1.8,1.8)
			"contracts", "office":
				Geo.asset(root,"computer",Vector3(0,0.05,-0.45),Vector3(1.2,1.9,1.2))
				_beacon(root,Vector3(0,1.8,-0.4),Color("77d9d2"))
			"shuttle":
				if region not in ["space","orbit"]:
					var pad:=Node3D.new(); parent.add_child(pad); pad.position=root.position; _landing_pad(pad)
				Ship.build(root,"cutlass")
				collision=Vector3(7.5,3.6,11.0)
				label_height=4.6
			"pirate":
				var craft := Geo.asset(root,"freibeuter",Vector3(0,0.35,0),Vector3(8,2,7.5))
				craft.name = "Craft"
				collision = Vector3(9,3,9)
				label_height = 3.8
			"kitchen":
				Geo.box(root,Vector3(0,0.6,-0.3),Vector3(2.4,1.2,1.15),Color("687f7d"))
				Geo.box(root,Vector3(0,1.25,-0.3),Vector3(2.6,0.15,1.3),Color("b1b7a1"))
				Geo.cylinder(root,Vector3(0.6,1.45,-0.25),0.27,0.3,Color("354e59"),10)
			"expansion_a", "expansion_b":
				Geo.box(root,Vector3(0,0.02,0),Vector3(12,0.04,12),Color("8b7964"))
				for edge in [-6.0,6.0]:
					Geo.box(root,Vector3(edge,0.065,0),Vector3(0.14,0.04,12),Color("c1a87a"))
					Geo.box(root,Vector3(0,0.065,edge),Vector3(12,0.04,0.14),Color("c1a87a"))
				Geo.box(root,Vector3(-8.5,0.09,0),Vector3(5,0.12,2.4),Color("9d927a"))
				collision=Vector3(12,0.15,12)
				label_height=0.6
			"satellite":
				_wreck(root)
				collision = Vector3(10,3.4,7)
				label_height = 4.3
			"market":
				Geo.asset(root,"computer-wide",Vector3(0,0.05,-0.25),Vector3(3.5,2,2))
				Geo.asset(root,"crate-wide",Vector3(-3.1,0.05,-1),Vector3(1.8,1.1,1.5),PI/2)
				Geo.asset(root,"crate-wide",Vector3(3.0,0.05,-1),Vector3(1.8,1.1,1.5),PI/2)
				collision = Vector3(4,2.4,2.5)
				label_height = 3.1
			"mining_site":
				_ore(root)
				collision=Vector3(11,3.6,9)
				label_height=4.2
			"derelict", "distribution_wreck":
				_ship_wreck(root)
				collision=Vector3(15,4,16)
				label_height=5.0
			"bunker_entry", "elevator":
				_lift(root)
				collision=Vector3(7.5,0.3,7.5)
				label_height=1.0
			"aa_turret":
				# Enemy geometry and confirmed health are supplied by GroundProjection.
				collision=Vector3(4,3.8,4)
				label_height=4.3
			"surface_cache", "bunker_cache", "distribution_cache", "tradepost_cache":
				Geo.asset(root,"crate-wide",Vector3(-0.7,0.05,-0.5),Vector3(2.2,1.1,1.6))
				Geo.asset(root,"crate-small",Vector3(1.4,0.05,0.1),Vector3(1.1,0.85,1.1))
				_beacon(root,Vector3(-0.7,1.3,-0.4),Color("b6d597"))
				collision=Vector3(4,1.8,2.6)
			"bunker_terminal":
				Geo.asset(root,"computer-wide",Vector3(0,0.05,-0.5),Vector3(3.2,2.0,1.5))
				collision=Vector3(3.5,2.3,2.0)
		Geo.collider(root,"object",str(id),collision)
		var title := Geo.label(root,site_title(str(id)),Vector3(0,label_height,0),Color("dce8df"),20 if str(id).begins_with("bed") else 23)
		if str(id).begins_with("bed"):
			title.visible = false
		title.name = "Title"
		var selection := Geo.ring(root,maxf(collision.x,collision.z)*0.55,Color("8ee2da"))
		selection.name = "Selection"
		selection.visible = false
		nodes[id] = root
	return nodes

static func site_title(id: String) -> String:
	id=Regions.object_base(id)
	return {"mining_site":"ERZVORKOMMEN","derelict":"VERLASSENES SCHIFFSWRACK","bunker_entry":"LASTENAUFZUG · ABWÄRTS","elevator":"LASTENAUFZUG · AUFWÄRTS","aa_turret":"FLAKGESCHÜTZ","surface_cache":"MATERIALKISTEN","bunker_cache":"LEGIERUNGSLAGER","bunker_terminal":"SICHERHEITSTERMINAL","distribution_cache":"FRACHTDEPOT","distribution_wreck":"BERGEDOCK / WRACK","tradepost_cache":"VERLASSENES DEPOT"}.get(id,TITLES.get(id,id))

static func _lift(root: Node3D) -> void:
	Geo.box(root,Vector3(0,0.035,0),Vector3(7.5,0.07,7.5),Color("354f58"))
	Geo.box(root,Vector3(0,0.085,0),Vector3(6.3,0.03,6.3),Color("849993"))
	for x in [-3.4,3.4]:
		Geo.box(root,Vector3(x,1.3,-3.4),Vector3(0.35,2.6,0.35),Color("c4b58c"))
		Geo.box(root,Vector3(x,0.105,0),Vector3(0.20,0.02,6.7),Color("e0bd78"))
		_beacon(root,Vector3(x,2.75,-3.4),Color("8ddaca"))
	Geo.box(root,Vector3(0,0.105,0),Vector3(0.12,0.02,6.3),Color("506966"))

static func _ore(root: Node3D) -> void:
	Geo.cylinder(root,Vector3(0,0.06,0),7.3,0.12,Color("766454"),9)
	for i in range(12):
		var angle:=i*2.39
		var radius:=1.2+float(i%4)*0.8
		var rock:=Geo.cylinder(root,Vector3(cos(angle)*radius,0.45+float(i%3)*0.35,sin(angle)*radius),1.2+float(i%3)*0.3,1.3+float(i%3)*0.55,Color("736a62"),5)
		rock.rotation=Vector3(0.1*i,0.8*i,0.13)
		Geo.box(rock,Vector3(0,0.7,0),Vector3(0.35,0.35,1.3),Color("75b5ad"),0.45)

static func _ship_wreck(root: Node3D) -> void:
	Geo.cylinder(root,Vector3(0,0.055,0),10.0,0.11,Color("625649"),9)
	var hull:=Geo.asset(root,"craft_cargoA",Vector3(0,0.5,0),Vector3(7,3.5,11),0.5)
	hull.rotation.z=0.26
	Geo._tint(hull,Geo.material(Color("65706c"),0.25))
	for i in range(10):
		var piece:=Geo.box(root,Vector3(sin(i*2.1)*5.5,0.3,cos(i*1.7)*5.4),Vector3(1.0+float(i%3)*0.45,0.45,0.8),Color("a08a69"))
		piece.rotation.y=i*0.84

static func _landing_pad(root: Node3D) -> void:
	Geo.cylinder(root,Vector3(0,0.015,0),6.4,0.035,Color("736d60"),8)
	Geo.cylinder(root,Vector3(0,0.038,0),5.9,0.04,Color("687279"),8)
	var line := Geo.ring(root,5.25,Color("d8bd89"))
	line.position.y = 0.075
	for x in [-4.8,4.8]:
		for z in [-3.8,3.8]:
			Geo.box(root,Vector3(x,0.25,z),Vector3(0.35,0.5,0.35),Color("405761"))
			_beacon(root,Vector3(x,0.58,z),Color("91d7d0"))
	for x in [-0.8,0.8]:
		Geo.box(root,Vector3(x,0.082,4.2),Vector3(0.15,0.025,0.9),Color("d6be8b"))

static func _wreck(root: Node3D) -> void:
	var debris := Node3D.new()
	root.add_child(debris)
	debris.rotation = Vector3(0.18,0.32,0.13)
	debris.position.y = 1.05
	debris.scale=Vector3.ONE*0.85
	Geo.cylinder(debris,Vector3(0,0.4,0),1.45,2.8,Color("778b8c"),8)
	Geo.box(debris,Vector3(0,1.95,0),Vector3(1.65,0.3,1.65),Color("cfb18b"),0.4)
	Geo.box(debris,Vector3(0,0.2,0),Vector3(10.5,0.2,0.35),Color("687f86"),0.4)
	for x in [-4.2,4.2]:
		Geo.box(debris,Vector3(x,0.16,0),Vector3(4.1,0.12,3.3),Color("244957"),0.6)
		for z in [-1.4,-0.7,0.0,0.7,1.4]:
			Geo.box(debris,Vector3(x,0.24,z),Vector3(3.9,0.025,0.035),Color("648891"),0.4)
		for step in [-1.8,-0.9,0.0,0.9,1.8]:
			Geo.box(debris,Vector3(x+step,0.24,0),Vector3(0.035,0.025,3.15),Color("648891"),0.4)
	Geo.cylinder(root,Vector3(0,0.2,0),2.3,0.4,Color("735241"),7)
	var dish := Geo.cylinder(debris,Vector3(0,2.5,0),1.2,0.16,Color("c6bfaa"),12)
	dish.rotation.z = 0.5
	_beacon(root,Vector3(0,3.6,0),Color("e5a568"))
	for i in range(6):
		var piece := Geo.box(root,Vector3(-5+i*1.9,0.18,2.3+sin(i)*0.5),Vector3(0.8,0.35,0.6),Color("606d70"))
		piece.rotation.y = i*0.9

static func _beacon(parent: Node3D, at: Vector3, color: Color) -> void:
	var lamp := Geo.cylinder(parent,at,0.15,0.18,color,8)
	lamp.material_override = Geo.material(color,0.0,1.5)
