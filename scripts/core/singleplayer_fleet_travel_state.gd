extends RefCounted
## Index of the existing per-craft travel owners. No second movement simulation.
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
var _owners: Dictionary={}
var _focus := ""
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
