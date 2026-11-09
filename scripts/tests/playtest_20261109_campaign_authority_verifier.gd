extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var sim = load("res://scripts/core/simulation_root.gd").new()
	if not sim.has_method("configure_singleplayer_owners"):
		printerr("FAIL: SimulationRoot has durable singleplayer command boundary")
		sim.free()
		quit(1)
		return
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	campaign.configure()
	supply.configure([{"craft_id": "craft1"}])
	sim.configure_singleplayer_owners(campaign, supply)
	var response: Dictionary = sim.request_singleplayer_command({"contract_category": "singleplayer_campaign", "operation": "accept_job", "payload": {"job_id": "satellite_recovery"}, "request_id": "authority-accept"})
	var ok: bool = bool(response.get("ok", false)) and campaign.get_campaign_snapshot().accepted_job_ids.has("satellite_recovery")
	var rejected: Dictionary = sim.request_singleplayer_command({"contract_category": "unknown", "operation": "accept_job", "request_id": "unknown"})
	ok = ok and not bool(rejected.get("ok", true))
	var forged: Dictionary = sim.request_singleplayer_command({"contract_category": "singleplayer_campaign", "operation": "complete_job", "payload": {"job_id": "satellite_recovery", "runtime_evidence": {"result": "victory"}}, "request_id": "forged"})
	ok = ok and not bool(forged.get("ok", true))
	print("CAMPAIGN_AUTHORITY: ", "PASS" if ok else "FAIL")
	sim.free()
	quit(0 if ok else 1)
