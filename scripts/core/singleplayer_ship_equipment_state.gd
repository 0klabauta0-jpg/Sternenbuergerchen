extends RefCounted
## Installed identities only. Cargo, credits and request replay belong to Supply.
const CATALOG = preload("res://scripts/mission/ship_equipment_catalog.gd")
var _crafts: Dictionary = {}
var _revision := 0
var _installs: Dictionary = {}
var _seal := str(Time.get_ticks_usec()) + ":" + str(randi())
func configure(definitions: Array) -> Dictionary:
	var candidate := {}
	for raw: Variant in definitions:
		if typeof(raw) != TYPE_DICTIONARY: return _reject("invalid_craft")
		var id := String(raw.get("craft_id", ""))
		if id.is_empty() or candidate.has(id): return _reject("invalid_craft")
		candidate[id] = _initial(raw)
	_crafts = candidate
	_revision = 0
	_installs.clear()
	return {"ok":true}
func _initial(definition: Dictionary) -> Dictionary:
	var model_id := String(definition.get("model_id", ""))
	var model := CATALOG.model(model_id)
	return {"model_id":model_id, "slots":{} if model.is_empty() else {"quantum_drive":String(model.default_item_id)}}
func register_craft(definition: Dictionary) -> Dictionary:
	var id := String(definition.get("craft_id", ""))
	if id.is_empty(): return _reject("invalid_craft")
	if _crafts.has(id): return {"ok":String(_crafts[id].model_id) == String(definition.get("model_id", ""))}
	_crafts[id] = _initial(definition)
	return {"ok":true}
func get_snapshot(craft_id: String = "") -> Dictionary:
	if not craft_id.is_empty():
		if not _crafts.has(craft_id): return {}
		var result: Dictionary = _crafts[craft_id].duplicate(true)
		result.merge({"craft_id":craft_id, "revision":_revision})
		return result
	return {"schema_version":1, "catalog_version":1, "revision":_revision, "crafts":_crafts.duplicate(true)}
func get_quantum_effect(craft_id: String) -> Dictionary:
	var installed := String(Dictionary(_crafts.get(craft_id, {})).get("slots", {}).get("quantum_drive", ""))
	return {"quantum_duration_multiplier":CATALOG.multiplier(installed), "item_id":installed, "equipment_revision":_revision}

func get_space_flight_profile(craft_id: String) -> Dictionary:
	if not _crafts.has(craft_id): return {"ok":false, "reason":"unknown_craft"}
	var model_id := String(_crafts[craft_id].get("model_id", ""))
	var profile: Dictionary = CATALOG.flight_profile(model_id)
	if not profile.has_all(["mass", "main_thrust", "reverse_thrust", "side_thrust", "turn_acceleration", "thrust_fraction"]):
		return {"ok":false, "reason":"flight_profile_unavailable"}
	for key in ["mass", "main_thrust", "reverse_thrust", "side_thrust", "turn_acceleration", "thrust_fraction"]:
		if typeof(profile[key]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(profile[key])) or float(profile[key]) <= 0.0:
			return {"ok":false, "reason":"invalid_flight_profile"}
	if float(profile.thrust_fraction) > 1.0: return {"ok":false, "reason":"invalid_flight_profile"}
	return {"ok":true, "craft_id":craft_id, "model_id":model_id, "equipment_revision":_revision, "mass":float(profile.mass), "hull":{"main_thrust":float(profile.main_thrust), "reverse_thrust":float(profile.reverse_thrust), "side_thrust":float(profile.side_thrust), "turn_acceleration":float(profile.turn_acceleration)}, "power":{"thrust_fraction":float(profile.thrust_fraction)}}
func prepare_install(craft_id: String, slot_id: String, item_id: String, expected_revision: int) -> Dictionary:
	if expected_revision != _revision: return _reject("equipment_changed")
	if not _crafts.has(craft_id) or not CATALOG.compatible(String(_crafts[craft_id].model_id), slot_id, item_id): return _reject("incompatible_component")
	var previous := String(_crafts[craft_id].slots.get(slot_id, ""))
	if previous == item_id: return _reject("already_installed")
	var prepared := {"ok":true, "craft_id":craft_id, "slot_id":slot_id, "item_id":item_id, "previous_item_id":previous, "previous_equipment_revision":_revision, "equipment_revision":_revision+1}
	prepared["seal"] = _sign(prepared)
	return prepared
