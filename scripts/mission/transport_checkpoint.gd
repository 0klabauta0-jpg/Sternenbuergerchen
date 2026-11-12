extends RefCounted
## Pure transport checkpoint preparation. Global transaction owns publication order.
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const BODY_PROFILE = preload("res://scripts/mission/polisa_ground_body_profile.gd")
const FIELDS = [
	"_mission_drop_source", "_mission_drop_craft_id", "_mission_drop_display_name",
	"_mission_drop_title_text", "_mission_drop_texture_path", "_mission_drop_state",
	"_mission_drop_pilot_text", "_mission_drop_status_line", "_mission_drop_progress",
	"_mission_drop_eta_seconds", "_mission_drop_pilot_unit_id", "_mission_drop_pilot_display_name",
	"_mission_drop_pilot_portrait_path", "_mission_drop_passenger_count", "_mission_drop_return_requested",
	"_mission_drop_cards", "_embarked_unit_ids", "_deployed_unit_ids", "_deployed_unit_positions",
	"_field_landing_by_craft", "_lz_position", "_has_lz_position", "_drop_ship_staged",
	"_drop_ship_cooldown_remaining", "_live_drop_bootstrap_consumed", "_drop_ship_requested",
	"_runtime_activation_pending_fireteam_ids", "_post_drop_security_pending_fireteam_ids"
]

static func capture(owner: Node) -> Dictionary:
	var root: Node = owner.get_node_or_null("../SimulationRoot")
	if not stable(owner, root): return bad("transport_transition_pending")
	var data := {"fields":{}, "primary":{}, "parallel":{}, "visits":owner.get_parent().get_meta("singleplayer_visit_identities", {}), "craft_identities":{}}
	for field in FIELDS: data.fields[field] = owner.get(field)
	var primary: Dictionary = owner.call("_capture_active_drop_sequence")
	var packed := pack_sequence(primary)
	if not packed.ok: return packed
	data.primary = packed.value
	for id in owner.get("_parallel_drop_sequences_by_craft"):
		packed = pack_sequence(owner.get("_parallel_drop_sequences_by_craft")[id])
		if not packed.ok: return packed
		data.parallel[id] = packed.value
	for card in data.fields._mission_drop_cards:
		if not card is Dictionary: return bad("transport_card_invalid")
		var id: String = card.get("craft_id", "")
		if id.is_empty() or data.craft_identities.has(id): return bad("transport_craft_duplicate")
		data.craft_identities[id] = {"model_id":card.get("model_id", "")}
	var encoded := encode_data(data)
	if not encoded.ok: return encoded
	var actors := {}
	for craft in data.visits:
		for id in data.visits[craft].get("unit_ids", []): actors[id] = root.call("_resolve_known_unit_for_contract", id)
	for card in data.fields._mission_drop_cards:
		var pilot: String = card.get("pilot_unit_id", "")
		if not pilot.is_empty(): actors[pilot] = root.call("_resolve_known_unit_for_contract", pilot)
	var checked := validate_data(owner, data, {"actors":actors, "simulation_root":root, "visits":data.visits, "craft_identities":data.craft_identities})
	if not checked.ok: return checked
	return {"schema":"mission_transport_checkpoint.v1", "value":encoded.value}

static func stable(owner: Node, root: Node) -> bool:
	if not is_instance_valid(root): return false
	if not Dictionary(owner.get("_selected_team_boarding_requests")).is_empty() or not String(owner.get("_campaign_extraction_craft_id")).is_empty(): return false
	for effect in Array(root.get("effects_queue")):
		if effect is Dictionary and effect.get("effect_type", "") in ["dropship_embark_unit", "dropship_deploy_unit"]: return false
	return true

static func pack_sequence(sequence: Dictionary) -> Dictionary:
	var result := sequence.duplicate(true)
	var phase: Variant = result.get("phase")
	if not phase in ["", "complete"] or not Dictionary(result.get("hex_admission", {})).is_empty(): return bad("transport_transition_pending")
	var ids: Array = []
	for actor in result.get("units", []):
		if not is_instance_valid(actor) or not actor.has_method("get_unit_id"): return bad("transport_actor_missing")
		var id: String = actor.call("get_unit_id")
		if id.is_empty() or ids.has(id): return bad("transport_actor_duplicate")
		ids.append(id)
	result.erase("units")
	result["unit_ids"] = ids
	return {"ok":true, "value":result}

