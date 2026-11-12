extends RefCounted
## Runtime-owned service. Lifecycle receipts are verified by the bound owner;
## the separate fleet is not the player's ship inventory. The physical actor,
## pilot, boarding and landings must be produced by the caller's lifecycle.
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const WAIT_SECONDS := 300.0
var _fleet = FLEET.new()
var _verify: Callable
var _person_status: Callable
var _phase := "unconfigured"
var _person := ""
var _craft := ""
var _elapsed := 0.0
var _prepare_key := str(Time.get_ticks_usec()) + ":" + str(randi())

func configure(verify_lifecycle: Callable, person_status: Callable) -> Dictionary:
	if _phase != "unconfigured" or not verify_lifecycle.is_valid() or not person_status.is_valid(): return _reject("invalid_configuration")
	var result: Dictionary = _fleet.configure()
	if not result.get("ok", false): return result
	_verify = verify_lifecycle
	_person_status = person_status
	_phase = "idle"
	return {"ok":true}

func begin(person: String, craft: String, receipt: Dictionary) -> Dictionary:
	if _phase != "idle" or person.is_empty() or craft.is_empty(): return _reject("unavailable")
	if not _verified("boarding_polisa", person, craft, receipt): return _reject("boarding_unverified")
	var result := _command("initialize_surface", {"craft_id":craft,"location_id":"polisa"}, "station-init:" + craft)
	if not result.get("ok", false): return result
	_person = person
	_craft = craft
	_phase = "station_departure_pending"
	return _depart_station()

func _depart_station() -> Dictionary:
	var route: Dictionary = _fleet.get_craft_snapshot(_craft)
	if route.get("phase") == "surface":
		var depart := _command("enter_orbit", {"craft_id":_craft}, "station-depart:" + _craft)
		if not depart.get("ok", false): return depart
	var result := _command("start_quantum", {"craft_id":_craft,"target_orbit_id":"moon_orbit"}, "home-quantum:" + _craft)
	if result.get("ok", false): _phase = "to_home"
	return result

func advance(delta: float) -> Dictionary:
	if not is_finite(delta) or delta < 0.0 or delta > 60.0: return _reject("invalid_delta")
	if _phase == "station_departure_pending": return _depart_station()
	if _phase == "home_departure_pending": return _depart_home()
	if _phase in ["to_home", "to_station"]:
		var result := _command("advance", {"delta_seconds":delta}, "")
		if not result.get("ok", false): return result
		var route: Dictionary = _fleet.get_craft_snapshot(_craft)
		if route.get("phase") == "orbit":
			_phase = "home_landing_required" if _phase == "to_home" else "station_landing_required"
	elif _phase == "home_waiting":
		var status: Variant = _person_status.call(_person)
		if typeof(status) != TYPE_DICTIONARY or typeof(status.get("has_bed")) != TYPE_BOOL or typeof(status.get("has_task")) != TYPE_BOOL:
			return _reject("person_status_unavailable")
		if status.has_bed or status.has_task: _phase = "settled"
		else:
			_elapsed = minf(WAIT_SECONDS, _elapsed + delta)
			if _elapsed >= WAIT_SECONDS: _phase = "return_boarding_required"
	return {"ok":true}

func confirm_landing(receipt: Dictionary) -> Dictionary:
	if _phase != "home_landing_required": return _reject("landing_unavailable")
	if not _verified("landing_home", _person, _craft, receipt): return _reject("landing_unverified")
	var result := _command("land_homebase", {"craft_id":_craft}, "home-land:" + _craft)
	if result.get("ok", false): _phase = "home_disembark_required"
	return result

func validate_disembark(receipt: Dictionary) -> Dictionary:
	if _phase != "home_disembark_required": return _reject("disembark_unavailable")
	if not _verified("disembark_home", _person, _craft, receipt): return _reject("disembark_unverified")
	return {"ok":true}

func prepare_home_disembark(receipt: Dictionary) -> Dictionary:
	var valid := validate_disembark(receipt)
	if not valid.ok: return valid
	var handle := {"ok":true,"service_id":get_instance_id(),"person_id":_person,"craft_id":_craft,"receipt":receipt.duplicate(true)}
	handle["seal"] = _sign_home_disembark(handle)
	return handle

func _sign_home_disembark(handle: Dictionary) -> String:
	return (_prepare_key + JSON.stringify([handle.get("service_id"),handle.get("person_id"),handle.get("craft_id"),handle.get("receipt")], "", true)).sha256_text()

