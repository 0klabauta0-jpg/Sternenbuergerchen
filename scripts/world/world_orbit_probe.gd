extends SceneTree
## Real-window map/asset probe; isolated career, all progression via product commands.
var game: Node
var checks := 0
var failures := 0
var picked := ""
var out := "res://output/rooms-orbit"
var performance: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	seed(7319)
	game=load("res://scenes/game.tscn").instantiate()
	game.load_on_start=false
	game.save_path="user://world-orbit-probe-isolated.json"
	root.add_child(game)
	game.simulation.auto_tick=false
	game.world.object_selected.connect(func(kind: String,id: String): picked=kind+":"+id)
	DisplayServer.window_set_title("Sternenbürgerchen · Räume/Orbit · Sichtprüfung")
	await create_timer(1.0).timeout
	_check(game.simulation.snapshot().crew.size()==2,"two stable crew")
	_check(game.world.get("_objects").has("kitchen"),"kitchen room landmark")
	_check(game.world.get("_objects").has("expansion_b"),"free module slots")
	game.world.present({})
	_check(game.world.get("_region")=="base" and game.world.get("_units").size()==2,"empty reconnect snapshot keeps confirmed world")
	await _capture("base")
	game.world.set("_zoom",110.0)
	await _capture("base-landscape")
	_send({"type":"accept_contract"})
	_send({"type":"travel","destination":"rust"})
	_step(20)
	_check(game.simulation.snapshot().region=="rust","rust arrival")
	await _capture("rust-landing")
	var objects: Dictionary=game.world.get("_objects")
	_check(not (objects.satellite as Node3D).visible,"unfound satellite mesh hidden")
	var body: CollisionObject3D=objects.satellite.find_children("*","StaticBody3D",true,false)[0]
	_check(body.collision_layer==0,"unfound satellite cannot be picked")
	_send({"type":"launch"})
	_step(6)
	_send({"type":"radar_scan"})
	_check(game.simulation.snapshot().discovery.signals.size()==3,"three confirmed contacts")
	game.world.set("_focus",Vector3.ZERO)
	game.world.set("_zoom",410.0)
	game.world.set("_flight_camera_follow",false)
	await _capture("rust-radar")
	_send({"type":"ship_move","position":[127,-125]})
	_step(13)
	_check(game.simulation.snapshot().discovery.satellite_found,"proximity identified satellite")
	_send({"type":"land"})
	await create_timer(0.2).timeout
	game.world.focus_home()
	game.world.focus_object("satellite")
	await _capture("rust-discovered")
	_check((objects.satellite as Node3D).visible,"identified wreck visible")
	_send({"type":"salvage","unit_id":"ida"})
	_step(12)
	_check(game.simulation.snapshot().contract.status=="recovered","real salvage completed")
	_send({"type":"travel","destination":"station"})
	_step_until_arrival()
	var seen_space:=false
	var seen_station:=false
	for attempt in range(12):
		var region: String=game.simulation.snapshot().region
		if region=="space":
			seen_space=true
			_send({"type":"ship_move","position":[-25,0]})
			_step(1.8)
			await create_timer(0.2).timeout
			_send({"type":"fire_turret","target_id":"pirate"})
			_step(0.1)
			game.world.focus_home()
			await _capture("space-contact")
			_check(game.world.get("_orbit").beams.size()>0,"confirmed shot produces visible trail")
			_check(game.world.get("_objects").has("pirate"),"freibeuter rendered")
			var camera: Camera3D=game.world.get("_camera")
			var enemy: Node3D=game.world.get("_objects").pirate
			game.world.call("_pick",camera.unproject_position(enemy.position+Vector3(0,5.5,0)))
			_check(picked=="object:pirate","airborne pirate model picking")
			_check((game.world.get("_objects").shuttle as Node3D).get_node("Craft/CrewStations").visible,"gunner station shown")
			game.world.focus_object("shuttle")
			game.world.set("_zoom",25.0)
			game.world.set("_flight_camera_follow",false)
			await _capture("space-gunner")
			_send({"type":"flee"})
			_step(9)
			_check(game.simulation.snapshot().region=="station","escape resumes station journey")
		if game.simulation.snapshot().region=="station":
			seen_station=true
			game.world.focus_home()
			await _capture("station")
		if seen_space and seen_station: break
		_send({"type":"travel","destination":"base"})
		_step(22)
		_send({"type":"travel","destination":"station"})
		_step_until_arrival()
	_check(seen_space and seen_station,"real random contact and station viewed")
	var active_regions:=0
	for child in game.world.get_children():
		if str(child.name).begins_with("Region_"): active_regions+=1
	_check(active_regions==1,"only current region attached")
	var report={"checks":checks,"failures":failures,"regions":["base","rust","space","station"],"career":"isolated","commands":"accept/travel/launch/radar/move/land/salvage/fire/flee","engine":Engine.get_version_info().string,"performance":performance,"measurement_limits":"Three-second rendering samples at fixed confirmed snapshots (auto_tick false), 0.35s warmup, no exclusive machine or universal performance claim."}
	var file:=FileAccess.open(out+"/world-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("WORLD_ORBIT_RESULT ",JSON.stringify(report))
	quit(0 if failures==0 else 1)

func _step(seconds: float) -> void:
	for i in range(int(ceil(seconds/0.1))): game.simulation.advance(0.1)
	game.call("_refresh")

func _step_until_arrival() -> void:
	for i in range(500):
		game.simulation.advance(0.1)
		if not game.simulation.snapshot().travel.active: break
	game.call("_refresh")

func _send(command: Dictionary) -> void:
	var result: Dictionary=game.send_command(command)
	_check(bool(result.get("ok",false)),str(command.type)+": "+str(result.get("reason","")))

func _check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("WORLD_PROBE_FAIL "+label)

func _capture(id: String) -> void:
	await create_timer(0.35).timeout
	if id in ["base","rust-radar","space-contact","station"] and not performance.has(id):
		var samples: Array[float]=[]
		var begin:=Time.get_ticks_usec()
		var last:=begin
		while Time.get_ticks_usec()-begin<3000000:
			await process_frame
			var now:=Time.get_ticks_usec()
			samples.append((now-last)/1000.0)
			last=now
		samples.sort()
		performance[id]={"samples":samples.size(),"median_ms":samples[int(samples.size()*0.5)],"p95_ms":samples[mini(samples.size()-1,int(samples.size()*0.95))],"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_memory_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"viewport":str(root.get_texture().get_size())}
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	_check(root.get_texture().get_image().save_png(out+"/"+id+".png")==OK,"capture "+id)
	var file:=FileAccess.open(out+"/"+id+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(game.simulation.snapshot(),"  "))
	print("WORLD_CAPTURE ",ProjectSettings.globalize_path(out+"/"+id+".png"))
