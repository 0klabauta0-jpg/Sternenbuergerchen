extends RefCounted
## Index of the existing per-craft travel owners. No second movement simulation.
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
var _owners: Dictionary={}
var _focus := ""
var _surface_seal := str(Time.get_ticks_usec()) + ":" + str(randi())
var _empty: RefCounted
var _space_area_authority: WeakRef
var _space_area_epoch := 0
var _space_area_seal := ""
var _space_area_contexts: Dictionary = {}
var _space_area_context_serials: Dictionary = {}
var _space_area_binding_serial := 0
var _space_area_bindings: Dictionary = {}
var _space_area_receipts: Dictionary = {}
func configure() -> Dictionary:
	_space_area_epoch += 1
	_space_area_seal = str(get_instance_id()) + ":" + str(_space_area_epoch) + ":" + str(Time.get_ticks_usec())
	_space_area_authority = null
	_space_area_contexts.clear(); _space_area_context_serials.clear(); _space_area_bindings.clear(); _space_area_receipts.clear()
	_owners.clear(); _focus=""; _empty=TRAVEL.new()
	return _empty.configure()
func register_craft(craft_id: String) -> void:
	if craft_id.is_empty() or _owners.has(craft_id): return
	var owner=TRAVEL.new(); owner.configure(craft_id); _owners[craft_id]=owner
	if _focus.is_empty(): _focus=craft_id
func unregister_craft(craft_id: String) -> void:
	_owners.erase(craft_id)
	if _focus == craft_id:
		_focus = String(_owners.keys()[0]) if not _owners.is_empty() else ""
func get_flight_state(craft_id: String) -> RefCounted:
	return _owners[craft_id].get_flight_state() if _owners.has(craft_id) else null
func get_craft_snapshot(craft_id: String) -> Dictionary:
	if not _owners.has(craft_id): return {}
	var snapshot: Dictionary = _owners[craft_id].get_snapshot()
	snapshot["craft_id"] = craft_id
	return snapshot
func focus_craft(craft_id: String) -> bool:
	if not _owners.has(craft_id): return false
	_focus=craft_id; return true
func get_snapshot(craft_id: String = "") -> Dictionary:
	var id:=_focus if craft_id.is_empty() else craft_id
	var snapshot: Dictionary=_owners[id].get_snapshot() if _owners.has(id) else _empty.get_snapshot()
	# Grounded legacy owner intentionally has no flight identity until launch.
	if _owners.has(id): snapshot["craft_id"]=id
	var routes: Dictionary={}
	for key in _owners:
		var route: Dictionary=_owners[key].get_snapshot(); route["craft_id"]=key; routes[key]=route
	snapshot["routes"]=routes; snapshot["focused_craft_id"]=_focus
	return snapshot
func is_quantum_active() -> bool:
	for owner in _owners.values():
		if owner.is_quantum_active(): return true
	return false
func all_grounded() -> bool:
	for owner in _owners.values():
		if String(owner.get_snapshot().phase)!="grounded": return false
	return true
func apply_command(command: Dictionary, context: Dictionary = {}) -> Dictionary:
	if String(command.get("operation", "")) == "initialize_surface":
		if command.get("contract_category") != "singleplayer_space_travel" or typeof(command.get("payload")) != TYPE_DICTIONARY or typeof(command.get("request_id")) != TYPE_STRING or String(command.request_id).strip_edges().is_empty(): return {"ok":false,"reason":"invalid_command"}
		if context.get("runtime_authorized") != true: return {"ok":false,"reason":"runtime_authority_required"}
		var args: Dictionary = command.get("payload", {})
		var craft_id := String(args.get("craft_id", ""))
		if _owners.has(craft_id):
			if String(_owners[craft_id].get_snapshot().get("craft_id", "")) != craft_id: return {"ok":false,"reason":"craft_already_registered"}
			return _owners[craft_id].apply_command(command, context)
		var prepared := prepare_surface_registration(craft_id, String(args.get("location_id", "")), String(command.get("request_id", "")))
		return commit_surface_registration(prepared) if prepared.get("ok", false) else prepared
	if String(command.get("operation",""))=="advance" and not Dictionary(command.get("payload",{})).has("craft_id"):
		# Preserve the original owner's authority/delta validation, including when idle.
		var validation: Dictionary=_empty.apply_command(command,context)
		if not validation.get("ok",false): return validation
		for owner in _owners.values():
			if owner.is_quantum_active(): owner.apply_command(command,context)
		return {"ok":true}
	var id:=String(Dictionary(command.get("payload",{})).get("craft_id",""))
	if not _owners.has(id): return {"ok":false,"reason":"unknown_craft","message":"Schiff ist nicht registriert"}
	var result: Dictionary=_owners[id].apply_command(command,context)
	if result.get("ok",false) and String(command.get("operation",""))=="launch_to_orbit": _focus=id
	return result


