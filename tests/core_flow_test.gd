extends SceneTree
const Journey=preload("res://tests/n4_test_journey.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")

var failures: int = 0
var checks: int = 0
var serial: int = 0
var sim: Node

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func command(kind: String, data: Dictionary = {}, sender: int = 1) -> Dictionary:
	if kind=="travel":
		var ok: bool=Journey.trip(sim,data.destination)
		if ok and data.destination=="base":
			for item: String in sim.snapshot().cargo:
				var amount: int=int(sim.snapshot().cargo[item])
				if amount>0:Journey.command(sim,"transfer",{"item":item,"amount":amount,"direction":"unload"})
		return {"ok":ok,"reason":"Explicit N4 test journey"}
	serial += 1
	var payload: Dictionary = data.duplicate(true)
	payload.type = kind
	payload.request_id = "test-%d" % serial
	var result:Dictionary=sim.submit(payload,sender)
	if result.ok and kind in ["trade","transfer"]:check(Journey.finish_hauling(sim),"physical delivery completes")
	return result

func prepare_salvage() -> void:
	var state: Dictionary=sim.snapshot()
	if state.region!="rust" or state.travel.active or state.salvage.active:return
	if state.discovery.satellite_found and Vector2(state.ship.position[0],state.ship.position[1]).distance_to(Vector2(145,-125))<40:return
	check(Journey.site(sim,[145,-125],true),"actual scan and safe satellite landing")