func validate_prepared_home_disembark(handle: Dictionary) -> Dictionary:
	if handle.get("ok") != true or handle.get("service_id") != get_instance_id() or handle.get("person_id") != _person or handle.get("craft_id") != _craft or typeof(handle.get("receipt")) != TYPE_DICTIONARY or handle.get("seal") != _sign_home_disembark(handle):
		return _reject("invalid_disembark_preparation")
	var valid := validate_disembark(handle.receipt)
	if not valid.ok: return valid
	return {"ok":true,"seal":handle.seal}

## Internal no-fail tail after the bound coordinator validated both owners.
## No callback, signal or further fallible operation may occur in this tail.
func _publish_prepared_home_disembark(_handle: Dictionary, _validation: Dictionary) -> Dictionary:
	_elapsed = 0.0
	_phase = "home_waiting"
	return {"ok":true}

func confirm_disembark(receipt: Dictionary) -> Dictionary:
	var prepared := prepare_home_disembark(receipt)
	if not prepared.ok: return prepared
	var valid := validate_prepared_home_disembark(prepared)
	if not valid.ok: return valid
	return _publish_prepared_home_disembark(prepared, valid)

func begin_return(receipt: Dictionary) -> Dictionary:
	if _phase != "return_boarding_required": return _reject("return_unavailable")
	if not _verified("boarding_home", _person, _craft, receipt): return _reject("boarding_unverified")
	_phase = "home_departure_pending"
	return _depart_home()

func _depart_home() -> Dictionary:
	var route: Dictionary = _fleet.get_craft_snapshot(_craft)
	if route.get("phase") == "grounded":
		var depart := _command("launch_to_orbit", {"craft_id":_craft}, "home-depart:" + _craft)
		if not depart.get("ok", false): return depart
	var result := _command("start_quantum", {"craft_id":_craft,"target_orbit_id":"polisa_orbit"}, "station-quantum:" + _craft)
	if result.get("ok", false): _phase = "to_station"
	return result

func confirm_station_landing(receipt: Dictionary) -> Dictionary:
	if _phase != "station_landing_required": return _reject("landing_unavailable")
	if not _verified("landing_polisa", _person, _craft, receipt): return _reject("landing_unverified")
	var route: Dictionary = _fleet.get_craft_snapshot(_craft)
	if route.get("phase") == "orbit":
		var approach := _command("begin_approach", {"craft_id":_craft,"location_id":"polisa"}, "station-approach:" + _craft)
		if not approach.get("ok", false): return approach
	elif route.get("phase") != "approach" or route.get("location_id") != "polisa":
		return _reject("station_route_changed")
	var landed := _command("finish_approach", {"craft_id":_craft}, "station-land:" + _craft)
	if landed.get("ok", false): _phase = "station_disembark_required"
	return landed

func confirm_station_disembark(receipt: Dictionary) -> Dictionary:
	if _phase != "station_disembark_required": return _reject("disembark_unavailable")
	if not _verified("disembark_polisa", _person, _craft, receipt): return _reject("disembark_unverified")
	_phase = "returned"
	return {"ok":true}

func retire_home(receipt: Dictionary) -> Dictionary:
	if _phase != "settled": return _reject("retirement_unavailable")
	if not _verified("shuttle_retired_home", _person, _craft, receipt): return _reject("retirement_unverified")
	var status: Variant = _person_status.call(_person)
	if typeof(status) != TYPE_DICTIONARY or status.get("ok") != true: return _reject("person_status_unavailable")
	_fleet.unregister_craft(_craft)
	_person = ""
	_craft = ""
	_elapsed = 0.0
	_phase = "idle"
	return {"ok":true}

## Station-side verifier must attest both independent person persistence and
## actual removal of the service ship from its station pad.
func retire_station(receipt: Dictionary) -> Dictionary:
	if _phase != "returned": return _reject("retirement_unavailable")
	if not _verified("shuttle_retired_polisa", _person, _craft, receipt): return _reject("retirement_unverified")
	_fleet.unregister_craft(_craft)
	_person = ""
	_craft = ""
	_elapsed = 0.0
	_phase = "idle"
	return {"ok":true}

func get_snapshot() -> Dictionary:
	# No shuttle/person restore owner exists yet, including at a terminal state.
	return {"phase":_phase,"person_id":_person,"craft_id":_craft,"wait_seconds":_elapsed,"route":_fleet.get_craft_snapshot(_craft) if not _craft.is_empty() else {},"checkpoint_safe":_phase == "idle"}

func _command(operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return _fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":operation,"payload":payload,"request_id":request_id}, {"runtime_authorized":true})

func _verified(kind: String, person: String, craft: String, receipt: Dictionary) -> bool:
	var result: Variant = _verify.call(kind, person, craft, receipt)
	return typeof(result) == TYPE_BOOL and result == true

func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
