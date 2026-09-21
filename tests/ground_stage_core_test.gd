extends SceneTree
const Journey=preload("res://tests/n4_test_journey.gd")
const Core=preload("res://scripts/core/simulation_root.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
const Validator=preload("res://scripts/core/save_validator.gd")
var sim: Node
var failures:=0
var checks:=0
var serial:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+label)
func cmd(kind: String,data: Dictionary={},sender: int=1) -> Dictionary:
	serial+=1
	var c:=data.duplicate(true);c.type=kind;c.request_id="n3-%s"%serial
	var result:Dictionary=sim.submit(c,sender)
	if result.ok and kind in ["trade","transfer"]:check(Journey.finish_hauling(sim),"physical shipment finishes")
	return result
func fresh() -> void:
	if is_instance_valid(sim):sim.free()
	sim=Core.new(1);sim.auto_tick=false;root.add_child(sim)
func trip(destination: String) -> void:
	check(Journey.trip(sim,destination),"explicit N4 journey "+destination)
	check(sim.snapshot().region==destination,"arrived "+destination)
func roundtrip(label: String) -> void:
	var saved: Dictionary=sim.save_game("user://n3-roundtrip.json")
	check(saved.ok,label+" save: "+saved.reason)
	if saved.ok:
		var before: Dictionary=sim.snapshot()
		var loaded: Dictionary=sim.load_game("user://n3-roundtrip.json")
		check(loaded.ok,label+" load: "+loaded.reason)
		var after: Dictionary=sim.snapshot();before.revision=after.revision
		check(_equivalent(before,after),label+" complete state preserved")
func fly_to(point: Array,scan: bool=false) -> void:
	check(Journey.site(sim,point,scan),"board, fly and land outside site")
func move_both(point: Array) -> void:
	for id in ["ida","jaro"]:check(cmd("move",{"unit_id":id,"position":point}).ok,"walk "+id)
	sim.advance(45)
