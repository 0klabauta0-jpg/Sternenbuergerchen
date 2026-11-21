extends SceneTree
## Real Root/Fleet/Supply/Combat/Encounter owners at an explicit boundary fixture.
## Prior departure and local poses are setup, not a claimed five-mission run.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
var passed := 0
var failed := 0

# Only a presentation callback is substituted. Travel, result recording,
# campaign failure receipts and fuel below use their production owners.
class FlowRefreshProbe extends Node:
	var refreshes := 0
	func _refresh_homebase_screen() -> void: refreshes += 1

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func _run() -> void:
	for outcome in ["aborted", "victory", "defeat"]:
		_run_case(outcome)
	_run_case("defeat", true)
	_test_adapter_retry()
	_test_stranded_in_approach()
	_test_old_branch_without_combat_owner()
	print("ASTRA_ENCOUNTER_RETURN_FIXES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _fixture(with_campaign: bool = false) -> Dictionary:
	var fleet = load("res://scripts/core/singleplayer_fleet_travel_state.gd").new()
	check(fleet.configure().get("ok", false), "fleet configured")
	var craft := "astra_player"
	fleet.register_craft(craft)
	var travel = fleet.get("_owners")[craft]
	travel.set("_phase", "approach")
	travel.set("_craft_id", craft)
	travel.set("_location_id", "distress_orbit")
	travel.set("_orbit_id", "planet_orbit")
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	check(supply.configure([{"craft_id":craft}]).get("ok", false), "supply configured")
	var sim = load("res://scripts/core/simulation_root.gd").new()
	sim.is_server_authoritative = false
	var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	var encounter = load("res://scripts/core/campaign_space_encounter.gd").new()
	var campaign: RefCounted
	var flow: FlowRefreshProbe
	if with_campaign:
		campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
		check(campaign.configure({}, {}, false).get("ok", false), "actual campaign owner configured with fixture sequence bypass")
		flow = FlowRefreshProbe.new()
		adapter.set("_campaign", campaign)
		adapter.set("_campaign_mode", true)
		adapter.set("_flow", flow)
	sim.configure_singleplayer_owners(campaign, supply, null, fleet)
	check(sim.configure_departure_adapter(adapter).get("ok", false), "actual adapter bound")
	sim.configure_space_encounter(encounter)
	adapter.set("_simulation", sim)
	adapter.set("_travel", fleet)
	adapter.set("_supply", supply)
	adapter.set("_space_encounter", encounter)
	adapter.set("_departure_token_by_craft", {craft:"astra-departure"})
	var combat: RefCounted = sim.get("_space_combat_state")
	var ids := {"player":craft, "hostile":"hostile_cutlass", "neutral":"neutral_buccaneer"}
	for role in ["player", "hostile", "neutral"]:
		var cell := Vector2i(10 + ["player", "hostile", "neutral"].find(role) * 3, 10)
		var flight: RefCounted = fleet.get_flight_state(craft) if role == "player" else load("res://scripts/core/space_flight_state.gd").new()
		check(flight.configure(ids[role], {"position_plane":Vector2.ZERO}).get("ok", false), role + " flight configured")
		var proposal := {"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:planet", "position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical", "heading_rad":0.0}
		var movement: Dictionary = flight.validate_area_transition(proposal, 1)
		var admitted: Dictionary = combat.validate_new_local_admission({"craft_id":ids[role], "faction_id":role, "control_domain":"enemy" if role == "hostile" else role, "footprint_hexes":[Vector2i.ZERO]}, flight, proposal, 1)
		if not check(movement.get("ok", false) and admitted.get("ok", false), role + " real admission preflight"): break
		flight._publish_area_transition(movement)
		combat._publish_new_local_admission(admitted)
		check(combat.bind_ship_systems(ids[role], CATALOG.effective_stats("buccaneer", CATALOG.default_loadout("buccaneer")), 8.0).get("ok", false), role + " real systems bound")
	check(encounter.start_encounter(craft, true).get("ok", false), "encounter enters prepared phase")
	check(sim.bind_campaign_space_combat(ids, {"runtime_authorized":true}).get("ok", false), "Root binds actual fleet/combat identities")
	sim.get("_departure_group_receipts")["astra-departure"] = {"craft_id":craft, "result":{"departure":{"destination_location_id":"distress_orbit"}}, "supply":supply, "supply_epoch":supply.get("_route_prepare_epoch"), "fleet":fleet, "flight":fleet.get_flight_state(craft)}
	if with_campaign:
		var departure := {"craft_id":craft, "origin_location_id":"homebase", "destination_location_id":"distress_orbit", "landing_pad_id":"homebase_pad_01", "job_id":"buccaneer_rescue"}
		for action: Dictionary in [{"operation":"accept_job", "payload":{"job_id":"buccaneer_rescue"}}, {"operation":"bind_departure", "payload":departure}, {"operation":"activate_job", "payload":{"craft_id":craft, "job_id":"buccaneer_rescue"}}]:
			var command := {"contract_category":"singleplayer_campaign", "operation":action.operation, "payload":action.payload, "request_id":"astra-fixture:" + String(action.operation)}
			check(sim.request_singleplayer_command(command, {"departure_authorized":true}).get("ok", false), "actual campaign " + String(action.operation))
	return {"sim":sim, "adapter":adapter, "fleet":fleet, "travel":travel, "supply":supply, "combat":combat, "encounter":encounter, "craft":craft, "campaign":campaign, "flow":flow}

func _run_case(outcome: String, player_loss: bool = false) -> void:
	var before_failures := failed
	var f := _fixture()
	if failed != before_failures:
		f.adapter.free(); f.sim.free(); return
	var request := "encounter-return:astra-departure"
	var supply_before: Dictionary = f.supply.export_state()
	check(not f.sim.commit_campaign_space_return(f.adapter, f.craft, request).get("ok", false), "unfinished encounter cannot return")
	check(f.supply.export_state() == supply_before and f.travel.get_snapshot().phase == "approach", "unfinished rejection does not publish")
	if outcome == "aborted":
		check(f.sim.request_singleplayer_command(_command("retreat")).get("ok", false), "actual Root retreat")
	else:
		var target: String = f.craft if player_loss else ("hostile_cutlass" if outcome == "victory" else "neutral_buccaneer")
		var shooter: String = "hostile_cutlass" if player_loss else f.craft
		# Actual damage owner consumes unique, resolved impact fixtures.
		for index in range(30):
			if float(f.combat.get_ship_systems(target).state.hull) <= 0.0: break
			check(f.combat._commit_ship_impact({"id":"impact-" + str(index), "shooter_id":shooter, "hit_craft_id":target, "weapon_slot":"weapon_1", "damage":4.0}).get("ok", false), "damage fixture reaches actual ship owner")
			f.combat.advance_ship_systems(1.0)
		check(f.sim.request_singleplayer_command(_command("advance", {"delta_seconds":1.0}), {"runtime_authorized":true}).get("ok", false), "Root observes actual combat hulls")
		if outcome == "victory": check(f.sim.request_singleplayer_command(_command("rescue")).get("ok", false), "actual rescue command completes victory")
	check(f.encounter.get_snapshot().phase == outcome, "terminal outcome " + outcome)
	if player_loss: check(float(f.combat.get_ship_systems(f.craft).state.hull) == 0.0 and float(f.combat.get_ship_systems("neutral_buccaneer").state.hull) > 0.0, "fourth case is actual player-hull defeat with surviving neutral")
	check(not f.sim.request_singleplayer_command(_command("retreat")).get("ok", false), "closed result cannot be replaced by retreat")
	var pending: Dictionary = f.encounter.peek_completed_result()
	var pose_before: Dictionary = f.fleet.get_flight_state(f.craft).get_snapshot()
	var foreign := Node.new()
	check(not f.sim.commit_campaign_space_return(foreign, f.craft, request).get("ok", false), "foreign adapter rejected")
	foreign.free()
	f.sim.is_processing_tick = true
	check(f.sim.commit_campaign_space_return(f.adapter, f.craft, request).get("reason") == "simulation_busy", "busy transaction is retryable")
	f.sim.is_processing_tick = false
	f.travel.set("_location_id", "satellite_crash")
	check(not f.sim.commit_campaign_space_return(f.adapter, f.craft, request).get("ok", false), "mismatching location rejects prepared transition")
	f.travel.set("_location_id", "distress_orbit")
	check(f.supply.export_state() == supply_before and f.encounter.peek_completed_result() == pending, "rejections preserve fuel and pending result")
	var fuel_before := float(f.supply.get_supply_snapshot().fuel_by_craft_id[f.craft])
	f.supply.get("_fuel_by_craft_id")[f.craft] = 0.0
	# Regel 8 / Auftrag 21.11.: der Grund heisst jetzt leg_fuel_insufficient (Etappe surface_exit), der Ablauf bleibt gleich.
	check(f.sim.commit_campaign_space_return(f.adapter, f.craft, request).get("reason") == "leg_fuel_insufficient", "insufficient fuel rejects entire prepared return")
	check(f.travel.get_snapshot().phase == "approach" and f.combat.get_actor("hostile_cutlass") != null and f.combat.get_actor("neutral_buccaneer") != null, "failed fuel does not remove contacts or change travel")
	f.supply.get("_fuel_by_craft_id")[f.craft] = fuel_before
	# Regel 8 / Auftrag 21.11.: der Ortsabflug bucht nur seinen Etappenanteil (surface_exit); der Heimsprung bucht spaeter selbst.
	var expected: Dictionary = f.supply.preview_leg_fuel({"craft_id":f.craft, "leg":"surface_exit", "origin_location_id":"distress_orbit", "destination_location_id":"homebase"}, {"departure_authorized":true})
	var result: Dictionary = f.sim.commit_campaign_space_return(f.adapter, f.craft, request)
	if not check(result.get("ok", false), "actual Root completes " + outcome + " return"):
		print("RETURN_FAILURE ", result); f.adapter.free(); f.sim.free(); return
	var travel: Dictionary = f.fleet.get_craft_snapshot(f.craft)
	check(travel.phase == "orbit" and travel.orbit_id == "planet_orbit" and String(travel.location_id).is_empty(), "return publishes canonical orbit instead of home landing")
	check(f.fleet.get_flight_state(f.craft).get_snapshot() == pose_before and f.combat.get_actor(f.craft) == f.fleet.get_flight_state(f.craft), "same live player flight and pose retained")
	if player_loss: check(float(f.combat.get_ship_systems(f.craft).state.hull) == 0.0, "terminal return does not invent repair of destroyed player hull")
	check(f.combat.get_actor("hostile_cutlass") == null and f.combat.get_actor("neutral_buccaneer") == null, "completed encounter contacts retired")
	check(is_equal_approx(float(f.supply.get_supply_snapshot().fuel_by_craft_id[f.craft]), fuel_before - float(expected.fuel_cost)), "return fuel debited exactly once")
	var completed: Dictionary = f.encounter.get_completed_result()
	check(completed.get("result") == outcome and f.encounter.get_completed_result().is_empty(), "real result consumed exactly once")
	var supply_after: Dictionary = f.supply.export_state()
	var replay: Dictionary = f.sim.commit_campaign_space_return(f.adapter, f.craft, request)
	check(replay.get("ok", false) and replay.get("replayed", false), "identical completed return replays")
	check(not f.sim.commit_campaign_space_return(f.adapter, "other", request).get("ok", false), "request cannot change craft")
	check(not f.sim.commit_campaign_space_return(f.adapter, f.craft, request + "-new").get("ok", false), "new ID cannot consume terminal result again")
	check(f.supply.export_state() == supply_after and f.fleet.get_craft_snapshot(f.craft) == travel, "replay and conflicts preserve supply and travel")
	f.adapter.free()
	f.sim.free()

func _test_adapter_retry() -> void:
	var before_failures := failed
	var f := _fixture(true)
	if failed != before_failures:
		f.adapter.free(); f.sim.free(); f.flow.free(); return
	check(f.sim.request_singleplayer_command(_command("retreat")).get("ok", false), "adapter fixture reaches real terminal retreat")
	var pending: Dictionary = f.encounter.peek_completed_result()
	var campaign_before: Dictionary = f.campaign.export_state()
	var supply_before: Dictionary = f.supply.export_state()
	# Regel 8 / Auftrag 21.11.: der Ortsabflug bucht nur seinen Etappenanteil (surface_exit); der Heimsprung bucht spaeter selbst.
	var expected: Dictionary = f.supply.preview_leg_fuel({"craft_id":f.craft, "leg":"surface_exit", "origin_location_id":"distress_orbit", "destination_location_id":"homebase"}, {"departure_authorized":true})
	# The first actual adapter tick observes Root's real busy guard. No wrapper
	# replaces advance_space_travel(), _finish_space_encounter_result() or Root.
	f.sim.is_processing_tick = true
	f.adapter.advance_space_travel(0.1)
	check(f.encounter.peek_completed_result() == pending and f.travel.get_snapshot().phase == "approach", "actual adapter leaves busy return pending")
	check(f.supply.export_state() == supply_before and f.campaign.export_state() == campaign_before and f.flow.refreshes == 0, "busy adapter tick commits no fuel, mission result or refresh")
	f.sim.is_processing_tick = false
	f.adapter.advance_space_travel(0.1)
	check(f.travel.get_snapshot().phase == "orbit" and f.encounter.get_snapshot().resolved and f.encounter.peek_completed_result().is_empty(), "next actual adapter tick retries and consumes the pending encounter")
	var campaign_after: Dictionary = f.campaign.export_state()
	var supply_after: Dictionary = f.supply.export_state()
	check(campaign_after.jobs.buccaneer_rescue.status == "failed" and campaign_after.requests.has("result:buccaneer_rescue:astra-departure"), "adapter records real campaign result through Root exactly once")
	check(is_equal_approx(float(supply_after.fuel_by_craft_id[f.craft]), float(supply_before.fuel_by_craft_id[f.craft]) - float(expected.fuel_cost)) and f.flow.refreshes == 1, "successful adapter retry debits one return fare and refreshes once")
	for tick in range(4): f.adapter.advance_space_travel(0.1)
	check(f.campaign.export_state() == campaign_after and f.supply.export_state() == supply_after and f.flow.refreshes == 1, "later actual adapter ticks cannot duplicate result or return fuel")
	var replay: Dictionary = f.sim.commit_campaign_space_return(f.adapter, f.craft, "encounter-return:astra-departure")
	check(replay.get("ok", false) and replay.get("replayed", false) and f.campaign.export_state() == campaign_after and f.supply.export_state() == supply_after, "Root receipt still replays after actual adapter result consumption")
	f.adapter.free()
	f.sim.free()
	f.flow.free()

## Fix-Runde 1, W2a: Ein Schiff im Anflug mit entschiedener Begegnung und unbezahlbarem Rueckweg (kein Tankservice) ist liegen geblieben.
func _test_stranded_in_approach() -> void:
	var before_failures := failed
	var f := _fixture()
	if failed != before_failures:
		f.adapter.free(); f.sim.free(); return
	check(f.sim.request_singleplayer_command(_command("retreat")).get("ok", false), "W2a: Begegnung ist durch echten Rueckzug entschieden")
	var fuel_before := float(f.supply.get_supply_snapshot().fuel_by_craft_id[f.craft])
	var covered: Dictionary = f.adapter.get_fuel_status(f.craft)
	check(String(covered.get("phase", "")) == "approach" and not bool(covered.get("stranded", true)), "W2a: mit gedecktem Rueckweg ist das Schiff im Anflug nicht liegen geblieben: " + str(covered))
	f.supply.get("_fuel_by_craft_id")[f.craft] = 0.0
	var status: Dictionary = f.adapter.get_fuel_status(f.craft)
	var legs: Array = Array(status.get("next_legs", []))
	check(String(status.get("phase", "")) == "approach" and bool(status.get("stranded", false)) and String(status.get("strand_place", "")) == "space", "W2a: unbezahlbarer Rueckweg im Anflug mit entschiedener Begegnung: liegen geblieben im All: " + str(status))
	check(legs.size() == 1 and String(legs[0].get("leg", "")) == "surface_exit" and not bool(legs[0].get("affordable", true)), "W2a: der offene Rueckweg ist der Ortsabflug und nicht bezahlbar")
	check(not bool(status.get("refuel_here", true)) and not bool(status.get("refuel_affordable", true)), "W2a: im Anflug gibt es keinen Tankservice")
	f.supply.get("_fuel_by_craft_id")[f.craft] = fuel_before
	f.adapter.free()
	f.sim.free()

## Fix-Runde 1, W2b: Der alte Zweig ohne Kampfbesitzer bucht das Ergebnis immer, den Rueckweg erst wenn er bezahlbar ist.
func _test_old_branch_without_combat_owner() -> void:
	var before_failures := failed
	var f := _fixture(true)
	if failed != before_failures:
		f.adapter.free(); f.sim.free(); f.flow.free(); return
	check(f.sim.request_singleplayer_command(_command("retreat")).get("ok", false), "W2b: Begegnung ist durch echten Rueckzug entschieden")
	f.encounter.set("_combat_owner", null)
	check(f.encounter.get("_combat_owner") == null, "W2b: der alte Zweig ohne Kampfbesitzer ist aktiv")
	var fuel_before := float(f.supply.get_supply_snapshot().fuel_by_craft_id[f.craft])
	var expected: Dictionary = f.supply.preview_leg_fuel({"craft_id":f.craft, "leg":"surface_exit", "origin_location_id":"distress_orbit", "destination_location_id":"homebase"}, {"departure_authorized":true})
	f.supply.get("_fuel_by_craft_id")[f.craft] = 0.0
	f.adapter.advance_space_travel(0.1)
	var held: Dictionary = f.campaign.export_state()
	check(held.jobs.buccaneer_rescue.status == "failed" and held.requests.has("result:buccaneer_rescue:astra-departure"), "W2b: das Ergebnis ist trotz leerem Tank gebucht")
	check(f.travel.get_snapshot().phase == "approach" and not f.encounter.peek_completed_result().is_empty(), "W2b: ohne bezahlten Rueckweg bleibt das Schiff im Anflug und das Ergebnis nicht zugestellt")
	check(is_equal_approx(float(f.supply.get_supply_snapshot().fuel_by_craft_id[f.craft]), 0.0), "W2b: es wird nichts gebucht, was nicht gedeckt ist")
	f.supply.get("_fuel_by_craft_id")[f.craft] = fuel_before
	f.adapter.advance_space_travel(0.1)
	# Der Phasenwechsel (finish_approach/enter_orbit) gehoert dem Reisebesitzer und ist hier nicht gemeint: das Fixture setzt den Anflug kuenstlich.
	check(f.encounter.peek_completed_result().is_empty() and f.encounter.get_snapshot().resolved, "W2b: mit bezahlbarem Rueckweg ist das Ergebnis zugestellt (resolved), erst nach der Buchung des Rueckwegs")
	check(is_equal_approx(float(f.supply.get_supply_snapshot().fuel_by_craft_id[f.craft]), fuel_before - float(expected.fuel_cost)), "W2b: der Rueckweg wird genau einmal gebucht (Ortsabflug)")
	var after: Dictionary = f.campaign.export_state()
	var supply_after: Dictionary = f.supply.export_state()
	for tick in range(3): f.adapter.advance_space_travel(0.1)
	check(f.campaign.export_state() == after and f.supply.export_state() == supply_after, "W2b: weitere Takte buchen weder Ergebnis noch Treibstoff noch einmal")
	f.adapter.free()
	f.sim.free()
	f.flow.free()

func _command(operation: String, payload: Dictionary = {}) -> Dictionary:
	return {"contract_category":"campaign_space", "operation":operation, "payload":payload, "request_id":"astra-" + operation}

func check(ok: bool, label: String) -> bool:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)
	return ok