func prepare_surface_registration(craft_id: String, location_id: String, request_id: String) -> Dictionary:
	if craft_id.is_empty() or request_id.is_empty() or _owners.has(craft_id): return {"ok":false,"reason":"craft_already_registered"}
	var candidate = TRAVEL.new()
	var configured: Dictionary = candidate.configure()
	if not configured.get("ok", false): return configured
	var result: Dictionary = candidate.apply_command({"contract_category":"singleplayer_space_travel","operation":"initialize_surface","payload":{"craft_id":craft_id,"location_id":location_id},"request_id":request_id},{"runtime_authorized":true})
	if not result.get("ok", false): return result
	var prepared := {"ok":true,"craft_id":craft_id,"location_id":location_id,"request_id":request_id,"candidate":candidate}
	prepared["seal"] = _sign_surface_candidate(prepared)
	return prepared

func _sign_surface_candidate(prepared: Dictionary) -> String:
	var candidate: RefCounted = prepared.get("candidate")
	if candidate == null: return ""
	return (_surface_seal+JSON.stringify([prepared.get("craft_id"),prepared.get("location_id"),prepared.get("request_id"),candidate.get_snapshot()],"",true)).sha256_text()

func validate_surface_registration(prepared: Dictionary) -> Dictionary:
	var id := String(prepared.get("craft_id", ""))
	if not prepared.get("ok", false) or id.is_empty() or _owners.has(id) or String(prepared.get("seal", "")) != _sign_surface_candidate(prepared): return {"ok":false,"reason":"surface_registration_changed"}
	return {"ok":true}

func commit_surface_registration(prepared: Dictionary) -> Dictionary:
	var valid := validate_surface_registration(prepared)
	return _publish_surface_registration(prepared) if valid.get("ok", false) else valid

func _publish_surface_registration(prepared: Dictionary) -> Dictionary:
	# Internal transaction tail only: caller validated before its last fallible
	# owner commit; no awaits/signals/reentry may occur before this no-fail write.
	var id := String(prepared.craft_id)
	_owners[id] = prepared.candidate
	# Purchase does not choose the player's travel focus.
	return {"ok":true,"craft_id":id,"phase":"surface","location_id":String(prepared.location_id)}


# Unwired trusted in-process setup. Object identity is NOT a sandbox against
# arbitrary code with access to these internals; a UI bool/context ID is insufficient.
func configure_space_area_transition_authority(authority: Object) -> Dictionary:
	if not is_instance_valid(authority): return _area_reject("invalid_area_authority")
	if _space_area_authority != null:
		return {"ok":true} if _space_area_authority.get_ref() == authority else _area_reject("area_authority_already_bound")
	_space_area_authority = weakref(authority)
	return {"ok":true}

func _has_space_area_authority(authority: Object = null) -> bool:
	return _space_area_authority != null and is_instance_valid(_space_area_authority.get_ref()) and (authority == null or _space_area_authority.get_ref() == authority)

