extends RefCounted
## Root-private receipt projection. No owner commands, binding, signals or awaits.
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const BLOCKED := ["_warp_entry_searches", "_warp_completion_intents", "_space_fire_receipts", "_fixture_area_receipts", "_fixture_surface_group_receipts", "_fixture_area_tokens", "_fixture_area_requests", "_air_ground_impact_receipts", "_air_support_move_receipts", "_campaign_space_return_receipts", "_campaign_space_entry_searches", "_campaign_space_entry_origins", "_piloted_air_ground_receipts", "_air_ground_fire_receipts", "_air_ground_order_receipts"]
const ORBIT_MAPS := {"move":"_space_move_receipts", "warp_entry":"_warp_entry_receipts", "warp_departure":"_warp_departure_receipts", "local_return":"_local_return_receipts", "warp_latest":"_warp_entry_latest_by_craft", "return_latest":"_local_return_latest_by_craft"}
const SPACE_COMMAND = preload("res://scripts/mission/space_combat_command_contract.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const ORBIT = preload("res://scripts/mission/orbit_approach_layout.gd")
const LAUNCH_FIELDS := ["craft_id", "context", "result", "command", "event_published"]
const DEPARTURE_FIELDS := ["craft_id", "station_dock", "station_landing", "approach_request_id", "result", "travel_context", "events", "events_published"]
class Prepared extends RefCounted:
	pass
static var _records: Dictionary = {}

static func capture(root: Node, bindings: Dictionary) -> Dictionary:
	if not _stable(root) or not _bound(root, bindings): return _bad("receipt_owner_unavailable")
	if _owner_stamp(bindings).get("ok",true) == false: return _bad("receipt_owner_export_failed")
	var data := {"launch":{}, "departure":{}, "equipment":{}}
	for kind in ["launch", "departure"]:
		var receipts: Dictionary = root.get("_launch_receipts" if kind == "launch" else "_departure_group_receipts")
		if receipts.size() > 1024: return _bad("receipt_capacity")
		for id in receipts:
			if not _id(id) or not receipts[id] is Dictionary: return _bad("receipt_invalid")
			var receipt: Dictionary = receipts[id]
			var fields: Array = LAUNCH_FIELDS if kind == "launch" else DEPARTURE_FIELDS
			var runtime: Array = _launch_runtime(receipt) if kind == "launch" else ["supply", "campaign", "supply_epoch", "campaign_epoch", "fleet", "fleet_epoch", "flight", "travel_candidate"]
			if runtime.is_empty(): return _bad("receipt_unsupported")
			if receipt.size() != fields.size() + runtime.size() or not receipt.has_all(fields) or not receipt.has_all(runtime): return _bad("receipt_unsupported")
			if receipt.get("fleet") != bindings.fleet or receipt.get("flight") != bindings.fleet.get_flight_state(receipt.get("craft_id", "")): return _bad("receipt_owner_changed")
			if kind == "launch":
				if receipt.has("equipment") and receipt.equipment != bindings.equipment: return _bad("receipt_equipment_changed")
			else:
				if receipt.supply != bindings.supply or receipt.campaign != bindings.campaign or receipt.supply_epoch != bindings.supply.get("_route_prepare_epoch") or receipt.campaign_epoch != bindings.campaign.get("_departure_preparation_epoch") or receipt.fleet_epoch != bindings.fleet.get("_space_area_epoch"): return _bad("receipt_owner_changed")
			var context: Dictionary = receipt.get("context" if kind == "launch" else "travel_context", {})
			var candidate: Dictionary = receipt.get("candidate" if kind == "launch" else "travel_candidate", {})
			var replay: Dictionary = bindings.fleet.validate_prepared_space_area_transition(candidate, context)
			if not replay.get("ok", false) or not replay.get("replayed", false): return _bad("receipt_replay_unconfirmed")
			var saved := {}
			for field in fields: saved[field] = receipt[field]
			data[kind][id] = saved
			if kind != "launch" or receipt.has("equipment"): data.equipment[receipt.craft_id] = bindings.equipment.get_snapshot(receipt.craft_id)
	var orbit := _capture_orbit(root, bindings)
	if not orbit.ok: return orbit
	for kind in ORBIT_MAPS: data[kind] = orbit.data[kind]
	data.equipment.merge(orbit.equipment)
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
	if not _owners(root,bindings): return _bad("receipt_bindings_invalid")
	var owner_stamp := _owner_stamp(bindings)
	var root_stamp := _root_stamp(root)
	if owner_stamp.get("ok",true) == false or root_stamp.get("ok",true) == false: return _bad("receipt_owner_export_failed")
	var rebuilt := _rebuild(root, decoded.value, bindings)
	if not rebuilt.ok: return rebuilt
	for key in _records.keys():
		if _records[key].handle.get_ref() == null: _records.erase(key)
	if _records.size() >= 32: return _bad("receipt_prepare_capacity")
	var handle := Prepared.new()
	_records[handle.get_instance_id()] = {"handle":weakref(handle), "root":weakref(root), "root_stamp":root_stamp, "bindings":bindings.duplicate(), "stamp":owner_stamp, "data":decoded.value.duplicate(true), "rebuilt":rebuilt}
	return {"ok":true, "candidate":handle}

static func validate(root: Node, candidate: RefCounted, bindings: Dictionary) -> Dictionary:
	if candidate == null or not _records.has(candidate.get_instance_id()): return _bad("receipt_candidate_unknown")
	var record: Dictionary = _records[candidate.get_instance_id()]
	if record.handle.get_ref() != candidate or record.root.get_ref() != root or not _empty(root) or not _bound(root, bindings) or record.bindings != bindings: return _bad("receipt_candidate_stale")
	return _validate_fresh(root, record, bindings)

static func validate_prebinding(root: Node, candidate: RefCounted, bindings: Dictionary) -> Dictionary:
	if candidate == null or not _records.has(candidate.get_instance_id()): return _bad("receipt_candidate_unknown")
	var record: Dictionary = _records[candidate.get_instance_id()]
	if record.handle.get_ref() != candidate or record.root.get_ref() != root or not _stable(root) or record.bindings != bindings: return _bad("receipt_candidate_stale")
	var root_stamp := _root_stamp(root)
	if root_stamp.get("ok",true) == false: return _bad("receipt_owner_export_failed")
	if record.root_stamp != root_stamp: return _bad("receipt_candidate_stale")
	return _validate_fresh(root, record, bindings)

static func _validate_fresh(root: Node, record: Dictionary, bindings: Dictionary) -> Dictionary:
	if not _owners(root, bindings): return _bad("receipt_candidate_stale")
	var owner_stamp := _owner_stamp(bindings)
	if owner_stamp.get("ok",true) == false: return _bad("receipt_owner_export_failed")
	if record.stamp != owner_stamp: return _bad("receipt_candidate_stale")
	var rebuilt := _rebuild(root, record.data, bindings)
	if not rebuilt.ok: return rebuilt
	if rebuilt != record.rebuilt: return _bad("receipt_candidate_stale")
	return {"ok":true}

static func publish(root: Node, candidate: RefCounted) -> void:
	# Global caller must validate all owner candidates immediately before this tail.
	var record: Dictionary = _records[candidate.get_instance_id()]
	root.set("_launch_receipts", record.rebuilt.launch)
	root.set("_departure_group_receipts", record.rebuilt.departure)
	for kind in ORBIT_MAPS: root.set(ORBIT_MAPS[kind], record.rebuilt[kind])
	_records.erase(candidate.get_instance_id())

static func _rebuild(root: Node, data: Dictionary, bindings: Dictionary) -> Dictionary:
	if not _stable(root) or not _owners(root, bindings) or not data.has_all(["launch", "departure", "equipment"]) or not data.launch is Dictionary or not data.departure is Dictionary or not data.equipment is Dictionary: return _bad("receipt_bindings_invalid")
	var schema_fields: Array = ["launch","departure","equipment"]
	if data.size() == 3:
		if not _legacy_without_area_history(bindings,data): return _bad("receipt_legacy_area_history")
	else:
		schema_fields.append_array(ORBIT_MAPS.keys())
	if not _keys(data,schema_fields): return _bad("receipt_maps_incomplete")
	var result := {"ok":true, "launch":{}, "departure":{}}
	var crafts := {}
	for kind in ["launch", "departure"]:
		if data[kind].size() > 1024: return _bad("receipt_capacity")
		for id in data[kind]:
			var receipt: Variant = data[kind][id]
			var fields: Array = LAUNCH_FIELDS if kind == "launch" else DEPARTURE_FIELDS
			if not _id(id) or not receipt is Dictionary or not _keys(receipt, fields) or not _id(receipt.get("craft_id")) or not receipt.get("result") is Dictionary or receipt.result.get("ok") != true: return _bad("receipt_invalid")
			var craft: String = receipt.craft_id
			if kind == "launch" and not receipt.get("context") is Dictionary: return _bad("receipt_context_invalid")
			var with_equipment: bool = kind != "launch" or receipt.get("context", {}).get("operation") == "launch_to_orbit"
			if with_equipment:
				crafts[craft] = true
				if not _equipment_matches(data, bindings, craft): return _bad("receipt_equipment_changed")
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
				if context.operation not in ["launch_to_orbit", "land_homebase"] or context.request_id != id or context.context_id != ("space-launch:" if context.operation == "launch_to_orbit" else "home-land:") + id or receipt.get("event_published") != true or receipt.command != expected or not _keys(receipt.result,["ok","replayed","receipt_id","travel_result"]) or receipt.result.receipt_id != id or receipt.result.replayed != false: return _bad("receipt_launch_invalid")
				restored["candidate"] = replay
				if with_equipment: restored["equipment"] = bindings.equipment
			else:
				if not _valid_departure(id, receipt, context, expected, bindings): return _bad("receipt_departure_invalid")
				restored.merge({"travel_candidate":replay, "supply":bindings.supply, "campaign":bindings.campaign, "supply_epoch":bindings.supply.get("_route_prepare_epoch"), "campaign_epoch":bindings.campaign.get("_departure_preparation_epoch"), "fleet_epoch":bindings.fleet.get("_space_area_epoch")})
			result[kind][id] = restored
	var orbit := _rebuild_orbit(data, bindings)
	if not orbit.ok: return orbit
	result.merge(orbit.maps)
	crafts.merge(orbit.crafts)
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

static func _launch_runtime(receipt: Dictionary) -> Array:
	var context: Variant = receipt.get("context")
	if not context is Dictionary: return []
	if context.get("operation") == "launch_to_orbit": return ["fleet", "flight", "equipment", "candidate"]
	if context.get("operation") == "land_homebase": return ["fleet", "flight", "candidate"]
	return []

static func _orbit_fields(kind: String) -> Array:
	match kind:
		"warp_entry": return ["context", "result", "command", "event_published"]
		"warp_departure": return ["signature", "context", "result", "command", "event_published"]
		"local_return": return ["travel_context", "events", "events_published"]
	return ["signature"]

static func _orbit_runtime(kind: String) -> Array:
	if kind == "local_return": return ["fleet", "flight", "supply", "supply_epoch", "travel_candidate"]
	if kind in ["warp_entry", "warp_departure"]: return ["fleet", "flight", "equipment", "candidate"]
	return []

static func _capture_orbit(root: Node, bindings: Dictionary) -> Dictionary:
	var data := {}; var equipment := {}
	for kind in ORBIT_MAPS:
		var source: Variant = root.get(ORBIT_MAPS[kind])
		if not source is Dictionary or source.size() > 1024: return _bad("receipt_capacity")
		data[kind] = {}
		if kind in ["warp_latest", "return_latest"]:
			data[kind] = source.duplicate(true)
			continue
		for id in source:
			if not _id(id) or not source[id] is Dictionary: return _bad("receipt_invalid")
			var receipt: Dictionary = source[id]
			var fields := _orbit_fields(kind)
			var runtime := _orbit_runtime(kind)
			if receipt.size() != fields.size() + runtime.size() or not receipt.has_all(fields) or not receipt.has_all(runtime): return _bad("receipt_unsupported")
			if kind != "move":
				var context: Variant = receipt.get("travel_context" if kind == "local_return" else "context")
				if not context is Dictionary or not context.get("payload") is Dictionary: return _bad("receipt_context_invalid")
				var craft: Variant = context.payload.get("craft_id")
				if not _id(craft) or receipt.fleet != bindings.fleet or receipt.flight != bindings.fleet.get_flight_state(craft): return _bad("receipt_owner_changed")
				if kind == "local_return":
					if receipt.supply != bindings.supply or receipt.supply_epoch != bindings.supply.get("_route_prepare_epoch"): return _bad("receipt_owner_changed")
				else:
					if receipt.equipment != bindings.equipment: return _bad("receipt_equipment_changed")
					equipment[craft] = bindings.equipment.get_snapshot(craft)
				var candidate: Variant = receipt.get("travel_candidate" if kind == "local_return" else "candidate")
				if not candidate is Dictionary: return _bad("receipt_replay_unconfirmed")
				var replay: Dictionary = bindings.fleet.validate_prepared_space_area_transition(candidate, context)
				if not replay.get("ok", false) or not replay.get("replayed", false): return _bad("receipt_replay_unconfirmed")
			var saved := {}
			for field in fields: saved[field] = receipt[field]
			data[kind][id] = saved
	return {"ok":true, "data":data, "equipment":equipment}

static func _equipment_matches(data: Dictionary, bindings: Dictionary, craft: String) -> bool:
	return data.equipment.get(craft) is Dictionary and not data.equipment[craft].is_empty() and bindings.equipment.get_snapshot(craft) == data.equipment[craft]

static func _rebuild_orbit(data: Dictionary, bindings: Dictionary) -> Dictionary:
	var maps := {}; var crafts := {}
	for kind in ORBIT_MAPS:
		var source: Variant = data.get(kind, {})
		if not source is Dictionary or source.size() > 1024: return _bad("receipt_capacity")
		maps[kind] = {}
		if kind in ["warp_latest", "return_latest"]:
			maps[kind] = source.duplicate(true)
			continue
		for id in source:
			var receipt: Variant = source[id]
			if not _id(id) or not receipt is Dictionary or not _keys(receipt, _orbit_fields(kind)): return _bad("receipt_invalid")
			if kind == "move":
				if not _valid_move(id, receipt, bindings): return _bad("receipt_move_invalid")
				maps.move[id] = receipt.duplicate(true)
				continue
			var context: Variant = receipt.get("travel_context" if kind == "local_return" else "context")
			if not context is Dictionary or not bindings.fleet._valid_space_area_context(context): return _bad("receipt_context_invalid")
			var craft: String = context.payload.craft_id
			if not _id(craft) or context.request_signature != JSON.stringify({"operation":context.operation,"payload":context.payload}, "", true): return _bad("receipt_signature_invalid")
			var flight: RefCounted = bindings.fleet.get_flight_state(craft)
			if flight == null: return _bad("receipt_flight_missing")
			var candidate: Dictionary = bindings.fleet.prepare_space_area_transition(craft, context.expected_travel_revision, context.source_area_id, context.target_area_id, context)
			var replay: Dictionary = bindings.fleet.validate_prepared_space_area_transition(candidate, context) if candidate.get("ok", false) else candidate
			if not replay.get("ok", false) or not replay.get("replayed", false): return _bad("receipt_replay_unconfirmed")
			var command := {"contract_category":"singleplayer_space_travel", "operation":context.operation, "payload":context.payload.duplicate(true), "request_id":context.request_id}
			var restored: Dictionary = receipt.duplicate(true)
			restored.merge({"fleet":bindings.fleet, "flight":flight})
			if kind == "local_return":
				if not _valid_local_return(id, receipt, context, command, replay.result, bindings): return _bad("receipt_return_invalid")
				restored.merge({"travel_candidate":candidate, "supply":bindings.supply, "supply_epoch":bindings.supply.get("_route_prepare_epoch")})
			else:
				if not _equipment_matches(data, bindings, craft): return _bad("receipt_equipment_changed")
				crafts[craft] = true
				if not _valid_warp(kind, id, receipt, context, command, replay.result): return _bad("receipt_warp_invalid")
				restored.merge({"candidate":candidate, "equipment":bindings.equipment})
			maps[kind][id] = restored
	if not _valid_latest(maps.warp_latest, maps.warp_entry, "context") or not _valid_latest(maps.return_latest, maps.local_return, "travel_context"): return _bad("receipt_latest_invalid")
	return {"ok":true, "maps":maps, "crafts":crafts}

static func _valid_warp(kind: String, id: String, receipt: Dictionary, context: Dictionary, command: Dictionary, travel_result: Dictionary) -> bool:
	if receipt.get("event_published") != true or receipt.command != command or context.request_id != id or not receipt.result is Dictionary or receipt.result.get("ok") != true or receipt.result.get("replayed") != false or receipt.result.get("receipt_id") != id or receipt.result.get("travel_result") != travel_result: return false
	if kind == "warp_entry":
		return _keys(receipt.result, ["ok", "status", "space_area_id", "travel_result", "receipt_id", "replayed"]) and receipt.result.status == "complete" and receipt.result.space_area_id == context.target_area_id and context.operation == "advance" and context.expected_phase == "quantum" and context.source_area_id.is_empty() and context.target_area_id.begins_with("orbit_approach:") and context.context_id == id and id == "warp-arrival:%s:%d" % [context.payload.craft_id, context.expected_travel_revision] and float(context.payload.delta_seconds) > 0.0 and float(context.payload.delta_seconds) <= 60.0
	var request: Dictionary = context.payload.duplicate(true)
	request["request_id"] = id
	return _keys(receipt.result, ["ok", "replayed", "receipt_id", "travel_result"]) and context.operation == "start_quantum" and context.expected_phase == "orbit" and context.source_area_id.begins_with("orbit_approach:") and context.target_area_id.is_empty() and context.context_id == "warp-departure:" + id and receipt.signature == SPACE_COMMAND.request_signature(request)

static func _valid_local_return(id: String, receipt: Dictionary, context: Dictionary, command: Dictionary, travel_result: Dictionary, bindings: Dictionary) -> bool:
	if receipt.get("events_published") != true or not receipt.events is Array or receipt.events.size() not in [1, 2] or context.operation not in ["enter_orbit", "undock_station", "depart_station_landing"] or context.source_area_id != context.target_area_id or not context.target_area_id.begins_with("orbit_approach:"): return false
	var cancel := id.begins_with("local-cancel:")
	if not cancel and not id.begins_with("local-return:"): return false
	if context.expected_phase != ("approach" if cancel else "surface"): return false
	var transition_id := ("station-undock:" if context.operation == "undock_station" else ("station-landing-return:" if context.operation == "depart_station_landing" else "")) + id
	if context.context_id != transition_id or context.request_id != transition_id or receipt.events.back() != {"command":command, "result":travel_result}: return false
	# Receipt key binds the outward request, craft and (for cancellation) revision.
	var suffix := ":" + String(context.payload.craft_id) + ((":" + str(context.expected_travel_revision)) if cancel else "")
	if not id.ends_with(suffix): return false
	var prefix := "local-cancel:" if cancel else "local-return:"
	var outward := id.substr(prefix.length(), id.length() - prefix.length() - suffix.length())
	if not _id(outward) or (cancel and receipt.events.size() != 1): return false
	if receipt.events.size() == 2:
		var event: Variant = receipt.events[0]
		if not _valid_supply_event(event, bindings): return false
		if event.command.get("request_id") != "return:" + outward + ":fuel" or event.command.get("operation") != "consume_route_fuel" or not event.command.get("payload") is Dictionary: return false
		if event.command.payload.get("craft_id") != context.payload.craft_id or event.command.payload.get("destination_location_id") != "homebase": return false
	if not cancel:
		var fuel_id := "return:" + outward + ":fuel"
		var entry: Variant = bindings.supply.get("_requests").get(fuel_id)
		if not entry is Dictionary or typeof(entry.get("signature")) != TYPE_STRING or not entry.get("result") is Dictionary or entry.result.get("ok") != true: return false
		var fuel: Variant = JSON.parse_string(entry.signature)
		if not fuel is Dictionary or not _keys(fuel, ["operation", "payload"]) or fuel.operation != "consume_route_fuel" or not fuel.payload is Dictionary or fuel.payload.get("craft_id") != context.payload.craft_id or fuel.payload.get("destination_location_id") != "homebase": return false
		if JSON.stringify(fuel, "", true) != entry.signature: return false
	return true

static func _valid_supply_event(event: Variant, bindings: Dictionary) -> bool:
	if not event is Dictionary or not _keys(event, ["command", "result"]) or not event.command is Dictionary or not _keys(event.command, ["contract_category", "operation", "payload", "request_id"]) or event.command.contract_category != "singleplayer_supply" or not _id(event.command.request_id) or not event.result is Dictionary or event.result.get("ok") != true: return false
	var entry: Variant = bindings.supply.get("_requests").get(event.command.request_id)
	return entry is Dictionary and entry.get("signature") == JSON.stringify({"operation":event.command.operation,"payload":event.command.payload}, "", true) and entry.get("result") == event.result

static func _valid_latest(latest: Dictionary, receipts: Dictionary, context_field: String) -> bool:
	var seen := {}
	for craft in latest:
		var id: Variant = latest[craft]
		if not _id(craft) or not _id(id) or not receipts.has(id) or receipts[id][context_field].payload.craft_id != craft: return false
		seen[craft] = true
	for receipt in receipts.values():
		var craft: String = receipt[context_field].payload.craft_id
		if not seen.has(craft) or receipts[latest[craft]][context_field].expected_travel_revision < receipt[context_field].expected_travel_revision: return false
	return true

static func _valid_move(id: String, receipt: Dictionary, bindings: Dictionary) -> bool:
	if typeof(receipt.signature) != TYPE_STRING or receipt.signature.length() > 4096: return false
	# str_to_var has no object-deserialization opt-in. Accept only the exact
	# primitive producer command and reproduce its canonical signature verbatim.
	var command: Variant = str_to_var(receipt.signature)
	if not command is Dictionary or not _keys(command, ["craft_id", "target_hex", "request_id"]) or command.request_id != id or not _id(command.craft_id) or typeof(command.target_hex) != TYPE_VECTOR2I or bindings.fleet.get_flight_state(command.craft_id) == null: return false
	return receipt.signature == SPACE_COMMAND.request_signature(command) and ORBIT.contains_local_cell(GRID.to_offset(command.target_hex))

static func _owners(root: Node, bindings: Dictionary) -> bool:
	if not _keys(bindings,["fleet","supply","campaign","equipment","adapter"]): return false
	for field in bindings:
		if not is_instance_valid(bindings[field]): return false
	for field in ["fleet", "supply", "campaign", "equipment"]:
		if not bindings[field] is RefCounted: return false
	if not bindings.adapter is Node or not bindings.adapter.has_method("preview_departure") or not bindings.adapter.has_method("_built_home_pad_ids"): return false
	if not bindings.fleet.has_method("_has_space_area_authority") or not bindings.fleet.has_method("export_checkpoint_state") or not bindings.supply.has_method("_has_route_fuel_authority") or not bindings.supply.has_method("export_state") or not bindings.campaign.has_method("configure_departure_preparation_authority") or not bindings.campaign.has_method("export_state") or not bindings.equipment.has_method("get_snapshot") or not bindings.equipment.has_method("export_state"): return false
	return bindings.fleet._has_space_area_authority(root) and bindings.supply._has_route_fuel_authority(root) and bindings.campaign.get("_departure_preparation_authority") != null and bindings.campaign.get("_departure_preparation_authority").get_ref() == root

static func _legacy_without_area_history(bindings: Dictionary, data: Dictionary) -> bool:
	# Historical three-map values support only the actual strategic producers.
	# Every Fleet area receipt must be covered by its original Root projection.
	var history: Variant = bindings.fleet.get("_space_area_receipts")
	if not history is Dictionary: return false
	var covered := {}
	for kind in ["launch","departure"]:
		for saved in data[kind].values():
			if not saved is Dictionary: return false
			var context: Variant = saved.get("context" if kind == "launch" else "travel_context")
			if not context is Dictionary: return false
			covered[JSON.stringify(context,"",true)] = true
	for entry in history.values():
		if not entry is Dictionary or typeof(entry.get("context_binding")) != TYPE_STRING: return false
		var context: Variant = JSON.parse_string(entry.context_binding)
		if not context is Dictionary or context.get("operation") not in ["launch_to_orbit","begin_approach"] or context.get("source_area_id") != "" or context.get("target_area_id") != "" or not covered.has(entry.context_binding): return false
	for craft in bindings.fleet.get_snapshot().get("routes",{}):
		var flight: RefCounted = bindings.fleet.get_flight_state(craft)
		if flight == null: return false
		var pose: Dictionary = flight.get_snapshot()
		if pose.get("coordinate_frame") != "strategic" or pose.get("space_area_id") != "": return false
	return true

static func _owner_stamp(bindings: Dictionary) -> Dictionary:
	var stamp := {"fleet":bindings.fleet.export_checkpoint_state(), "supply":bindings.supply.export_state(), "campaign":bindings.campaign.export_state(), "equipment":bindings.equipment.export_state()}
	for value in stamp.values():
		if not value is Dictionary or value.get("ok",true) == false: return _bad("receipt_owner_export_failed")
	return stamp

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
	for value in state.values():
		if not value is Dictionary or value.get("ok",true) == false: return _bad("receipt_owner_export_failed")
	var orbit := {}
	for kind in ORBIT_MAPS: orbit[kind] = root.get(ORBIT_MAPS[kind]).duplicate(true)
	return {"bindings":bindings, "onboarding":root.get("_campaign_onboarding_owner"), "state":state, "epochs":epochs, "launch":root.get("_launch_receipts").duplicate(true), "departure":root.get("_departure_group_receipts").duplicate(true), "orbit":orbit,"derived_blockers":root.get("_fixture_area_blockers").duplicate(true)}

static func _bound(root: Node, bindings: Dictionary) -> bool:
	return _owners(root,bindings) and root.get("_singleplayer_space_travel_owner") == bindings.fleet and root.get("_singleplayer_supply_owner") == bindings.supply and root.get("_singleplayer_campaign_owner") == bindings.campaign and root.get("_ship_equipment_owner") == bindings.equipment and root.get("_departure_adapter") != null and root.get("_departure_adapter").get_ref() == bindings.adapter

static func _canonical_blocker_cache(root: Node) -> bool:
	# Despite its historical name, normal local movement fills this pure cache.
	# Derive the identical body mask from the canonical layout; never save it as
	# gameplay truth or accept arbitrary fixture obstacles. Target rebuilds lazily.
	var cache: Variant = root.get("_fixture_area_blockers")
	if not cache is Dictionary or cache.size() > 64: return false
	for area in cache:
		if typeof(area) != TYPE_STRING or not area.begins_with("orbit_approach:") or not cache[area] is Array: return false
		var layout: Dictionary = ORBIT.build(area.trim_prefix("orbit_approach:").uri_decode())
		if not layout.get("ok",false) or layout.body_map_id != area: return false
		var expected: Array[Vector2i] = []
		for offset in layout.body_cells: expected.append(GRID.from_offset(offset))
		if cache[area] != expected: return false
	return true

static func _stable(root: Node) -> bool:
	if not is_instance_valid(root) or not root.has_method("commit_singleplayer_space_launch") or root.get("is_processing_tick") or not root.get("command_queue").is_empty() or not root.get("effects_queue").is_empty(): return false
	for field in BLOCKED:
		if not root.get(field) is Dictionary or not root.get(field).is_empty(): return false
	return _canonical_blocker_cache(root)

static func _empty(root: Node) -> bool:
	if not _stable(root) or not root.get("_launch_receipts").is_empty() or not root.get("_departure_group_receipts").is_empty(): return false
	for kind in ORBIT_MAPS:
		if not root.get(ORBIT_MAPS[kind]) is Dictionary or not root.get(ORBIT_MAPS[kind]).is_empty(): return false
	return true
static func _keys(value: Dictionary, fields: Array) -> bool:
	return value.size() == fields.size() and value.has_all(fields)
static func _id(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not value.strip_edges().is_empty() and value.length() <= 512
static func _bad(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason}
