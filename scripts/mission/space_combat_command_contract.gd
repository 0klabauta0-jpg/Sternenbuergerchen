extends RefCounted
## Stateless validation only. Ownership and revision come from the trusted caller.

const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const OPERATIONS := ["wing_create", "wing_assign", "wing_remove", "wing_rename", "wing_leader_set", "order_issue", "order_cancel", "fire_rule_set", "assist_preference_set", "maneuver_request"]

static func validate(command: Dictionary, context: Dictionary) -> Dictionary:
	if command.get("contract_category") != "space_combat" or typeof(command.get("operation")) != TYPE_STRING:
		return _reject("invalid_envelope")
	var operation: String = command.operation
	if not OPERATIONS.has(operation):
		return _reject("unknown_operation")
	if typeof(command.get("request_id")) != TYPE_STRING or String(command.request_id).strip_edges().is_empty() or typeof(command.get("payload")) != TYPE_DICTIONARY:
		return _reject("invalid_envelope")
	if context.get("authorized") != true:
		return _reject("authority_required")
	if _has_authority_key(command):
		return _reject("untrusted_authority")
	if not _finite(command):
		return _reject("invalid_payload")
	var receipts: Variant = context.get("receipts", {})
	if typeof(receipts) != TYPE_DICTIONARY:
		return _reject("invalid_context")
	if receipts.has(command.request_id):
		var receipt: Variant = receipts[command.request_id]
		if typeof(receipt) != TYPE_DICTIONARY or typeof(receipt.get("signature")) != TYPE_STRING or typeof(receipt.get("result")) != TYPE_DICTIONARY:
			return _reject("invalid_context")
		if receipt.signature != request_signature(command):
			return _reject("request_id_conflict")
		var replay: Dictionary = receipt.result.duplicate(true)
		replay["replayed"] = true
		return replay
	if typeof(command.get("expected_revision")) != TYPE_INT or typeof(context.get("revision")) != TYPE_INT or command.expected_revision != context.revision:
		return _reject("stale_revision")
	if context.get("phase") not in ["grounded", "orbit", "tactical"]:
		return _reject("invalid_phase")
	var payload: Dictionary = command.payload
	if not _finite(payload):
		return _reject("invalid_payload")
	for key in ["wing_id", "craft_id", "leader_craft_id"]:
		if payload.has(key) and (typeof(payload[key]) != TYPE_STRING or String(payload[key]).strip_edges().is_empty()):
			return _reject("invalid_id")
	if payload.has("target_hex") and (typeof(payload.target_hex) != TYPE_VECTOR2I or not GRID.contains(payload.target_hex)):
		return _reject("invalid_hex")
	for key in ["area_hexes", "waypoints"]:
		if payload.has(key):
			if typeof(payload[key]) != TYPE_ARRAY or payload[key].is_empty():
				return _reject("invalid_hex")
			for cell in payload[key]:
				if typeof(cell) != TYPE_VECTOR2I or not GRID.contains(cell):
					return _reject("invalid_hex")
	if operation in ["wing_assign", "wing_remove"] and not payload.has_all(["wing_id", "craft_id"]):
		return _reject("missing_field")
	if operation == "wing_rename" and (not payload.has_all(["wing_id", "name"]) or typeof(payload.name) != TYPE_STRING or String(payload.name).strip_edges().is_empty()):
		return _reject("missing_field")
	if operation == "wing_leader_set" and not payload.has_all(["wing_id", "leader_craft_id"]):
		return _reject("missing_field")
	if operation in ["wing_create"] and not payload.has("wing_id"):
		return _reject("missing_field")
	if operation in ["order_cancel", "fire_rule_set", "assist_preference_set"] and not payload.has("wing_id"):
		return _reject("missing_field")
	if operation in ["order_issue", "maneuver_request"] and (typeof(payload.get("wing_ids")) != TYPE_ARRAY or payload.wing_ids.is_empty()):
		return _reject("missing_field")
	if operation == "order_issue" and (typeof(payload.get("verb")) != TYPE_STRING or String(payload.verb) not in ["move", "patrol", "secure", "protect", "attack_target", "attack_area", "withdraw"]):
		return _reject("invalid_order")
	if operation == "order_issue":
		if payload.has("stance") and payload.stance not in ["cautious", "normal", "aggressive"]: return _reject("invalid_stance")
		if payload.has("fire_rule") and payload.fire_rule not in ["hold", "return", "free"]: return _reject("invalid_fire_rule")
		if payload.has("contact_response") and payload.contact_response not in ["avoid", "observe", "engage"]: return _reject("invalid_contact_response")
		if payload.get("contact_response") == "avoid" and payload.get("fire_rule") != "hold": return _reject("incompatible_rules")
		for key in ["protect_radius", "pursuit_limit"]:
			if payload.has(key) and (typeof(payload[key]) not in [TYPE_INT, TYPE_FLOAT] or float(payload[key]) <= 0.0): return _reject("invalid_radius")
		match String(payload.verb):
			"move", "secure", "withdraw":
				if not payload.has("target_hex"): return _reject("missing_field")
			"patrol":
				if not payload.has("waypoints"): return _reject("missing_field")
			"attack_area":
				if not payload.has("area_hexes"): return _reject("missing_field")
			"attack_target", "protect":
				if typeof(payload.get("target_id")) != TYPE_STRING or String(payload.target_id).strip_edges().is_empty(): return _reject("missing_field")
				if not Array(context.get("known_targets", [])).has(payload.target_id): return _reject("unknown_target")
	if operation == "fire_rule_set" and payload.get("fire_rule") not in ["hold", "return", "free"]:
		return _reject("invalid_fire_rule")
	if operation == "assist_preference_set" and payload.get("assist_mode") not in ["auto", "coupled", "decoupled"]:
		return _reject("invalid_assist_mode")
	if operation == "maneuver_request" and (typeof(payload.get("maneuver_id")) != TYPE_STRING or String(payload.maneuver_id).strip_edges().is_empty() or not payload.has("target")):
		return _reject("missing_field")
	if operation == "maneuver_request":
		var target: Variant = payload.target
		if typeof(target) == TYPE_VECTOR2I:
			if not GRID.contains(target): return _reject("invalid_hex")
		elif typeof(target) != TYPE_STRING or not Array(context.get("known_targets", [])).has(target):
			return _reject("unknown_target")
	var wings: Array = [payload.wing_id] if payload.has("wing_id") else payload.get("wing_ids", [])
	var seen: Dictionary = {}
	for wing in wings:
		if typeof(wing) != TYPE_STRING or String(wing).strip_edges().is_empty():
			return _reject("invalid_id")
		if seen.has(wing): return _reject("duplicate_wing")
		seen[wing] = true
		if operation != "wing_create" and not Array(context.get("owned_wings", [])).has(wing):
			return _reject("not_owned")
	for key in ["craft_id", "leader_craft_id"]:
		if payload.has(key) and not Array(context.get("owned_crafts", [])).has(payload[key]):
			return _reject("not_owned")
	if operation == "wing_leader_set" and not Array(Dictionary(context.get("wing_members", {})).get(payload.wing_id, [])).has(payload.leader_craft_id):
		return _reject("not_member")
	return {"ok": true, "reason": "", "replayed": false, "signature": request_signature(command), "command": command.duplicate(true)}

static func request_signature(command: Dictionary) -> String:
	return JSON.stringify(command, "", true)

static func _has_authority_key(value: Variant) -> bool:
	if typeof(value) == TYPE_DICTIONARY:
		for key in value:
			if key in ["runtime_authorized", "authorized", "authority_context"] or _has_authority_key(value[key]): return true
	elif typeof(value) == TYPE_ARRAY:
		for item in value:
			if _has_authority_key(item): return true
	return false

static func _finite(value: Variant) -> bool:
	match typeof(value):
		TYPE_FLOAT: return is_finite(value)
		TYPE_VECTOR2: return is_finite(value.x) and is_finite(value.y)
		TYPE_VECTOR2I: return true
		TYPE_DICTIONARY:
			for key in value:
				if typeof(key) != TYPE_STRING or not _finite(value[key]): return false
		TYPE_ARRAY:
			for item in value:
				if not _finite(item): return false
		TYPE_NIL, TYPE_STRING, TYPE_BOOL, TYPE_INT: return true
		_: return false
	return true

static func _reject(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
