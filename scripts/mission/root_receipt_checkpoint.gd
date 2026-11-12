extends RefCounted
## Root-private receipt projection. No owner commands, binding, signals or awaits.
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const BLOCKED := ["_local_return_receipts", "_local_return_latest_by_craft", "_warp_entry_receipts", "_warp_entry_latest_by_craft", "_warp_departure_receipts", "_warp_entry_searches", "_warp_completion_intents", "_space_move_receipts", "_space_fire_receipts", "_fixture_area_receipts", "_fixture_surface_group_receipts", "_fixture_area_tokens", "_fixture_area_requests", "_fixture_area_blockers", "_air_ground_impact_receipts", "_air_support_move_receipts", "_campaign_space_return_receipts", "_campaign_space_entry_searches", "_campaign_space_entry_origins", "_piloted_air_ground_receipts", "_air_ground_fire_receipts", "_air_ground_order_receipts"]
const LAUNCH_FIELDS := ["craft_id", "context", "result", "command", "event_published"]
const DEPARTURE_FIELDS := ["craft_id", "station_dock", "station_landing", "approach_request_id", "result", "travel_context", "events", "events_published"]
class Prepared extends RefCounted:
	pass
static var _records: Dictionary = {}

static func capture(root: Node, bindings: Dictionary) -> Dictionary:
	if not _stable(root) or not _bound(root, bindings): return _bad("receipt_owner_unavailable")
	var data := {"launch":{}, "departure":{}, "equipment":{}}
	for kind in ["launch", "departure"]:
		var receipts: Dictionary = root.get("_launch_receipts" if kind == "launch" else "_departure_group_receipts")
		if receipts.size() > 1024: return _bad("receipt_capacity")
		for id in receipts:
			if not _id(id) or not receipts[id] is Dictionary: return _bad("receipt_invalid")
			var receipt: Dictionary = receipts[id]
			var fields: Array = LAUNCH_FIELDS if kind == "launch" else DEPARTURE_FIELDS
			var runtime: Array = ["fleet", "flight", "equipment", "candidate"] if kind == "launch" else ["supply", "campaign", "supply_epoch", "campaign_epoch", "fleet", "fleet_epoch", "flight", "travel_candidate"]
			if receipt.size() != fields.size() + runtime.size() or not receipt.has_all(fields) or not receipt.has_all(runtime): return _bad("receipt_unsupported")
			if receipt.get("fleet") != bindings.fleet or receipt.get("flight") != bindings.fleet.get_flight_state(receipt.get("craft_id", "")): return _bad("receipt_owner_changed")
			if kind == "launch":
				if receipt.equipment != bindings.equipment: return _bad("receipt_equipment_changed")
			else:
				if receipt.supply != bindings.supply or receipt.campaign != bindings.campaign or receipt.supply_epoch != bindings.supply.get("_route_prepare_epoch") or receipt.campaign_epoch != bindings.campaign.get("_departure_preparation_epoch") or receipt.fleet_epoch != bindings.fleet.get("_space_area_epoch"): return _bad("receipt_owner_changed")
			var context: Dictionary = receipt.get("context" if kind == "launch" else "travel_context", {})
			var candidate: Dictionary = receipt.get("candidate" if kind == "launch" else "travel_candidate", {})
			var replay: Dictionary = bindings.fleet.validate_prepared_space_area_transition(candidate, context)
			if not replay.get("ok", false) or not replay.get("replayed", false): return _bad("receipt_replay_unconfirmed")
			var saved := {}
			for field in fields: saved[field] = receipt[field]
			data[kind][id] = saved
			data.equipment[receipt.craft_id] = bindings.equipment.get_snapshot(receipt.craft_id)
	var checked := _rebuild(root, data, bindings)
	if not checked.ok: return checked
	var encoded := CODEC.encode_value(data)
	if not encoded.ok: return encoded
	return {"schema":"root_receipt_checkpoint.v1", "value":encoded.value}

static func prepare(root: Node, state: Dictionary, bindings: Dictionary) -> Dictionary:
	return _prepare(root, state, bindings, false)

static func prepare_prebinding(root: Node, state: Dictionary, bindings: Dictionary) -> Dictionary:
	# Explicit global-world replacement only. Existing completed maps must first
	# prove their own old owner bindings; ordinary prepare still refuses overwrite.
	if not _stable(root): return _bad("receipt_checkpoint_invalid")
	if not _empty(root):
		var old := capture(root, _root_bindings(root))
		if old.get("schema") != "root_receipt_checkpoint.v1": return _bad("receipt_old_root_unconfirmed")
	return _prepare(root, state, bindings, true)