static func prepare(owner: Node, state: Dictionary, bindings: Dictionary) -> Dictionary:
	if state.size() != 2 or state.get("schema") != "mission_transport_checkpoint.v1": return bad("transport_schema_invalid")
	var decoded := CODEC.decode_value(state.get("value"))
	if not decoded.ok or not decoded.value is Dictionary: return bad("transport_value_invalid")
	var data: Dictionary = decoded.value
	var geometry := decode_geometry(data)
	if not geometry.ok: return geometry
	# Check bounded codec values before handing nested dictionaries to validation.
	var checked := validate_data(owner, data, bindings)
	if not checked.ok: return checked
	var canonical := {"schema":"mission_transport_checkpoint.v1", "value":encode_data(data).value}
	var candidate := {"data":data, "bindings":bindings.duplicate(true), "binding_stamp":binding_stamp(bindings), "state":canonical, "owner":owner, "baseline":owner_stamp(owner)}
	return {"ok":true, "candidate":candidate}

static func validate(owner: Node, candidate: Dictionary, bindings: Dictionary) -> Dictionary:
	if candidate.get("owner") != owner or candidate.get("bindings") != bindings or binding_stamp(bindings) != candidate.get("binding_stamp") or owner_stamp(owner) != candidate.get("baseline"): return bad("transport_candidate_stale")
	var encoded := encode_data(candidate.get("data", {}))
	if not encoded.ok or {"schema":"mission_transport_checkpoint.v1", "value":encoded.value} != candidate.get("state"): return bad("transport_candidate_changed")
	return validate_data(owner, candidate.data, bindings)

