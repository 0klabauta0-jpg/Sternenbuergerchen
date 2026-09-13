extends SceneTree
const Journey=preload("res://tests/n4_test_journey.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
const Core = preload("res://scripts/core/simulation_root.gd")
var sim: Node
var checks: int = 0
var failures: int = 0
var serial: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+label)
func cmd(kind: String,data: Dictionary = {},sender: int = 1) -> Dictionary:
	serial += 1
	var c: Dictionary = data.duplicate(true)
	c.type=kind;c.request_id="n2-%d"%serial
	return sim.submit(c,sender)
func run() -> void:
	sim=Core.new(1);sim.auto_tick=false;root.add_child(sim)
	check(sim.snapshot().schema_version==5,"schema5 retains orbit extensions")
	if sim.snapshot().schema_version!=5:
		sim.free();quit(1);return
	check(sim.snapshot().base.workbench_tier==1,"simple starting workbench")
	check(sim.snapshot().crew.ida.skills.pilot>sim.snapshot().crew.jaro.skills.pilot,"different actual crew profiles")
	check(not cmd("assign_work",{"unit_id":"ida","recipe_id":"cutter"}).ok,"advanced recipe unavailable at start")
	check(cmd("assign_work",{"unit_id":"ida","recipe_id":"helmet"}).ok,"tier1 helmet can be crafted")
	sim.advance(20)
	check(sim.snapshot().inventory.helmet==1,"helmet produced from real materials")
	cmd("move",{"unit_id":"ida","position":Catalog.interaction_point("base","storage")});sim.advance(20)
	check(cmd("equip",{"unit_id":"ida","item":"helmet"}).ok,"inventory helmet can equip crew")
	check(sim.snapshot().inventory.helmet==0 and sim.snapshot().crew.ida.equipment.helmet=="helmet","equipment consumed once")
	cmd("accept_contract");cmd("accept_contract");Journey.trip(sim,"rust")
	check(sim.snapshot().region=="rust" and not sim.snapshot().discovery.satellite_found,"new rust visit starts undiscovered")
	check(not JSON.stringify(sim.snapshot().discovery.signals).contains("satellite"),"hidden discovery snapshot has no satellite identity")
	check(not cmd("salvage",{"unit_id":"jaro"}).ok,"cannot work an undiscovered satellite")
	Journey.board(sim)
	check(cmd("launch").ok,"occupied shuttle starts local flight")
	sim.advance(5)
	check(sim.snapshot().ship.mode=="flying","crew boards for map exploration")
	check(cmd("radar_scan").ok and sim.snapshot().discovery.signals.size()==3,"radar returns three anonymous signals")
	check(not JSON.stringify(sim.snapshot().discovery.signals).contains("satellite"),"radar alone does not identify satellite")
	check(cmd("ship_move",{"position":[145,-103]}).ok,"pointclick ship target accepted")
	cmd("toggle_pause")
	var before: Dictionary=sim.snapshot();sim.advance(20)
	check(sim.snapshot()==before,"pause freezes exploration")
	cmd("toggle_pause");sim.advance(20)
	check(sim.snapshot().discovery.satellite_found,"ship proximity identifies satellite")
	check(cmd("land").ok and sim.snapshot().ship.mode=="landed","land at chosen map position")
	for id: String in sim.snapshot().crew:cmd("disembark",{"unit_id":id})
	check(cmd("salvage",{"unit_id":"jaro"}).ok,"discovered landed satellite can be worked")
	sim.advance(20)
	check(sim.snapshot().contract.status=="recovered","real exploration loop yields blackbox")
	Journey.trip(sim,"base");unload()
	cmd("claim_contract")
	Journey.trip(sim,"station")
	if sim.snapshot().encounter.active:cmd("flee");sim.advance(10)
	cmd("trade",{"side":"buy","item":"parts","amount":2})
	Journey.trip(sim,"base");unload()
	check(cmd("upgrade_workbench",{"unit_id":"ida"}).ok,"upgrade reserves actual worker and materials")
	check(sim.save_game("user://n2-active-upgrade.json").ok and sim.load_game("user://n2-active-upgrade.json").ok,"upgrade reservation survives reload")
	sim.advance(30)
	check(sim.snapshot().base.workbench_tier==2,"upgrade completes tier2")
	check(cmd("assign_work",{"unit_id":"ida","recipe_id":"cutter"}).ok,"tier2 reward recipe works")
	sim.advance(20)
	check(sim.snapshot().inventory.cutter==1,"tier2 output produced")
	# Fixed initial seed makes the production random sequence reproducible, not forced outcomes.
	sim.free();sim=Core.new(3);sim.auto_tick=false;root.add_child(sim)
	to_orbit()
	sim._state.random_seed=3 # deterministic route-roll fixture, after explicit orbit ascent
	var journey: Dictionary={"type":"travel","destination":"station","request_id":"station-once"}
	check(sim.submit(journey).ok,"station route accepted")
	var roll: int=sim.snapshot().travel.encounter_roll
	check(roll>=0 and roll<35,"seeded station trip uses the chance rule")
	check(sim.submit(journey).ok and sim.snapshot().travel.encounter_roll==roll,"repeated travel request never rerolls")
	check(sim.save_game("user://n2-journey.json").ok and sim.load_game("user://n2-journey.json").ok and sim.snapshot().travel.encounter_roll==roll,"accepted travel roll survives save/load")
	sim.advance(12)
	check(sim.snapshot().region=="space" and sim.snapshot().encounter.active,"station route enters independent encounter map")
	sim.set_guest(7)
	check(cmd("ship_move",{"position":[-100,0]},7).ok,"guest can pilot shared shuttle")
	check(cmd("fire_turret",{"target_id":"pirate"}).ok,"host can operate guest gunner")
	check(cmd("fire_turret",{"target_id":"pirate"},7).ok,"guest gunner orders fire")
	cmd("toggle_pause");before=sim.snapshot();sim.advance(20)
	check(sim.snapshot()==before,"pause freezes enemy shots and turret")
	check(sim.save_game("user://n2-combat.json").ok and sim.load_game("user://n2-combat.json").ok,"paused active encounter survives validated reload")
	check(sim.snapshot().crew.jaro.owner==7,"load preserves connected gunner ownership")
	cmd("toggle_pause");sim.advance(20)
	check(sim.snapshot().region=="station" and sim.snapshot().encounter.status=="won","weak pirate defeated and original journey continues")
	check(not cmd("fire_turret",{"target_id":"pirate"},7).ok,"cannot shoot after encounter")
	check(sim.save_game("user://n2-won.json").ok,"resolved encounter can be saved")
	sim.free();sim=Core.new(3);sim.auto_tick=false;root.add_child(sim)
	to_orbit();sim._state.random_seed=3
	cmd("travel",{"destination":"station"});sim.advance(12)
	check(cmd("ship_move",{"position":[-180,80]}).ok,"pilot can choose planar evasive point")
	check(not cmd("ship_move",{"position":[999,0]}).ok,"space bounds validated")
	check(cmd("flee").ok,"host can withdraw")
	check(sim.save_game("user://n2-escape.json").ok and sim.load_game("user://n2-escape.json").ok,"escape countdown preserved")
	sim.advance(10)
	check(sim.snapshot().region=="station" and sim.snapshot().encounter.status=="escaped","escape reaches intended destination without reroll")
	sim.free();sim=Core.new(3);sim.auto_tick=false;root.add_child(sim)
	to_orbit();sim._state.random_seed=3
	cmd("travel",{"destination":"station"});sim.advance(100)
	check(sim.snapshot().region=="base" and sim.snapshot().encounter.status=="rescued","enemy defeat returns crew safely to base")
	check(sim.snapshot().crew.size()==2 and sim.snapshot().ship.condition==50,"rescue retains crew and usable ship")
	check(cmd("enter_orbit").ok,"rescue cannot strand first crew")
	# Independent historical fixtures are retained in crew_migration_test.gd.
	var encounters: int=0
	for initial_seed: int in range(1,101):
		var sample: Node=Core.new(initial_seed)
		sample._state.region="orbit";sample._state.ship.mode="flying";sample._state.ship.position=[0,0];sample._state.ship.target=[0,0]
		for id: String in sample._state.crew:
			var seat: String="pilot" if id=="ida" else "gunner"
			sample._state.ship.seats[seat]=id;sample._state.ship.roles[seat]=id;sample._state.crew[id].seat=seat;sample._state.crew[id].assignment="aboard"
		var result: Dictionary=sample.submit({"type":"travel","destination":"station","request_id":"probability"})
		if result.ok and sample.snapshot().travel.encounter_roll<35:encounters+=1
		sample.free()
	check(encounters==35,"35 of first 100 seeded station trips trigger contact")
	sim.free();sim=Core.new(3);sim.auto_tick=false;root.add_child(sim)
	cmd("accept_contract");Journey.trip(sim,"rust")
	check(sim.snapshot().region=="rust" and not sim.snapshot().encounter.active,"rust journey resolves its possible contact")
	Journey.board(sim);cmd("launch");sim.advance(0.1);cmd("radar_scan")
	check(sim.save_game("user://n2-hidden.json").ok and sim.load_game("user://n2-hidden.json").ok,"unidentified radar contacts survive save/load")
	check(not sim.snapshot().discovery.satellite_found,"reload cannot reveal unknown satellite")
	sim.set_guest(7)
	check(cmd("ship_move",{"position":[145,-103]},7).ok and cmd("radar_scan",{},7).ok,"guest can pilot and scan")
	sim.clear_guest();cmd("toggle_pause")
	check(cmd("ship_move",{"position":[145,-103]}).ok,"host resumes flight after guest disconnect")
	sim.advance(20);cmd("land")
	for id: String in sim.snapshot().crew:cmd("disembark",{"unit_id":id})
	check(cmd("salvage",{"unit_id":"jaro"}).ok,"disconnected guest seat returns to host for actual work")
	sim.advance(2)
	check(sim.save_game("user://n2-working.json").ok and sim.load_game("user://n2-working.json").ok,"new discovered active salvage save remains valid")
	sim.advance(15)
	check(Journey.trip(sim,"base"),"explicit return journey");unload();cmd("claim_contract")
	var paid_once: int=sim.snapshot().credits
	check(sim.save_game("user://n2-claimed.json").ok and sim.load_game("user://n2-claimed.json").ok and not cmd("claim_contract").ok and sim.snapshot().credits==paid_once,"schema2 claim remains once across reload")
	# Invalid orbital metadata must reject atomically rather than change a live campaign.
	var invalid: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://n2-claimed.json"))
	invalid.state.ship.position=[9999,0]
	var file: FileAccess=FileAccess.open("user://n2-invalid.json",FileAccess.WRITE);file.store_string(JSON.stringify(invalid));file.close()
	before=sim.snapshot()
	check(not sim.load_game("user://n2-invalid.json").ok and sim.snapshot()==before,"out-of-bounds saved ship cannot mutate campaign")
	print("N2 CORE: %d checks, %d failures"%[checks,failures])
	sim.free();quit(0 if failures==0 else 1)

func to_orbit() -> void:
	check(Journey.board(sim),"explicit crew boarding")
	check(cmd("launch").ok,"occupied launch")
	check(cmd("enter_orbit").ok,"orbit ascent");sim.advance(5.1)
func unload() -> void:
	for item: String in sim.snapshot().cargo:
		var amount: int=int(sim.snapshot().cargo[item])
		if amount>0:check(cmd("transfer",{"item":item,"amount":amount,"direction":"unload"}).ok,"dock unload "+item)