static func _prepare(root: Node, state: Dictionary, bindings: Dictionary, prebinding: bool) -> Dictionary:
	if not _stable(root) or (not prebinding and not _empty(root)) or state.size() != 2 or state.get("schema") != "root_receipt_checkpoint.v1": return _bad("receipt_checkpoint_invalid")
	var decoded := CODEC.decode_value(state.get("value"))
	if not decoded.ok or not decoded.value is Dictionary: return _bad("receipt_checkpoint_invalid")
	var rebuilt := _rebuild(root, decoded.value, bindings)
	if not rebuilt.ok: return rebuilt
	for key in _records.keys():
		if _records[key].handle.get_ref() == null: _records.erase(key)
	if _records.size() >= 32: return _bad("receipt_prepare_capacity")
	var handle := Prepared.new()
	_records[handle.get_instance_id()] = {"handle":weakref(handle), "root":weakref(root), "root_stamp":_root_stamp(root), "bindings":bindings.duplicate(), "stamp":_owner_stamp(bindings), "data":decoded.value.duplicate(true), "rebuilt":rebuilt}
	return {"ok":true, "candidate":handle}

static func validate(root: Node, candidate: RefCounted, bindings: Dictionary) -> Dictionary:
	if candidate == null or not _records.has(candidate.get_instance_id()): return _bad("receipt_candidate_unknown")
	var record: Dictionary = _records[candidate.get_instance_id()]
	if record.handle.get_ref() != candidate or record.root.get_ref() != root or not _empty(root) or not _bound(root, bindings) or record.bindings != bindings: return _bad("receipt_candidate_stale")
	return _validate_fresh(root, record, bindings)

static func validate_prebinding(root: Node, candidate: RefCounted, bindings: Dictionary) -> Dictionary:
	if candidate == null or not _records.has(candidate.get_instance_id()): return _bad("receipt_candidate_unknown")
	var record: Dictionary = _records[candidate.get_instance_id()]
	if record.handle.get_ref() != candidate or record.root.get_ref() != root or not _stable(root) or record.bindings != bindings or record.root_stamp != _root_stamp(root): return _bad("receipt_candidate_stale")
	return _validate_fresh(root, record, bindings)

static func _validate_fresh(root: Node, record: Dictionary, bindings: Dictionary) -> Dictionary:
	if not _owners(root, bindings): return _bad("receipt_candidate_stale")
	if record.stamp != _owner_stamp(bindings): return _bad("receipt_candidate_stale")
	var rebuilt := _rebuild(root, record.data, bindings)
	if not rebuilt.ok: return rebuilt
	if rebuilt != record.rebuilt: return _bad("receipt_candidate_stale")
	return {"ok":true}

static func publish(root: Node, candidate: RefCounted) -> void:
	# Global caller must validate all owner candidates immediately before this tail.
	var record: Dictionary = _records[candidate.get_instance_id()]
	root.set("_launch_receipts", record.rebuilt.launch)
	root.set("_departure_group_receipts", record.rebuilt.departure)
	_records.erase(candidate.get_instance_id())

