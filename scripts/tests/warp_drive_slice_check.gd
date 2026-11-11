extends SceneTree
## Bounded real-owner path; no mission actors, GPU, user-save IO or wide matrix.
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const ROOT = preload("res://scripts/core/simulation_root.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const CATALOG = preload("res://scripts/mission/ship_equipment_catalog.gd")
var checks := 0
var failures := 0
var sequence := 0
var definitions: Array = [{"craft_id":"ship", "craft_type":"dropship", "model_id":"cutlass"}, {"craft_id":"legacy", "craft_type":"dropship"}]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	failures += int(not ok)
	print("PASS: " if ok else "FAIL: ", label)
func world(defs: Array) -> Dictionary:
	var supply = SUPPLY.new()
	supply.configure(defs)
	var ids: Array = []
	for definition: Dictionary in defs: ids.append(definition.craft_id)
	supply.configure_inventory([], ids, false)
	var equipment = EQUIPMENT.new()
	equipment.configure(defs)
	var travel = FLEET.new()
	travel.configure()
	for id: String in ids: travel.register_craft(id)
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, supply, null, travel)
	sim.configure_ship_equipment(equipment)
	return {"supply":supply, "equipment":equipment, "travel":travel, "sim":sim}
func command(w: Dictionary, category: String, operation: String, payload: Dictionary, id: String = "", extra: Dictionary = {}) -> Dictionary:
	sequence += 1
	var context := {"location_id":"polisa", "craft_id":String(payload.get("craft_id", "")), "craft_busy":false, "station_service_verified":true, "ship_component_model_id":String(w.equipment.get_snapshot(String(payload.get("craft_id", ""))).get("model_id", "")), "runtime_authorized":true}
	context.merge(extra, true)
	return w.sim.request_singleplayer_command({"contract_category":category, "operation":operation, "payload":payload, "request_id":id if not id.is_empty() else "warp-check:"+str(sequence)}, context)
func buy(w: Dictionary, craft: String = "ship", id: String = "buy") -> Dictionary:
	return command(w, "singleplayer_supply", "buy", {"craft_id":craft, "offer_id":"polisa_warp_hemera", "quantity":1}, id)
func install_args(w: Dictionary, item: String = "warp_hemera", craft: String = "ship") -> Dictionary:
	return {"craft_id":craft, "slot_id":"quantum_drive", "item_id":item, "source_container_id":"craft:"+craft, "expected_equipment_revision":int(w.equipment.get_snapshot().revision)}
func install(w: Dictionary, item: String = "warp_hemera", id: String = "install", extra: Dictionary = {}) -> Dictionary:
	return command(w, "singleplayer_supply", "station_install_ship_component", install_args(w,item), id, extra)
