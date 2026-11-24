extends SceneTree
## LC2f K1/K2: Speichern und Laden nach Schiffsverlust (Stand-Ebene: echte Besitzer, echte Pruefung, echte Datei).
## K1: Hauptschiff verloren, nur die Buccaneer (Jaeger) bleibt: der Stand ist mit dem Verlustbeleg gueltig, speicher- und ladbar.
## K2: verlorenes Kaufschiff gibt seinen Heimlandeplatz frei; der Ersatzkauf bekommt denselben Platz, der Stand bleibt speicher- und ladbar.
const C = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const S = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const TEST_PATH := "user://campaigns/lc2f_test/checkpoint_v1.json"
var checks := 0
var failures := 0
var sequence := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func call_c(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(C.build_command(operation, payload, "lc2f:%d" % sequence), context)

## Vollstaendiger Zwei-Schiff-Stand wie in campaign_five_missions_chain_test: {"checkpoint", "supply"}.
func _base() -> Dictionary:
	var owner = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	var tutorial = load("res://scripts/core/campaign_onboarding_state.gd").new()
	check(owner.configure().ok, "campaign owner configures")
	check(supply.configure(["dropship_1"]).ok, "supply configures")
	supply.configure_inventory(["campaign_leader"], ["dropship_1"])
	supply.configure_start_inventory("campaign")
	tutorial.configure()
	var observe := {"contract_category": "campaign_onboarding", "operation": "observe", "payload": {}}
	tutorial.apply_command(observe, {"runtime_evidence": {"base_ready": true}})
	for id in ["satellite_recovery", "outpost_recovery", "benit_delivery", "outpost_chip_recovery", "buccaneer_rescue"]:
		var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
		call_c(owner, "accept_job", {"job_id": id})
		call_c(owner, "bind_departure", {"craft_id": "dropship_1", "origin_location_id": "homebase", "destination_location_id": job.location_id, "landing_pad_id": "homebase_pad_01", "job_id": id}, {"departure_authorized": true})
		call_c(owner, "activate_job", {"job_id": id, "craft_id": "dropship_1"}, {"departure_authorized": true})
		if id == "benit_delivery": call_c(owner, "deliver_crate", {}, {"runtime_authorized": true})
		var done := call_c(owner, "complete_job", {"job_id": id, "craft_id": "dropship_1"}, {"runtime_evidence": {"scenario_id": job.scenario_id, "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": job.required_step_ids}}})
		if bool(job.home_upload): done = call_c(owner, "upload_job", {"job_id": id}, {"at_home": true})
		var receipt: Dictionary = done.get("completion_receipt", {})
		supply.apply_command(S.build_command("apply_reward", {"completion_id": receipt.completion_id}, "reward:" + id), {"completion_receipt": receipt})
		if id == "outpost_recovery":
			call_c(owner, "claim_recruit", {"kind": "outpost"}, {"runtime_authorized": true})
			call_c(owner, "load_crate", {}, {"runtime_authorized": true})
		if id == "buccaneer_rescue":
			call_c(owner, "claim_recruit", {"kind": "pilot"}, {"runtime_authorized": true})
			call_c(owner, "build_pad", {}, {"runtime_authorized": true, "at_home": true})
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

func _roundtrip(payload: Dictionary, label: String) -> Dictionary:
	var fresh: Dictionary = JSON.parse_string(JSON.stringify(payload))
	var saved: Dictionary = STORE.save_checkpoint(fresh, TEST_PATH)
	check(bool(saved.get("ok", false)), "%s: Speichern gelingt (%s)" % [label, str(saved.get("reason", ""))])
	var loaded: Dictionary = STORE.load_checkpoint(TEST_PATH)
	check(bool(loaded.get("ok", false)), "%s: Laden gelingt (%s)" % [label, str(loaded.get("reason", ""))])
	return Dictionary(loaded.get("payload", {}))

func _fleet_ids(payload: Dictionary) -> Array:
	var ids: Array = []
	for ship in Array(payload.get("fleet", [])): ids.append(String(Dictionary(Dictionary(ship).get("definition", {})).get("craft_id", "")))
	return ids

func _k1() -> void:
	var base: Dictionary = _base()
	var supply = base.supply
	var checkpoint: Dictionary = Dictionary(base.checkpoint).duplicate(true)
	check(STORE.validate_payload(JSON.parse_string(JSON.stringify(checkpoint))).ok, "K1: Ausgangsstand mit zwei Schiffen ist gueltig")
	var dropship: Dictionary = Dictionary(Dictionary(checkpoint.fleet[0]).definition).duplicate(true)
	var buccaneer_entry: Dictionary = Dictionary(checkpoint.fleet[1]).duplicate(true)
	supply.retire_lost_craft("dropship_1")
	checkpoint.fleet = [buccaneer_entry]
	checkpoint.craft = {"definition": buccaneer_entry.definition, "pilot_id": buccaneer_entry.pilot_id}
	checkpoint.supply = supply.export_state()
	# Ohne Verlustbeleg bleibt ein Stand ohne Landungsschiff ungueltig (die Lockerung gilt nur mit Beleg).
	var without_record: Dictionary = STORE.validate_payload(JSON.parse_string(JSON.stringify(checkpoint)))
	check(not bool(without_record.get("ok", true)), "K1: nur Jaeger ohne Verlustbeleg bleibt abgelehnt (%s)" % str(without_record.get("reason", "")))
	checkpoint.lost_craft = [{"craft_id": "dropship_1", "definition": dropship, "ship_name": "Dropship 1", "outcome": "crash", "equipment_kept": false}]
	var loaded: Dictionary = _roundtrip(checkpoint, "K1")
	check(_fleet_ids(loaded) == ["campaign_buccaneer_01"], "K1: nach dem Laden besteht die Flotte nur aus der Buccaneer (%s)" % str(_fleet_ids(loaded)))
	check(Array(loaded.get("lost_craft", [])).size() == 1 and String(Dictionary(Array(loaded.lost_craft)[0]).get("craft_id", "")) == "dropship_1", "K1: der Verlustbeleg des Landungsschiffs ist da")
	# Ein Beleg fuer einen Jaeger belegt das fehlende Landungsschiff nicht.
	var fake: Dictionary = checkpoint.duplicate(true)
	fake.lost_craft = [{"craft_id": "dropship_1", "definition": {"craft_id": "dropship_1", "craft_type": "fighter"}, "ship_name": "x", "outcome": "crash", "equipment_kept": false}]
	check(not bool(STORE.validate_payload(JSON.parse_string(JSON.stringify(fake))).get("ok", true)), "K1: ein Beleg ohne Landungsschiff-Definition lockert nichts")

