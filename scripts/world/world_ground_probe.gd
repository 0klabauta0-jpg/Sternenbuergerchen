extends "res://scripts/world/world_orbit_probe.gd"
## Real product window, isolated fresh career and authoritative commands only.
const Catalog=preload("res://scripts/core/catalog.gd")

func _run() -> void:
	seed(914)
	out="res://output/ground-world"
	root.size=Vector2i(1440,900)
	game=load("res://scenes/game.tscn").instantiate()
	game.load_on_start=false
	game.save_path="res://output/ground-world/isolated-career.json"
	root.add_child(game)
	game.simulation.auto_tick=false
	game.world.object_selected.connect(func(kind: String,id: String): picked=kind+":"+id)
	DisplayServer.window_set_title("Sternenbürgerchen · Neue Außenposten · Weltprüfung")
	await create_timer(0.5).timeout
	_send({"type":"assign_work","unit_id":"ida","recipe_id":"armor"}); _step(20)
	_send({"type":"equip","unit_id":"ida","item":"armor"})
	_send({"type":"move","unit_id":"ida","position":[0,4]}); _step(3)
	_send({"type":"move","unit_id":"ida","position":[1,6]}); _step(1)
	game.world.set("_focus",game.world.get("_units").ida.position-Vector3(2.1,0,-1.7)); game.world.set("_zoom",9)
	var parts: Array=game.world.get("_units").ida.get_meta("armor_parts",[])
	_check(parts.size()==3,"chest and two shoulders attached to rig")
	for part: Node3D in parts: _check(part.visible,"equipped armor visible")
	await _capture("armor")
	if "--armor-only" in OS.get_cmdline_user_args():
		print("ARMOR_WINDOW_CHECKS ",checks," failures ",failures)
		quit(0 if failures==0 else 1); return
	_send({"type":"accept_contract"}); _travel_to("rust")
	_check(not game.world.get("_objects").mining_site.visible,"unidentified ore not shown")
	_check(not game.world.get("_objects").derelict.visible,"unidentified shipwreck not shown")
	_send({"type":"launch"}); _step(8)
	_send({"type":"radar_scan"})
	_fly_to("satellite")
	_send({"type":"salvage","unit_id":"ida"}); _step(20)
	_travel_to("base"); _send({"type":"claim_contract"})
	_travel_to("rust")
	_send({"type":"launch"}); _step(8); _fly_to("mining_site")
	for i in range(2): _send({"type":"gather","unit_id":"ida","site_id":"mining_site"}); _step(20)
	game.world.focus_object("mining_site"); game.world.set("_zoom",48)
	await _capture("rust-mining")
	_send({"type":"launch"}); _step(10); _fly_to("derelict")
	for i in range(2): _send({"type":"gather","unit_id":"ida","site_id":"derelict"}); _step(20)
	game.world.focus_object("derelict"); game.world.set("_zoom",56)
	await _capture("rust-wreck")
	_travel_to("station")
	_send({"type":"trade","item":"ore","side":"sell","amount":6})
	_send({"type":"trade","item":"alloy","side":"sell","amount":4})
	_send({"type":"rent_ship","ship_id":"vulture"})
	_check(game.simulation.snapshot().ship.model=="vulture","actual Geier rental")
	_check(str(game.world.get("_objects").shuttle.get_meta("ship_model",""))=="vulture","rendered ship model switched")
	var geier_meshes: Array=game.world.get("_objects").shuttle.find_children("*Geier*","MeshInstance3D",true,false)
	_check(not geier_meshes.is_empty(),"converted Geier GLB instantiated")
	game.world.focus_object("shuttle"); game.world.set("_zoom",23)
	await _capture("geier")
	_travel_to("bunker_surface")
	game.world.set("_focus",Vector3(-8,0,5)); game.world.set("_zoom",145)
	await _capture("bunker-surface")
	_check_blockers()
	await _pick_enemy("aa_turret")
	_fight("aa_turret"); _fight("surface_guard")
	_lift("bunker_entry")
	_check(game.simulation.snapshot().region=="bunker_depths","real elevator reached separate underground map")
	game.world.set("_focus",Vector3.ZERO); game.world.set("_zoom",120)
	await _capture("bunker-depths")
	_check_blockers()
	var front: MeshInstance3D=game.world.get("_map").get_node("Blocker_east_south").get_child(0)
	_check((front.material_override as StandardMaterial3D).albedo_color.a<0.2,"camera-facing procedural wall visibly transparent")
	await _pick_enemy("depth_guard")
	_fight("depth_guard")
	_send({"type":"gather","unit_id":"ida","site_id":"bunker_cache"}); _step(30)
	_check(int(game.simulation.snapshot().inventory.alloy)>0,"real walking extraction through bunker door")
	_lift("elevator")
	_travel_to("distribution")
	game.world.set("_focus",Vector3(5,0,0)); game.world.set("_zoom",270)
	await _capture("distribution")
	_check_blockers()
	await _pick_enemy("depot_guard")
	_travel_to("tradepost")
	game.world.set("_focus",Vector3(35,0,-20)); game.world.set("_zoom",310)
	await _capture("tradepost-landscape")
	game.world.set("_focus",Vector3(-2,0,0)); game.world.set("_zoom",86)
	await _capture("tradepost")
	_check_blockers()
	_check(not game.world.get("_objects").has("depot_guard"),"enemies from old map absent")
	var regions:=0
	for child in game.world.get_children():
		if str(child.name).begins_with("Region_"): regions+=1
	_check(regions==1,"only one active map attached")
	var report:={"checks":checks,"failures":failures,"performance":performance,"commands":"fresh career: craft/equip/contract/radar/mine/salvage/sell/rent/travel/attack/elevator","viewport":"1440x900","measurement_limits":"3 second fixed-snapshot rendering samples; shared desktop load, no general performance promise"}
	var file:=FileAccess.open(out+"/world-results.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"  "))
	print("GROUND_WORLD_RESULT ",JSON.stringify(report))
	quit(0 if failures==0 else 1)

func _send(command: Dictionary) -> void:
	super._send(command)
	game.world.present(game.simulation.snapshot())

func _step(seconds: float) -> void:
	super._step(seconds)
	game.world.present(game.simulation.snapshot())

func _travel_to(region: String) -> void:
	_send({"type":"travel","destination":region})
	for i in range(900):
		game.simulation.advance(0.1)
		if not game.simulation.snapshot().travel.active: break
	game.world.present(game.simulation.snapshot())
	if game.simulation.snapshot().region=="space": _send({"type":"flee"}); _step(10)
	_check(game.simulation.snapshot().region==region,"travel arrived "+region)

func _fly_to(id: String) -> void:
	var at: Array=Catalog.landmarks("rust")[id]
	_send({"type":"ship_move","position":[at[0]-18,at[1]]}); _step(32)
	_send({"type":"land"}); _step(0.1)

func _fight(id: String) -> void:
	var snapshot: Dictionary=game.simulation.snapshot()
	if snapshot.ground.enemies[snapshot.region][id].defeated: return
	for unit_id in ["ida","jaro"]: _send({"type":"attack","unit_id":unit_id,"target_id":id})
	_step(35)
	_check(game.simulation.snapshot().ground.enemies[snapshot.region][id].defeated,"actual enemy defeated "+id)

func _lift(id: String) -> void:
	var snapshot: Dictionary=game.simulation.snapshot()
	var at: Array=Catalog.landmarks(snapshot.region)[id]
	for unit_id in ["ida","jaro"]: _send({"type":"move","unit_id":unit_id,"position":[at[0],at[1]+2]})
	_step(40); _send({"type":"use_elevator"})

func _check_blockers() -> void:
	for id in Catalog.obstacles(game.simulation.snapshot().region):
		var node: Node=game.world.get("_map").get_node_or_null("Blocker_"+str(id))
		_check(node!=null and node.get_meta("footprint")==Catalog.obstacles(game.simulation.snapshot().region)[id],"rendered catalog footprint "+str(id))

func _pick_enemy(id: String) -> void:
	game.world.focus_object(id); game.world.set("_zoom",32)
	await process_frame; await physics_frame
	var camera: Camera3D=game.world.get("_camera")
	var object: Node3D=game.world.get("_objects")[id]
	game.world.call("_pick",camera.unproject_position(object.position+Vector3.UP*1.5))
	_check(picked=="object:"+id,"real ray picks "+id)

func _capture(id: String) -> void:
	await create_timer(0.35).timeout
	if id in ["rust-mining","bunker-surface","bunker-depths","distribution","tradepost-landscape"]:
		var samples: Array[float]=[]; var begin:=Time.get_ticks_usec(); var last:=begin
		while Time.get_ticks_usec()-begin<3000000:
			await process_frame
			var now:=Time.get_ticks_usec(); samples.append((now-last)/1000.0); last=now
		samples.sort()
		performance[id]={"samples":samples.size(),"p95_ms":samples[mini(samples.size()-1,int(samples.size()*0.95))],"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	_check(root.get_texture().get_image().save_png(out+"/"+id+".png")==OK,"capture "+id)
	var file:=FileAccess.open(out+"/"+id+".json",FileAccess.WRITE); file.store_string(JSON.stringify(game.simulation.snapshot(),"  "))
	print("GROUND_CAPTURE ",id)