func run() -> void:
	fresh()
	check(sim.snapshot().schema_version==5,"schema5 retains ground stage")
	var saved: Dictionary=sim.save_game("user://n3-initial.json")
	check(saved.ok,"initial save: "+saved.reason)
	check(cmd("assign_work",{"unit_id":"ida","recipe_id":"armor"}).ok,"armor recipe is available")
	sim.advance(30)
	cmd("move",{"unit_id":"ida","position":Catalog.interaction_point("base","storage")});sim.advance(20)
	check(cmd("equip",{"unit_id":"ida","item":"armor"}).ok,"crafted armor is wearable")
	check(is_equal_approx(Catalog.skill_effects(sim.snapshot().crew.ida).armor_reduction,0.35),"armor has explicit actual reduction")
	check(Catalog.skill_effects(sim.snapshot().crew.jaro).ground_damage>Catalog.skill_effects(sim.snapshot().crew.ida).ground_damage,"gunnery changes ground damage")
	check(Catalog.skill_effects(sim.snapshot().crew.ida).gather_multiplier>Catalog.skill_effects(sim.snapshot().crew.jaro).gather_multiplier,"tech changes extraction speed")
	roundtrip("equipped armor")
	trip("bunker_surface")
	cmd("move",{"unit_id":"ida","position":[-12,-5]})
	for index in 600:
		sim.advance(0.05)
		if sim.snapshot().crew.ida.health<100:break
	check(is_equal_approx(sim.snapshot().crew.ida.health,94.8),"actual enemy hit is reduced from8 to5.2 by crafted armor")
	check(not cmd("use_elevator").ok,"lift rejects remote crew")
	check(not cmd("move",{"unit_id":"ida","position":[-24,-10]}).ok,"solid obstacle destination rejected")
	check(cmd("attack",{"unit_id":"ida","target_id":"surface_guard"}).ok,"Ida ground attack")
	check(cmd("attack",{"unit_id":"jaro","target_id":"surface_guard"}).ok,"Jaro ground attack")
	sim.advance(30)
	check(sim.snapshot().ground.enemies.bunker_surface.surface_guard.defeated,"real walking and shots defeat guard")
	var bounty: int=sim.snapshot().credits
	check(not cmd("attack",{"unit_id":"ida","target_id":"surface_guard"}).ok and sim.snapshot().credits==bounty,"dead guard cannot pay twice")
	for id in ["ida","jaro"]:check(cmd("attack",{"unit_id":id,"target_id":"aa_turret"}).ok,"attack AA "+id)
	sim.advance(25)
	check(sim.snapshot().ground.enemies.bunker_surface.aa_turret.defeated,"ground crew neutralizes actual AA")
	check(cmd("gather",{"unit_id":"ida","site_id":"surface_cache"}).ok,"surface find is reachable")
	sim.advance(0.5);roundtrip("active surface extraction")
	cmd("cancel_gather")
	check(sim.snapshot().resources.surface_cache.remaining==4,"cancel consumes no resource")
	move_both([0,12])
	check(cmd("use_elevator").ok and sim.snapshot().region=="bunker_surface" and sim.snapshot().crew.ida.level_region=="bunker_depths","lift changes crew level within persistent site")
	check(not cmd("travel",{"destination":"base"}).ok,"no shuttle teleport out of underground")
	check(not cmd("move",{"unit_id":"ida","position":[100,110]}).ok,"underground void is not walkable")
	check(not Nav.clear("bunker_depths",Vector2(-20,10),Vector2(20,10)),"walls block direct shooting line")
	for id in ["ida","jaro"]:cmd("attack",{"unit_id":id,"target_id":"depth_guard"})
	sim.advance(25)
	check(sim.snapshot().ground.enemies.bunker_depths.depth_guard.defeated,"depth guard fought through real doorway")
	check(cmd("gather",{"unit_id":"ida","site_id":"bunker_cache"}).ok,"underground loot order")
	sim.advance(20)
	check(sim.snapshot().inventory.alloy==2 and sim.snapshot().resources.bunker_cache.remaining==6,"underground find finite and added to carried basis stock")
	roundtrip("underground progress")
	move_both(Catalog.landmarks("bunker_depths").elevator);check(cmd("use_elevator").ok and sim.snapshot().region=="bunker_surface","lift returns to parked ship map")
	check(sim.snapshot().ground.enemies.bunker_surface.aa_turret.defeated,"enemy state persists across maps")
	trip("base")
	# Actual unarmored injury, timed recovery, pause and save.
	fresh();trip("bunker_surface")
	cmd("move",{"unit_id":"ida","position":[-12,-5]})
	for index in 1200:
		sim.advance(0.05)
		if sim.snapshot().crew.ida.health==0:break
	check(sim.snapshot().crew.ida.assignment=="downed","enemy inflicts real wound")
	check(not cmd("move",{"unit_id":"ida","position":[0,0]}).ok,"downed unit cannot move")
	check(not cmd("travel",{"destination":"base"}).ok,"cannot leave downed crew")
	cmd("toggle_pause");var before: Dictionary=sim.snapshot();sim.advance(30)
	check(sim.snapshot()==before,"pause freezes recovery/combat")
	roundtrip("paused wound")
	cmd("toggle_pause");sim.advance(21)
	check(sim.snapshot().crew.ida.health==100 and sim.snapshot().crew.ida.assignment=="idle","timed recovery preserves crew")
	# Flak only damages ships inside its actual airborne radius.
	fresh();trip("bunker_surface")
	Journey.board(sim);cmd("launch");sim.advance(0.1)
	cmd("ship_move",{"position":[-24,-10]});sim.advance(3)
	check(not cmd("land").ok,"cannot land with ship centered in a physical wall")
	# A target inside a wall remains legal in flight but cannot become a ground landing.
	cmd("ship_move",{"position":[-65,70]});sim.advance(3)
	var hull: float=sim.snapshot().ship.condition
	sim.advance(4);check(sim.snapshot().ship.condition==hull,"distant airborne ship safe from AA")
	cmd("ship_move",{"position":[28,-12]});sim.advance(6)
	check(sim.snapshot().ship.condition<hull,"AA damages flying ship in radius")
	cmd("toggle_pause");before=sim.snapshot();sim.advance(8);check(sim.snapshot()==before,"pause freezes AA fire")
	cmd("toggle_pause");sim.advance(25)
	check(sim.snapshot().region=="base" and sim.snapshot().ship.condition==50,"AA defeat safely rescues ship and crew")
	# A real earning route proves the rental is attainable without fixture credits.
	fresh()
	# Tool fixture isolates this finite extraction/rental regression; crafting/equip tested separately.
	sim._state.crew.ida.equipment.tool="multitool";sim._state.crew.ida.equipment.attachment="mining_attachment"
	trip("rust")
	check(not cmd("gather",{"unit_id":"ida","site_id":"mining_site"}).ok,"hidden mining cannot be ordered")
	for batch in 2:
		fly_to([-300,-210],true)
		for job in 4:
			check(cmd("gather",{"unit_id":"ida","site_id":"mining_site"}).ok,"mine actual ore")
			sim.advance(12)
		check(sim.snapshot().cargo.ore==12,"full mining batch in real cargo")
		trip("station")
		check(cmd("trade",{"side":"sell","item":"ore","amount":12}).ok,"sell earned ore")
		if batch==0:trip("rust")
	check(sim.snapshot().credits==1020,"finite mining funds Geier saving goal")
	check(not cmd("rent_ship",{"ship_id":"cutlass"}).ok,"no arbitrary ship rental")
	var request: Dictionary={"type":"rent_ship","ship_id":"vulture","request_id":"rent-once"}
	check(sim.submit(request).ok and sim.submit(request).ok,"rental request idempotent")
	check(sim.snapshot().credits==120 and sim.snapshot().ship.capacity==40 and sim.snapshot().ship.model=="vulture","rental charged once and changes actual ship")
	roundtrip("active rental")
	check(sim.submit(request).ok and sim.snapshot().credits==120,"rental receipt survives reload without another charge")
	sim._state.crew.ida.equipment.attachment="salvage_attachment"
	trip("rust");fly_to([310,250],true)
	check(cmd("gather",{"unit_id":"ida","site_id":"derelict"}).ok,"rental salvages discovered wreck")
	sim.advance(15)
	check(sim.snapshot().cargo.alloy==6,"Geier gives threefold real salvage yield")
	check(cmd("gather",{"unit_id":"ida","site_id":"derelict"}).ok,"second salvage")
	sim.advance(15)
	check(sim.snapshot().cargo.alloy==12,"large rental capacity used")
	cmd("gather",{"unit_id":"ida","site_id":"derelict"});sim.advance(15)
	check(sim.snapshot().cargo.alloy==18,"finite valuable wreck exhausted")
	check(not cmd("gather",{"unit_id":"ida","site_id":"derelict"}).ok,"cannot duplicate depleted salvage")
	cmd("toggle_pause");before=sim.snapshot();sim.advance(1500);check(sim.snapshot()==before,"pause freezes rental clock")
	cmd("toggle_pause");sim.advance(1300)
	check(sim.snapshot().rental.expired and sim.snapshot().ship.capacity==40 and sim.snapshot().cargo.alloy==18,"expiry on remote map preserves cargo and safe return")
	roundtrip("expired remote rental")
	trip("station")
	check(cmd("return_rental").ok,"explicit safe rental handover")
	check(not sim.snapshot().rental.active and sim.snapshot().ship.model=="cutlass" and sim.snapshot().inventory.alloy==18 and sim.snapshot().cargo.alloy==0,"safe rental handover preserves excess cargo")
	# Newly independent maps, market and ownership commands.
	trip("distribution");check(not cmd("trade",{"side":"buy","item":"scrap","amount":1}).ok,"hostile distribution blocks market until secured")
	trip("tradepost");sim.set_guest(7)
	check(cmd("gather",{"unit_id":"jaro","site_id":"tradepost_cache"}).ok,"host can order guest worker")
	check(cmd("cancel_gather",{},7).ok,"guest cancels shared gathering")
	check(cmd("gather",{"unit_id":"jaro","site_id":"tradepost_cache"},7).ok,"guest can gather its own unit")
	check(cmd("cancel_gather").ok,"host cancels shared gathering")
	cmd("gather",{"unit_id":"jaro","site_id":"tradepost_cache"},7)
	sim.advance(80)
	check(sim.snapshot().cargo.parts==2,"distant tradepost cache yields actual parts")
	roundtrip("guest progress")
	fresh();trip("bunker_surface");sim.set_guest(7)
	var ownership_before: Dictionary=sim.snapshot()
	check(cmd("attack",{"unit_id":"jaro","target_id":"surface_guard"}).ok,"host may command guest ground attack")
	check(cmd("attack",{"unit_id":"ida","target_id":"surface_guard"},7).ok,"guest can command host ground attack")
	check(cmd("attack",{"unit_id":"jaro","target_id":"surface_guard"},7).ok,"guest controls its own ground attack")
	cmd("toggle_pause");roundtrip("guest attack paused")
	fresh();trip("bunker_surface")
	sim._state.crew.ida.position=[-12,-5];sim._state.crew.ida.target=[-12,-5];sim._state.crew.ida.health=1.0
	sim._state.ground.enemies.bunker_surface.surface_guard.cooldown=0.0
	check(cmd("board",{"unit_id":"ida","role":"pilot"}).ok,"boarding inside danger starts physical route")
	sim.advance(0.05)
	check(sim.snapshot().crew.ida.assignment=="downed" and sim.snapshot().ship.seats.pilot.is_empty(),"boarding is vulnerable and wound releases reservation")
	roundtrip("wounded boarding")
	_test_corruption()
	var report:=FileAccess.open("res://output/ground-stage-core.json",FileAccess.WRITE)
	if report!=null:
		report.store_string(JSON.stringify({"checks":checks,"failures":failures,"engine":Engine.get_version_info().string,"scope":"Authoritative schema5 with N3 ground mechanics; real commands and simulation time, separate test saves, no normal campaign"},"  "));report.close()
	print("GROUND_STAGE ",checks," checks; ",failures," failures")
	sim.free();quit(1 if failures else 0)

