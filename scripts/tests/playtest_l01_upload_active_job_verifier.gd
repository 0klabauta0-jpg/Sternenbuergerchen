extends SceneTree
## Playtest 14.11.2026, L01: with the recovered chip in a local container at the home base,
## the data terminal offers the upload and completes the job exactly once, even when the
## job is still "active" because the mission result never reported its last step.
const C = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
var checks := 0
var failed := 0


func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS: ", label)
	else:
		failed += 1
		printerr("FAIL: ", label)


func _initialize() -> void:
	call_deferred("run")


func _chips(runtime: Node, container: String) -> int:
	var inventory: Dictionary = runtime.get("_supply").get_supply_snapshot().get("inventory", {})
	return int(Dictionary(Dictionary(inventory.get(container, {})).get("items", {})).get("satellite_chip", 0))


func run() -> void:
	root.size = Vector2i(1280, 720)
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	current_scene = flow
	for i in 24:
		await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var campaign: RefCounted = runtime.get("_campaign")
	var presenter: Node = screen.get("_operations_presenter")
	var craft_id := String(Array(flow.get("_homebase_aircraft_definitions"))[0].craft_id)
	check(bool(screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false)), "job accepted through the real screen")
	var departure := {"craft_id": craft_id, "origin_location_id": "homebase", "destination_location_id": "satellite_crash", "landing_pad_id": "homebase_pad_01", "job_id": "satellite_recovery"}
	check(bool(campaign.apply_command(C.build_command("bind_departure", departure, "l01:bind"), {"departure_authorized": true}).get("ok", false)), "departure bound")
	check(bool(campaign.apply_command(C.build_command("activate_job", {"job_id": "satellite_recovery", "craft_id": craft_id}, "l01:activate"), {"departure_authorized": true}).get("ok", false)), "job is active")
	check(Array(runtime.call("_home_services_snapshot").upload_job_ids).is_empty(), "active job without a chip at home offers no upload")
	check(not bool(runtime.call("request_operation", "campaign_upload", {"job_id": "satellite_recovery"}).get("ok", false)), "upload without a chip is rejected")
	check(String(campaign.get_campaign_snapshot().jobs.satellite_recovery.status) == "active", "rejected upload leaves the job active")
	var grant: Dictionary = runtime.call("_commit", "singleplayer_supply", "campaign_cargo", {"container_id": "base:homebase", "item_id": "satellite_chip", "amount": 1}, "l01:chip", {"campaign_authorized": true})
	check(bool(grant.get("ok", false)) and _chips(runtime, "base:homebase") == 1, "chip lies in the base storage")
	check(Array(runtime.call("_home_services_snapshot").upload_job_ids).has("satellite_recovery"), "chip at home makes the active job uploadable")
	presenter.call("_open_base_management", "data")
	await create_timer(0.6).timeout
	var services: Node = presenter.get("_services_view")
	var upload: Button = services.get("_campaign_buttons").campaign_upload.button
	check(upload.is_visible_in_tree() and not upload.disabled, "data terminal shows an enabled upload button")
	check(String(services.get("_section_note").text).contains("hochladen"), "terminal note points to the upload")
	var before: String = JSON.stringify(runtime.get("_supply").export_state())
	upload.pressed.emit()
	await create_timer(0.4).timeout
	check(String(campaign.get_campaign_snapshot().jobs.satellite_recovery.status) == "completed", "pressing the button completes the job")
	check(_chips(runtime, "base:homebase") == 0, "chip is consumed exactly once")
	var after: String = JSON.stringify(runtime.get("_supply").export_state())
	check(after != before, "reward and chip consumption reached the supply owner")
	check(not bool(runtime.call("request_operation", "campaign_upload", {"job_id": "satellite_recovery"}).get("ok", false)), "second upload is rejected")
	check(JSON.stringify(runtime.get("_supply").export_state()) == after, "second upload changes neither stock nor money")
	flow.queue_free()
	current_scene = null
	for i in 4:
		await process_frame
	print("PLAYTEST_L01_UPLOAD checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)