static func validate_data(owner: Node, data: Dictionary, bindings: Dictionary) -> Dictionary:
	if data.size() != 5: return bad("transport_fields_invalid")
	for name in ["fields", "primary", "parallel", "visits", "craft_identities"]:
		if not data.get(name) is Dictionary: return bad("transport_fields_invalid")
	if data.fields.size() != FIELDS.size(): return bad("transport_fields_invalid")
	for field in FIELDS:
		if not data.fields.has(field) or typeof(data.fields[field]) != typeof(owner.get(field)): return bad("transport_field_type")
	if bindings.get("visits") != data.visits or bindings.get("craft_identities") != data.craft_identities: return bad("transport_identity_mismatch")
	var root: Variant = bindings.get("simulation_root")
	var actors: Variant = bindings.get("actors")
	if not is_instance_valid(root) or root != owner.get_node_or_null("../SimulationRoot") or not root.has_method("_resolve_known_unit_for_contract") or not actors is Dictionary: return bad("transport_bindings_missing")
	if not stable(owner, root): return bad("transport_transition_pending")
	var membership: Dictionary = {}
	var cards: Dictionary = {}
	for card in data.fields._mission_drop_cards:
		if not card is Dictionary or not card.get("craft_id") is String: return bad("transport_card_invalid")
		var craft: String = card.craft_id
		if cards.has(craft) or not data.craft_identities.has(craft) or data.craft_identities[craft] != {"model_id":card.get("model_id", "")}: return bad("transport_craft_duplicate")
		if card.get("state", "") in ["inbound", "landed", "unloading", "outbound", "to_mission", "to_homebase", "to_fob"]: return bad("transport_transition_pending")
		cards[craft] = card
	if cards.size() != data.craft_identities.size(): return bad("transport_craft_missing")
	for craft in data.fields._field_landing_by_craft:
		var landing: Variant = data.fields._field_landing_by_craft[craft]
		if not cards.has(craft) or not landing is Dictionary: return bad("transport_landing_invalid")
		if landing.has("ground_body_profile") and not BODY_PROFILE.read_bound(cards[craft], landing.ground_body_profile).ok: return bad("transport_landing_invalid")
	if bindings.has("pilot_bindings"):
		if not bindings.pilot_bindings is Dictionary: return bad("transport_pilot_binding_invalid")
		for craft in cards:
			if bindings.pilot_bindings.get(craft, "") != cards[craft].get("pilot_unit_id", ""): return bad("transport_pilot_binding_invalid")
	for craft in data.visits:
		var visit: Variant = data.visits[craft]
		if not visit is Dictionary or visit.get("craft_id") != craft or not cards.has(craft) or not visit.get("unit_ids") is Array: return bad("transport_visit_invalid")
		for id in visit.unit_ids:
			if not id is String or id.is_empty() or id != id.strip_edges() or membership.has(id): return bad("transport_crew_duplicate")
			membership[id] = craft
	for craft in data.visits:
		var pilot: Variant = cards[craft].get("pilot_unit_id", "")
		if not pilot is String or (membership.has(pilot) and membership[pilot] != craft): return bad("transport_pilot_foreign")
		if not pilot.is_empty(): membership[pilot] = craft
	var sequences: Dictionary = data.parallel.duplicate(true)
	var shape := pack_sequence(owner.call("_capture_active_drop_sequence"))
	if not shape.ok: return bad("transport_transition_pending")
	if data.primary.size() != shape.value.size(): return bad("transport_sequence_invalid")
	for key in shape.value:
		if not data.primary.has(key) or typeof(data.primary[key]) != typeof(shape.value[key]): return bad("transport_sequence_invalid")
	if data.primary.phase != "":
		var id: String = data.primary.craft_id
		if sequences.has(id): return bad("transport_sequence_duplicate")
		sequences[id] = data.primary
	elif not data.primary.unit_ids.is_empty(): return bad("transport_sequence_invalid")
	var aboard: Dictionary = data.fields._embarked_unit_ids.duplicate()
	for craft in sequences:
		if not sequences[craft] is Dictionary or not sequences[craft].get("embarked_unit_ids") is Dictionary: return bad("transport_sequence_invalid")
		for id in sequences[craft].embarked_unit_ids: aboard[id] = true
	for id in membership:
		var actor: Variant = actors.get(id)
		if not is_instance_valid(actor) or not actor is Node2D or actor.is_queued_for_deletion() or not actor.has_method("get_unit_id") or actor.call("get_unit_id") != id or root.call("_resolve_known_unit_for_contract", id) != actor: return bad("transport_actor_binding_invalid")
		var deployed: bool = data.fields._deployed_unit_ids.has(id)
		var embarked: bool = aboard.has(id)
		if deployed == embarked: return bad("transport_presence_mismatch")
		if bindings.has("presence_bindings"):
			if not bindings.presence_bindings is Dictionary or not bindings.presence_bindings.get(id) is bool or bindings.presence_bindings[id] != embarked: return bad("transport_presence_binding_invalid")
		elif bool(actor.get_meta("dropship_embarked", false)) != embarked: return bad("transport_presence_mismatch")
		if root.has_method("has_hex_pending_admission") and root.call("has_hex_pending_admission", id): return bad("transport_transition_pending")
	for field in ["_deployed_unit_ids", "_embarked_unit_ids"]:
		for id in data.fields[field]:
			if not membership.has(id) or data.fields[field][id] != true: return bad("transport_foreign_presence")
	for id in data.fields._deployed_unit_positions:
		if not data.fields._deployed_unit_ids.has(id) or not data.fields._deployed_unit_positions[id] is Vector2: return bad("transport_position_invalid")
	for craft in sequences:
		var sequence: Variant = sequences[craft]
		if not sequence is Dictionary or sequence.get("phase") != "complete" or sequence.get("craft_id") != craft or not cards.has(craft): return bad("transport_sequence_invalid")
		var types := {"phase":TYPE_STRING,"unit_ids":TYPE_ARRAY,"unit_index":TYPE_INT,"timer":TYPE_FLOAT,"position":TYPE_VECTOR2,"lz_position":TYPE_VECTOR2,"visual_only":TYPE_BOOL,"craft_id":TYPE_STRING,"display_name":TYPE_STRING,"approach_angle":TYPE_STRING,"embarked_unit_ids":TYPE_DICTIONARY,"card_feedback_text":TYPE_STRING}
		for key in types:
			if not sequence.has(key) or typeof(sequence[key]) != types[key]: return bad("transport_sequence_invalid")
		var optional := {"hex_admission":TYPE_DICTIONARY,"fireteam_name":TYPE_STRING,"model_id":TYPE_STRING,"craft_type":TYPE_STRING,"station_pad_id":TYPE_STRING,"boarded_fireteam_ids":TYPE_ARRAY,"progress":TYPE_FLOAT,"service_reentry":TYPE_BOOL}
		for key in sequence:
			if not types.has(key) and (not optional.has(key) or typeof(sequence[key]) != optional[key]): return bad("transport_sequence_invalid")
		if sequence.has("model_id") and sequence.model_id != cards[craft].get("model_id", ""): return bad("transport_identity_mismatch")
		if sequence.unit_index < 0 or sequence.unit_index > sequence.unit_ids.size() or sequence.timer < 0.0 or sequence.visual_only: return bad("transport_sequence_invalid")
		if root.has_method("is_air_support_craft_airborne") and root.call("is_air_support_craft_airborne", craft): return bad("transport_not_grounded")
		if not sequence.get("position") is Vector2 or sequence.position != sequence.get("lz_position") or not sequence.get("hex_admission", {}).is_empty(): return bad("transport_not_grounded")
		if not sequence.get("unit_ids") is Array or not sequence.get("embarked_unit_ids") is Dictionary: return bad("transport_sequence_invalid")
		var seen: Dictionary = {}
		for id in sequence.unit_ids:
			if not id is String or not membership.has(id) or membership[id] != craft or seen.has(id): return bad("transport_sequence_crew_invalid")
			seen[id] = true
		var expected_count := 0
		for id in membership:
			if membership[id] == craft: expected_count += 1
		if seen.size() != expected_count: return bad("transport_sequence_crew_missing")
		for id in sequence.embarked_unit_ids:
			if not seen.has(id) or data.fields._deployed_unit_ids.has(id) or sequence.embarked_unit_ids[id] != true: return bad("transport_sequence_presence_invalid")
	for craft in data.visits:
		if not sequences.has(craft): return bad("transport_sequence_missing")
	if not sequences.is_empty() and not owner.call("_should_keep_campaign_dropship_landed"): return bad("transport_not_grounded")
	if bindings.has("presence_bindings") and bindings.presence_bindings.size() != membership.size(): return bad("transport_presence_binding_invalid")
	var selected: String = data.fields._mission_drop_craft_id
	if not selected.is_empty() and (not cards.has(selected) or data.fields._mission_drop_pilot_unit_id != cards[selected].get("pilot_unit_id", "")): return bad("transport_selected_identity_invalid")
	if data.fields._mission_drop_progress < 0.0 or data.fields._mission_drop_progress > 100.0 or data.fields._mission_drop_eta_seconds < 0 or data.fields._mission_drop_passenger_count < 0 or data.fields._drop_ship_cooldown_remaining < 0.0: return bad("transport_field_range")
	return {"ok":true}

