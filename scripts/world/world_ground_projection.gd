extends RefCounted
const Regions=preload("res://scripts/core/regions.gd")
const Heights=preload("res://scripts/core/terrain_layout.gd")
## Finite resources, enemies and injury visuals only reflect confirmed snapshots.
const Geo = preload("res://scripts/world/world_geometry.gd")
const Landmarks = preload("res://scripts/world/world_landmarks.gd")
const Armor = preload("res://scripts/world/world_armor.gd")
const Equipment = preload("res://scripts/world/world_equipment.gd")
const Space = preload("res://scripts/world/world_space.gd")
const Nav = preload("res://scripts/core/ground_navigation.gd")
var previous: Dictionary={}
var beams: Array[Dictionary]=[]

func present(map: Node3D, objects: Dictionary, units: Dictionary, state: Dictionary) -> void:
	var region:=str(state.region)
	var time:=float(state.get("time",0))
	if time<float(previous.get("time",0)):
		for entry: Dictionary in beams:
			if is_instance_valid(entry.node): (entry.node as Node).queue_free()
		beams.clear(); previous={}
	for id in objects:
		if state.get("resources",{}).has(id):
			var root: Node3D=objects[id]
			var known:=true
			if Regions.archetype(region)=="rust" and Regions.object_base(str(id)) in ["mining_site","derelict"]:
				known=false
				for contact: Dictionary in state.get("discovery",{}).get("signals",[]):
					if str(contact.get("kind",""))==Regions.object_base(str(id)) and bool(contact.get("identified",false)): known=true
			root.visible=known
			Geo.set_pickable(root,known)
			(root.get_node("Title") as Label3D).text=Landmarks.site_title(str(id))+" · %d" % int(state.resources[id].remaining)
	var enemies: Dictionary=state.get("ground",{}).get("enemies",{}).get(region,{})
	for id in objects.keys():
		if str(id).begins_with("team") and not enemies.has(id):
			(objects[id] as Node).queue_free();objects.erase(id)
	for id in enemies:
		var data: Dictionary=enemies[id]
		if not objects.has(id):
			var root:=Node3D.new(); root.name=str(id); map.add_child(root)
			Geo.collider(root,"object",str(id),Vector3(1.8,2.4,1.8))
			var title:=Geo.label(root,"",Vector3(0,2.8,0),Color("f2ad87"),24); title.name="Title"
			var ring:=Geo.ring(root,0.9,Color("f0a06c")); ring.name="Selection"; ring.visible=false
			objects[id]=root
		var root: Node3D=objects[id]
		if not root.has_node("EnemyModel"): _enemy_model(root,str(data.kind))
		root.position=Vector3(data.position[0],0.08+Heights.height_at(region,Vector2(data.position[0],data.position[1])),data.position[1])
		var model:=root.get_node("EnemyModel") as Node3D
		var down:=bool(data.defeated)
		model.rotation.z=PI/2 if down and str(data.kind)!="aa" else 0.0
		model.position.y=0.32 if down else 0.0
		(root.get_node("Title") as Label3D).text=str(data.name).to_upper()+ (" · AUSGESCHALTET" if down else " · %d/%d" % [int(data.health),int(data.max_health)])
		if str(data.kind)=="aa":
			(root.get_node("Title") as Label3D).position.y=4.5
			var turret:=model.get_node("Barrels") as Node3D
			var ship: Dictionary=state.get("ship",{})
			var at: Array=ship.get("position",data.position)
			var toward:=Vector2(at[0]-data.position[0],at[1]-data.position[1])
			if not down and toward.length()>0.1: turret.rotation.y=atan2(-toward.x,-toward.y)
		else:
			var closest: Node3D=null
			for unit: Node3D in units.values():
				if closest==null or unit.position.distance_to(root.position)<closest.position.distance_to(root.position): closest=unit
			if closest!=null and not down:
				var toward:=closest.position-root.position
				model.rotation.y=atan2(toward.x,toward.z)
			var player: AnimationPlayer=root.get_meta("animation_player",null)
			if player!=null: player.speed_scale=0 if bool(state.paused) or down else 1
		if not previous.is_empty():
			var old: Dictionary=previous.get("ground",{}).get("enemies",{}).get(region,{}).get(id,{})
			if float(data.cooldown)>float(old.get("cooldown",99))+0.05 and not down:
				_enemy_shot(map,root,data,units,state,time)
	for id in state.crew:
		if not units.has(id): continue
		var unit: Dictionary=state.crew[id]
		Equipment.present(units[id],unit.get("equipment",{}))
		var target:=str(unit.get("attack_target",""))
		if objects.has(target) and float(unit.get("attack_cooldown",0))>float(previous.get("crew",{}).get(id,{}).get("attack_cooldown",99))+0.05:
			_shot(map,(units[id] as Node3D).position+Vector3.UP*1.2,(objects[target] as Node3D).position+Vector3.UP*1.4,Color("a0e9d0"),time)
	for i in range(beams.size()-1,-1,-1):
		if not is_instance_valid(beams[i].node): beams.remove_at(i)
		elif time>float(beams[i].until):
			(beams[i].node as Node).queue_free(); beams.remove_at(i)
	previous=state.duplicate(true)

