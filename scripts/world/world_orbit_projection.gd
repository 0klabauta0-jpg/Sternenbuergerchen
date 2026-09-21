extends RefCounted
const Regions=preload("res://scripts/core/regions.gd")
const Heights=preload("res://scripts/core/terrain_layout.gd")
## Snapshot-only contact, ship and confirmed-shot projection.
const Geo = preload("res://scripts/world/world_geometry.gd")
const Ship = preload("res://scripts/world/world_ship.gd")
const Space = preload("res://scripts/world/world_space.gd")
var markers: Dictionary = {}
var beams: Array[Dictionary] = []
var previous: Dictionary = {}

func present(map: Node3D, objects: Dictionary, state: Dictionary) -> void:
	if float(state.get("time",0))+0.00001<float(previous.get("time",0)):
		for entry: Dictionary in beams:
			if is_instance_valid(entry.node): (entry.node as Node).queue_free()
		beams.clear()
		previous={}
	var region := str(state.get("region","base"))
	if region=="base":
		var infrastructure:Dictionary=state.base.get("infrastructure",{"solar":3,"solar_tier":1,"sender_tier":1})
		for i in 6:
			var module:=map.find_child("Furniture_solar_slot_%d"%i,true,false) as Node3D
			if module!=null:module.visible=i<int(infrastructure.solar)
		for kind:String in ["small","large"]:
			var reactor:=map.find_child("Furniture_reactor_"+kind,true,false) as Node3D
			if reactor!=null:reactor.visible=int(infrastructure.get("fusion_"+kind,0))>0
	var ship: Dictionary = state.get("ship",{})
	var airborne := str(ship.get("mode","landed"))=="flying"
	if objects.has("shuttle"):
		var root: Node3D=objects.shuttle
		var model:=str(ship.get("model","cutlass"))
		Ship.present(root,ship,state.get("crew",{}))
		(root.get_node("Title") as Label3D).text=str(ship.get("name","Entersäbel")).to_upper()+ (" · MIETSCHIFF" if model=="vulture" else " · SHUTTLE")
		if ship.has("position"):
			var coords: Array=ship.position
			var at:=Vector2(coords[0],coords[1])
			var profile:Dictionary=preload("res://scripts/core/catalog.gd").ship_profile(model)
			var radius:=Vector2(profile.size[0],profile.size[1]).length()*0.5
			var altitude:=Heights.flight_floor(region,at,radius) if airborne else Heights.height_at(region,at)
			root.position=Vector3(at.x,altitude,at.y)
		(root.get_node("Title") as Label3D).position.y=8.4 if airborne else 4.5
		Geo.set_pickable(root,true)
	if objects.has("satellite"):
		var known:=bool(state.get("discovery",{}).get("satellite_found",false))
		(objects.satellite as Node3D).visible=known
		Geo.set_pickable(objects.satellite,known)
	if objects.has("workbench"):
		(objects.workbench.get_node("Title") as Label3D).text="WERKBANK · STUFE %d" % int(state.get("base",{}).get("workbench_tier",1))
	if Regions.archetype(region)=="rust": _signals(map,state)
	if region=="space" and objects.has("pirate"):
		var encounter: Dictionary=state.get("encounter",{})
		var enemy: Dictionary=encounter.get("enemy",{})
		var pirate: Node3D=objects.pirate
		pirate.visible=bool(encounter.get("active",false)) and not enemy.is_empty()
		Geo.set_pickable(pirate,pirate.visible)
		if pirate.visible:
			pirate.position=Vector3(enemy.position[0],0,enemy.position[1])
			var craft:=pirate.get_node("Craft") as Node3D
			craft.position.y=4.0
			craft.scale=Vector3.ONE*1.6
			_ship_pick_shape(pirate,1.6,4.0)
			var toward: Vector3=(objects.shuttle as Node3D).position-pirate.position
			if toward.length()>0.05: craft.rotation.y=atan2(-toward.x,-toward.z)
			var title:=pirate.get_node("Title") as Label3D
			title.text="FREIBEUTER · %d/%d" % [int(enemy.hull),int(enemy.max_hull)]
			title.position.y=8.3
			_confirmed_shots(map,objects,state)
	var now:=float(state.get("time",0))
	for i in range(beams.size()-1,-1,-1):
		if not is_instance_valid(beams[i].node): beams.remove_at(i)
		elif now>float(beams[i].until):
			(beams[i].node as Node).queue_free()
			beams.remove_at(i)
	previous=state.duplicate(true)

func _ship_pick_shape(root: Node3D, scale: float, height: float) -> void:
	var shapes:=root.find_children("*","CollisionShape3D",true,false)
	if shapes.is_empty(): return
	var shape:=shapes[0] as CollisionShape3D
	var box:=shape.shape as BoxShape3D
	if not shape.has_meta("base_size"): shape.set_meta("base_size",box.size)
	box.size=(shape.get_meta("base_size") as Vector3)*scale
	shape.position.y=height+box.size.y/2

func _signals(map: Node3D, state: Dictionary) -> void:
	var alive: Array[String]=[]
	for signal_data: Dictionary in state.get("discovery",{}).get("signals",[]):
		var id:=str(signal_data.id)
		alive.append(id)
		if not markers.has(id):
			var root:=Node3D.new()
			map.add_child(root)
			Geo.ring(root,5.0,Color("d3c48c"))
			var title:=Geo.label(root,"",Vector3(0,2,0),Color("e1d3a3"),24)
			title.name="Title"
			Geo.collider(root,"object",id,Vector3(10,0.15,10))
			markers[id]=root
		var marker: Node3D=markers[id]
		marker.position=Vector3(signal_data.position[0],Heights.height_at(str(state.region),Vector2(signal_data.position[0],signal_data.position[1])),signal_data.position[1])
		(marker.get_node("Title") as Label3D).text=str(signal_data.get("label","Unbekanntes Signal"))
		marker.visible=not (bool(signal_data.get("identified",false)) and str(signal_data.get("kind",""))=="satellite")
		Geo.set_pickable(marker,marker.visible)
	for id in markers.keys():
		if id not in alive:
			(markers[id] as Node).queue_free()
			markers.erase(id)

func _confirmed_shots(map: Node3D, objects: Dictionary, state: Dictionary) -> void:
	if previous.is_empty() or str(previous.get("region",""))!="space": return
	var now: Dictionary=state.encounter
	var old: Dictionary=previous.get("encounter",{})
	var player: Vector3=(objects.shuttle as Node3D).position+Vector3(0,7.35,0)
	var enemy: Vector3=(objects.pirate as Node3D).position+Vector3(0,5.5,0)
	if float(now.fire_cooldown)>float(old.get("fire_cooldown",0))+0.05 and str(now.get("turret_target",""))!="":
		var beam:=Space.beam(map,player,enemy,Color("83e8e1"))
		beams.append({"node":beam,"until":float(state.time)+0.18})
	if float(now.enemy_cooldown)>float(old.get("enemy_cooldown",0))+0.05:
		var beam:=Space.beam(map,enemy,player,Color("f0a17d"))
		beams.append({"node":beam,"until":float(state.time)+0.18})