static func unpack_sequence(sequence: Dictionary, actors: Dictionary) -> Dictionary:
	var result := sequence.duplicate(true)
	result.units = []
	for id in result.unit_ids: result.units.append(actors[id])
	result.erase("unit_ids")
	return result

static func binding_stamp(bindings: Dictionary) -> Dictionary:
	var root: Variant = bindings.get("simulation_root")
	if not is_instance_valid(root): return {}
	var result := {"root":root.get_instance_id(), "actors":{}, "context":root.call("get_hex_ground_context_revision") if root.has_method("get_hex_ground_context_revision") else -1}
	for id in bindings.get("actors", {}):
		var actor: Variant = bindings.actors[id]
		if not is_instance_valid(actor): return {}
		result.actors[id] = [actor.get_instance_id(), actor.get_meta("dropship_embarked", false), root.call("_hex_payload_identity", id) if root.has_method("_hex_payload_identity") else {}]
	return result

static func owner_stamp(owner: Node) -> Dictionary:
	var fields := {}
	for field in FIELDS: fields[field] = owner.get(field)
	return {"fields":fields.duplicate(true), "primary":owner.call("_capture_active_drop_sequence"), "parallel":Dictionary(owner.get("_parallel_drop_sequences_by_craft")).duplicate(true), "visits":Dictionary(owner.get_parent().get_meta("singleplayer_visit_identities", {})).duplicate(true)}

