extends RefCounted
## Adapter intent projection only; Flight/navigation and capability have owners.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const SURFACE_SCRIPT := "res://scripts/mission/orbit_surface_locations.gd"
const PENDING := ["_warp_entry_searches", "_warp_completion_intents", "_campaign_space_entry_searches", "_campaign_space_entry_origins"]
class Prepared extends RefCounted:
	pass
static var _records: Dictionary = {}

static func capture(adapter: Node, bindings: Dictionary) -> Dictionary:
	if not _adapter_valid(adapter) or not _bindings_valid(bindings) or not _stable(bindings.simulation_root): return _bad("orbit_checkpoint_unavailable")
	if adapter.get("_simulation") != bindings.simulation_root or adapter.get("_travel") != bindings.fleet or adapter.get("_campaign") != bindings.campaign or bindings.simulation_root.get("_space_combat_state") != bindings.combat: return _bad("orbit_owner_changed")
	var data := {"intents":adapter.get("_surface_orbit_intents").duplicate(true), "auto_disabled":adapter.get("_surface_orbit_auto_disabled").duplicate(true)}
	var requests: Dictionary = adapter.get("_space_operation_requests")
	if bindings.has("space_operation_requests") and bindings.space_operation_requests != requests: return _bad("orbit_request_owner_changed")
	var checked := _check_data(data, bindings, requests)
	if not checked.ok: return checked
	var encoded := CODEC.encode_value(data)
	if not encoded.ok: return encoded
	return {"schema":"orbit_intent_checkpoint.v1", "value":encoded.value}

static func prepare(adapter: Node, state: Dictionary, bindings: Dictionary) -> Dictionary:
	if not _adapter_valid(adapter) or not _bindings_valid(bindings) or adapter.get("_simulation") != bindings.simulation_root or not _stable(bindings.simulation_root) or not _keys(state,["schema","value"]) or state.schema != "orbit_intent_checkpoint.v1": return _bad("orbit_checkpoint_invalid")
	var decoded := CODEC.decode_value(state.value)
	if not decoded.ok or not decoded.value is Dictionary: return _bad("orbit_checkpoint_invalid")
	var checked := _check_data(decoded.value,bindings,bindings.get("space_operation_requests"))
	if not checked.ok: return checked
	for key in _records.keys():
		if _records[key].handle.get_ref() == null: _records.erase(key)
	if _records.size() >= 32: return _bad("orbit_checkpoint_capacity")
	var handle := Prepared.new()
	_records[handle.get_instance_id()] = {"handle":weakref(handle), "adapter":weakref(adapter), "old_stamp":_adapter_stamp(adapter), "bindings":bindings.duplicate(), "new_stamp":_owner_stamp(bindings), "data":decoded.value.duplicate(true)}
	return {"ok":true,"candidate":handle}

static func validate(adapter: Node, candidate: RefCounted, bindings: Dictionary) -> Dictionary:
	if candidate == null or not _records.has(candidate.get_instance_id()): return _bad("orbit_candidate_unknown")
	var record: Dictionary = _records[candidate.get_instance_id()]
	if record.handle.get_ref() != candidate or record.adapter.get_ref() != adapter or not _adapter_valid(adapter) or not _bindings_valid(bindings) or record.bindings != bindings or record.old_stamp != _adapter_stamp(adapter) or not _stable(bindings.simulation_root) or record.new_stamp != _owner_stamp(bindings): return _bad("orbit_candidate_stale")
	return _check_data(record.data,bindings,bindings.get("space_operation_requests"))

static func publish(adapter: Node, candidate: RefCounted) -> void:
	# Caller already validated every global candidate before owner assignment.
	var record: Dictionary = _records[candidate.get_instance_id()]
	adapter.set("_surface_orbit_intents",record.data.intents)
	adapter.set("_surface_orbit_auto_disabled",record.data.auto_disabled)
	_records.erase(candidate.get_instance_id())

