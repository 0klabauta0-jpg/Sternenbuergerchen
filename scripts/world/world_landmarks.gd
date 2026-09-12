extends RefCounted
## Selectable station models and set dressing, keyed by the shared catalog IDs.
const Geo = preload("res://scripts/world/world_geometry.gd")
const TITLES := {"workbench":"WERKBANK", "storage":"LAGER", "contracts":"AUFTRÄGE", "shuttle":"ENTERSÄBEL · SHUTTLE", "market":"HANDEL", "satellite":"SATELLITENWRACK", "bed_ida":"IDA", "bed_jaro":"JARO"}

static func build(parent: Node3D, region: String, landmarks: Dictionary) -> Dictionary:
	var nodes := {}
	if region == "base":
		_base_shell(parent)
	elif region == "station":
		_station_shell(parent)
	for id in landmarks:
		var at: Array = landmarks[id]
		var root := Node3D.new()
		root.name = str(id)
		parent.add_child(root)
		root.position = Vector3(at[0],0,at[1])
		var collision := Vector3(1.8,2,1.8)
		var label_height := 2.3
		match id:
			"bed_ida", "bed_jaro":
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
			"contracts":
				Geo.asset(root,"computer",Vector3(0,0.05,-0.45),Vector3(1.2,1.9,1.2))
				_beacon(root,Vector3(0,1.8,-0.4),Color("77d9d2"))
			"shuttle":
				_landing_pad(root)
				var craft := Geo.asset(root,"craft_cargoA",Vector3(0,0.35,0),Vector3(4.8,2.4,7.35),-0.25)
				craft.name = "Craft"
				# Landing feet touch the pad under the actual cargo ship hull.
				for x in [-1.45,1.45]:
					for z in [-1.7,1.7]:
						Geo.box(root,Vector3(x,0.2,z),Vector3(0.25,0.4,0.85),Color("465662"),0.5)
				collision = Vector3(5.7,3.0,8.0)
				label_height = 3.4
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
		Geo.collider(root,"object",str(id),collision)
		var title := Geo.label(root,TITLES.get(id,str(id)),Vector3(0,label_height,0),Color("dce8df"),20 if str(id).begins_with("bed") else 23)
		if str(id).begins_with("bed"):
			title.visible = false
		title.name = "Title"
		var selection := Geo.ring(root,maxf(collision.x,collision.z)*0.55,Color("8ee2da"))
		selection.name = "Selection"
		selection.visible = false
		nodes[id] = root
	return nodes