func _receipt(request_id: String, pad: String) -> Dictionary:
	var offer_id := "polisa_ship_cutlass"
	return {"signature": JSON.stringify({"operation": "station_buy_ship", "payload": {"offer_id": offer_id, "delivery_mode": "homebase"}}, "", true),
		"result": {"ok": true, "operation": "station_buy_ship", "request_id": request_id, "craft_id": "polisa_cutlass_" + request_id.sha256_text().substr(0, 12), "offer_id": offer_id, "cost": 0, "landing_pad_id": pad, "delivery_location_id": "homebase"}}

func _k2() -> void:
	var base: Dictionary = _base()
	var supply = base.supply
	var checkpoint: Dictionary = Dictionary(base.checkpoint).duplicate(true)
	var offer: Dictionary = Dictionary(Dictionary(supply.get("_definitions")).get("offers", {})).get("polisa_ship_cutlass", {})
	check(not offer.is_empty(), "K2: Angebot polisa_ship_cutlass ist bekannt")
	var requests: Dictionary = supply.get("_requests")
	requests["lc2f-pad"] = {"signature": JSON.stringify({"operation": "station_build_home_pad", "payload": {}}, "", true), "result": {"ok": true, "operation": "station_build_home_pad", "request_id": "lc2f-pad", "home_pad_count": 3, "cost": 200}}
	var first: Dictionary = _receipt("lc2f-buy-1", "homebase_pad_03")
	var second: Dictionary = _receipt("lc2f-buy-2", "homebase_pad_03")
	first.result.cost = offer.get("unit_price")
	second.result.cost = offer.get("unit_price")
	requests["lc2f-buy-1"] = first
	supply.register_craft(String(first.result.craft_id))
	# Das erste Kaufschiff geht verloren (wie _retire_lost_craft es ruft); sein Platz ist frei, der Ersatzkauf bekommt denselben.
	supply.retire_lost_craft(String(first.result.craft_id))
	requests["lc2f-buy-2"] = second
	supply.register_craft(String(second.result.craft_id))
	var definition := {"craft_id": String(second.result.craft_id), "craft_type": String(offer.get("craft_type", "")), "model_id": String(offer.get("model_id", ""))}
	var lost_definition := {"craft_id": String(first.result.craft_id), "craft_type": String(offer.get("craft_type", "")), "model_id": String(offer.get("model_id", ""))}
	checkpoint.fleet.append({"definition": definition, "pilot_id": "", "location": "homebase"})
	checkpoint.lost_craft = [{"craft_id": lost_definition.craft_id, "definition": lost_definition, "ship_name": "Cutlass", "outcome": "crash", "equipment_kept": false}]
	checkpoint.supply = supply.export_state()
	var verdict: Dictionary = supply.validate_station_receipts(Dictionary(Dictionary(checkpoint.supply).get("requests", {})))
	check(bool(verdict.get("ok", false)), "K2: Kaufbelege mit gleichem Heimlandeplatz (erstes Schiff verloren) sind gueltig (%s)" % str(verdict.get("reason", "")))
	var loaded: Dictionary = _roundtrip(checkpoint, "K2")
	check(_fleet_ids(loaded).has(definition.craft_id) and not _fleet_ids(loaded).has(lost_definition.craft_id), "K2: nach dem Laden steht das neue Schiff in der Flotte, das verlorene nicht (%s)" % str(_fleet_ids(loaded)))
	# Gegenprobe: zwei Schiffe in der Flotte auf demselben Platz bleiben ungueltig.
	var live_a: Dictionary = _receipt("lc2f-buy-1", "homebase_pad_03")
	var live_b: Dictionary = _receipt("lc2f-buy-2", "homebase_pad_03")
	live_a.result.cost = offer.get("unit_price")
	live_b.result.cost = offer.get("unit_price")
	var clash_requests: Dictionary = {"lc2f-pad": Dictionary(requests["lc2f-pad"]).duplicate(true), "lc2f-buy-1": live_a, "lc2f-buy-2": live_b}
	check(not bool(supply.validate_station_receipts(clash_requests).get("ok", true)), "K2: zwei lebende Kaufschiffe auf demselben Platz bleiben abgelehnt")

func _initialize() -> void:
	_k1()
	_k2()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("CAMPAIGN_CRAFT_LOSS_SAVE passed=%d failed=%d" % [checks - failures, failures])
	quit(1 if failures else 0)