static func _check_data(data: Dictionary, bindings: Dictionary, requests: Variant = null) -> Dictionary:
	if not _keys(data,["intents","auto_disabled"]) or not data.intents is Dictionary or not data.auto_disabled is Dictionary or data.intents.size() > 64 or data.auto_disabled.size() > 64: return _bad("orbit_intents_invalid")
	var routes: Dictionary = bindings.fleet.get_snapshot().get("routes",{})
	if routes.size() > 64: return _bad("orbit_checkpoint_capacity")
	var controls: Dictionary = bindings.combat.get_flight_controls()
	for craft in data.auto_disabled:
		if not _id(craft) or typeof(data.auto_disabled[craft]) != TYPE_BOOL or data.auto_disabled[craft] != true or not routes.has(craft) or bindings.fleet.get_flight_state(craft) == null: return _bad("orbit_preference_invalid")
	for craft in controls:
		var control: Variant = controls[craft]
		if not control is Dictionary: return _bad("orbit_control_invalid")
		if control.get("orbit_auto_braking",false): return _bad("orbit_braking_pending")
		if control.get("orbit_auto_transit",false) and (not data.intents.has(craft) or data.auto_disabled.has(craft)): return _bad("orbit_control_unmatched")
	var pending_ids := {}
	for craft in data.intents:
		if not _id(craft) or not routes.has(craft): return _bad("orbit_craft_unknown")
		var intent: Variant = data.intents[craft]
		if not intent is Dictionary or not intent.has_all(["location_id","target_orbit_id","status"]) or intent.size() > 6: return _bad("orbit_intent_invalid")
		for key in intent:
			if key in ["pending_approach","pending_warp"]:
				if not intent[key] is Dictionary: return _bad("orbit_pending_invalid")
			elif key not in ["location_id","target_orbit_id","status","direction","reason"] or typeof(intent[key]) != TYPE_STRING: return _bad("orbit_intent_unsupported")
		if not _id(intent.location_id) or not _id(intent.target_orbit_id) or intent.status not in ["warp","manual","flying","arrived"] or (intent.has("reason") and intent.reason.length() > 512): return _bad("orbit_transition_unsupported")
		var travel: Dictionary = bindings.fleet.get_craft_snapshot(craft)
		var flight: RefCounted = bindings.fleet.get_flight_state(craft)
		if flight == null or travel.get("location_orbits",{}).get(intent.location_id) != intent.target_orbit_id or not bindings.campaign.get_campaign_snapshot().get("locations",{}).has(intent.location_id): return _bad("orbit_route_mismatch")
		var pending_check := _check_pending(craft,intent,travel,data.auto_disabled,requests,pending_ids)
		if not pending_check.ok: return pending_check
		var orbit: Dictionary = travel.get("orbits",{}).get(intent.target_orbit_id,{})
		var body: Dictionary = travel.get("bodies",{}).get(orbit.get("body_id",""),{})
		if not ResourceLoader.exists(SURFACE_SCRIPT): return _bad("orbit_surface_catalog_unavailable")
		var surfaces: GDScript = load(SURFACE_SCRIPT)
		if surfaces == null or not surfaces.contains(body,intent.location_id): return _bad("orbit_surface_mismatch")
		var pose: Dictionary = flight.get_snapshot()
		var control: Dictionary = controls.get(craft,{})
		var actor: RefCounted = bindings.combat.get_actor(craft)
		if intent.status == "warp":
			if intent.size() != 3 or travel.get("phase") != "quantum" or travel.get("target_orbit_id") != intent.target_orbit_id or pose.get("coordinate_frame") != "strategic" or actor != null or not control.is_empty(): return _bad("orbit_warp_mismatch")
			continue
		if intent.get("direction") not in ["inbound","outbound"] or travel.get("phase") != "orbit" or travel.get("orbit_id") != intent.target_orbit_id or pose.get("coordinate_frame") != "local" or pose.get("motion_mode") != "tactical" or pose.get("space_area_id") != "orbit_approach:" + String(body.get("id","")).uri_encode() or actor != flight: return _bad("orbit_local_mismatch")
		var status: Dictionary = bindings.combat.get_flight_status(craft)
		if intent.status == "flying":
			if data.auto_disabled.has(craft) or control.get("orbit_auto_transit") != true or control.get("orbit_auto_location_id") != intent.location_id or control.get("orbit_auto_direction") != intent.direction or typeof(status.get("ok")) != TYPE_BOOL or status.get("ok") != true or status.get("reason") not in ["transit", ""]: return _bad("orbit_automatic_mismatch")
		elif intent.status == "arrived":
			if control.get("orbit_auto_transit",false) or status.get("ok") != true or status.get("reason") != "arrived": return _bad("orbit_arrival_unconfirmed")
		elif control.get("orbit_auto_transit",false): return _bad("orbit_manual_mismatch")
	return {"ok":true}

