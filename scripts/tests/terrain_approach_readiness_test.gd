extends SceneTree
const FLOW = preload("res://scripts/meta/meta_layer_flow.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
class RuntimeProbe extends Node:
	var travel_owner = TRAVEL.new()
	var forwarded := ""
	var request_result := {"ok": true}
	func _init() -> void:
		travel_owner.configure()
		command("launch_to_orbit")
		command("start_quantum", {"target_orbit_id": "glut_1a_orbit"})
		command("advance", {"delta_seconds": 3.0})
		command("begin_approach", {"location_id": "satellite_crash"})
	func command(operation: String, payload: Dictionary = {}) -> Dictionary:
		if operation != "advance": payload["craft_id"] = "probe"
		return travel_owner.apply_command({"contract_category": "singleplayer_space_travel", "operation": operation, "payload": payload}, {"runtime_authorized": true})
	func get_space_travel_snapshot(_craft_id: String = "") -> Dictionary: return travel_owner.get_snapshot()
	func get_snapshot() -> Dictionary: return {"space_travel": travel_owner.get_snapshot()}
	func enter_space_orbit(_craft_id: String) -> Dictionary: return command("enter_orbit")
	func request_operation(operation: String, _payload: Dictionary) -> Dictionary:
		forwarded = operation
		return request_result.duplicate(true)
var passed := 0
var failed := 0
func _init() -> void: call_deferred("_run")
func _check(ok: bool, label: String) -> void:
	passed += int(ok)
	failed += int(not ok)
	print("PASS: " if ok else "FAIL: ", label)
func _entry(preloader: Node = null) -> Dictionary:
	return {"remaining": 0.0, "started_msec": Time.get_ticks_msec(), "requires_resources": true,
		"prepared_map": _map, "preloader": preloader, "identity": {"craft_id": "probe", "location_id": "satellite_crash"},
		"previous_craft_location": "old_location"}
var _map
func _run() -> void:
	var flow := FLOW.new()
	if not flow.has_method("get_surface_preparation_snapshot"):
		_check(false, "Approach readiness snapshot API exists")
		flow.free()
		_finish()
		return
	var runtime := RuntimeProbe.new()
	flow.add_child(runtime)
	flow.set("_singleplayer_runtime", runtime)
	_map = MAP.load_from_file("res://maps/satellite_crash_site.json")
	var preloader := VIEW.new()
	preloader.hide()
	root.add_child(preloader)
	await process_frame
	preloader.configure_terrain_resource_prefill(_map)
	flow.get("_space_approaches")["probe"] = _entry(preloader)
	flow.call("_finish_space_approach", "probe")
	_check(runtime.travel_owner.get_snapshot().phase == "approach" and flow.get("_active_mission") == null, "Actual travel owner remains in approach and creates no mission before full readiness")
	var progress: Dictionary = flow.call("get_surface_preparation_snapshot", "probe")
	_check(progress.status == "preparing_resources" and progress.expected_chunks == 2161 and not progress.ready, "Readiness/progress comes from the actual whole-map preloader")
	_check(flow.call("_get_star_map_snapshot").map_preparation == progress, "StarMap provider projects the same owner loading snapshot")
	flow.call("_request_star_map_operation", "space_abort_quantum", {"craft_id": "probe"})
	_check(runtime.forwarded == "space_abort_quantum", "Existing star-map operations still use the runtime adapter")
	flow.get("_craft_location_runtime")["probe"] = "satellite_crash"
	var cancelled: Dictionary = flow.call("_request_star_map_operation", "space_cancel_approach", {"craft_id": "probe"})
	_check(cancelled.ok and runtime.travel_owner.get_snapshot().phase == "orbit" and runtime.travel_owner.get_snapshot().orbit_id == "glut_1a_orbit", "Cancel returns through the actual owner to the same destination orbit")
	_check(flow.get("_space_approaches").is_empty() and flow.get("_active_mission") == null and flow.get("_craft_location_runtime")["probe"] == "old_location", "Cancel starts no units and restores the preceding craft-location projection")
	_check(flow.call("get_surface_preparation_snapshot", "probe").status == "cancelled", "Cancellation stays visible in loading feedback")
	await process_frame
	runtime.command("begin_approach", {"location_id": "satellite_crash"})
	var failed_loader := VIEW.new()
	failed_loader.hide()
	root.add_child(failed_loader)
	await process_frame
	failed_loader.configure_terrain_resource_prefill(_map, 1)
	failed_loader.call("_process_terrain_resource_prefill")
	flow.get("_space_approaches")["probe"] = _entry(failed_loader)
	flow.call("_finish_space_approach", "probe")
	_check(runtime.travel_owner.get_snapshot().phase == "orbit" and flow.get("_active_mission") == null, "Budget failure aborts before mission and returns the actual owner to orbit")
	var failure: Dictionary = flow.call("get_surface_preparation_snapshot", "probe")
	_check(failure.status == "failed" and not failure.error.is_empty() and not failure.ready, "Failure is explicit and never partial-ready")
	await process_frame
	runtime.command("begin_approach", {"location_id": "satellite_crash"})
	var old: Dictionary = _entry()
	old.identity.location_id = "trade_outpost"
	flow.get("_space_approaches")["probe"] = old
	flow.call("_finish_space_approach", "probe")
	_check(runtime.travel_owner.get_snapshot().phase == "approach" and flow.get("_space_approaches").is_empty(), "Stale location job is discarded without changing a newer travel phase")
	var worker := Thread.new()
	worker.start(Callable(self, "_slow_data_result"))
	var threaded: Dictionary = _entry()
	threaded.map_worker = worker
	flow.get("_space_approaches")["probe"] = threaded
	flow.call("_request_star_map_operation", "space_cancel_approach", {"craft_id": "probe"})
	_check(runtime.travel_owner.get_snapshot().phase == "orbit" and flow.get("_space_approaches").is_empty(), "Cancel does not wait synchronously for an unfinished data worker")
	var join_deadline := Time.get_ticks_msec() + 1000
	while not flow.get("_retired_terrain_workers").is_empty() and Time.get_ticks_msec() < join_deadline:
		flow.call("_poll_retired_terrain_workers")
		await process_frame
	if worker.is_started(): worker.wait_to_finish()
	_check(flow.get("_retired_terrain_workers").is_empty() and flow.get("_active_mission") == null, "Retired data result is joined and cannot activate a stale mission")
	runtime.command("begin_approach", {"location_id": "satellite_crash"})
	var timed_out: Dictionary = _entry()
	timed_out.started_msec = Time.get_ticks_msec() - 180001
	flow.get("_space_approaches")["probe"] = timed_out
	flow.call("_finish_space_approach", "probe")
	_check(runtime.travel_owner.get_snapshot().phase == "orbit" and flow.call("get_surface_preparation_snapshot", "probe").status == "failed", "Loading timeout cannot leave an endless approach")
	flow.get("_surface_preparation_results")["other"] = {"status": "failed", "error": "other"}
	for old_status in ["failed", "cancelled"]:
		flow.get("_surface_preparation_results")["probe"] = {"status": old_status, "error": "old"}
		runtime.request_result = {"ok": false, "reason": "rejected"}
		var rejected: Dictionary = flow.call("_request_star_map_operation", "space_start_quantum", {"craft_id": "probe"})
		_check(not rejected.ok and flow.get_surface_preparation_snapshot("probe").status == old_status, "Rejected new journey preserves preceding " + old_status + " feedback")
		runtime.request_result = {"ok": true}
		var started: Dictionary = flow.call("_request_star_map_operation", "space_start_quantum", {"craft_id": "probe"})
		_check(started.ok and flow.get_surface_preparation_snapshot("probe").status == "idle", "Successful new journey clears preceding " + old_status + " feedback")
	_check(flow.get_surface_preparation_snapshot("other").error == "other", "New journey leaves another craft loading feedback unchanged")
	flow.free()
	await process_frame
	_finish()
func _slow_data_result() -> int:
	OS.delay_msec(80)
	return 1
func _finish() -> void:
	print("TERRAIN_APPROACH_READINESS %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