func fingerprint(w: Dictionary) -> String: return JSON.stringify([w.supply.export_state(), w.equipment.export_state()], "", true)
func snapshot(w: Dictionary, id: String = "ship") -> Dictionary: return w.travel.get_snapshot(id)
func run() -> void:
	var data := CATALOG.definition()
	check(data.schema_version == 1 and data.quality_order == ["D","C","B","A"] and data.items.warp_odyssey.quality == "C" and data.items.warp_hemera.quality == "A" and is_equal_approx(CATALOG.multiplier("warp_hemera"),238314.0/326114.0), "Shipped sourced Warp catalog has correct qualities and finite positive ratio")
	var w := world(definitions)
	check(w.equipment.get_snapshot("ship").slots.quantum_drive == "warp_odyssey" and w.equipment.get_snapshot("legacy").slots.is_empty() and w.equipment.get_quantum_effect("legacy").quantum_duration_multiplier == 1.0, "Explicit Cutlass defaults Odyssey; generic legacy remains baseline without slot")
	var missing := world([definitions[0]])
	missing.supply._inventory.clear()
	var missing_before := fingerprint(missing)
	check(not buy(missing,"ship","missing-cargo").ok and fingerprint(missing) == missing_before, "Component purchase cannot use global inventory fallback without real craft cargo")
	missing.sim.free()
	var before := fingerprint(w)
	check(not buy(w,"legacy","legacy-buy").ok and fingerprint(w) == before, "Unsourced legacy cannot buy a supposedly usable Warp part")
	check(not install(w).ok and fingerprint(w) == before, "Missing purchased part leaves both owners unchanged")
	check(buy(w).ok and w.supply.get_supply_snapshot().credits == 340 and w.supply.get_supply_snapshot().inventory["craft:ship"].items.warp_hemera == 1 and w.supply.get_supply_snapshot().stock_by_offer_id.polisa_warp_hemera == 3, "Real finite-stock purchase160Cr goes to exact craft cargo")
	before = fingerprint(w)
	check(buy(w).get("replayed", false) and fingerprint(w) == before, "Purchase request replay charges once")
	var args := install_args(w)
	for override: Dictionary in [{"craft_busy":true}, {"station_service_verified":false}, {"location_id":"homebase"}]:
		check(not command(w,"singleplayer_supply","station_install_ship_component",args,"blocked:"+str(sequence),override).ok and fingerprint(w) == before, "Wrong service/airborne evidence rejects atomically " + JSON.stringify(override))
	var bad := args.duplicate(true)
	bad.slot_id = "weapon"
	check(not command(w,"singleplayer_supply","station_install_ship_component",bad,"bad-slot").ok and fingerprint(w) == before, "Wrong slot rejects without cargo mutation")
	bad = args.duplicate(true)
	bad.expected_equipment_revision = 1.5
	check(not command(w,"singleplayer_supply","station_install_ship_component",bad,"fractional").ok and fingerprint(w) == before, "Fractional expected revision never truncates into authority")
	var publication := {"consistent":false}
	w.sim.singleplayer_command_committed.connect(func(cmd: Dictionary, result: Dictionary):
		if cmd.operation == "station_install_ship_component" and result.get("ok", false): publication.consistent = w.equipment.get_snapshot("ship").slots.quantum_drive == "warp_hemera" and w.supply.get_supply_snapshot().inventory["craft:ship"].items.get("warp_odyssey",0) == 1)
	check(command(w,"singleplayer_supply","station_install_ship_component",args,"install").ok and publication.consistent, "Actual Root publishes only after fitted Hemera and returned Odyssey agree")
	check(w.supply.get_supply_snapshot().credits == 340 and w.equipment.get_snapshot().revision == 1 and not w.supply.get_supply_snapshot().inventory["craft:ship"].items.has("warp_hemera"), "Install consumes purchased part with no second charge")
	before = fingerprint(w)
	check(command(w,"singleplayer_supply","station_install_ship_component",args,"install").get("replayed",false) and fingerprint(w) == before, "Install replay never consumes or returns twice")
	bad = args.duplicate(true)
	bad.item_id = "warp_odyssey"
	check(not command(w,"singleplayer_supply","station_install_ship_component",bad,"install").ok and fingerprint(w) == before, "Conflicting ID is rejected before owner mutation")
	check(not command(w,"singleplayer_supply","station_install_ship_component",args,"stale").ok and fingerprint(w) == before, "Stale expected revision is rejected")
	check(not install(w,"warp_hemera","same").ok and fingerprint(w) == before, "Same installed part does not manufacture a returned copy")
	for id: String in ["ship","legacy"]: command(w,"singleplayer_space_travel","launch_to_orbit",{"craft_id":id})
	check(command(w,"singleplayer_space_travel","start_quantum",{"craft_id":"ship","target_orbit_id":"planet_orbit","quantum_duration_multiplier":0.001},"jump").ok and is_equal_approx(snapshot(w).duration_seconds,3.0*238314.0/326114.0), "Actual Root+Travel uses equipped owner ratio and ignores UI effect")
	command(w,"singleplayer_space_travel","start_quantum",{"craft_id":"legacy","target_orbit_id":"planet_orbit"},"legacy-jump")
	check(snapshot(w,"legacy").duration_seconds == 3.0, "Other craft keeps its own full baseline duration")
	# Force a later trusted re-fit while airborne solely to prove jump freezing;
	# product Adapter rejects such service evidence before this Root domain edge.
	check(install(w,"warp_odyssey","refit").ok, "Returned Odyssey can be installed back through real owners")
	check(is_equal_approx(snapshot(w).duration_seconds,3.0*238314.0/326114.0), "Later equipment change cannot alter already-started duration")
	command(w,"singleplayer_space_travel","advance",{"delta_seconds":2.3})
	check(snapshot(w).phase == "orbit" and snapshot(w,"legacy").phase == "quantum" and snapshot(w,"legacy").progress < 1.0, "Two real travel owners arrive at different fitted durations")
	command(w,"singleplayer_space_travel","start_quantum",{"craft_id":"ship","target_orbit_id":"moon_orbit"},"next-jump")
	check(snapshot(w).duration_seconds == 3.0, "Next jump reads new fitted Odyssey")
	var travel_before := snapshot(w)
	check(command(w,"singleplayer_space_travel","start_quantum",{"craft_id":"ship","target_orbit_id":"moon_orbit"},"next-jump").get("replayed",false) and snapshot(w) == travel_before, "Travel replay preserves frozen duration and progress")
	command(w,"singleplayer_space_travel","abort_quantum",{"craft_id":"ship"})
	var raw_travel = load("res://scripts/core/singleplayer_space_travel_state.gd").new()
	raw_travel.configure()
	raw_travel.apply_command({"contract_category":"singleplayer_space_travel","operation":"launch_to_orbit","payload":{"craft_id":"raw"},"request_id":"launch"},{"runtime_authorized":true})
	var raw_before: Dictionary = raw_travel.get_snapshot()
	check(not raw_travel.apply_command({"contract_category":"singleplayer_space_travel","operation":"start_quantum","payload":{"craft_id":"raw","target_orbit_id":"planet_orbit"},"request_id":"invalid"},{"quantum_duration_multiplier":NAN}).ok and raw_travel.get_snapshot() == raw_before, "Invalid trusted effect fails before any travel write")
	var full := world([definitions[0]])
	buy(full)
	full.supply._inventory["craft:ship"].items.ore = 47
	check(install(full).ok and full.supply.get_supply_snapshot().inventory["craft:ship"].items.ore == 47, "Full cargo permits net1-for1 replacement and returns old drive")
	var saved_supply: Dictionary = JSON.parse_string(JSON.stringify(w.supply.export_state()))
	var saved_equipment: Dictionary = JSON.parse_string(JSON.stringify(w.equipment.export_state()))
	var fresh_supply = SUPPLY.new()
	check(fresh_supply.restore_state(saved_supply).ok, "Real Supply validates component request receipts on JSON restore")
	var fresh_equipment = EQUIPMENT.new()
	check(fresh_equipment.restore_state(saved_equipment,definitions,saved_supply.requests,saved_supply.inventory).ok and fresh_equipment.get_snapshot() == w.equipment.get_snapshot(), "Equipment+Supply JSON roundtrip preserves history and installed identity")
	var stable := JSON.stringify(fresh_equipment.export_state(),"",true)
	for attack: String in ["catalog","foreign","item","receipt","effect","missing-history"]:
		var forged := saved_equipment.duplicate(true)
		match attack:
			"catalog": forged.catalog_version = 9
			"foreign": forged.crafts.foreign = forged.crafts.ship.duplicate(true)
			"item": forged.crafts.ship.slots.quantum_drive = "warp_hemera"
			"receipt": forged.installs.install.previous_item_id = "warp_hemera"
			"effect": forged.quantum_duration_multiplier = 0.001
			"missing-history": forged.installs.erase("install")
		check(not fresh_equipment.restore_state(forged,definitions,saved_supply.requests,saved_supply.inventory).ok and JSON.stringify(fresh_equipment.export_state(),"",true) == stable, "Rejected equipment tampering leaves live state intact: "+attack)
	var forged_supply := saved_supply.duplicate(true)
	forged_supply.requests.install.result.previous_item_id = "nonsense"
	check(not SUPPLY.new().restore_state(forged_supply).ok, "Supply itself rejects forged component receipt")
	forged_supply = saved_supply.duplicate(true)
	forged_supply.inventory["craft:ship"].items.warp_hemera += 1
	check(not EQUIPMENT.new().restore_state(saved_equipment,definitions,forged_supply.requests,forged_supply.inventory).ok, "Cross-owner component conservation rejects duplicated cargo")
	check(not EQUIPMENT.new().validate_legacy(definitions,saved_supply.requests,saved_supply.inventory).ok, "Deleting equipment subsection cannot erase paid install history")
	checkpoint_checks()
	w.sim.free()
	full.sim.free()
	print("WARP_DRIVE_SLICE checks=",checks," failures=",failures)
	quit(int(failures > 0))