static func _check_pending(craft: String, intent: Dictionary, travel: Dictionary, disabled: Dictionary, requests: Variant, pending_ids: Dictionary) -> Dictionary:
	var approach: bool = intent.has("pending_approach")
	var warp: bool = intent.has("pending_warp")
	if not approach and not warp: return {"ok":true}
	if approach and warp or intent.status != "flying" or disabled.has(craft) or not requests is Dictionary: return _bad("orbit_pending_unavailable")
	var pending: Dictionary = intent.pending_approach if approach else intent.pending_warp
	if not _keys(pending,["request_id","signature"] if approach else ["request_id","signature","payload"]) or not _id(pending.request_id) or not _id(pending.signature) or pending_ids.has(pending.request_id) or requests.has(pending.request_id): return _bad("orbit_pending_request_conflict")
	var payload := {"craft_id":craft,"location_id":intent.location_id}
	var operation := "space_begin_approach"
	if approach:
		if intent.get("direction") != "inbound" or intent.location_id == "homebase": return _bad("orbit_pending_direction_invalid")
	else:
		if intent.get("direction") != "outbound" or not pending.payload is Dictionary: return _bad("orbit_pending_direction_invalid")
		payload = pending.payload
		if payload.size() != (3 if payload.has("target_orbit_marker_id") else 2) or not payload.has_all(["craft_id","target_orbit_id"]) or payload.craft_id != craft or not _id(payload.target_orbit_id) or payload.target_orbit_id == travel.get("orbit_id"): return _bad("orbit_pending_warp_invalid")
		var orbit: Variant = travel.get("orbits",{}).get(payload.target_orbit_id)
		if not orbit is Dictionary: return _bad("orbit_pending_target_unknown")
		var marker: Variant = payload.get("target_orbit_marker_id",GRID.ORBIT_MARKER_IDS[0])
		if not _id(marker) or GRID.orbit_marker(orbit,marker).is_empty(): return _bad("orbit_pending_target_unknown")
		operation = "space_start_quantum"
	if pending.signature != JSON.stringify({"operation":operation,"payload":payload},"",true): return _bad("orbit_pending_signature_invalid")
	pending_ids[pending.request_id] = true
	return {"ok":true}

static func _bindings_valid(bindings: Dictionary) -> bool:
	if not bindings.has_all(["simulation_root","fleet","combat","campaign"]) or bindings.size() != (5 if bindings.has("space_operation_requests") else 4): return false
	if bindings.has("space_operation_requests") and (not bindings.space_operation_requests is Dictionary or bindings.space_operation_requests.size() > 4096): return false
	for key in ["simulation_root","fleet","combat","campaign"]:
		if not is_instance_valid(bindings[key]): return false
	if not bindings.simulation_root is Node: return false
	for method in ["get_snapshot","get_craft_snapshot","get_flight_state"]:
		if not bindings.fleet.has_method(method): return false
	for method in ["get_flight_controls","get_flight_status","get_actor"]:
		if not bindings.combat.has_method(method): return false
	return bindings.campaign.has_method("get_campaign_snapshot")

static func _adapter_valid(adapter: Node) -> bool:
	if not is_instance_valid(adapter): return false
	var fields := {}
	for entry in adapter.get_property_list(): fields[String(entry.name)] = true
	if not fields.has_all(["_simulation","_travel","_campaign","_surface_orbit_path_enabled","_surface_orbit_intents","_surface_orbit_auto_disabled","_space_operation_requests"]): return false
	return typeof(adapter.get("_surface_orbit_path_enabled")) == TYPE_BOOL and adapter.get("_surface_orbit_intents") is Dictionary and adapter.get("_surface_orbit_auto_disabled") is Dictionary and adapter.get("_space_operation_requests") is Dictionary

static func _stable(root: Node) -> bool:
	if not is_instance_valid(root) or not root.has_method("get_space_flight_status") or root.get("is_processing_tick") or not root.get("command_queue").is_empty() or not root.get("effects_queue").is_empty(): return false
	for field in PENDING:
		if not root.get(field) is Dictionary or not root.get(field).is_empty(): return false
	return true

static func _adapter_stamp(adapter: Node) -> Dictionary:
	return {"root":adapter.get("_simulation"), "fleet":adapter.get("_travel"), "campaign":adapter.get("_campaign"), "capability":adapter.get("_surface_orbit_path_enabled"), "intents":adapter.get("_surface_orbit_intents").duplicate(true), "disabled":adapter.get("_surface_orbit_auto_disabled").duplicate(true), "requests":adapter.get("_space_operation_requests").duplicate(true)}

static func _owner_stamp(bindings: Dictionary) -> Dictionary:
	var snapshot: Dictionary = bindings.fleet.get_snapshot()
	var flights := {}
	for craft in snapshot.get("routes",{}):
		var flight: RefCounted = bindings.fleet.get_flight_state(craft)
		flights[craft] = {"owner":flight,"pose":flight.get_snapshot() if flight != null else {},"actor":bindings.combat.get_actor(craft),"status":bindings.combat.get_flight_status(craft)}
	return {"fleet":snapshot,"flights":flights,"controls":bindings.combat.get_flight_controls(),"campaign":bindings.campaign.get_campaign_snapshot(), "requests":bindings.get("space_operation_requests").duplicate(true) if bindings.has("space_operation_requests") else null}

static func _keys(value: Dictionary, fields: Array) -> bool:
	return value.size() == fields.size() and value.has_all(fields)
static func _id(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not value.strip_edges().is_empty() and value.length() <= 512
static func _bad(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
