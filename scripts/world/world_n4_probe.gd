extends "res://scripts/world/world_orbit_probe.gd"
## Isolated real product window. Finite equipment fixture; travel uses real commands.
const Catalog=preload("res://scripts/core/catalog.gd")
const Layout=preload("res://scripts/core/world_layout.gd")
const Geo=preload("res://scripts/world/world_geometry.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")

func _run() -> void:
	out="res://output/n4-world";root.size=Vector2i(1440,900)
	game=load("res://scenes/game.tscn").instantiate();game.load_on_start=false;game.save_path=out+"/isolated-career.json";game.simulation_seed=1
	root.add_child(game);game.simulation.auto_tick=false
	DisplayServer.window_set_title("Sternenbürgerchen · N4 Welt und Schiffsrollen")
	await create_timer(0.6).timeout
	# Explicit bounded fixture avoids pretending that photo equipment was earned.
	for item in ["armor","backpack","multitool","mining_attachment","medgun"]:game.simulation._state.inventory[item]=2
	_send({"type":"move","unit_id":"ida","position":Catalog.interaction_point("base","storage")});_step(20)
	for pair in [["armor","armor"],["backpack","backpack"],["tool","multitool"],["attachment","mining_attachment"]]:
		_send({"type":"equip_item","unit_id":"ida","slot":pair[0],"item":pair[1],"source":"inventory"})
	_send({"type":"move","unit_id":"ida","position":[0,4]});_step(20)
	_check(game.world.get("_objects").has("bed_6"),"six bed models")
	_check_layout("base")
	game.world.set("_focus",Vector3(3,0,0));game.world.set("_zoom",62)
	await _capture("base")
	var parts: Dictionary=game.world.get("_units").ida.get_meta("visible_equipment",{})
	_check(not parts.is_empty(),"equipment real rig attachments")
	if not parts.is_empty():_check(parts.backpack.visible and parts.tool.visible,"backpack and tool visible from equipped snapshot")
	game.world.set("_focus",Vector3(-0.7,0,4.5));game.world.set("_zoom",7.5)
	await _capture("crew-equipment")
	game.world.set("_focus",Vector3(25,0,22));game.world.set("_zoom",22)
	await _capture("entersaebel")
	var craft: Node3D=game.world.get("_objects").shuttle.get_node("Craft")
	_check(craft.has_meta("turret"),"separate turret pivot")
	var bounds: AABB=Geo._bounds(craft,Transform3D.IDENTITY)
	_check(bounds.size.x<=7.55 and bounds.size.z<=11.05,"actual hull fits shared nav footprint")
	_check(Nav.path("base",Vector2(18,22),Vector2(32,22),game.simulation.snapshot().ship).size()>1,"route goes around real ship hull")
	_board()
	_check((craft.get_meta("gunner") as Node3D).visible,"occupied gunner helmet on actual turret")
	await _capture("turret-occupied")
	_send({"type":"launch"});_send({"type":"enter_orbit"});_step(5.2)
	_check(game.simulation.snapshot().region=="orbit","actual orbit climb")
	game.world.set("_focus",Vector3.ZERO);game.world.set("_zoom",95);game.world.set("_flight_camera_follow",false)
	await _capture("orbit")
	for region in ["rust","bunker_surface","distribution","tradepost","station"]:
		if game.simulation.snapshot().region!="orbit":_send({"type":"enter_orbit"});_step(5.2)
		_send({"type":"travel","destination":region});_step(5.2)
		if game.simulation.snapshot().region=="space":
			game.world.set("_zoom",135);await _capture("space-contact")
			_send({"type":"flee"});_step(9)
		_check(game.simulation.snapshot().region==region,"real arrival "+region)
		game.world.set("_flight_camera_follow",false)
		game.world.set("_focus",Vector3.ZERO if region!="station" else Vector3(0,0,12))
		game.world.set("_zoom",130 if region=="bunker_surface" else 270 if region=="distribution" else 90 if region=="tradepost" else 105 if region=="station" else 1000)
		_check_layout(region)
		await _capture(region)
	# Underground is a render-only snapshot fixture; core elevator path is tested by root.
	var snapshot: Dictionary=game.simulation.snapshot();snapshot.region="bunker_depths";snapshot.ship.mode="landed"
	for unit: Dictionary in snapshot.crew.values():unit.assignment="idle";unit.position=[0,25];unit.target=unit.position.duplicate()
	game.set_process(false);game.world.present(snapshot);game.world.set("_focus",Vector3.ZERO);game.world.set("_zoom",120);game.world.set("_flight_camera_follow",false)
	_check_layout("bunker_depths")
	await _capture("bunker-depths-render-fixture")
	var report:={"checks":checks,"failures":failures,"performance":performance,"fixture":"Finite equipment items injected once; equip, boarding, launch, orbit and all surface arrivals use real commands. Underground image is a render-only snapshot fixture.","limits":"3 second rendering samples on a shared desktop; no performance guarantee or complete campaign claim."}
	var file:=FileAccess.open(out+"/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "))
	print("N4_WORLD_RESULT ",JSON.stringify(report));quit(0 if failures==0 else 1)

func _board() -> void:
	_send({"type":"board","unit_id":"ida","role":"pilot"})
	_send({"type":"board","unit_id":"jaro","role":"gunner"});_step(30)
	_check(game.simulation.snapshot().crew.ida.assignment=="aboard" and game.simulation.snapshot().crew.jaro.assignment=="aboard","both walked to boarding access")

func _send(command: Dictionary) -> void:
	super._send(command);game.world.present(game.simulation.snapshot())

func _step(seconds: float) -> void:
	super._step(seconds);game.world.present(game.simulation.snapshot())

func _check_layout(region: String) -> void:
	var map: Node3D=game.world.get("_map")
	for id in Catalog.obstacles(region):
		var spec: Dictionary=Catalog.obstacles(region)[id]
		if str(spec.get("kind",""))=="wall":
			var node:=map.get_node_or_null(("Blocker_"+str(id)).validate_node_name())
			_check(node!=null and node.get_meta("footprint",{})==spec,"wall/nav alignment "+region+"/"+str(id))
		if spec.get("category","")=="furniture":
			var node:=map.get_node_or_null(("Furniture_"+str(id)).validate_node_name())
			_check(node!=null and node.get_meta("footprint",{})==spec,"furniture/nav alignment "+region+"/"+str(id))

func _capture(id: String) -> void:
	await create_timer(0.35).timeout
	if id in ["base","orbit","rust","bunker_surface","distribution","tradepost","station"]:
		var samples: Array[float]=[];var begin:=Time.get_ticks_usec();var last:=begin
		while Time.get_ticks_usec()-begin<3000000:
			await process_frame
			var now:=Time.get_ticks_usec();samples.append((now-last)/1000.0);last=now
		samples.sort();performance[id]={"samples":samples.size(),"p95_ms":samples[mini(samples.size()-1,int(samples.size()*0.95))],"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"obstacles":Catalog.obstacles(str(game.world.get("_region"))).size()}
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	_check(root.get_texture().get_image().save_png(out+"/"+id+".png")==OK,"capture "+id)
	var file:=FileAccess.open(out+"/"+id+".json",FileAccess.WRITE);file.store_string(JSON.stringify(game.world.get("_snapshot"),"  "))
	print("N4_CAPTURE ",id)
