extends RefCounted
## LC2g: Pruefaufbau fuer Staende mit zwei Schiffen (Landungsschiff dropship_1 + Buccaneer, vier Personen), wie campaign_five_missions_chain_test
## und campaign_craft_loss_save_verifier ihn bauen. Liefert {"checkpoint": Stand-Woerterbuch, "supply": Versorgungsbesitzer}.
const C = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const S = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
var sequence := 0

func _call_c(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(C.build_command(operation, payload, "lc2g:%d" % sequence), context)

func build() -> Dictionary:
	var owner = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	var tutorial = load("res://scripts/core/campaign_onboarding_state.gd").new()
	owner.configure()
	supply.configure(["dropship_1"])
	supply.configure_inventory(["campaign_leader"], ["dropship_1"])
	supply.configure_start_inventory("campaign")
	tutorial.configure()
	var observe := {"contract_category": "campaign_onboarding", "operation": "observe", "payload": {}}
	tutorial.apply_command(observe, {"runtime_evidence": {"base_ready": true}})
	for id in ["satellite_recovery", "outpost_recovery", "benit_delivery", "outpost_chip_recovery", "buccaneer_rescue"]:
		var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
		_call_c(owner, "accept_job", {"job_id": id})
		_call_c(owner, "bind_departure", {"craft_id": "dropship_1", "origin_location_id": "homebase", "destination_location_id": job.location_id, "landing_pad_id": "homebase_pad_01", "job_id": id}, {"departure_authorized": true})
		_call_c(owner, "activate_job", {"job_id": id, "craft_id": "dropship_1"}, {"departure_authorized": true})
		if id == "benit_delivery": _call_c(owner, "deliver_crate", {}, {"runtime_authorized": true})
		var done := _call_c(owner, "complete_job", {"job_id": id, "craft_id": "dropship_1"}, {"runtime_evidence": {"scenario_id": job.scenario_id, "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": job.required_step_ids}}})
		if bool(job.home_upload): done = _call_c(owner, "upload_job", {"job_id": id}, {"at_home": true})
		var receipt_data: Dictionary = done.get("completion_receipt", {})
		supply.apply_command(S.build_command("apply_reward", {"completion_id": receipt_data.completion_id}, "reward:" + id), {"completion_receipt": receipt_data})
		if id == "outpost_recovery":
			_call_c(owner, "claim_recruit", {"kind": "outpost"}, {"runtime_authorized": true})
			_call_c(owner, "load_crate", {}, {"runtime_authorized": true})
		if id == "buccaneer_rescue":
			_call_c(owner, "claim_recruit", {"kind": "pilot"}, {"runtime_authorized": true})
			_call_c(owner, "build_pad", {}, {"runtime_authorized": true, "at_home": true})
		tutorial.apply_command(observe, {"runtime_evidence": {"satellite_uploaded": true, "outpost_completed": true, "outpost_recruited": true, "crate_loaded": true, "delivery_completed": true, "outpost_chip_uploaded": true, "rescue_completed": true, "pilot_recruited": true, "second_pad_built": true}})
	var roster: Array = load("res://scripts/meta/campaign_start_configuration.gd").new()._initial_roster()
	var recruit: Dictionary = Dictionary(roster[0]).duplicate(true)
	recruit.unit_id = "campaign_outpost_recruit"
	roster.append(recruit)
	recruit = Dictionary(roster[1]).duplicate(true)
	recruit.unit_id = "campaign_rescue_pilot"
	roster.append(recruit)
	supply.register_craft("campaign_buccaneer_01")
	var saved: Dictionary = owner.export_state()
	saved.departures_by_craft_id = {}
	saved.selected_location_id = "homebase"
	saved.selected_job_id = ""
	var dropship := {"craft_id": "dropship_1", "craft_type": "dropship"}
	var buccaneer := {"craft_id": "campaign_buccaneer_01", "craft_type": "fighter"}
	var checkpoint := {"schema_version": 1, "roster": roster, "craft": {"definition": dropship, "pilot_id": "campaign_pilot"},
		"fleet": [{"definition": dropship, "pilot_id": "campaign_pilot", "location": "homebase"}, {"definition": buccaneer, "pilot_id": "campaign_rescue_pilot", "location": "homebase"}],
		"campaign": saved, "supply": supply.export_state(), "onboarding": tutorial.export_state()}
	return {"checkpoint": checkpoint, "supply": supply}

## Kaufbeleg eines Kaufschiffs (Polisa, Heimlieferung) mit dem angegebenen Heimlandeplatz.
func receipt(request_id: String, pad: String, cost: int) -> Dictionary:
	var offer_id := "polisa_ship_cutlass"
	return {"signature": JSON.stringify({"operation": "station_buy_ship", "payload": {"offer_id": offer_id, "delivery_mode": "homebase"}}, "", true),
		"result": {"ok": true, "operation": "station_buy_ship", "request_id": request_id, "craft_id": "polisa_cutlass_" + request_id.sha256_text().substr(0, 12), "offer_id": offer_id, "cost": cost, "landing_pad_id": pad, "delivery_location_id": "homebase"}}