func _test_corruption() -> void:
	fresh()
	for mutation in ["armor","health","stock","rental","enemy","activity","underground_void","wrong_flight_region"]:
		var broken: Dictionary={"schema_version":5,"state":sim.snapshot(),"receipts":{}}
		match mutation:
			"armor":broken.state.crew.ida.equipment.armor="godmode"
			"health":broken.state.crew.ida.health=-1
			"stock":broken.state.resources.derelict.remaining=999
			"rental":broken.state.ship.capacity=40
			"enemy":broken.state.ground.enemies.bunker_surface.surface_guard.defeated=true
			"activity":broken.state.ground.activity.active=true
			"underground_void":
				broken.state.region="bunker_depths"
				broken.state.crew.ida.position=[100,110];broken.state.crew.ida.target=[100,110]
			"wrong_flight_region":
				broken.state.ship.mode="flying"
				for unit: Dictionary in broken.state.crew.values():unit.assignment="aboard";unit.position=broken.state.ship.position.duplicate();unit.target=unit.position.duplicate()
		check(not Validator.validate(broken).is_empty(),"invalid schema5 "+mutation+" rejected")

func _equivalent(a: Variant,b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key: Variant in a:
			if not b.has(key) or not _equivalent(a[key],b[key]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for index in a.size():
			if not _equivalent(a[index],b[index]):return false
		return true
	if (a is float or a is int) and (b is float or b is int):return is_equal_approx(float(a),float(b))
	return a==b
