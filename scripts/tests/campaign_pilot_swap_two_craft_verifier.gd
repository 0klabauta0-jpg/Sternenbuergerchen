extends SceneTree
## Homecoming team choice with two ships (N9F). A person aboard a ship who is neither its pilot nor staged joins the
## team of THAT ship's payload, never a team of the other ship, and the choice does not depend on the base view's
## selection state (the view is refreshed only after the homecoming).
## S1: second ship has its own team; pilot swap displaces its pilot; the view is current.
## S2: same, but the base view is stale (nobody selected) when the ship lands.
## S3: second ship carries no team; a free team is assigned to it (existing assignment path) and takes the person.
## Needs an isolated APPDATA (runner).
const START = preload("res://scripts/meta/game_start_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const SHIP1 := "dropship_1"
const SHIP2 := "campaign_buccaneer_01"
const CAMPAIGN_CONTRACT = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const SUPPLY_CONTRACT = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
var _passed := 0
var _failed := 0
var _sequence := 0

func _command(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	_sequence += 1
	return owner.apply_command(CAMPAIGN_CONTRACT.build_command(operation,payload,"twocraft:%d" % _sequence),context)

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> bool:
	if value: _passed += 1
	else: _failed += 1
	print("PASS: " if value else "FAIL: ", label)
	return value

func _fixture(flow: Node, second_team: bool, stale_view: bool) -> Dictionary:
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	var onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
	campaign.configure(); supply.configure(["dropship_1"])
	supply.configure_inventory(["campaign_leader","campaign_pilot","campaign_outpost_recruit","campaign_rescue_pilot"],[SHIP1,SHIP2])
	supply.configure_start_inventory("campaign")
	onboarding.configure()
	# Four earned people and a second pad: the five campaign jobs are completed through the real owners (as game_review_multicraft_20261112).
	for id in ["satellite_recovery","outpost_recovery","benit_delivery","outpost_chip_recovery","buccaneer_rescue"]:
		var job: Dictionary = campaign.get_campaign_snapshot().jobs[id]
		_command(campaign,"accept_job",{"job_id":id})
		_command(campaign,"bind_departure",{"craft_id":"dropship_1","origin_location_id":"homebase","destination_location_id":job.location_id,"landing_pad_id":"homebase_pad_01","job_id":id},{"departure_authorized":true})
		_command(campaign,"activate_job",{"job_id":id,"craft_id":"dropship_1"},{"departure_authorized":true})
		if id == "benit_delivery": _command(campaign,"deliver_crate",{},{"runtime_authorized":true})
		var done := _command(campaign,"complete_job",{"job_id":id,"craft_id":"dropship_1"},{"runtime_evidence":{"scenario_id":job.scenario_id,"result":"victory","mission_scenario_runtime_gates":{"all_gates_complete":true,"completed_step_ids":job.required_step_ids}}})
		if bool(job.home_upload): done = _command(campaign,"upload_job",{"job_id":id},{"at_home":true})
		var receipt: Dictionary = done.get("completion_receipt",{})
		supply.apply_command(SUPPLY_CONTRACT.build_command("apply_reward",{"completion_id":receipt.completion_id},"reward:"+id),{"completion_receipt":receipt})
		if id == "outpost_recovery":
			_command(campaign,"claim_recruit",{"kind":"outpost"},{"runtime_authorized":true})
			_command(campaign,"load_crate",{},{"runtime_authorized":true})
		if id == "buccaneer_rescue":
			_command(campaign,"claim_recruit",{"kind":"pilot"},{"runtime_authorized":true})
			_command(campaign,"build_pad",{},{"runtime_authorized":true,"at_home":true})
	onboarding.apply_command({"contract_category":"campaign_onboarding","operation":"observe","payload":{}},{"runtime_evidence":{"base_ready":true,"satellite_uploaded":true,"outpost_completed":true,"outpost_recruited":true,"crate_loaded":true,"delivery_completed":true,"outpost_chip_uploaded":true,"rescue_completed":true,"pilot_recruited":true,"second_pad_built":true}})
	var roster: Array = flow.get("_all_team_units").duplicate(true)
	for index in 2:
		var person: Dictionary = roster[index].duplicate(true)
		person.unit_id = "campaign_outpost_recruit" if index == 0 else "campaign_rescue_pilot"
		person.fireteam_id = "ft2" if index == 0 else ""
		roster.append(person)
	var first: Dictionary = flow.call("_build_homebase_aircraft_definition","dropship",1)
	var second: Dictionary = flow.call("_build_homebase_aircraft_definition","fighter",1)
	second.merge({"craft_id":SHIP2,"display_name":"Buccaneer","model_id":"buccaneer","craft_type":"dropship"},true)
	supply.register_craft(SHIP2)
	var state: Dictionary = campaign.export_state()
	state.departures_by_craft_id = {}; state.selected_location_id = "homebase"; state.selected_job_id = ""
	var staged_units := ["campaign_leader"]; var staged_teams := ["ft1"]
	var definitions := [{"id":"ft1","lead_unit_id":"campaign_leader","member_unit_ids":["campaign_leader"]}]
	if second_team:
		staged_units.append("campaign_outpost_recruit"); staged_teams.append("ft2")
		# Without member ids in the definition the view knows the members only from its selection (so it can be stale).
		definitions.append({"id":"ft2","lead_unit_id":"campaign_outpost_recruit"} if stale_view else {"id":"ft2","lead_unit_id":"campaign_outpost_recruit","member_unit_ids":["campaign_outpost_recruit"]})
	else:
		definitions.append({"id":"ft2","lead_unit_id":"","member_unit_ids":[]})
	var craft := {"definition":first,"pilot_id":"campaign_pilot","staged_unit_ids":staged_units,"staged_fireteam_ids":staged_teams,"fireteam_definitions":definitions}
	var payload := {"schema_version":1,"roster":roster,"craft":craft,"fleet":[{"definition":first,"pilot_id":"campaign_pilot","location":"homebase"},{"definition":second,"pilot_id":"campaign_rescue_pilot","location":"homebase"}],"campaign":state,"supply":supply.export_state(),"onboarding":onboarding.export_state()}
	payload.base_personnel = {"version":1,"units":{}}
	var aboard := {"campaign_leader":SHIP1,"campaign_pilot":SHIP1,"campaign_rescue_pilot":SHIP2,"campaign_outpost_recruit":SHIP2 if second_team else ""}
	for person: Dictionary in roster:
		var craft_id := String(aboard.get(person.unit_id,""))
		payload.base_personnel.units[person.unit_id] = {"position":[0,0],"status":"outside" if craft_id.is_empty() else "aboard","craft_id":craft_id,"bed_id":""}
	return payload

func _open(action: String) -> Node:
	START.request_start(self,"campaign",action)
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	return flow

func _teams(screen: Node) -> Dictionary:
	var result := {}
	for team: Dictionary in Array(screen.call("get_operations_snapshot").get("fireteams", [])):
		var ids: Array = []
		for member: Dictionary in Array(team.get("members", [])): ids.append(String(member.get("id", "")))
		result[String(team.get("id", ""))] = ids
	return result

func _payload(screen: Node, craft_id: String) -> Array:
	return Array(screen.call("_get_homebase_direct_payload_fireteam_ids_for_craft_raw", craft_id))

## Boots the two-ship checkpoint, optionally displaces the second ship's pilot, lands the second ship at home.
func _scenario(label: String, second_team: bool, swap: bool, stale_view: bool) -> void:
	var flow := _open("new"); await process_frame
	flow.set_process(false)
	var payload := _fixture(flow, second_team, stale_view)
	flow.queue_free(); await process_frame
	var saved: Dictionary = STORE.save_checkpoint(payload)
	if not _check(bool(saved.get("ok", false)), label + ": two-ship checkpoint saves"):
		print(saved); return
	flow = _open("continue"); await process_frame
	flow.set_process(false)
	var screen: Node = flow.get_node("HomebaseScreen")
	var adapter: Node = flow.get("_singleplayer_runtime")
	var owner: Node = adapter.call("get_base_personnel_runtime")
	owner.call("get_simulation_root").set_physics_process(false)
	var displaced := "campaign_rescue_pilot"
	var recruit := "campaign_outpost_recruit"
	if swap:
		var result: Dictionary = screen.call("request_operation", "pilot", {"craft_id": SHIP2, "unit_id": recruit})
		if not _check(bool(result.get("ok", false)) and String(Dictionary(flow.get("_assigned_aircraft_pilot_by_craft")).get(SHIP2, "")) == recruit, label + ": pilot seat of the second ship goes to its team member"):
			print(result); flow.queue_free(); await process_frame; return
	else:
		var remote: Dictionary = owner.call("mark_recruit_remote", recruit, SHIP2)
		_check(bool(remote.get("ok", false)), label + ": recruit is aboard the second ship without any team")
		displaced = recruit
	var first_before: Array = Array(_teams(screen).get("ft1", []))
	if stale_view:
		# Not-yet-refreshed view: it holds the assignment of both ships but knows no member of the second team
		# (the sanitizing setters would drop such an assignment, so the held assignment is put back directly).
		var held := {SHIP1: PackedStringArray(["ft1"]), SHIP2: PackedStringArray(["ft2"])}
		screen.call("set_fireteam_context", PackedStringArray(), [{"id":"ft1","lead_unit_id":"campaign_leader","member_unit_ids":["campaign_leader"]},{"id":"ft2","lead_unit_id":"","member_unit_ids":[]}], false)
		screen.call("set_selected_unit_ids", PackedStringArray(["campaign_leader"]))
		screen.set("_homebase_dropship_staged_fireteam_ids_by_craft", held)
		_check(PackedStringArray(screen.call("_get_member_unit_ids_for_fireteam", "ft2")).is_empty(), label + ": fixture: the base view has no members for the second team")
		_check(_payload(screen, SHIP2) == ["ft2"] and _payload(screen, SHIP1) == ["ft1"], label + ": fixture: both ships keep their assigned team")
	flow.call("_finish_space_home_landing", SHIP2)
	var teams := _teams(screen)
	print("TWO_CRAFT_STATE ", label, " ", var_to_str({"teams": teams, "payload1": _payload(screen, SHIP1), "payload2": _payload(screen, SHIP2), "staged": flow.get("_homebase_staged_unit_ids"), "staged_teams": flow.get("_homebase_staged_fireteam_ids"), "pilot2": Dictionary(flow.get("_assigned_aircraft_pilot_by_craft")).get(SHIP2, "")}))
	var payload2: Array = _payload(screen, SHIP2)
	_check(not payload2.is_empty() and Array(teams.get(String(payload2[0]) if not payload2.is_empty() else "", [])).has(displaced), label + ": displaced person is in a payload team of the second ship")
	_check(not Array(teams.get("ft1", [])).has(displaced) and Array(teams.get("ft1", [])) == first_before and _payload(screen, SHIP1) == ["ft1"], label + ": the first ship's team is unchanged")
	var save: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint", flow, adapter, true)
	if not _check(bool(save.get("ok", false)) and not bool(save.get("throttled", false)), label + ": home checkpoint saves"):
		print("SAVE_RESULT ", label, " ", save)
	flow.queue_free(); await process_frame

func _run() -> void:
	await _scenario("S1", true, true, false)
	await _scenario("S2", true, true, true)
	await _scenario("S3", false, false, false)
	print("CAMPAIGN_PILOT_SWAP_TWO_CRAFT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
