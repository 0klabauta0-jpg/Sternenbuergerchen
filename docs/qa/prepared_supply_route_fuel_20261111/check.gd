extends SceneTree
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	failures += int(not ok)
	print("PASS: " if ok else "FAIL: ",label)
func owner():
	var state = SUPPLY.new()
	state.configure(["ship"])
	state.configure_inventory([], ["ship"], false)
	return state
func command(id: String = "route") -> Dictionary:
	return {"contract_category":"singleplayer_supply","operation":"consume_route_fuel","payload":{"craft_id":"ship","origin_location_id":"homebase","destination_location_id":"polisa"},"request_id":id}
func context(cap: Object) -> Dictionary: return {"route_fuel_authority":cap,"departure_authorized":true,"require_return_reserve":true}
func fingerprint(state) -> String: return JSON.stringify(state.export_state(),"",true)
func run() -> void:
	var state = owner()
	var cap := RefCounted.new()
	var other := RefCounted.new()
	var before := fingerprint(state)
	check(not state.prepare_route_fuel(command(),{"route_fuel_authority":true,"departure_authorized":true}).ok and not state.prepare_route_fuel(command(),context(cap)).ok and fingerprint(state) == before,"Default unbound and UIboolean authority cannot prepare or mutate")
	seed(9713)
	var expected_rng := randi()
	seed(9713)
	var setup = owner()
	var bound: bool = setup.bind_route_fuel_preparation_authority(cap)
	var rng_unchanged := randi() == expected_rng
	check(bound and setup.bind_route_fuel_preparation_authority(cap) and not setup.bind_route_fuel_preparation_authority(other) and rng_unchanged and not setup.prepare_route_fuel(command(),context(other)).ok,"Exact capability binds once and setup consumes no global RNG")
	state.bind_route_fuel_preparation_authority(cap)
	var resource_id: int = state._location_resources.values()[0].get_instance_id()
	var candidate: Dictionary = state.prepare_route_fuel(command(),context(cap))
	var bad_context := context(cap)
	bad_context.require_return_reserve = "yes"
	var missing := command("missing")
	missing.payload.destination_location_id = "unknown"
	check(candidate.ok and not state.prepare_route_fuel(missing,context(cap)).ok and not state.prepare_route_fuel(command("bad-context"),bad_context).ok and fingerprint(state) == before,"Prepare is pure; invalid route and nonboolean reserve proof reject")
	var legacy = owner()
	var old_result: Dictionary = legacy.apply_command(command(),{"departure_authorized":true,"require_return_reserve":true})
	var committed: Dictionary = state.commit_prepared_route_fuel(candidate,cap)
	check(committed == old_result and fingerprint(state) == fingerprint(legacy) and state._location_resources.values()[0].get_instance_id() == resource_id,"Prepared commit exactly matches old Fuel/Revision/Receipt behavior and retains Resourceowner")
	state._fuel_by_craft_id.ship = 0.0
	var replay: Dictionary = state.prepare_route_fuel(command(),context(cap))
	before = fingerprint(state)
	var conflict := command()
	conflict.payload.destination_location_id = "unknown"
	check(replay.ok and state.commit_prepared_route_fuel(replay,cap).get("replayed",false) and not state.prepare_route_fuel(conflict,context(cap)).ok and fingerprint(state) == before,"Replay precedes insufficient reserve/route gates; conflicting ID never writes")
	var tamper_state = owner()
	tamper_state.bind_route_fuel_preparation_authority(cap)
	var genuine: Dictionary = tamper_state.prepare_route_fuel(command(),context(cap))
	var altered := genuine.duplicate(true)
	altered.fuel_after = 999.0
	var foreign = owner()
	foreign.bind_route_fuel_preparation_authority(cap)
	before = fingerprint(tamper_state)
	check(not tamper_state.commit_prepared_route_fuel(altered,cap).ok and not foreign.commit_prepared_route_fuel(genuine,cap).ok and not tamper_state.validate_prepared_route_fuel(genuine,other).ok and fingerprint(tamper_state) == before,"Seal/owner/objectidentity reject tampered and foreign candidates atomically")
	var late = owner()
	late.bind_route_fuel_preparation_authority(cap)
	var pending: Dictionary = late.prepare_route_fuel(command(),context(cap))
	late.apply_command(command("other-charge"),{"departure_authorized":true})
	before = fingerprint(late)
	check(not late.commit_prepared_route_fuel(pending,cap).ok and fingerprint(late) == before,"Changed revision/Fuel invalidates pending candidate without further writes")
	var noop = owner()
	noop.bind_route_fuel_preparation_authority(cap)
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	campaign.configure()
	var job: Dictionary = campaign.get_campaign_snapshot().jobs.satellite_recovery
	var receipt := {"completion_id":"satellite_recovery:completed","job_id":"satellite_recovery","scenario_id":job.scenario_id,"runtime_verified":true,"reward":job.reward}
	var reward := {"contract_category":"singleplayer_supply","operation":"apply_reward","payload":{"completion_id":receipt.completion_id},"request_id":"reward-first"}
	noop.apply_command(reward,{"completion_receipt":receipt})
	pending = noop.prepare_route_fuel(command(),context(cap))
	var revision: int = noop._revision
	reward.request_id = "reward-noop"
	var repeat: Dictionary = noop.apply_command(reward,{"completion_receipt":receipt})
	var unrelated_valid: bool = repeat.get("already_rewarded",false) and noop._revision == revision and noop.validate_prepared_route_fuel(pending,cap).ok
	reward.request_id = "route"
	var same_id_noop: Dictionary = noop.apply_command(reward,{"completion_receipt":receipt})
	check(unrelated_valid and same_id_noop.get("already_rewarded",false) and noop._revision == revision and not noop.validate_prepared_route_fuel(pending,cap).ok,"Unrelated noop receipt stays valid; same requested ID consumed by real noop becomes stale without revision")
	var config = owner()
	config.bind_route_fuel_preparation_authority(cap)
	pending = config.prepare_route_fuel(command(),context(cap))
	revision = config._revision
	config.register_craft("new-ship")
	var unrelated_registration_valid: bool = config.validate_prepared_route_fuel(pending,cap).ok and config._revision == revision
	config.configure_inventory(["new-person"],["ship","new-ship"],true)
	var inventory_valid: bool = config.validate_prepared_route_fuel(pending,cap).ok and config._revision == revision
	config._fuel_by_craft_id.erase("ship")
	var missing_craft_stale: bool = not config.validate_prepared_route_fuel(pending,cap).ok
	config.register_craft("ship",45.0)
	check(unrelated_registration_valid and inventory_valid and missing_craft_stale and config._revision == revision and not config.validate_prepared_route_fuel(pending,cap).ok,"Other craft/container setup stays valid; selected craft fuel absence or reregistration change becomes stale without revision")
	var definitions = owner()
	definitions.bind_route_fuel_preparation_authority(cap)
	pending = definitions.prepare_route_fuel(command(),context(cap))
	definitions._definitions.route_fuel_costs["homebase>trade_outpost"] = 123.0
	var unrelated_route_valid: bool = definitions.validate_prepared_route_fuel(pending,cap).ok
	definitions._definitions.route_fuel_costs["polisa>homebase"] = 99.0
	before = fingerprint(definitions)
	check(unrelated_route_valid and not definitions.validate_prepared_route_fuel(pending,cap).ok and not definitions.prepare_route_fuel(command(),context(cap)).ok and fingerprint(definitions) == before,"Unrelated route stays valid; selected reverse-reserve change invalidates preparation and fresh gate")
	var reset = owner()
	reset.bind_route_fuel_preparation_authority(cap)
	pending = reset.prepare_route_fuel(command(),context(cap))
	reset.configure(["ship"])
	reset.configure_inventory([], ["ship"],false)
	check(not reset.prepare_route_fuel(command(),context(cap)).ok and reset.bind_route_fuel_preparation_authority(other) and not reset.validate_prepared_route_fuel(pending,other).ok,"Configure resets capability and invalidates candidates even for equal restored gameplay")
	var isolated = owner()
	isolated.bind_route_fuel_preparation_authority(cap)
	var caller_command := command()
	pending = isolated.prepare_route_fuel(caller_command,context(cap))
	caller_command.payload.destination_location_id = "unknown"
	var validated: Dictionary = isolated.validate_prepared_route_fuel(pending,cap)
	pending.result.fuel_cost = 999.0
	var published: Dictionary = isolated._publish_prepared_route_fuel(pending,validated)
	validated.patch.receipt.result.fuel_cost = 888.0
	check(published.fuel_cost == 10.0 and isolated._fuel_by_craft_id.ship == 50.0 and isolated._requests.route.result.fuel_cost == 10.0,"Candidate and validated patch are detached; private no-fail tail uses only checked copy")
	print("PREPARED_SUPPLY_ROUTE_FUEL checks=",checks," failures=",failures)
	quit(int(failures > 0))


