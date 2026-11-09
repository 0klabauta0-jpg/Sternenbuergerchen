extends SceneTree
var failed := 0
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var craft: String = String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"})
	screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	_check(runtime.call("authorize_departure", craft).get("ok", false), "Fixture uses actual authorized departure binding")
	# Focused mid-flight boundary fixture, not a full transport acceptance test.
	flow.set("_aircraft_location_by_craft", {craft: "mission"})
	_check(screen.call("request_operation", "abandon_job", {"job_id": "satellite_recovery"}).get("ok", false), "Abandon records failed mission without erasing return binding")
	var retry: Dictionary = screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"})
	_check(not retry.get("ok", true) and retry.get("reason") == "retry_requires_home", "Retry while away is rejected")
	_check(runtime.call("get_snapshot").campaign.departures_by_craft_id.has(craft), "Rejected retry retains original route identity")
	_check(runtime.call("authorize_return", craft).get("ok", false), "Craft can still authorize its original reverse route")
	flow.set("_aircraft_location_by_craft", {craft: "homebase"})
	_check(screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Failed job can be retried after actual home boundary")
	_check(String(runtime.call("get_snapshot").campaign.jobs.satellite_recovery.status) == "accepted", "Retry returns same job to accepted state")
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_RETRY failed=", failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value:
		failed += 1
	print("PASS: " if value else "FAIL: ", label)