## Only this existing profile slot contains 3D values; never deserialize objects.
static func encode_data(data: Dictionary) -> Dictionary:
	var wire := data.duplicate(true)
	var landings: Variant = wire.get("fields", {}).get("_field_landing_by_craft", {})
	if not landings is Dictionary: return bad("transport_landing_invalid")
	for craft in landings:
		if not landings[craft] is Dictionary: return bad("transport_landing_invalid")
		var landing: Dictionary = landings[craft]
		if landing.has("transport_ok_key_kind_v1"): return bad("transport_landing_invalid")
		# Existing non-hex landing.ok=true creates a StringName key. Preserve
		# that one known key kind explicitly; all other unsupported keys fail.
		for key in landing.keys():
			if typeof(key) == TYPE_STRING_NAME and key == &"ok":
				if not landing[key] is bool: return bad("transport_landing_invalid")
				var ok: bool = landing[key]
				landing.erase(key)
				landing["ok"] = ok
				landing["transport_ok_key_kind_v1"] = "StringName"
		var profile: Variant = landings[craft].get("ground_body_profile")
		if profile == null: continue
		if not profile is Dictionary or not profile.get("bounds") is AABB: return bad("transport_landing_invalid")
		var bounds: AABB = profile.bounds
		profile["bounds"] = {"transport_aabb_v1":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}
	return CODEC.encode_value(wire)

static func decode_geometry(data: Dictionary) -> Dictionary:
	if not data.get("fields") is Dictionary: return bad("transport_fields_invalid")
	var landings: Variant = data.fields.get("_field_landing_by_craft")
	if not landings is Dictionary: return bad("transport_landing_invalid")
	for craft in landings:
		if not landings[craft] is Dictionary: return bad("transport_landing_invalid")
		var landing: Dictionary = landings[craft]
		if landing.has("transport_ok_key_kind_v1"):
			if landing.transport_ok_key_kind_v1 != "StringName" or not landing.get("ok") is bool: return bad("transport_landing_invalid")
			var ok: bool = landing["ok"]
			landing.erase("ok")
			landing.erase("transport_ok_key_kind_v1")
			landing[&"ok"] = ok
		var profile: Variant = landings[craft].get("ground_body_profile")
		if profile == null: continue
		if not profile is Dictionary or not profile.get("bounds") is Dictionary: return bad("transport_landing_invalid")
		var bounds: Dictionary = profile.bounds
		if bounds.size() != 1 or not bounds.get("transport_aabb_v1") is Array or bounds.transport_aabb_v1.size() != 6: return bad("transport_landing_invalid")
		for number in bounds.transport_aabb_v1:
			if typeof(number) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(number)): return bad("transport_landing_invalid")
		var a: Array = bounds.transport_aabb_v1
		profile["bounds"] = AABB(Vector3(a[0],a[1],a[2]),Vector3(a[3],a[4],a[5]))
	return {"ok":true}

static func publish(owner: Node, candidate: Dictionary) -> void:
	var data: Dictionary = candidate.data
	for field in FIELDS: owner.set(field, data.fields[field])
	owner.get_parent().set_meta("singleplayer_visit_identities", data.visits)
	var primary := unpack_sequence(data.primary, candidate.bindings.actors)
	for key in ["phase", "units", "unit_index", "hex_admission", "timer", "position", "fireteam_name", "visual_only", "craft_id", "display_name", "lz_position", "approach_angle", "embarked_unit_ids"]:
		owner.set("_drop_sequence_" + key, primary[key])
	var parallel: Dictionary = {}
	for craft in data.parallel: parallel[craft] = unpack_sequence(data.parallel[craft], candidate.bindings.actors)
	owner.set("_parallel_drop_sequences_by_craft", parallel)
	if candidate.bindings.has("presence_bindings"):
		for id in candidate.bindings.presence_bindings:
			candidate.bindings.actors[id].set_meta("dropship_embarked", candidate.bindings.presence_bindings[id])

static func bad(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason}
