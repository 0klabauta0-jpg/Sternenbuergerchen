extends RefCounted
## Command-owned wing membership; pilot/craft ownership is supplied by runtime.
const CONTRACT = preload("res://scripts/mission/space_combat_command_contract.gd")
const MAX_MEMBERS := 6
var _wings: Dictionary = {}
var _craft_wings: Dictionary = {}
var _receipts: Dictionary = {}
var _revision := 0

func get_snapshot() -> Dictionary:
	var wings: Dictionary = _wings.duplicate(true)
	for id in wings:
		wings[id].erase("owner_id")
		wings[id]["active"] = not wings[id].craft_ids.is_empty()
	return {"revision": _revision, "wings": wings}

func apply_command(command: Dictionary, context: Dictionary = {}) -> Dictionary:
	var actor: Variant = context.get("actor_id")
	if typeof(actor) != TYPE_STRING or String(actor).strip_edges().is_empty() or context.get("authorized") != true:
		return _reject("authority_required")
	var operation: String = String(command.get("operation", ""))
	if operation not in ["wing_create", "wing_assign", "wing_remove", "wing_rename", "wing_leader_set"]:
		return _reject("unsupported_operation")
	var owned: Array = []
	var members: Dictionary = {}
	for wing_id in _wings:
		if _wings[wing_id].owner_id == actor:
			owned.append(wing_id)
			members[wing_id] = _wings[wing_id].craft_ids.duplicate()
	var validation_context := context.duplicate(true)
	validation_context["revision"] = _revision
	validation_context["owned_wings"] = owned
	validation_context["wing_members"] = members
	validation_context["receipts"] = _receipts.get(actor, {})
	var checked: Dictionary = CONTRACT.validate(command, validation_context)
	if not checked.get("ok", false) or checked.get("replayed", false):
		return checked
	var payload: Dictionary = command.payload
	var id: String = payload.wing_id
	match operation:
		"wing_create":
			if _wings.has(id): return _reject("wing_exists")
			_wings[id] = {"wing_id": id, "name": id, "owner_id": actor, "craft_ids": [], "leader_craft_id": ""}
		"wing_assign":
			var craft: String = payload.craft_id
			if _craft_wings.has(craft): return _reject("craft_already_assigned")
			if _wings[id].craft_ids.size() >= MAX_MEMBERS: return _reject("wing_full")
			var pilots: Variant = context.get("craft_pilots")
			if typeof(pilots) != TYPE_DICTIONARY or typeof(pilots.get(craft)) != TYPE_STRING or String(pilots[craft]).strip_edges().is_empty():
				return _reject("pilot_missing")
			for other_craft in _craft_wings:
				if typeof(pilots.get(other_craft)) != TYPE_STRING or String(pilots[other_craft]).is_empty():
					return _reject("pilot_mapping_incomplete")
				if pilots[other_craft] == pilots[craft]: return _reject("pilot_already_assigned")
			_wings[id].craft_ids.append(craft)
			_craft_wings[craft] = id
			if String(_wings[id].leader_craft_id).is_empty(): _wings[id].leader_craft_id = craft
		"wing_remove":
			var craft: String = payload.craft_id
			if not _wings[id].craft_ids.has(craft): return _reject("not_member")
			_wings[id].craft_ids.erase(craft)
			_craft_wings.erase(craft)
			if _wings[id].craft_ids.is_empty():
				_wings.erase(id)
			elif _wings[id].leader_craft_id == craft:
				_wings[id].craft_ids.sort()
				_wings[id].leader_craft_id = _wings[id].craft_ids[0]
		"wing_rename":
			_wings[id].name = String(payload.name).strip_edges()
		"wing_leader_set":
			_wings[id].leader_craft_id = payload.leader_craft_id
	_revision += 1
	var result := {"ok": true, "reason": "", "revision": _revision, "replayed": false}
	if not _receipts.has(actor): _receipts[actor] = {}
	_receipts[actor][command.request_id] = {"signature": checked.signature, "result": result.duplicate(true)}
	return result

func _reject(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "revision": _revision, "replayed": false}
