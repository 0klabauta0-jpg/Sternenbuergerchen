extends SceneTree
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
const CHECKPOINT = preload("res://scripts/meta/campaign_checkpoint_store.gd")
var failures: Array = []
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, label: String) -> void:
	if not value: failures.append(label)
	print("POLISA ", label, ": ", "PASS" if value else "FAIL")
func _run() -> void:
	var travel = load("res://scripts/core/singleplayer_space_travel_state.gd").new()
	check(travel.configure().get("ok", false), "strategic_definition")
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	check(campaign.configure().get("ok", false), "campaign_locations")
	var departure := {"craft_id":"test_craft","origin_location_id":"homebase","destination_location_id":"polisa","landing_pad_id":"homebase_pad_03","job_id":""}
	check(not campaign.validate_departure(departure, {"departure_authorized":true}).get("ok", false) and campaign.validate_departure(departure, {"departure_authorized":true,"built_home_pad_ids":["homebase_pad_03"]}).get("ok", false), "extra_pad_requires_runtime_proof")
	var args := OS.get_cmdline_user_args()
	if args.size() != 1: quit(2); return
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	check(CHECKPOINT.validate_payload(original).get("ok", false), "legacy_checkpoint")
	var supply = SUPPLY.new()
	check(supply.restore_state(original.supply).get("ok", false), "legacy_supply_additive_restore")
	supply.set("_credits", 10000) # Bounded fixture funding, never a gameplay grant.
	var context := {"location_id":"polisa","craft_busy":false,"station_service_verified":true,"second_pad_built":true,"station_pad_builder":func(_count: int): return {"ok":true}}
	var build := COMMANDS.build_command("station_build_home_pad", {}, "polisa-test-pad3")
	var built: Dictionary = supply.apply_command(build, context)
	check(built.get("ok", false) and built.get("home_pad_count") == 3, "paid_pad_receipt")
	var credits: int = supply.get_supply_snapshot().credits
	check(supply.apply_command(build, context).get("replayed", false) and supply.get_supply_snapshot().credits == credits, "pad_idempotence")
	context.station_ship_fulfillment = func(offer: Dictionary, request: String): return {"ok":true,"craft_id":"polisa_"+String(offer.model_id)+"_"+request.sha256_text().substr(0,12),"landing_pad_id":"homebase_pad_03","delivery_location_id":"homebase"}
	var purchase := COMMANDS.build_command("station_buy_ship", {"offer_id":"polisa_ship_cutlass"}, "polisa-test-ship")
	var bought: Dictionary = supply.apply_command(purchase, context)
	check(bought.get("ok", false), "ship_purchase_receipt")
	credits = supply.get_supply_snapshot().credits
	check(supply.apply_command(purchase, context).get("replayed", false) and supply.get_supply_snapshot().credits == credits, "ship_idempotence")
	var ship_id := String(bought.get("craft_id", ""))
	supply.register_craft(ship_id)
	var payload := original.duplicate(true)
	payload.supply = supply.export_state()
	for location: String in payload.get("location_resources", {}):
		if payload.supply.location_resources.has(location): payload.location_resources[location].sites = payload.supply.location_resources[location].duplicate(true)
	var definition: Dictionary = payload.craft.definition.duplicate(true)
	definition.merge({"craft_id":ship_id,"model_id":"cutlass","craft_type":"dropship"}, true)
	payload.fleet.append({"definition":definition,"pilot_id":"","location":"homebase"})
	var validated := CHECKPOINT.validate_payload(payload)
	check(validated.get("ok", false), "three_ship_checkpoint_"+String(validated.get("reason", "ok")))
	var restored = SUPPLY.new()
	check(restored.restore_state(JSON.parse_string(JSON.stringify(payload.supply))).get("ok", false) and restored.get_station_home_pads() == 3, "serialized_pad_restore")
	var invalid := payload.duplicate(true)
	invalid.supply.requests.erase("polisa-test-pad3")
	check(not CHECKPOINT.validate_payload(invalid).get("ok", false), "reject_missing_build_receipt")
	invalid = payload.duplicate(true)
	invalid.supply.requests["polisa-test-pad3"].result.home_pad_count = 3.5
	check(not CHECKPOINT.validate_payload(invalid).get("ok", false), "reject_fractional_pad_receipt")
	invalid = payload.duplicate(true)
	invalid.fleet[-1].definition.craft_id = "polisa_unpaid"
	check(not CHECKPOINT.validate_payload(invalid).get("ok", false), "reject_unpaid_ship")
	invalid = payload.duplicate(true)
	invalid.supply.requests["polisa-test-ship"].result.landing_pad_id = "homebase_pad_03junk"
	check(not CHECKPOINT.validate_payload(invalid).get("ok", false), "reject_noncanonical_pad")
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json")
	check(map != null and map.get_grid_size() == Vector2i(512,256) and map.has_marker("polisa_pad_07") and not map.has_marker("polisa_pad_08") and map.get_marker_position("spawn_alpha").is_equal_approx(map.get_marker_position("polisa_pad_01")) and map.get_marker_position("ship_return").is_equal_approx(map.get_marker_position("polisa_pad_01")), "station_authored_pad_binding")
	var visual: Node = load("res://scenes/terrain/polisa_station_visual.tscn").instantiate()
	root.add_child(visual)
	check(visual.has_meta("polisa_visual_metrics") and int(visual.get_meta("polisa_visual_metrics").get("static_triangles", 0)) > 0, "cold_station_visual_build")
	var ui: Control = load("res://scripts/ui/polisa_station_screen.gd").new()
	root.add_child(ui)
	ui.configure(visual)
	ui.refresh({"credits":100,"service_ready":false})
	ui.call("_select_page", "ships")
	check(ui.get_node("Shop").visible, "station_menu_projection")
	ui.queue_free()
	visual.queue_free()
	print("POLISA RESULT failures=", failures)
	quit(0 if failures.is_empty() else 1)
