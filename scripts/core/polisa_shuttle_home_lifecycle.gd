extends RefCounted
## Bound pad owner is authoritative; visuals only project this lifecycle.
const LANDING_SECONDS := 8.0
const DEPARTURE_SECONDS := 8.0
var _reserve: Callable
var _validate: Callable
var _release: Callable
var _craft := ""
var _person := ""
var _pad := ""
var _elapsed := 0.0
var _phase := "unconfigured"
var _seal_key := ""

func configure(reserve: Callable, validate: Callable, release: Callable) -> Dictionary:
	if _phase != "unconfigured" or not reserve.is_valid() or not validate.is_valid() or not release.is_valid(): return {"ok":false,"reason":"invalid_configuration"}
	_reserve = reserve; _validate = validate; _release = release
	_seal_key = str(Time.get_ticks_usec()) + ":" + str(randi())
	_phase = "idle"
	return {"ok":true}

func begin(craft: String, person: String) -> Dictionary:
	if _phase != "idle" or craft.strip_edges().is_empty() or person.strip_edges().is_empty(): return {"ok":false,"reason":"landing_unavailable"}
	var claim: Variant = _reserve.call(craft)
	if typeof(claim) != TYPE_DICTIONARY or not claim.get("ok", false): return claim if typeof(claim) == TYPE_DICTIONARY else {"ok":false,"reason":"invalid_pad_claim"}
	var pad := String(claim.get("pad_id", ""))
	if pad.is_empty() or not bool(_validate.call(craft, pad)):
		_release.call(craft, pad)
		return {"ok":false,"reason":"invalid_pad_claim"}
	_craft = craft; _person = person; _pad = pad; _elapsed = 0.0; _phase = "inbound"
	return {"ok":true,"pad_id":pad}

func advance(delta: float) -> Dictionary:
	if not is_finite(delta) or delta < 0.0 or delta > 60.0: return {"ok":false,"reason":"invalid_delta"}
	if _phase not in ["inbound", "departing"]: return {"ok":true}
	if not bool(_validate.call(_craft, _pad)): return {"ok":false,"reason":"pad_reservation_lost"}
	var duration := LANDING_SECONDS if _phase == "inbound" else DEPARTURE_SECONDS
	_elapsed = minf(duration, _elapsed + delta)
	if _elapsed >= duration: _phase = "landed" if _phase == "inbound" else "departed"
	return {"ok":true}

func landing_receipt() -> Dictionary:
	if _phase != "landed" or not bool(_validate.call(_craft, _pad)): return {}
	return {"craft_id":_craft,"pad_id":_pad,"seal":(_seal_key + _craft + ":" + _pad).sha256_text()}

func verify_landing(craft: String, receipt: Dictionary) -> bool:
	return craft == _craft and not receipt.is_empty() and receipt == landing_receipt()

## Authorizes an atomic transfer; the Base/Ground commit performs the exit.
func prepare_passenger_exit(person: String) -> Dictionary:
	if person != _person or landing_receipt().is_empty(): return {}
	return {"craft_id":_craft,"person_id":_person,"pad_id":_pad,"seal":(_seal_key + ":exit:" + _craft + ":" + _person + ":" + _pad).sha256_text()}

func verify_passenger_exit(craft: String, person: String, receipt: Dictionary) -> bool:
	return craft == _craft and person == _person and not receipt.is_empty() and receipt == prepare_passenger_exit(person)

func begin_departure(craft: String) -> Dictionary:
	if _phase != "landed" or craft != _craft or not bool(_validate.call(_craft, _pad)): return {"ok":false,"reason":"departure_unavailable"}
	_phase = "departing"; _elapsed = 0.0
	return {"ok":true}

func departure_receipt() -> Dictionary:
	if _phase != "departed" or not bool(_validate.call(_craft, _pad)): return {}
	return {"craft_id":_craft,"pad_id":_pad,"seal":(_seal_key + ":depart:" + _craft + ":" + _pad).sha256_text()}

func verify_departure(craft: String, receipt: Dictionary) -> bool:
	return craft == _craft and not receipt.is_empty() and receipt == departure_receipt()

func verify_pad_binding(craft: String, pad: String) -> bool:
	return _phase in ["landed", "departing", "departed"] and craft == _craft and pad == _pad and bool(_validate.call(craft, pad))

func get_snapshot() -> Dictionary:
	var motion := {}
	if _phase == "inbound": motion = {"phase":"inbound","progress":_elapsed / LANDING_SECONDS}
	if _phase == "departing": motion = {"phase":"departing","progress":_elapsed / DEPARTURE_SECONDS}
	return {"phase":_phase,"craft_id":_craft,"landing_pad_id":_pad,"pad_visual":motion}

func release() -> void:
	if not _craft.is_empty(): _release.call(_craft, _pad)
	_craft = ""; _person = ""; _pad = ""; _elapsed = 0.0; _phase = "idle"