func _sign(prepared: Dictionary) -> String:
	var content := prepared.duplicate(true)
	content.erase("seal")
	return (_seal + JSON.stringify(content, "", true)).sha256_text()
func commit_prepared_install(prepared: Dictionary, request_id: String) -> Dictionary:
	if request_id.is_empty() or _installs.has(request_id) or String(prepared.get("seal", "")) != _sign(prepared): return _reject("invalid_equipment_transaction")
	var current := prepare_install(String(prepared.get("craft_id", "")), String(prepared.get("slot_id", "")), String(prepared.get("item_id", "")), int(prepared.get("previous_equipment_revision", -1)))
	if not bool(current.get("ok", false)) or current != prepared: return _reject("equipment_changed")
	var receipt := prepared.duplicate(true)
	receipt.erase("seal")
	receipt["request_id"] = request_id
	_crafts[String(prepared.craft_id)].slots[String(prepared.slot_id)] = String(prepared.item_id)
	_revision += 1
	_installs[request_id] = receipt.duplicate(true)
	return receipt
func export_state() -> Dictionary:
	var state := get_snapshot()
	state["installs"] = _installs.duplicate(true)
	return state
func restore_state(data: Dictionary, definitions: Array, supply_requests: Dictionary, inventory: Dictionary = {}) -> Dictionary:
	var fresh = get_script().new()
	var configured: Dictionary = fresh.configure(definitions)
	if not configured.ok: return configured
	if data.size() != 5 or data.get("schema_version") != 1 or data.get("catalog_version") != 1 or not _integer(data.get("revision")) or typeof(data.get("crafts")) != TYPE_DICTIONARY or typeof(data.get("installs")) != TYPE_DICTIONARY: return _reject("invalid_equipment_state")
	if data.installs.size() != int(data.revision): return _reject("invalid_equipment_history")
	var receipts: Array = data.installs.values()
	for raw: Variant in receipts:
		if typeof(raw) != TYPE_DICTIONARY or not _integer(raw.get("equipment_revision")) or not _integer(raw.get("previous_equipment_revision")): return _reject("invalid_equipment_receipt")
	receipts.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.equipment_revision) < int(b.equipment_revision))
	var expected_supply_ids: Array = []
	for id: String in supply_requests:
		var entry: Dictionary = supply_requests[id]
		if String(Dictionary(entry.get("result", {})).get("operation", "")) == "station_install_ship_component": expected_supply_ids.append(id)
	if expected_supply_ids.size() != receipts.size(): return _reject("equipment_receipt_mismatch")
	for receipt: Dictionary in receipts:
		var id := String(receipt.get("request_id", ""))
		if not expected_supply_ids.has(id) or data.installs.get(id) != receipt: return _reject("equipment_receipt_mismatch")
		var payload: Variant = JSON.parse_string(String(Dictionary(supply_requests[id]).get("signature", "")))
		if typeof(payload) != TYPE_DICTIONARY or payload.get("operation") != "station_install_ship_component" or typeof(payload.get("payload")) != TYPE_DICTIONARY: return _reject("equipment_receipt_mismatch")
		var args: Dictionary = payload.payload
		var result: Dictionary = supply_requests[id].result
		for key: String in receipt:
			if result.get(key) != receipt[key]: return _reject("equipment_receipt_mismatch")
		for key in ["craft_id", "slot_id", "item_id"]:
			if args.get(key) != receipt.get(key): return _reject("equipment_receipt_mismatch")
		if args.get("expected_equipment_revision") != receipt.get("previous_equipment_revision") or result.get("source_container_id") != "craft:"+String(receipt.get("craft_id", "")) or args.get("source_container_id") != result.get("source_container_id") or result.get("cost") != 0: return _reject("equipment_receipt_mismatch")
		var proposed: Dictionary = fresh.prepare_install(String(receipt.get("craft_id", "")), String(receipt.get("slot_id", "")), String(receipt.get("item_id", "")), int(receipt.previous_equipment_revision))
		if not proposed.get("ok", false): return _reject("invalid_equipment_history")
		var committed: Dictionary = fresh.commit_prepared_install(proposed, id)
		# JSON parses numbers as floats. Only the already integer-validated revision
		# fields may be canonicalized; every other receipt field stays exact.
		var canonical := receipt.duplicate(true)
		canonical["previous_equipment_revision"] = int(receipt.previous_equipment_revision)
		canonical["equipment_revision"] = int(receipt.equipment_revision)
		if committed != canonical: return _reject("invalid_equipment_history")
	if fresh.get_snapshot().crafts != data.crafts or fresh._revision != int(data.revision): return _reject("equipment_state_mismatch")
	if not _component_balance(fresh._crafts, supply_requests, inventory): return _reject("component_balance_mismatch")
	_crafts = fresh._crafts.duplicate(true)
	_installs = fresh._installs.duplicate(true)
	_revision = fresh._revision
	return {"ok":true}
