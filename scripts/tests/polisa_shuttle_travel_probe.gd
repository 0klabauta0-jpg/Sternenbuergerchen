extends SceneTree
## Diagnostic only: probes the existing travel owner; it does not spawn or board a shuttle.
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")

func _init() -> void:
	call_deferred("_run")

func _command(fleet: RefCounted, operation: String, payload: Dictionary, id: String = "") -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":id}, {"runtime_authorized":true})

func _run() -> void:
	var fleet = FLEET.new()
	var failures: Array[String] = []
	var craft := "station_shuttle_probe"
	_check(failures, fleet.configure().get("ok", false), "configure fleet")
	var registered := _command(fleet, "initialize_surface", {"craft_id":craft, "location_id":"polisa"}, "probe-init")
	_check(failures, registered.get("ok", false), "register shuttle at Polisa")
	_check(failures, not fleet.all_grounded(), "foreign station craft blocks current all_grounded guard")
	_check(failures, _command(fleet, "enter_orbit", {"craft_id":craft}, "probe-depart").get("ok", false), "enter station orbit")
	_check(failures, _command(fleet, "start_quantum", {"craft_id":craft, "target_orbit_id":"moon_orbit"}, "probe-quantum").get("ok", false), "start home quantum")
	var before: Dictionary = fleet.get_craft_snapshot(craft)
	_check(failures, _command(fleet, "advance", {"delta_seconds":1.0}).get("ok", false), "advance fleet")
	var during: Dictionary = fleet.get_craft_snapshot(craft)
	_check(failures, float(during.get("progress", 0.0)) > float(before.get("progress", 0.0)), "quantum has observable progress")
	_check(failures, _command(fleet, "advance", {"delta_seconds":30.0}).get("ok", false), "finish quantum")
	_check(failures, String(fleet.get_craft_snapshot(craft).get("orbit_id", "")) == "moon_orbit", "arrive moon orbit")
	_check(failures, _command(fleet, "land_homebase", {"craft_id":craft}, "probe-land").get("ok", false), "land on travel owner")
	for failure in failures: printerr("FAIL: " + failure)
	print("PASS: travel owner accepts a timed independent route" if failures.is_empty() else "FAIL: shuttle travel probe")
	quit(0 if failures.is_empty() else 1)

func _check(failures: Array[String], condition: bool, name: String) -> void:
	if not condition: failures.append(name)
