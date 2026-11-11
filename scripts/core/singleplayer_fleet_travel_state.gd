extends RefCounted
## Index of the existing per-craft travel owners. No second movement simulation.
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
var _owners: Dictionary={}
var _focus := ""
var _surface_seal := str(Time.get_ticks_usec()) + ":" + str(randi())
var _empty: RefCounted
func configure() -> Dictionary:
	_owners.clear(); _focus=""; _empty=TRAVEL.new()
	return _empty.configure()
func register_craft(craft_id: String) -> void:
	if craft_id.is_empty() or _owners.has(craft_id): return
	var owner=TRAVEL.new(); owner.configure(); _owners[craft_id]=owner
	if _focus.is_empty(): _focus=craft_id
func unregister_craft(craft_id: String) -> void:
	_owners.erase(craft_id)
	if _focus == craft_id:
		_focus = String(_owners.keys()[0]) if not _owners.is_empty() else ""
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