func validate_legacy(definitions: Array, supply_requests: Dictionary, inventory: Dictionary) -> Dictionary:
	var fresh = get_script().new()
	var result: Dictionary = fresh.configure(definitions)
	if not result.ok: return result
	for entry: Dictionary in supply_requests.values():
		if String(Dictionary(entry.get("result", {})).get("operation", "")) == "station_install_ship_component": return _reject("missing_equipment_state")
	# New component ownership cannot be hidden by deleting the save subsection.
	if not _component_balance(fresh._crafts, supply_requests, inventory): return _reject("component_balance_mismatch")
	return {"ok":true}
func _component_balance(crafts: Dictionary, requests: Dictionary, inventory: Dictionary) -> bool:
	var expected := {"warp_odyssey":0, "warp_hemera":0}
	var actual := {"warp_odyssey":0, "warp_hemera":0}
	for craft: Dictionary in crafts.values():
		if not Dictionary(craft.slots).is_empty(): expected.warp_odyssey += 1
		for item_id: String in craft.slots.values():
			if not CATALOG.known(item_id): return false
			actual[item_id] += 1
	for entry: Dictionary in requests.values():
		var result: Dictionary = entry.get("result", {})
		if String(result.get("operation", "")) != "buy" or not CATALOG.known(String(result.get("item_id", ""))): continue
		var parsed: Variant = JSON.parse_string(String(entry.get("signature", "")))
		if typeof(parsed) != TYPE_DICTIONARY or parsed.get("operation") != "buy": return false
		var args: Dictionary = parsed.get("payload", {})
		if String(args.get("offer_id", "")) != "polisa_warp_hemera" or result.get("item_id") != "warp_hemera" or not _integer(args.get("quantity")) or int(args.quantity) < 1 or result.get("quantity") != args.quantity or result.get("cost") != int(args.quantity)*160: return false
		expected.warp_hemera += int(args.quantity)
	for container: Dictionary in inventory.values():
		for item_id: String in CATALOG.ITEMS: actual[item_id] += int(Dictionary(container.get("items", {})).get(item_id, 0))
	return expected == actual
func _integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0 and float(value) == floor(float(value)) and float(value) <= 2147483647
func _reject(reason: String) -> Dictionary: return {"ok":false, "reason":reason, "message":"Warp-Antrieb: " + reason}


func validate_craft_return(craft_id: String) -> Dictionary:
	if not _crafts.has(craft_id): return _reject("unknown_equipment_craft")
	for receipt: Dictionary in _installs.values():
		if String(receipt.get("craft_id", "")) == craft_id:
			return {"ok":false, "reason":"equipment_retirement_pending", "message":"Nach einem Antriebsumbau ist die Schiffsrückgabe derzeit nicht verfügbar"}
	return {"ok":true}

func unregister_unmodified_craft(craft_id: String) -> Dictionary:
	var allowed := validate_craft_return(craft_id)
	if not allowed.get("ok", false): return allowed
	# Lifecycle-only removal; installation revision/history remains unchanged.
	_crafts.erase(craft_id)
	return {"ok":true}