func checkpoint_checks() -> void:
	var defs := [definitions[0]]
	var w := world(defs)
	var roster: Array = load("res://scripts/meta/campaign_start_configuration.gd").new()._initial_roster()
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	campaign.configure({}, {}, true)
	var onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
	onboarding.configure()
	var payload := {"schema_version":1,"roster":roster,"craft":{"definition":defs[0],"pilot_id":roster[1].unit_id},"fleet":[{"definition":defs[0],"pilot_id":roster[1].unit_id,"location":"homebase"}],"campaign":campaign.export_state(),"supply":w.supply.export_state(),"onboarding":onboarding.export_state()}
	var old := payload.duplicate(true)
	old.supply.definitions.offers.erase("polisa_warp_hemera")
	old.supply.stock_by_offer_id.erase("polisa_warp_hemera")
	check(STORE.validate_payload(old).ok, "Actual CheckpointStore accepts old home checkpoint without equipment or new offer")
	buy(w)
	install(w)
	payload.supply = w.supply.export_state()
	payload.ship_equipment = w.equipment.export_state()
	payload = JSON.parse_string(JSON.stringify(payload))
	var validation: Dictionary = STORE.validate_payload(payload)
	if not validation.ok: print("CHECKPOINT_DIAGNOSTIC ",validation)
	check(validation.ok, "Actual CheckpointStore accepts new fitted home checkpoint JSON")
	payload.erase("ship_equipment")
	check(not STORE.validate_payload(payload).ok, "Actual CheckpointStore rejects removed equipment section after installation")
	payload.ship_equipment = w.equipment.export_state()
	payload.ship_equipment.crafts.ship.model_id = "buccaneer"
	check(not STORE.validate_payload(payload).ok, "Actual CheckpointStore rejects model mismatch before runtime restore")
	w.sim.free()