func _valid_space_area_context(context: Dictionary) -> bool:
	if context.size() != (11 if context.get("operation") == "start_quantum" else 9): return false
	for key in ["request_id","request_signature","operation","source_area_id","target_area_id","context_id","expected_phase"]:
		if typeof(context.get(key)) != TYPE_STRING: return false
	for key in ["request_id","request_signature","context_id","expected_phase"]:
		if String(context[key]).strip_edges().is_empty(): return false
	if typeof(context.get("expected_travel_revision")) != TYPE_INT or int(context.expected_travel_revision) < 0 or typeof(context.get("payload")) != TYPE_DICTIONARY: return false
	var payload: Dictionary = context.payload
	if typeof(payload.get("craft_id")) != TYPE_STRING or String(payload.craft_id).is_empty(): return false
	if context.operation == "advance":
		return payload.size() == 2 and typeof(payload.get("delta_seconds")) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(payload.delta_seconds))
	if context.operation == "begin_approach":
		return payload.size() == 2 and typeof(payload.get("location_id")) == TYPE_STRING and not String(payload.location_id).is_empty()
	if context.operation in ["launch_to_orbit", "land_homebase"]: return payload.size() == 1
	if context.operation == "start_quantum":
		if payload.size() not in [2, 3] or typeof(payload.get("target_orbit_id")) != TYPE_STRING or String(payload.target_orbit_id).is_empty() or (payload.has("target_orbit_marker_id") and typeof(payload.target_orbit_marker_id) != TYPE_STRING): return false
		for key in payload:
			if key not in ["craft_id", "target_orbit_id", "target_orbit_marker_id"]: return false
		if typeof(context.get("origin_position")) != TYPE_ARRAY or context.origin_position.size() != 2 or typeof(context.get("warp_multiplier")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(context.warp_multiplier)) or float(context.warp_multiplier) <= 0.0: return false
		for value in context.origin_position:
			if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)): return false
		return true
	return context.operation == "enter_orbit" and payload.size() == 1

func bind_space_area_transition_context(context: Dictionary, authority: Object) -> Dictionary:
	if not _has_space_area_authority(authority): return _area_reject("area_authority_required")
	if not _valid_space_area_context(context): return _area_reject("invalid_area_context")
	var binding := JSON.stringify(context, "", true)
	var request_id := String(context.request_id)
	var context_id := String(context.context_id)
	if _space_area_bindings.has(request_id) and String(_space_area_bindings[request_id]) != binding: return _area_reject("request_id_conflict")
	if _space_area_contexts.has(context_id) and String(_space_area_contexts[context_id]) != binding: return _area_reject("context_id_conflict")
	if not _space_area_contexts.has(context_id) and _space_area_contexts.size() >= 64: return _area_reject("too_many_area_contexts")
	if not _space_area_contexts.has(context_id):
		_space_area_binding_serial += 1
		_space_area_context_serials[context_id] = _space_area_binding_serial
	_space_area_contexts[context_id] = binding
	_space_area_bindings[request_id] = binding
	return {"ok":true}

func release_space_area_transition_context(context_id: String, authority: Object) -> Dictionary:
	if not _has_space_area_authority(authority): return _area_reject("area_authority_required")
	var binding := String(_space_area_contexts.get(context_id, ""))
	_space_area_contexts.erase(context_id)
	_space_area_context_serials.erase(context_id)
	for request_id: String in _space_area_bindings.keys():
		if String(_space_area_bindings[request_id]) == binding and not _space_area_receipts.has(request_id): _space_area_bindings.erase(request_id)
	return {"ok":true}

func _check_bound_space_area_context(context: Dictionary) -> Dictionary:
	if not _has_space_area_authority() or not _valid_space_area_context(context): return _area_reject("area_authority_required")
	var binding := JSON.stringify(context, "", true)
	var context_id := String(context.context_id)
	if String(_space_area_contexts.get(context_id, "")) == binding: return {"ok":true}
	# A completed identical request remains replayable after its short-lived
	# context is released. Uncommitted/released candidates have no such receipt.
	var receipt: Dictionary = _space_area_receipts.get(String(context.request_id), {})
	return {"ok":true} if not receipt.is_empty() and String(receipt.context_binding) == binding else _area_reject("unregistered_area_context")

func prepare_space_area_transition(craft_id: String, expected_travel_revision: int, source_area_id: String, target_area_id: String, root_context: Dictionary) -> Dictionary:
	var authorized := _check_bound_space_area_context(root_context)
	if not authorized.get("ok", false): return authorized
	if String(root_context.payload.craft_id) != craft_id or int(root_context.expected_travel_revision) != expected_travel_revision or String(root_context.source_area_id) != source_area_id or String(root_context.target_area_id) != target_area_id: return _area_reject("area_context_arguments_changed")
	var binding := JSON.stringify(root_context, "", true)
	var request_id := String(root_context.request_id)
	if _space_area_receipts.has(request_id):
		var receipt: Dictionary = _space_area_receipts[request_id]
		if String(receipt.context_binding) != binding: return _area_reject("request_id_conflict")
		if not _space_area_receipt_owner_valid(receipt, craft_id): return _area_reject("travel_owner_changed")
		var replay := {"ok":true,"fleet_instance_id":get_instance_id(),"fleet_epoch":_space_area_epoch,"context":root_context.duplicate(true),"replay":true,"result":receipt.result.duplicate(true)}
		replay["seal"] = _sign_space_area_candidate(replay)
		return replay
	if not _owners.has(craft_id): return _area_reject("unknown_craft")
	var state: Dictionary = _owners[craft_id]._prepare_space_area_transition_state(expected_travel_revision, root_context)
	if not state.get("ok", false): return state
	var candidate := {"ok":true,"fleet_instance_id":get_instance_id(),"fleet_epoch":_space_area_epoch,
		"craft_id":craft_id,"travel_owner_instance_id":_owners[craft_id].get_instance_id(),"context_binding_serial":int(_space_area_context_serials.get(String(root_context.context_id), -1)),"context":root_context.duplicate(true),"state":state}
	candidate["seal"] = _sign_space_area_candidate(candidate)
	return candidate