static func _rebuild(root: Node, data: Dictionary, bindings: Dictionary) -> Dictionary:
	if not _stable(root) or not _owners(root, bindings) or not _keys(data, ["launch", "departure", "equipment"]) or not data.launch is Dictionary or not data.departure is Dictionary or not data.equipment is Dictionary: return _bad("receipt_bindings_invalid")
	var result := {"ok":true, "launch":{}, "departure":{}}
	var crafts := {}
	for kind in ["launch", "departure"]:
		if data[kind].size() > 1024: return _bad("receipt_capacity")
		for id in data[kind]:
			var receipt: Variant = data[kind][id]
			var fields: Array = LAUNCH_FIELDS if kind == "launch" else DEPARTURE_FIELDS
			if not _id(id) or not receipt is Dictionary or not _keys(receipt, fields) or not _id(receipt.get("craft_id")) or not receipt.get("result") is Dictionary or receipt.result.get("ok") != true: return _bad("receipt_invalid")
			var craft: String = receipt.craft_id
			crafts[craft] = true
			if not data.equipment.get(craft) is Dictionary or bindings.equipment.get_snapshot(craft) != data.equipment[craft] or data.equipment[craft].is_empty(): return _bad("receipt_equipment_changed")
			var flight: RefCounted = bindings.fleet.get_flight_state(craft)
			if flight == null: return _bad("receipt_flight_missing")
			var context: Variant = receipt.get("context" if kind == "launch" else "travel_context")
			if not context is Dictionary or not bindings.fleet._valid_space_area_context(context) or context.payload.craft_id != craft: return _bad("receipt_context_invalid")
			var expected: Dictionary = {"contract_category":"singleplayer_space_travel", "operation":context.operation, "payload":context.payload.duplicate(true), "request_id":context.request_id}
			if context.request_signature != JSON.stringify({"operation":context.operation,"payload":context.payload}, "", true): return _bad("receipt_signature_invalid")
			var replay: Dictionary = bindings.fleet.prepare_space_area_transition(craft, context.expected_travel_revision, context.source_area_id, context.target_area_id, context)
			var confirmed: Dictionary = bindings.fleet.validate_prepared_space_area_transition(replay, context) if replay.get("ok", false) else replay
			if not confirmed.get("ok", false) or not confirmed.get("replayed", false) or receipt.result.get("travel_result") != confirmed.get("result"): return _bad("receipt_replay_unconfirmed")
			var restored: Dictionary = receipt.duplicate(true)
			restored.merge({"fleet":bindings.fleet, "flight":flight})
			if kind == "launch":
				if context.operation != "launch_to_orbit" or context.request_id != id or context.context_id != "space-launch:" + id or receipt.get("event_published") != true or receipt.command != expected or not _keys(receipt.result,["ok","replayed","receipt_id","travel_result"]) or receipt.result.receipt_id != id or receipt.result.replayed != false: return _bad("receipt_launch_invalid")
				restored.merge({"candidate":replay, "equipment":bindings.equipment})
			else:
				if not _valid_departure(id, receipt, context, expected, bindings): return _bad("receipt_departure_invalid")
				restored.merge({"travel_candidate":replay, "supply":bindings.supply, "campaign":bindings.campaign, "supply_epoch":bindings.supply.get("_route_prepare_epoch"), "campaign_epoch":bindings.campaign.get("_departure_preparation_epoch"), "fleet_epoch":bindings.fleet.get("_space_area_epoch")})
			result[kind][id] = restored
	if data.equipment.size() != crafts.size(): return _bad("receipt_equipment_invalid")
	return result

static func _valid_departure(id: String, receipt: Dictionary, context: Dictionary, travel_command: Dictionary, bindings: Dictionary) -> bool:
	if typeof(receipt.station_dock) != TYPE_BOOL or typeof(receipt.station_landing) != TYPE_BOOL or receipt.get("events_published") != true or not _id(receipt.approach_request_id) or context.request_id != receipt.approach_request_id or not receipt.events is Array or not _keys(receipt.result,["ok","departure","travel_result"]) or not receipt.result.departure is Dictionary: return false
	var departure: Dictionary = receipt.result.departure
	if departure.get("craft_id") != receipt.craft_id or bindings.campaign.get("_departures_by_craft_id").get(receipt.craft_id) != departure: return false
	var operation := "begin_station_dock" if receipt.station_dock else ("begin_station_landing" if receipt.station_landing else "begin_approach")
	if receipt.station_dock and receipt.station_landing or context.operation != operation or context.context_id != ("station-dock:" if receipt.station_dock else "departure:") + id or context.payload.get("location_id") != departure.get("destination_location_id"): return false
	var events: Array = [
		{"contract_category":"singleplayer_supply", "operation":"consume_route_fuel", "payload":departure, "request_id":id + ":fuel"},
		{"contract_category":"singleplayer_campaign", "operation":"bind_departure", "payload":departure, "request_id":id}]
	if not String(departure.get("job_id", "")).is_empty(): events.append({"contract_category":"singleplayer_campaign", "operation":"activate_job", "payload":{"job_id":departure.job_id,"craft_id":receipt.craft_id}, "request_id":id + ":active"})
	if receipt.events.size() != events.size() + 1: return false
	for index in events.size():
		var event: Variant = receipt.events[index]
		var command: Dictionary = events[index]
		if not event is Dictionary or not _keys(event,["command","result"]) or event.command != command: return false
		var owner: RefCounted = bindings.supply if index == 0 else bindings.campaign
		var entry: Variant = owner.get("_requests").get(command.request_id)
		if not entry is Dictionary or entry.get("signature") != JSON.stringify({"operation":command.operation,"payload":command.payload}, "", true) or entry.get("result") != event.result or not event.result is Dictionary or event.result.get("ok") != true: return false
	return receipt.events.back() == {"command":travel_command,"result":receipt.result.travel_result}