func run() -> void:
	if not ResourceLoader.exists("res://scripts/core/simulation_root.gd"):
		check(false, "authoritative simulation exists")
		quit(1)
		return
	var script: Script = load("res://scripts/core/simulation_root.gd")
	sim = script.new(1)
	sim.auto_tick = false
	root.add_child(sim)
	var initial: Dictionary = sim.snapshot()
	check(initial.crew.size() == 2 and initial.credits == 180, "two crew and initial funds")
	check(not command("move", {"unit_id":"ida","position":[0,0]}, 42).ok, "unknown sender denied")
	var denied: Dictionary = {"type":"trade","request_id":"invalid-retry","side":"buy","item":"parts","amount":1}
	check(not sim.submit(denied).ok, "trade outside station denied")
	check(command("assign_work", {"unit_id":"ida","recipe_id":"toolkit"}).ok, "reserve toolkit work")
	check(sim.snapshot().inventory.scrap == 6, "materials reserved immediately")
	check(not command("move", {"unit_id":"ida","position":[0,0]}).ok, "worker cannot move while bound")
	check(sim.snapshot().inventory.toolkit == 0, "walking has no early output")
	command("toggle_pause")
	sim.advance(20.0)
	check(sim.snapshot().inventory.toolkit == 0, "pause stops work")
	command("toggle_pause")
	sim.advance(20.0)
	check(sim.snapshot().inventory.toolkit == 1, "walk and craft produce once")
	check(command("assign_work", {"unit_id":"ida","recipe_id":"repair"}).ok, "reserve repair")
	check(command("cancel_work").ok, "cancel repair")
	check(sim.snapshot().inventory.parts == 2, "cancel refunds materials")
	command("accept_contract")
	check(command("travel", {"destination":"rust"}).ok, "travel accepted")
	check(sim.snapshot().ship.mode == "landed", "explicit journey lands after boarding/orbit")
	sim.advance(0.1)
	check(sim.snapshot().region == "rust", "completed explicit journey reaches rust")
	sim.advance(30.0)
	check(sim.snapshot().region == "rust", "travel arrives")
	prepare_salvage()
	check(command("salvage", {"unit_id":"jaro"}).ok, "salvage assigned")
	sim.advance(1.0)
	check(sim.snapshot().cargo.blackbox == 0, "distant crew cannot salvage instantly")
	var save_path: String = "user://core-flow-test.json"
	check(sim.save_game(save_path).ok, "save while walking to salvage")
	var before: Dictionary = sim.snapshot()
	sim.advance(60.0)
	check(sim.snapshot().contract.status == "recovered", "real walking and salvage recover black box")
	check(sim.load_game(save_path).ok, "load in-progress salvage")
	check(sim.snapshot().cargo == before.cargo, "load restores prior cargo")
	sim.advance(60.0)
	check(sim.snapshot().cargo.blackbox == 1, "reloaded salvage one blackbox")
	command("travel", {"destination":"base"})
	sim.advance(40.0)
	check(command("claim_contract").ok, "claim contract at base")
	check(sim.snapshot().credits == 440 and sim.snapshot().blueprints.has("cutter"), "money and blueprint granted")
	check(not command("claim_contract").ok and sim.snapshot().credits == 440, "cannot claim twice")
	var claim_request: Dictionary = {"type":"trade","request_id":"buy-once","side":"buy","item":"parts","amount":1}
	command("travel", {"destination":"station"})
	sim.advance(40.0)
	check(not sim.submit(denied).ok, "invalid request remains invalid after prerequisites change")
	check(sim.submit(claim_request).ok, "station purchase")
	var credits: int = sim.snapshot().credits
	check(sim.submit(claim_request).ok and sim.snapshot().credits == credits, "duplicate purchase returns receipt without debit")
	check(not command("trade", {"side":"buy","item":"parts","amount":-1}).ok, "negative trade denied")
	check(sim.save_game(save_path).ok, "save after payout")
	check(sim.load_game(save_path).ok, "load after payout")
	check(sim.submit(claim_request).ok and sim.snapshot().credits == credits, "receipt persists across reload")
	var corrupt: FileAccess = FileAccess.open("user://core-corrupt.json", FileAccess.WRITE)
	corrupt.store_string('{"schema_version":1,"state":{"credits":999999}}')
	corrupt.close()
	check(not sim.load_game("user://core-corrupt.json").ok and sim.snapshot().credits == credits, "corrupt load is atomic")
	sim.set_guest(7)
	check(command("move", {"unit_id":"jaro","position":[0,0]}).ok, "host can command guest unit")
	check(command("move", {"unit_id":"jaro","position":[0,0]},7).ok, "guest commands assigned unit")
	check(command("travel", {"destination":"base"},7).ok, "shared crew can travel")
	sim.clear_guest()
	check(sim.snapshot().paused and sim.snapshot().crew.jaro.owner == 1, "disconnect pauses and releases guest seat")
	# A second independent session exercises in-progress reservations and finite resources.
	sim.free()
	sim = script.new(1)
	sim.auto_tick = false
	root.add_child(sim)
	check(not command("assign_work", {"unit_id":"jaro","recipe_id":"toolkit"}).ok, "skill requirement is enforced")
	check(command("assign_work", {"unit_id":"ida","recipe_id":"repair"}).ok, "real repair starts")
	sim.advance(3.0)
	check(sim.snapshot().work.phase == "working", "repair begins at workbench")
	command("toggle_pause")
	check(sim.save_game(save_path).ok, "save paused work reservation")
	check(sim.load_game(save_path).ok, "load paused work reservation")
	var paused_state: Dictionary = sim.snapshot()
	sim.advance(100.0)
	check(sim.snapshot() == paused_state, "loaded pause freezes every state field")
	command("toggle_pause")
	sim.advance(20.0)
	check(sim.snapshot().ship.condition == 100.0 and sim.snapshot().inventory.scrap == 6, "loaded repair finishes once from reservation")
	check(not command("assign_work", {"unit_id":"ida","recipe_id":"repair"}).ok, "fully repaired ship cannot waste materials")
	check(command("assign_work", {"unit_id":"ida","recipe_id":"toolkit"}).ok, "second reservation starts")
	check(sim.save_game(save_path).ok and sim.load_game(save_path).ok, "reservation survives save roundtrip")
	check(command("cancel_work").ok and sim.snapshot().inventory.parts == 2, "cancel loaded reservation refunds exactly once")
	check(not command("cancel_work").ok and sim.snapshot().inventory.parts == 2, "second cancellation cannot mint materials")
	command("accept_contract")
	command("travel", {"destination":"rust"})
	check(sim.save_game(save_path).ok and sim.load_game(save_path).ok, "boarding roundtrip")
	sim.advance(5.8)
	check(sim.snapshot().ship.mode == "landed", "journey completes via explicit landing")
	check(sim.save_game(save_path).ok and sim.load_game(save_path).ok, "flying roundtrip")
	sim.advance(10.0)
	prepare_salvage()
	command("salvage", {"unit_id":"jaro"})
	sim.advance(40.0)
	prepare_salvage()
	# Fixture isolates finite old wreck accounting; dedicated cutter stays usable in N4.
	sim._state.crew.jaro.equipment.tool="cutter"
	check(command("salvage", {"unit_id":"jaro"}).ok, "remaining salvage can be worked again")
	sim.advance(10.0)
	check(sim.snapshot().wreck_remaining == 0 and sim.snapshot().cargo.scrap == 8 and sim.snapshot().cargo.blackbox == 1, "wreck yields finite scrap and one blackbox")
	prepare_salvage()
	check(not command("salvage", {"unit_id":"jaro"}).ok, "empty wreck cannot repeat yield")
	command("travel", {"destination":"station"})
	sim.advance(40.0)
	var before_bad_trade: Dictionary = sim.snapshot()
	check(not command("trade", {"side":"buy","item":"scrap","amount":4}).ok and sim.snapshot().cargo == before_bad_trade.cargo and sim.snapshot().credits == before_bad_trade.credits, "cargo overflow rejects atomically")
	check(command("trade", {"side":"sell","item":"scrap","amount":3}).ok and sim.snapshot().credits == 198, "sale transfers real cargo to credits")
	check(command("trade", {"side":"buy","item":"parts","amount":2}).ok, "usable parts purchased")
	command("travel", {"destination":"base"})
	sim.advance(40.0)
	command("claim_contract")
	check(command("upgrade_workbench", {"unit_id":"ida"}).ok, "workbench upgrade accepted")
	# Include the real ramp approach, but bound the wait to catch stuck workers.
	for second in 60:
		if not sim.snapshot().work.active:break
		sim.advance(1.0)
	check(not sim.snapshot().work.active, "workbench upgrade finishes after ramp approach")
	check(command("assign_work", {"unit_id":"ida","recipe_id":"cutter"}).ok, "reward blueprint and market materials enable cutter")
	sim.advance(20.0)
	check(sim.snapshot().inventory.cutter == 1, "cutter crafted from real inputs")
	check(sim.save_game(save_path).ok, "final save succeeds")
	var original_payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	var corrupt_cases: Array[Dictionary] = []
	var negative: Dictionary = original_payload.duplicate(true)
	negative.state.inventory.scrap = -1
	corrupt_cases.append(negative)
	var teleport: Dictionary = original_payload.duplicate(true)
	teleport.state.crew.ida.position = [9999,0]
	corrupt_cases.append(teleport)
	var unbound: Dictionary = original_payload.duplicate(true)
	unbound.state.crew.ida.assignment = "work"
	corrupt_cases.append(unbound)
	var payout: Dictionary = original_payload.duplicate(true)
	payout.state.contract.status = "recovered"
	corrupt_cases.append(payout)
	for malformed: Dictionary in corrupt_cases:
		var corrupt_file: FileAccess = FileAccess.open("user://core-corrupt.json",FileAccess.WRITE)
		corrupt_file.store_string(JSON.stringify(malformed))
		corrupt_file.close()
		var clean: Dictionary = sim.snapshot()
		check(not sim.load_game("user://core-corrupt.json").ok and sim.snapshot() == clean, "semantic corruption leaves live state unchanged")
	var exposed: Dictionary = sim.snapshot()
	exposed.credits = 9000000
	exposed.crew.ida.position[0] = 9000
	check(sim.snapshot().credits != 9000000 and sim.snapshot().crew.ida.position[0] != 9000, "snapshot is detached from authoritative state")
	check(not command("move", {"unit_id":"ida","position":[NAN,0]}).ok, "nonfinite movement denied")
	check(not command("trade", {"side":"buy","item":"parts","amount":1.5}).ok, "fractional trade denied")
		# Loading crafted stock must make station selling reachable through real commands.
	sim.free()
	sim = script.new(1)
	sim.auto_tick = false
	root.add_child(sim)
	command("assign_work", {"unit_id":"ida","recipe_id":"toolkit"})
	sim.advance(20.0)
	command("move",{"unit_id":"ida","position":Catalog.ship_access(sim.snapshot().ship)});sim.advance(20)
	var load_once: Dictionary = {"type":"transfer","request_id":"load-crafted-once","item":"toolkit","amount":1,"direction":"load"}
	check(sim.submit(load_once).ok, "crafted toolkit can be loaded into shuttle")
	if sim.snapshot().cargo.toolkit == 1:
		check(sim.submit(load_once).ok and sim.snapshot().cargo.toolkit == 1 and sim.snapshot().inventory.toolkit == 0, "duplicate loading cannot create cargo")
		var transfer_before: Dictionary = sim.snapshot()
		check(not command("transfer", {"item":"scrap","amount":-1,"direction":"load"}).ok and sim.snapshot() == transfer_before, "negative transfer is atomic")
		check(not command("transfer", {"item":"scrap","amount":1.5,"direction":"load"}).ok and sim.snapshot() == transfer_before, "fractional transfer is atomic")
		check(not command("transfer", {"item":"scrap","amount":50,"direction":"load"}).ok and sim.snapshot() == transfer_before, "unavailable transfer is atomic")
		check(not command("transfer", {"item":"fuel","amount":1,"direction":"load"}).ok and sim.snapshot() == transfer_before, "unknown transfer item rejected")
		check(not command("transfer", {"item":"scrap","amount":1,"direction":"sideways"}).ok and sim.snapshot() == transfer_before, "unknown transfer direction rejected")
		sim.set_guest(7)
		transfer_before = sim.snapshot()
		check(command("transfer", {"item":"scrap","amount":1,"direction":"load"},7).ok, "guest transfers communal stock")
		sim.clear_guest()
		command("toggle_pause")
		check(command("transfer", {"item":"toolkit","amount":1,"direction":"unload"}).ok and sim.snapshot().inventory.toolkit == 1 and sim.snapshot().cargo.toolkit == 0, "unload returns stock once")
		check(command("transfer", {"item":"toolkit","amount":1,"direction":"load"}).ok, "reload crafted toolkit")
		command("travel", {"destination":"station"})
		transfer_before = sim.snapshot()
		check(not command("transfer", {"item":"parts","amount":1,"direction":"load"}).ok and sim.snapshot() == transfer_before, "transfer blocked during boarding")
		sim.advance(20.0)
		transfer_before = sim.snapshot()
		check(not command("transfer", {"item":"parts","amount":1,"direction":"load"}).ok and sim.snapshot() == transfer_before, "transfer blocked away from base")
		check(command("trade", {"side":"sell","item":"toolkit","amount":1}).ok and sim.snapshot().credits == 230 and sim.snapshot().cargo.toolkit == 0, "crafted loaded toolkit sold at station")
		command("accept_contract")
		command("travel", {"destination":"base"})
		sim.advance(20.0)
		command("accept_contract")
		command("travel", {"destination":"rust"})
		sim.advance(20.0)
		prepare_salvage()
		command("salvage", {"unit_id":"jaro"})
		sim.advance(40.0)
		prepare_salvage()
		sim._state.crew.jaro.equipment.tool="cutter"
		command("salvage", {"unit_id":"jaro"})
		sim.advance(10.0)
		command("travel", {"destination":"base"})
		sim.advance(40.0)
		check(command("transfer", {"item":"scrap","amount":12,"direction":"load"}).ok, "cargo can be filled to capacity")
		transfer_before = sim.snapshot()
		check(not command("transfer", {"item":"parts","amount":1,"direction":"load"}).ok and sim.snapshot() == transfer_before, "capacity overflow transfer is atomic")
		check(command("transfer", {"item":"scrap","amount":1,"direction":"unload"}).ok, "unload opens cargo slot")
		check(command("transfer", {"item":"blackbox","amount":1,"direction":"load"}).ok, "blackbox transfer preserves contract cargo")
		check(not command("claim_contract").ok, "claim requires blackbox in inventory")
		check(command("transfer", {"item":"blackbox","amount":1,"direction":"unload"}).ok and command("claim_contract").ok, "unloaded blackbox can be claimed once")
		# Loading an older paused snapshot must still broadcast a new revision.
	sim.free()
	sim = script.new(1)
	sim.auto_tick = false
	root.add_child(sim)
	command("toggle_pause")
	var saved_target: Array = sim.snapshot().crew.ida.target.duplicate()
	check(sim.save_game(save_path).ok, "paused revision baseline saved")
	command("move", {"unit_id":"ida","position":[15,15]})
	var live_revision: int = sim.snapshot().revision
	check(sim.load_game(save_path).ok, "older paused revision loads")
	check(sim.snapshot().revision > live_revision, "load revision is strictly newer than previous live revision")
	check(sim.snapshot().crew.ida.target == saved_target and sim.snapshot().paused, "load restores paused target while preserving publication progress")
		# Product workers must stand at authoritative approach points outside object meshes.
	sim.free()
	sim = script.new(1)
	sim.auto_tick = false
	root.add_child(sim)
	command("assign_work", {"unit_id":"ida","recipe_id":"toolkit"})
	var work_target: Array = sim.snapshot().crew.ida.target
	check(is_equal_approx(float(work_target[0]),10.0) and is_equal_approx(float(work_target[1]),4.3), "workbench target uses external interaction point")
	sim.advance(3.0)
	var worker_position: Array = sim.snapshot().crew.ida.position
	check(is_equal_approx(float(worker_position[0]),10.0) and is_equal_approx(float(worker_position[1]),4.3) and sim.snapshot().work.phase == "working", "worker performs work at external workbench point")
	check(sim.save_game(save_path).ok and sim.load_game(save_path).ok, "external workbench target survives validated load")
	sim.advance(20.0)
	command("accept_contract")
	command("travel", {"destination":"rust"})
	sim.advance(20.0)
	prepare_salvage()
	command("salvage", {"unit_id":"jaro"})
	var salvage_target: Array = sim.snapshot().crew.jaro.target
	check(is_equal_approx(float(salvage_target[0]),145.0) and is_equal_approx(float(salvage_target[1]),-120.2), "satellite target stands outside central wreck mesh")
	check(sim.save_game(save_path).ok and sim.load_game(save_path).ok, "external satellite target survives validated load")
	sim.advance(6.0)
	worker_position = sim.snapshot().crew.jaro.position
	check(is_equal_approx(float(worker_position[0]),145.0) and is_equal_approx(float(worker_position[1]),-120.2) and sim.snapshot().salvage.phase == "working", "salvage progresses at external satellite point")
	var landing_ship: Array = [-45.0,32.0]
	# Arrival itself was traversed above; fresh arrival keeps both people outside the hull.
	command("cancel_salvage")
	command("travel", {"destination":"base"})
	sim.advance(40.0)
	landing_ship = [25.0,22.0]
	for unit_id: String in ["ida","jaro"]:
		var arrival: Array = sim.snapshot().crew[unit_id].position
		check(Nav.walkable("base",Vector2(arrival[0],arrival[1]),sim.snapshot().ship), "explicit disembark places crew outside hull: " + unit_id)
	print("CORE FLOW: %d checks, %d failures" % [checks, failures])
	sim.free()
	quit(0 if failures == 0 else 1)