static func _base_shell(parent: Node3D) -> void:
	# Enclosed outline; the fixed camera sees through the near (+X/+Z) walls.
	Geo.box(parent,Vector3(-0.5,-0.22,-3.25),Vector3(16,0.5,13.5),Color("38454a"))
	for x in range(6):
		for z in range(5):
			Geo.asset(parent,"floor",Vector3(-6.75+x*2.5,-0.10,-8.25+z*2.5),Vector3(2.49,0.15,2.49))
	for x in range(6):
		Geo.asset(parent,"wall",Vector3(-6.75+x*2.5,0.03,-9.6),Vector3(2.5,2.9,0.55))
	for z in [-8.15,-5.65,-3.15,-0.65,1.85]:
		Geo.asset(parent,"wall",Vector3(-8.15,0.03,z),Vector3(2.5,2.9,0.55),PI/2)
		var near_wall := Geo.asset(parent,"wall",Vector3(7.15,0.03,z),Vector3(2.5,2.9,0.55),PI/2)
		Geo.fade_asset(near_wall,0.18)
	for x in [-6.875,-4.325,-1.775,0.775]:
		var front_wall := Geo.asset(parent,"wall",Vector3(x,0.03,3.15),Vector3(2.55,2.9,0.55))
		Geo.fade_asset(front_wall,0.18)
	var entry_side := Geo.asset(parent,"wall",Vector3(6.15,0.03,3.15),Vector3(2.1,2.9,0.55))
	Geo.fade_asset(entry_side,0.18)
	# Narrow solid edges make the ghosted wall contour legible without a solid roof.
	Geo.box(parent,Vector3(-0.5,3.0,-9.6),Vector3(16.1,0.25,1.2),Color("425a63"),0.2)
	for x in [-8.15,7.15]:
		Geo.box(parent,Vector3(x,3.0,-3.2),Vector3(0.38,0.22,13.1),Color("425a63"),0.2)
		for z in [-9.6,-3.15,3.15]:
			Geo.box(parent,Vector3(x,1.5,z),Vector3(0.22,2.95,0.22),Color("667e82"),0.2)
	Geo.box(parent,Vector3(-0.5,3.0,3.15),Vector3(15.5,0.22,0.38),Color("425a63"),0.2)
	Geo.box(parent,Vector3(7.15,0.15,-3.2),Vector3(0.36,0.25,12.9),Color("667e82"),0.2)
	for edge in [Vector2(-3.05,10.2),Vector2(6.15,2.1)]:
		Geo.box(parent,Vector3(edge.x,0.15,3.15),Vector3(edge.y,0.25,0.36),Color("667e82"),0.2)
	# Three-metre open entrance aligns with the existing approach to the shuttle.
	for x in [2.05,5.1]:
		Geo.box(parent,Vector3(x,1.5,3.15),Vector3(0.24,2.95,0.42),Color("a7bab5"),0.2)
	Geo.box(parent,Vector3(3.575,2.83,3.15),Vector3(3.3,0.14,0.46),Color("a7bab5"),0.2)
	Geo.box(parent,Vector3(0.5,0.52,-7.5),Vector3(0.2,1.0,3.5),Color("64787c"))
	Geo.box(parent,Vector3(-3.4,0.06,-6.5),Vector3(6.5,0.025,4.3),Color("627d7c"))
	Geo.box(parent,Vector3(3.2,0.08,3.35),Vector3(5.4,0.12,0.5),Color("c5a67c"))
	# Raised service mast and a roof-mounted solar awning identify the outpost.
	Geo.cylinder(parent,Vector3(7.1,3.3,-8.7),0.11,6.6,Color("526771"),8)
	Geo.box(parent,Vector3(7.1,6.5,-8.7),Vector3(2.5,0.16,0.18),Color("94abb2"))
	_beacon(parent,Vector3(7.1,6.7,-8.7),Color("ffc780"))
	for x in [1.0,3.5,6.0]:
		var panel := Geo.box(parent,Vector3(x,3.4,-10.7),Vector3(2.3,0.13,3.1),Color("365868"),0.45)
		panel.rotation.x = -0.2
		Geo.box(parent,Vector3(x,1.7,-10.7),Vector3(0.16,3.4,0.16),Color("50636a"))
	Geo.label(parent,"FERNPOSTEN 07",Vector3(-0.5,3.7,-9.55),Color("c6d8d5"),25)
	# Broad, continuous approach to the landing pad.
	for i in range(7):
		var slab := Geo.box(parent,Vector3(3.5+i*1.4,0.035,3.6+i*0.58),Vector3(1.5,0.06,2.8),Color("bc9a73"))
		slab.rotation.y = -0.38

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
		var piece := Geo.box(root,Vector3(-5+i*1.9,0.18,3.2+sin(i)*1.2),Vector3(0.8,0.35,0.6),Color("606d70"))
		piece.rotation.y = i*0.9

static func _station_shell(parent: Node3D) -> void:
	for x in [-9.0,-6.0,-3.0,0.0,3.0,6.0,9.0]:
		Geo.asset(parent,"wall",Vector3(x,0,-12.2),Vector3(3,4,0.7))
	Geo.box(parent,Vector3(0,4.2,-12),Vector3(24,0.35,1.5),Color("324e5c"))
	Geo.label(parent,"MERIDIAN / FREIHANDEL",Vector3(0,5.1,-12),Color("a8d8d3"),38)
	for x in [-10.0,10.0]:
		Geo.box(parent,Vector3(x,0.05,0),Vector3(0.13,0.04,27),Color("bcb891"))
		Geo.asset(parent,"crate-wide",Vector3(x,0.05,-8),Vector3(2,1.5,2))

static func _beacon(parent: Node3D, at: Vector3, color: Color) -> void:
	var lamp := Geo.cylinder(parent,at,0.15,0.18,color,8)
	lamp.material_override = Geo.material(color,0.0,1.5)