static func _owners(root: Node, bindings: Dictionary) -> bool:
	if not _keys(bindings,["fleet","supply","campaign","equipment","adapter"]): return false
	for field in bindings:
		if not is_instance_valid(bindings[field]): return false
	for field in ["fleet", "supply", "campaign", "equipment"]:
		if not bindings[field] is RefCounted: return false
	if not bindings.adapter is Node or not bindings.adapter.has_method("preview_departure") or not bindings.adapter.has_method("_built_home_pad_ids"): return false
	if not bindings.fleet.has_method("_has_space_area_authority") or not bindings.fleet.has_method("export_checkpoint_state") or not bindings.supply.has_method("_has_route_fuel_authority") or not bindings.supply.has_method("export_state") or not bindings.campaign.has_method("configure_departure_preparation_authority") or not bindings.campaign.has_method("export_state") or not bindings.equipment.has_method("get_snapshot") or not bindings.equipment.has_method("export_state"): return false
	return bindings.fleet._has_space_area_authority(root) and bindings.supply._has_route_fuel_authority(root) and bindings.campaign.get("_departure_preparation_authority") != null and bindings.campaign.get("_departure_preparation_authority").get_ref() == root

static func _owner_stamp(bindings: Dictionary) -> Dictionary:
	return {"fleet":bindings.fleet.export_checkpoint_state(), "supply":bindings.supply.export_state(), "campaign":bindings.campaign.export_state(), "equipment":bindings.equipment.export_state()}

static func _root_bindings(root: Node) -> Dictionary:
	var adapter: Variant = root.get("_departure_adapter")
	return {"fleet":root.get("_singleplayer_space_travel_owner"), "supply":root.get("_singleplayer_supply_owner"), "campaign":root.get("_singleplayer_campaign_owner"), "equipment":root.get("_ship_equipment_owner"), "adapter":adapter.get_ref() if adapter is WeakRef else null}

static func _root_stamp(root: Node) -> Dictionary:
	var bindings := _root_bindings(root)
	var state := {}
	var epochs := {}
	# Old state remains live and read-only until the global publication tail.
	for field in ["fleet", "supply", "campaign", "equipment"]:
		var owner: Variant = bindings[field]
		if is_instance_valid(owner):
			if field == "fleet" and owner.has_method("export_checkpoint_state"):
				state[field] = owner.export_checkpoint_state()
				epochs[field] = owner.get("_space_area_epoch")
			elif owner.has_method("export_state"):
				state[field] = owner.export_state()
				if field == "supply": epochs[field] = owner.get("_route_prepare_epoch")
				if field == "campaign": epochs[field] = owner.get("_departure_preparation_epoch")
	return {"bindings":bindings, "onboarding":root.get("_campaign_onboarding_owner"), "state":state, "epochs":epochs, "launch":root.get("_launch_receipts").duplicate(true), "departure":root.get("_departure_group_receipts").duplicate(true)}

static func _bound(root: Node, bindings: Dictionary) -> bool:
	return _owners(root,bindings) and root.get("_singleplayer_space_travel_owner") == bindings.fleet and root.get("_singleplayer_supply_owner") == bindings.supply and root.get("_singleplayer_campaign_owner") == bindings.campaign and root.get("_ship_equipment_owner") == bindings.equipment and root.get("_departure_adapter") != null and root.get("_departure_adapter").get_ref() == bindings.adapter

static func _stable(root: Node) -> bool:
	if not is_instance_valid(root) or not root.has_method("commit_singleplayer_space_launch") or root.get("is_processing_tick") or not root.get("command_queue").is_empty() or not root.get("effects_queue").is_empty(): return false
	for field in BLOCKED:
		if not root.get(field) is Dictionary or not root.get(field).is_empty(): return false
	return true

static func _empty(root: Node) -> bool:
	return _stable(root) and root.get("_launch_receipts").is_empty() and root.get("_departure_group_receipts").is_empty()
static func _keys(value: Dictionary, fields: Array) -> bool:
	return value.size() == fields.size() and value.has_all(fields)
static func _id(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not value.strip_edges().is_empty() and value.length() <= 512
static func _bad(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason}
