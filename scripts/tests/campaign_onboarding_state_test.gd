extends SceneTree
var failures: int = 0
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", label)
func _initialize() -> void:
	var path := "res://scripts/core/campaign_onboarding_state.gd"
	check(ResourceLoader.exists(path), "onboarding owner exists")
	if not ResourceLoader.exists(path):
		quit(1)
		return
	var owner = load(path).new()
	owner.configure()
	var command := {"contract_category":"campaign_onboarding", "operation":"observe", "payload":{}}
	owner.apply_command(command, {"runtime_evidence":{"trade_home":true,"bought":true,"refueled":true}})
	check(owner.get_snapshot().stage_index == 0, "early trade ignored")
	owner.apply_command(command.merged({"payload":{"base_ready":true}}, true))
	check(owner.get_snapshot().stage_index == 0, "UI evidence ignored")
	owner.apply_command(command, {"runtime_evidence":{"base_ready":true,"satellite_completed":true,"satellite_home":true}})
	check(owner.get_snapshot().stage_index == 1, "bounded stage transition")
	owner.apply_command(command, {"runtime_evidence":{"satellite_home":true}})
	check(owner.get_snapshot().stage_index == 1, "completion required")
	owner.apply_command(command, {"runtime_evidence":{"satellite_completed":true}})
	owner.apply_command(command, {"runtime_evidence":{"satellite_home":true}})
	check(owner.get_snapshot().stage_index == 2, "satellite returned")
	owner.apply_command(command, {"runtime_evidence":{"bought":true,"refueled":true,"trade_home":true}})
	check(not owner.get_snapshot().completed, "departure and use required")
	owner.apply_command(command, {"runtime_evidence":{"trade_departed":true}})
	owner.apply_command(command, {"runtime_evidence":{"trade_used":true}})
	owner.apply_command(command, {"runtime_evidence":{"bought":true,"refueled":true}})
	owner.apply_command(command, {"runtime_evidence":{"trade_home":true}})
	check(owner.get_snapshot().completed, "trade full loop completes")
	var state: Dictionary = owner.export_state()
	var revision: int = owner.get_snapshot().revision
	owner.apply_command(command, {"runtime_evidence":{"trade_home":true}})
	check(owner.get_snapshot().revision == revision, "replay idempotent")
	check(not owner.restore_state({"schema_version":1,"stage_index":99}).ok, "bad restore rejected")
	check(owner.export_state() == state, "bad restore atomic")
	check(not owner.restore_state({"schema_version":1,"stage_index":2,"revision":1,"facts":{"trade_home":true}}).ok, "restored early home rejected")
	check(not owner.restore_state({"schema_version":1,"stage_index":0,"revision":1,"facts":{"base_ready":true}}).ok, "uncommitted stage rejected")
	var restored = load(path).new()
	check(restored.restore_state(state).ok, "valid onboarding restore")
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	campaign.configure()
	check(campaign.has_method("export_state"), "campaign persistence API")
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	supply.configure(["campaign_craft"])
	check(supply.has_method("export_state"), "supply persistence API")
	check(ResourceLoader.exists("res://scripts/meta/campaign_checkpoint_store.gd"), "checkpoint store exists")
	var campaign_state: Dictionary = campaign.export_state()
	var supply_state: Dictionary = supply.export_state()
	check(campaign.restore_state(JSON.parse_string(JSON.stringify(campaign_state))).ok, "campaign JSON roundtrip")
	check(supply.restore_state(JSON.parse_string(JSON.stringify(supply_state))).ok, "supply JSON roundtrip")
	var bad: Dictionary = campaign_state.duplicate(true)
	bad.jobs.satellite_recovery.reward.credits = 9999
	check(not campaign.restore_state(bad).ok, "changed mission definition rejected")
	check(campaign.export_state() == campaign_state, "campaign rejection atomic")
	bad = supply_state.duplicate(true)
	bad.fuel_by_craft_id.campaign_craft = -1
	check(not supply.restore_state(bad).ok, "negative persisted fuel rejected")
	check(supply.export_state() == supply_state, "supply rejection atomic")
	var contract = load("res://scripts/mission/singleplayer_campaign_command_contract.gd")
	check(campaign.apply_command(contract.build_command("accept_job", {"job_id":"satellite_recovery"}, "a")).ok, "accept satellite")
	check(campaign.apply_command(contract.build_command("fail_job", {"job_id":"satellite_recovery"}, "f"), {"mission_aborted":true}).ok, "abort satellite")
	check(campaign.apply_command(contract.build_command("retry_failed_job", {"job_id":"satellite_recovery"}, "r")).ok, "retry satellite")
	check(campaign.get_campaign_snapshot().jobs.satellite_recovery.status == "accepted", "retry ready")
	check(campaign.restore_state(campaign.export_state()).ok, "request receipts roundtrip")
	var store = load("res://scripts/meta/campaign_checkpoint_store.gd")
	owner.configure()
	var roster: Array = load("res://scripts/npc/unit_roster_presets.gd").get_homebase_roster()
	var leader: Dictionary = roster[0].duplicate(true)
	leader.merge({"unit_id":"leader","roster_role_category":"operator"}, true)
	var pilot: Dictionary = roster.back().duplicate(true)
	pilot.merge({"unit_id":"pilot","roster_role_category":"pilot","dropship_piloting":0.7}, true)
	var payload := {"schema_version":1,"roster":[leader,pilot],"craft":{"definition":{"craft_id":"campaign_craft","craft_type":"dropship"},"pilot_id":"pilot"},"campaign":campaign.export_state(),"supply":supply.export_state(),"onboarding":owner.export_state()}
	var checkpoint := "user://campaigns/domain_test/checkpoint.json"
	check(store.save_checkpoint(payload, checkpoint).ok, "independent checkpoint saved")
	check(store.load_checkpoint(checkpoint).ok, "checkpoint loaded")
	check(store.save_checkpoint(payload, checkpoint).ok, "atomic checkpoint replacement")
	check(not store.save_checkpoint(payload, "user://profiles/local_player/roster_v1.json").ok, "Skirmish write rejected")
	bad = payload.duplicate(true)
	bad.roster[0].unit_id = "pilot"
	check(not store.save_checkpoint(bad, checkpoint).ok, "duplicate identities rejected")
	check(store.load_checkpoint(checkpoint).ok, "invalid save keeps old checkpoint")
	var preparation: Dictionary = payload.duplicate(true)
	preparation.craft.pilot_id = ""
	preparation.craft.staged_unit_ids = []
	preparation.craft.staged_fireteam_ids = []
	preparation.craft.fireteam_definitions = [{"id":"ft1","lead_unit_id":"leader","member_unit_ids":["leader"],"member_loadouts":{"leader":{}}},{"id":"ft2","lead_unit_id":"","member_unit_ids":[],"member_loadouts":{}}]
	check(store.save_checkpoint(preparation, checkpoint).ok, "unassigned pilot and empty fireteam preparation saves")
	var preparation_loaded: Dictionary = store.load_checkpoint(checkpoint)
	check(preparation_loaded.ok and preparation_loaded.get("payload", {}).get("craft", {}).get("pilot_id", "wrong") == "", "unassigned pilot preparation roundtrip")
	check(preparation_loaded.ok and preparation_loaded.get("payload", {}).get("craft", {}).get("fireteam_definitions", []).size() == 2, "empty fireteam retained on roundtrip")
	preparation.craft.fireteam_definitions[0].member_unit_ids = PackedStringArray(["leader"])
	preparation.craft.fireteam_definitions[1].member_unit_ids = PackedStringArray()
	check(store.save_checkpoint(preparation, checkpoint).ok, "native packed fireteam members save")
	check(store.load_checkpoint(checkpoint).ok, "packed fireteam members JSON roundtrip")
	bad = preparation.duplicate(true)
	bad.craft.fireteam_definitions[1].member_unit_ids = ["pilot"]
	check(not store.validate_payload(bad).ok, "nonempty pilot team still requires a leader")
	bad = preparation.duplicate(true)
	bad.craft.staged_unit_ids = ["pilot"]
	check(store.validate_payload(bad).ok, "unassigned pilot may stage as real ground crew")
	bad = preparation.duplicate(true)
	bad.craft.fireteam_definitions[1].member_unit_ids = ["foreign"]
	check(not store.validate_payload(bad).ok, "empty team rejects foreign member")
	bad = preparation.duplicate(true)
	bad.craft.fireteam_definitions[1].member_loadouts = {"foreign":{}}
	check(not store.validate_payload(bad).ok, "empty team rejects foreign loadout")
	bad = preparation.duplicate(true)
	bad.craft.fireteam_definitions[1].member_unit_ids = ["leader"]
	check(not store.validate_payload(bad).ok, "nonempty team requires leader")
	bad = preparation.duplicate(true)
	bad.craft.fireteam_definitions[1].id = "ft1"
	check(not store.validate_payload(bad).ok, "empty team rejects duplicate identity")
	bad = preparation.duplicate(true)
	bad.craft.pilot_id = "leader"
	check(store.validate_payload(bad).ok, "any roster person may pilot while preserving permanent fireteam identity")
	var dep := {"craft_id":"campaign_craft","origin_location_id":"homebase","destination_location_id":"satellite_crash","landing_pad_id":"homebase_pad_01","job_id":"satellite_recovery"}
	check(campaign.apply_command(contract.build_command("bind_departure", dep, "dep"), {"departure_authorized":true}).ok, "bind real departure")
	check(campaign.apply_command(contract.build_command("activate_job", {"job_id":"satellite_recovery","craft_id":"campaign_craft"}, "act"), {"departure_authorized":true}).ok, "activate departed satellite")
	check(campaign.restore_state(JSON.parse_string(JSON.stringify(campaign.export_state()))).ok, "active owner roundtrip")
	var victory := {"runtime_evidence":{"scenario_id":"satellite_recovery","result":"victory","mission_scenario_runtime_gates":{"all_gates_complete":true,"completed_step_ids":["secure_satellite","return_to_ship"]}}}
	var completed: Dictionary = campaign.apply_command(contract.build_command("complete_job", {"job_id":"satellite_recovery"}, "done"), victory)
	check(completed.ok, "verified completion")
	if completed.ok:
		var supply_command := {"contract_category":"singleplayer_supply","operation":"apply_reward","request_id":"reward","payload":{"completion_id":"satellite_recovery:completed"}}
		check(supply.apply_command(supply_command, {"completion_receipt":completed.completion_receipt}).ok, "verified reward")
		check(supply.restore_state(JSON.parse_string(JSON.stringify(supply.export_state()))).ok, "reward owner JSON roundtrip")
		check(campaign.restore_state(JSON.parse_string(JSON.stringify(campaign.export_state()))).ok, "completed owner JSON roundtrip")
		var credits: int = supply.get_supply_snapshot().credits
		supply_command.request_id = "reward-new-id"
		check(supply.apply_command(supply_command, {"completion_receipt":completed.completion_receipt}).get("already_rewarded", false), "reward receipt survives restore")
		check(supply.get_supply_snapshot().credits == credits, "no duplicate persisted reward")
		owner.configure()
		owner.apply_command(command, {"runtime_evidence":{"base_ready":true}})
		owner.apply_command(command, {"runtime_evidence":{"satellite_completed":true,"satellite_home":true}})
		payload.campaign = campaign.export_state()
		payload.campaign.departures_by_craft_id = {}
		payload.campaign.selected_location_id = "homebase"
		payload.campaign.selected_job_id = ""
		payload.supply = supply.export_state()
		payload.onboarding = owner.export_state()
		check(store.save_checkpoint(payload, checkpoint).ok, "satellite home checkpoint")
		check(store.load_checkpoint(checkpoint).ok, "satellite home continue")
		bad = payload.duplicate(true)
		bad.supply.reward_receipts = {}
		check(not store.validate_payload(bad).ok, "missing reward receipt rejected")
		bad = payload.duplicate(true)
		bad.onboarding.stage_index = 3
		check(not store.validate_payload(bad).ok, "completed onboarding requires trade receipts")
		var buy := {"contract_category":"singleplayer_supply","operation":"buy","payload":{"offer_id":"medictool_supply","quantity":1},"request_id":"buy"}
		check(supply.apply_command(buy, {"location_id":"trade_outpost","craft_busy":false}).ok, "actual trade purchase")
		var refuel := {"contract_category":"singleplayer_supply","operation":"refuel","payload":{"craft_id":"campaign_craft","amount":1.0},"request_id":"refuel"}
		check(supply.apply_command(refuel, {"location_id":"trade_outpost","craft_busy":false}).ok, "actual refuel")
		owner.apply_command(command, {"runtime_evidence":{"trade_departed":true,"trade_used":true,"bought":true,"refueled":true,"trade_home":true}})
		payload.supply = supply.export_state()
		payload.onboarding = owner.export_state()
		check(store.save_checkpoint(payload, checkpoint).ok, "completed campaign checkpoint")
		check(store.load_checkpoint(checkpoint).ok, "completed campaign continue")
	print("CAMPAIGN_DOMAIN failures=", failures)
	quit(0 if failures == 0 else 1)
