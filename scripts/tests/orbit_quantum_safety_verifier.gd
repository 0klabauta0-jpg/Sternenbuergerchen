extends SceneTree
## Real operation bridge safety: invalid UI commands may not mutate fuel,
## campaign evidence or instantiate a location before the authorized handoff.

var _flow: Node
var _screen: Control
var _runtime: Node
var _craft_id: String
var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: ", label)

func _request(operation: String, payload: Dictionary = {}) -> Dictionary:
	var data: Dictionary = payload.duplicate(true)
	if not _craft_id.is_empty():
		data["craft_id"] = _craft_id
	return _screen.call("request_operation", operation, data)

func _snapshot() -> Dictionary:
	return _runtime.call("get_snapshot")

func _space() -> Dictionary:
	return Dictionary(_snapshot().get("space_travel", {}))

func _wait(predicate: Callable, milliseconds: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await physics_frame
	return false

func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	_flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	_craft_id = String(Dictionary(_screen.call("get_operations_snapshot").get("selected_craft", {})).get("id", ""))
	_check(not _craft_id.is_empty(), "Real bootstrap provides a real craft")
	if _craft_id.is_empty():
		await _finish()
		return
	_request("accept_job", {"job_id": "satellite_recovery"})
	_request("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	if personnel == null:
		_check(false, "Campaign exposes authoritative base personnel")
		await _finish()
		return
	var rejected_start: Dictionary = _request("start")
	_check(not bool(rejected_start.get("ok", false)), "Start rejects physically absent pilot")
	var boarding: Dictionary = _request("base_board", {"fireteam_id": "ft1", "whole_fireteam": true})
	_check(bool(boarding.get("ok", false)), "Public command starts physical crew boarding")
	var sim: Node = personnel.call("get_simulation_root")
	for tick in range(3000):
		sim.call("_physics_process", 0.05)
		_screen.call("_debug_advance_homebase_direct_boarding", 0.05)
		if personnel.call("is_pilot_aboard", _craft_id) and _screen.call("_has_homebase_direct_launch_payload_for_craft", _craft_id):
			break
	_check(bool(personnel.call("is_pilot_aboard", _craft_id)), "Pilot physically arrives aboard before launch")
	var before: Dictionary = _snapshot()
	_check(not _request("space_advance", {"delta_seconds": 3.0, "runtime_authorized": true}).get("ok", false), "UI cannot inject trusted travel ticks")
	var unauthorized: Dictionary = _runtime.get("_simulation").call("request_singleplayer_command", {"contract_category": "singleplayer_space_travel", "operation": "launch_to_orbit", "payload": {"craft_id": _craft_id, "runtime_authorized": true}, "request_id": "forged-launch"})
	_check(not bool(unauthorized.get("ok", false)) and _space().phase == "grounded", "Payload cannot forge SimulationRoot lifecycle context")
	_check(_snapshot().supply == before.supply and _snapshot().campaign == before.campaign, "Rejected forged requests preserve all campaign and supply values")
	var launch: Dictionary = _request("start")
	_check(bool(launch.get("ok", false)), "Actual start operation takes off")
	if not bool(launch.get("ok", false)):
		print("SAFETY_LAUNCH:", launch)
		await _finish()
		return
	_check(_flow.get("_active_mission") == null and _space().phase == "orbit", "Launch reaches orbit without loading a map")
	var orbit: Dictionary = _space()
	_check(not _request("space_start_quantum", {"target_orbit_id": "unmapped_orbit"}).get("ok", false) and _space() == orbit, "Unknown quantum target preserves exact current state")
	_check(not _request("space_begin_approach", {"location_id": "satellite_crash"}).get("ok", false), "Wrong-orbit approach rejected")
	_check(_snapshot().supply == before.supply and _snapshot().campaign == before.campaign, "Wrong-orbit approach debits no fuel and activates no job")
	_check(not _request("space_close_map").get("ok", false), "Away craft cannot dismiss its trip as a home arrival")
	var jump: Dictionary = _request("space_start_quantum", {"target_orbit_id": "planet_orbit", "request_id": "safety:jump"})
	_check(bool(jump.get("ok", false)), "Valid quantum target accepted")
	var begun: Dictionary = _space()
	var replay: Dictionary = _request("space_start_quantum", {"target_orbit_id": "planet_orbit", "request_id": "safety:jump"})
	_check(bool(replay.get("ok", false)) and _space() == begun, "Repeated quantum request does not reset trip or phase")
	_check(not _request("space_land_homebase").get("ok", false), "Quantum cannot fabricate home landing")
	_check(not _request("space_begin_approach", {"location_id": "satellite_crash", "runtime_authorized": true}).get("ok", false), "Quantum cannot fabricate surface handoff")
	_check(_flow.get("_active_mission") == null and _snapshot().supply == before.supply and _snapshot().campaign == before.campaign, "Quantum and rejected lifecycle requests leave job and economy untouched")
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "planet_orbit", 5000):
		_check(false, "Actual short quantum arrives through normal runtime")
		await _finish()
		return
	_check(true, "Actual short quantum arrives through normal runtime")
	var reused_id: Dictionary = _request("space_begin_approach", {"location_id": "satellite_crash", "request_id": "safety:jump"})
	_check(not bool(reused_id.get("ok", false)) and String(reused_id.get("reason", "")) == "request_id_conflict", "Quantum request ID cannot be reused for a different public operation")
	_check(_snapshot().supply == before.supply and _snapshot().campaign == before.campaign, "Request ID conflict is rejected before approach fuel and job transactions")
	_check(not _request("space_begin_approach", {"location_id": "trade_outpost"}).get("ok", false), "Unselected location cannot consume the selected job departure")
	_check(_snapshot().supply == before.supply and _snapshot().campaign == before.campaign, "Mismatched location leaves campaign and economy untouched")
	var approach: Dictionary = _request("space_begin_approach", {"location_id": "satellite_crash", "request_id": "safety:approach"})
	_check(bool(approach.get("ok", false)), "Explicit selected approach accepted")
	var bound: Dictionary = _snapshot()
	_check(_flow.get("_active_mission") == null and _space().phase == "approach", "Map remains absent during visible star-map exit")
	var duplicate: Dictionary = _request("space_begin_approach", {"location_id": "satellite_crash", "request_id": "safety:approach"})
	_check(bool(duplicate.get("ok", false)) and _snapshot().supply == bound.supply and _snapshot().campaign == bound.campaign and _space() == bound.space_travel, "Repeated approach acknowledges once without another fuel debit or activation")
	var conflicting: Dictionary = _request("space_begin_approach", {"location_id": "trade_outpost", "request_id": "safety:approach"})
	_check(not bool(conflicting.get("ok", false)) and String(conflicting.get("reason", "")) == "request_id_conflict" and _snapshot().supply == bound.supply and _snapshot().campaign == bound.campaign, "Same approach ID with different destination is rejected without mutations")
	var arrived: bool = await _wait(func(): return _flow.get("_active_mission") != null, 12000)
	if not arrived: print("APPROACH_DIAG ", _flow.call("get_surface_preparation_snapshot", _craft_id))
	_check(arrived, "Accepted approach eventually instantiates actual map")
	await _finish()

func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("ORBIT_QUANTUM_SAFETY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)
