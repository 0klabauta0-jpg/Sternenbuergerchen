extends SceneTree
const Core=preload("res://scripts/core/simulation_root.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
const Regions=preload("res://scripts/core/regions.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
const Journey=preload("res://tests/n4_test_journey.gd")
const Validator=preload("res://scripts/core/save_validator.gd")
const V4=preload("res://scripts/core/legacy_n4/save_validator.gd")
const V4State=preload("res://scripts/core/legacy_n4/crew_state.gd")
const OldTests=preload("res://tests/crew_migration_test.gd")
const Stage=preload("res://scripts/core/stage_state.gd")
const Ground=preload("res://scripts/core/ground_state.gd")
var checks:=0
var failures:=0
var sim: Node
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func send(kind: String,data: Dictionary={}) -> Dictionary:return Journey.command(sim,kind,data)
func fresh() -> void:
	if is_instance_valid(sim):sim.free()
	sim=Core.new(1);sim.auto_tick=false;root.add_child(sim)
func valid(label: String) -> void:
	var error:=Validator.validate({"schema_version":5,"state":sim.snapshot(),"receipts":{}})
	check(error.is_empty(),label+": "+error)
func run() -> void:
	fresh();valid("fresh schema5")
	check(Catalog.destination_info().size()==30 and Regions.ALL.size()==44,"thirty destinations, forty-four region layers")
	check(Catalog.bounds("space")==600 and Catalog.bounds("orbit")==600,"space 1200m")
	for region: String in Regions.ALL:
		if region in ["space","orbit"]:continue
		var ship: Dictionary=sim.snapshot().ship.duplicate(true)
		ship.position=Catalog.landmarks(Regions.surface(region)).get("shuttle",[0,0]);ship.mode="landed"
		var access: Array=Catalog.landmarks(region).elevator if Regions.underground(region) else Catalog.ship_access(ship)
		for id: String in Catalog.landmarks(region):
			if id in ["shuttle","aa_turret","kitchen","expansion_a","expansion_b"]:continue
			var point: Array=Catalog.interaction_point(region,id)
			check(Nav.walkable(region,Vector2(point[0],point[1]),ship),region+" reachable interaction "+id)
			check(not Nav.path(region,Vector2(access[0],access[1]),Vector2(point[0],point[1]),ship).is_empty(),region+" real route "+id)
	check(Catalog.ground_enemies("distribution_friendly").is_empty() and not Catalog.ground_enemies("distribution").is_empty(),"friendly and hostile depots distinct")
	# Real three-leg trade loop; no credits/cargo injected.
	check(Journey.trip(sim,"station"),"fly to Meridian")
	var start: int=sim.snapshot().credits
	for route: Dictionary in Catalog.TradeRoutes.routes():
		var quantity:=1
		check(send("trade",{"side":"buy","item":route.item,"amount":quantity}).ok,"buy "+route.item)
		check(Journey.trip(sim,route.to),"fly trade leg "+route.to)
		valid("arrival "+route.to)
		check(send("trade",{"side":"sell","item":route.item,"amount":quantity}).ok,"sell "+route.item)
	check(sim.snapshot().credits==start+53,"three real trades yield exactly 53 gross credits")
	valid("completed trade loop")
	# Each bunker has a real surface approach and independent elevator round trip.
	for surface: String in ["bunker_surface","bunker_medium","bunker_hard"]:
		fresh()
		check(Journey.trip(sim,surface),"fly to "+surface)
		var ship_at: Array=sim.snapshot().ship.position.duplicate()
		var enemies: Dictionary=Catalog.ground_enemies(surface)
		check(enemies.size()==[2,3,5][Regions.difficulty(surface)-1],"surface difficulty "+surface)
		# Combat fixture: finite starting armor. Real commands defeat the original enemies.
		for unit: Dictionary in sim._state.crew.values():unit.equipment.armor="armor";unit.equipment.helmet="helmet"
		for enemy_id: String in enemies:
			for attempt in 5:
				if sim.snapshot().ground.enemies[surface][enemy_id].defeated:break
				for id: String in sim.snapshot().crew:
					if sim.snapshot().crew[id].assignment=="idle":send("attack",{"unit_id":id,"target_id":enemy_id})
				sim.advance(35)
			check(sim.snapshot().ground.enemies[surface][enemy_id].defeated,"defeat "+surface+"/"+enemy_id)
		for id: String in sim.snapshot().crew:
			send("attack",{"unit_id":id,"target_id":""});send("move",{"unit_id":id,"position":Catalog.landmarks(surface).bunker_entry})
		sim.advance(60)
		check(send("use_elevator").ok,"actual lift down "+surface)
		var depth:=Regions.elevator_target(surface)
		check(sim.snapshot().region==surface and sim.snapshot().crew.ida.level_region==depth and sim.snapshot().crew.jaro.level_region==depth,"correct crew level "+depth)
		check(sim.snapshot().ship.position==ship_at,"ship stays on its surface")
		valid("underground "+depth)
		check(not send("board",{"unit_id":"ida"}).ok,"no remote boarding from underground")
		check(send("use_elevator").ok and sim.snapshot().region==surface,"correct lift return "+surface)
		valid("lift return")
	# Repair fixture: known finite equipment and damaged hull; operations conserve stock.
	fresh();sim.set_guest(7)
	for item: String in ["backpack","multitool","repair_attachment"]:sim._state.inventory[item]=1
	check(send("move",{"unit_id":"ida","position":Catalog.interaction_point("base","storage")}).ok,"repair worker to store");sim.advance(20)
	for item: String in ["backpack","multitool","repair_attachment"]:
		check(send("equip_item",{"unit_id":"ida","slot":Catalog.Gear.slot_for(item),"item":item,"source":"inventory"}).ok,"equip "+item)
	check(send("backpack_transfer",{"unit_id":"ida","item":"parts","amount":3,"source":"inventory","destination":"backpack"}).ok,"three real repair parts")
	sim._state.ship.condition=40.0
	check(not send("field_repair",{"unit_id":"ida"}).ok,"repair cannot work remotely")
	check(send("move",{"unit_id":"ida","position":Catalog.ship_access(sim.snapshot().ship)}).ok,"walk to actual access");sim.advance(20)
	var request: Dictionary={"type":"field_repair","unit_id":"ida","request_id":"repair-once"}
	check(sim.submit(request,7).ok,"guest repairs shared ship")
	check(sim.snapshot().ship.condition==53 and sim.snapshot().crew.ida.backpack.items.parts==2,"tech3 heals thirteen for one part")
	check(sim.submit(request,7).ok and sim.snapshot().crew.ida.backpack.items.parts==2,"duplicate repair cannot consume twice")
	check(send("field_repair",{"unit_id":"ida"}).ok and send("field_repair",{"unit_id":"ida"}).ok,"remaining finite repairs")
	check(sim.snapshot().ship.condition==70 and not send("field_repair",{"unit_id":"ida"}).ok,"70 percent field limit")
	valid("field repair state")
	# N4 validator and transition are frozen; invalid legacy data never gets upgraded.
	var old_helper:=OldTests.new()
	var old: Dictionary=V4State.migrate(Ground.migrate(Stage.migrate(old_helper.base_v1())))
	old_helper.free()
	check(V4.validate(old).is_empty(),"frozen independent N4 fixture")
	var file:=FileAccess.open("user://n5-legacy.json",FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(sim.load_game("user://n5-legacy.json").ok,"N4 load migrates")
	check(sim.snapshot().schema_version==5 and sim.snapshot().credits==old.state.credits,"version and credits")
	for item: String in old.state.inventory:check(sim.snapshot().inventory[item]==old.state.inventory[item],"legacy inventory "+item)
	valid("migrated N4")
	old.state.inventory.parts=-1
	file=FileAccess.open("user://n5-legacy.json",FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(not sim.load_game("user://n5-legacy.json").ok,"corrupt legacy refused")
	check(sim.save_game("user://n5-roundtrip.json").ok and sim.load_game("user://n5-roundtrip.json").ok,"schema5 disk roundtrip")
	var output:=FileAccess.open("res://output/n5-expansion-result.json",FileAccess.WRITE);output.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "));output.close()
	print("N5_EXPANSION ",checks," checks, ",failures," failures")
	sim.free();quit(1 if failures else 0)