func _enemy_shot(map: Node3D, root: Node3D, data: Dictionary, units: Dictionary, state: Dictionary, time: float) -> void:
	var target:=Vector3.ZERO
	var found:=false
	if str(data.kind)=="aa" and str(state.get("ship",{}).get("mode",""))=="flying":
		var at: Array=state.ship.position; target=Vector3(at[0],5,at[1]); found=true
	else:
		var nearest:=INF
		for id in units:
			var health:=float(state.crew.get(id,{}).get("health",0))
			if float(previous.get("crew",{}).get(id,{}).get("health",0))<=health: continue
			var at: Vector3=(units[id] as Node3D).position
			if not Nav.clear(str(state.region),Vector2(root.position.x,root.position.z),Vector2(at.x,at.z)): continue
			if at.distance_to(root.position)<nearest: nearest=at.distance_to(root.position); target=at+Vector3.UP*1.2; found=true
	if found: _shot(map,root.position+Vector3.UP*(3 if str(data.kind)=="aa" else 1.3),target,Color("efa26e"),time)

func _shot(map: Node3D, from: Vector3, to: Vector3, color: Color, time: float) -> void:
	beams.append({"node":Space.beam(map,from,to,color),"until":time+0.16})

static func _enemy_model(root: Node3D, kind: String) -> void:
	var model:=Node3D.new(); model.name="EnemyModel"; root.add_child(model)
	if kind=="aa":
		Geo.cylinder(model,Vector3(0,0.35,0),2.7,0.7,Color("626e65"),8)
		Geo.cylinder(model,Vector3(0,1.2,0),1.25,1.7,Color("78837a"),8)
		var turret:=Node3D.new(); turret.name="Barrels"; model.add_child(turret)
		Geo.box(turret,Vector3(0,2.25,0),Vector3(2.5,1.3,2),Color("93a196"))
		for x in [-0.8,0.8]:
			var barrel:=Geo.box(turret,Vector3(x,2.65,-2.0),Vector3(0.3,0.3,3.1),Color("455e61"),0.5)
			barrel.rotation.x=-0.15
	else:
		var body:=Geo.asset(model,"white_astronaut",Vector3.ZERO,Vector3(0.9,1.95,0.65))
		var players:=body.find_children("*","AnimationPlayer",true,false)
		if not players.is_empty():
			var player:=players[0] as AnimationPlayer
			if player.has_animation("Idle"):
				player.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR
				player.play("Idle"); player.advance(0)
			root.set_meta("animation_player",player)
		Armor.attach(body,Color("b27455"))
