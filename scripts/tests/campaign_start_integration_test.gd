extends SceneTree

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var start: GDScript = load("res://scripts/meta/game_start_contract.gd")
	if not _check(start != null, "Explicit mode boundary exists"):
		quit(1)
		return
	start.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	_check(flow.has_method("is_campaign_start"), "Flow exposes actual entry mode")
	_check(Array(flow.get("_all_team_units")).size() == 2, "Campaign has exactly two NPCs including pilot")
	var state: Dictionary = flow.call("get_singleplayer_snapshot")
	_check(not Dictionary(state.get("onboarding", {})).is_empty(), "Actual SimulationRoot has onboarding owner")
	var screen: Control = flow.get_node("HomebaseScreen")
	var operations: Dictionary = screen.call("get_operations_snapshot")
	for id in ["campaign_leader","campaign_pilot"]:
		var actual_loadout: Dictionary=screen.call("_get_member_loadout",id)
		# Neue Kampagne seit 21.11.2026: nur Raumanzug, keine Waffen; Pistolen und Sanitaetsgeraet liegen im Basislager (Auftrag P1).
		_check(String(actual_loadout.armor)=="suit" and String(actual_loadout.weapon_1)=="none" and String(actual_loadout.weapon_2)=="none","Campaign starts in undersuit without weapons on "+id)
	var craft: Dictionary = operations.get("selected_craft", {})
	_check(not String(craft.get("pilot_id", "")).is_empty(), "Campaign has a real assigned pilot")
	_check(Array(flow.get("_selected_unit_ids")).size() == 1, "Exactly one deployable leader selected")
	var blocked: Dictionary = screen.call("request_operation", "select_destination", {"location_id": "trade_outpost"})
	_check(not bool(blocked.get("ok", false)), "Trade is locked before satellite lesson")
	flow.call("_show_homebase")
	_check(Array(flow.get("_all_team_units")).size() == 2, "Returning to base never repairs campaign to Skirmish roster")
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint", flow, flow.get("_singleplayer_runtime"))
	_check(bool(saved.get("ok", false)), "New base creates coherent first home checkpoint")
	if not saved.get("ok", false):
		print("SAVE_RESULT:", saved)
	var base: Control = screen.get("_operations_presenter").get("_base")
	base.call("set_transport_snapshot", state)
	_check(String(base.get("_map_path")) == "res://maps/campaign_intro_base.json", "Campaign uses its full-size homebase map")
	# Katalog der Kampagne: fuenf feste Besuchs-/Startszenarien plus jeder Auftrag, dessen Szenario dort noch fehlt (Adapter).
	var catalog_ids: Array = []
	for item: Dictionary in Array(flow.get("_mission_catalog")):
		catalog_ids.append(String(item.get("mission_id", "")))
	var campaign_jobs: Dictionary = Dictionary(flow.get("_singleplayer_runtime").get("_campaign").get_campaign_snapshot().get("jobs", {}))
	var expected_ids: Array = ["satellite_recovery", "polisa_visit", "trade_outpost_visit", "satellite_crash_visit", "trade_outpost_open_visit"]
	for job: Dictionary in campaign_jobs.values():
		if not expected_ids.has(String(job.scenario_id)):
			expected_ids.append(String(job.scenario_id))
	_check(campaign_jobs.size() >= 5 and catalog_ids.size() == expected_ids.size(), "Campaign offers every job plus the free visits (Auftraege %d, Katalog %d)" % [campaign_jobs.size(), catalog_ids.size()])
	for id in expected_ids:
		_check(catalog_ids.has(id), "Campaign catalog offers " + String(id))
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_START_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _check(value: bool, label: String) -> bool:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		printerr("FAIL: ", label)
	return value