func _sign_space_area_candidate(candidate: Dictionary) -> String:
	var content := candidate.duplicate(true)
	content.erase("seal")
	return (_space_area_seal + JSON.stringify(content, "", true)).sha256_text()

func validate_prepared_space_area_transition(candidate: Dictionary, root_context: Dictionary) -> Dictionary:
	var authorized := _check_bound_space_area_context(root_context)
	if not authorized.get("ok", false): return authorized
	if not candidate.get("ok", false) or int(candidate.get("fleet_instance_id", 0)) != get_instance_id() or int(candidate.get("fleet_epoch", -1)) != _space_area_epoch or String(candidate.get("seal", "")) != _sign_space_area_candidate(candidate): return _area_reject("invalid_area_candidate")
	if JSON.stringify(candidate.get("context", {}), "", true) != JSON.stringify(root_context, "", true): return _area_reject("area_context_changed")
	var receipt: Dictionary = _space_area_receipts.get(String(root_context.request_id), {})
	if not receipt.is_empty():
		if String(receipt.context_binding) != JSON.stringify(root_context, "", true): return _area_reject("request_id_conflict")
		if not _space_area_receipt_owner_valid(receipt, String(root_context.payload.craft_id)): return _area_reject("travel_owner_changed")
		return {"ok":true,"replayed":true,"result":receipt.result.duplicate(true)}
	if int(candidate.get("context_binding_serial", -1)) != int(_space_area_context_serials.get(String(root_context.context_id), -2)): return _area_reject("area_context_rebound")
	var id := String(candidate.get("craft_id", ""))
	if not _owners.has(id) or _owners[id].get_instance_id() != int(candidate.get("travel_owner_instance_id", 0)): return _area_reject("travel_owner_changed")
	return _owners[id]._validate_prepared_space_area_state(Dictionary(candidate.get("state", {})), root_context)

func commit_prepared_space_area_transition(candidate: Dictionary, root_context: Dictionary) -> Dictionary:
	var validation := validate_prepared_space_area_transition(candidate, root_context)
	if not validation.get("ok", false): return validation
	return _publish_prepared_space_area_transition(candidate, validation)

func _publish_prepared_space_area_transition(candidate: Dictionary, validation: Dictionary) -> Dictionary:
	# Root-private no-fail tail after validation and before ANY callbacks/signals.
	if validation.get("replayed", false):
		var replay: Dictionary = validation.result.duplicate(true); replay["replayed"] = true; return replay
	var result: Dictionary = _owners[String(candidate.craft_id)]._publish_prepared_space_area_state(candidate.state)
	if candidate.context.operation == "launch_to_orbit": _focus = String(candidate.craft_id)
	_space_area_receipts[String(candidate.context.request_id)] = {"context_binding":JSON.stringify(candidate.context, "", true),"result":result.duplicate(true),"travel_owner_instance_id":_owners[String(candidate.craft_id)].get_instance_id(),"travel_owner_epoch":int(_owners[String(candidate.craft_id)].get("_space_area_epoch"))}
	_space_area_contexts.erase(String(candidate.context.context_id))
	_space_area_context_serials.erase(String(candidate.context.context_id))
	return result

func _space_area_receipt_owner_valid(receipt: Dictionary, craft_id: String) -> bool:
	return _owners.has(craft_id) and _owners[craft_id].get_instance_id() == int(receipt.get("travel_owner_instance_id", 0)) and int(_owners[craft_id].get("_space_area_epoch")) == int(receipt.get("travel_owner_epoch", -1))

func _area_reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
