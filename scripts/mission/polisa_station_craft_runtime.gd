extends RefCounted
## Pure facts/builders. The local TacticalController owns admission and presence.
const LAYOUT_PATH := "res://art/polisar_r09_20261114/layout_compiled.json"
const RECEIPT_PAD_COMPATIBILITY_REVISION := 1
const RECEIPT_PAD_IDS := ["polisa_pad_01", "polisa_pad_02", "polisa_pad_03", "polisa_pad_04", "polisa_pad_05", "polisa_pad_06", "polisa_pad_07"]

## Immutable historical compatibility for receipt v2, not an admission shortcut.
## Ref03 bodies at existing .22/model and 1.0/cell fit all R08 decks at every yaw,
## including the real snapped marker offset (bounded source fixture proves this).
static func receipt_pad_compatible(model_id: String, pad_id: String) -> bool:
	return model_id in ["cutlass", "buccaneer"] and pad_id in RECEIPT_PAD_IDS

static func iso_to_plane(position: Vector2) -> Vector2:
	return Vector2(position.x / 128.0 + position.y / 64.0, position.y / 64.0 - position.x / 128.0)

static func station_pads(map: RefCounted) -> Array:
	var result: Array = []
	if map == null: return result
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	if not parsed is Dictionary: return result
	var origin: Array = parsed.get("origin_plane", [])
	if origin.size() != 2: return result
	for source: Dictionary in parsed.get("pads", []):
		var id := String(source.get("id", ""))
		if id.is_empty() or not map.call("has_marker", id): continue
		var position: Vector2 = map.call("get_marker_position", id)
		if not position.is_finite(): continue
		var center: Array = source.get("center", [])
		var size: Array = source.get("size", [])
		if center.size() != 2 or size.size() != 2: continue
		var dimensions := Vector2(float(size[0]), float(size[1]))
		if not dimensions.is_finite() or dimensions.x <= 0.0 or dimensions.y <= 0.0: continue
		var actual_center := Vector2(float(center[0]) + float(origin[0]), float(center[1]) + float(origin[1]))
		result.append({"pad_id": id, "position": position, "class": String(source.get("class", "")),
			"deck": Rect2(actual_center - dimensions * 0.5, dimensions)})
	return result

## Projection must come from the actual existing renderer: body AABB, model scale,
## grid cell size and current landed yaw. No real-SC metres or art reserve assumptions.
static func projected_body(position: Vector2, projection: Dictionary) -> Dictionary:
	if not projection.get("bounds") is AABB: return _reject("missing_body_bounds")
	var bounds: AABB = projection.bounds
	var scale := float(projection.get("model_scale", 0.0))
	var cell_size := float(projection.get("cell_size", 0.0))
	var yaw := float(projection.get("yaw_degrees", NAN))
	if not position.is_finite() or not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.x <= 0.0 or bounds.size.z <= 0.0 or not is_finite(scale) or not is_finite(cell_size) or not is_finite(yaw) or scale <= 0.0 or cell_size <= 0.0:
		return _reject("invalid_body_projection")
	var angle := deg_to_rad(yaw)
	var center := iso_to_plane(position)
	var corners: Array[Vector2] = []
	for x in [bounds.position.x, bounds.end.x]:
		for z in [bounds.position.z, bounds.end.z]:
			var local := Vector2(float(x), float(z)) * scale / cell_size
			corners.append(center + Vector2(cos(angle) * local.x + sin(angle) * local.y, -sin(angle) * local.x + cos(angle) * local.y))
	var minimum: Vector2 = corners[0]
	var maximum: Vector2 = corners[0]
	for corner in corners:
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return {"ok": true, "footprint": Rect2(minimum, maximum - minimum), "corners": corners}

static func preview_admission(craft: Dictionary, pads: Array, projection: Dictionary, occupied: Array, requested_pad_id: String = "") -> Dictionary:
	if String(craft.get("craft_id", "")).is_empty() or String(craft.get("model_id", "")) not in ["cutlass", "buccaneer"]:
		return _reject("unsupported_station_craft")
	for pad: Dictionary in pads:
		if not requested_pad_id.is_empty() and String(pad.pad_id) != requested_pad_id: continue
		var body := projected_body(pad.position, projection)
		if not bool(body.get("ok", false)): return body
		var deck: Rect2 = pad.deck
		var footprint: Rect2 = body.footprint
		# Rect containment includes the far edge, unlike Rect2.has_point.
		if not deck.encloses(footprint): continue
		var blocked := false
		for obstacle: Dictionary in occupied:
			if not obstacle.get("footprint") is Rect2: return _reject("missing_occupied_body_projection")
			if String(obstacle.get("pad_id", "")) == String(pad.pad_id): blocked = true
			if obstacle.get("footprint") is Rect2 and footprint.intersects(obstacle.footprint, true): blocked = true
		if blocked: continue
		return {"ok": true, "craft_id": String(craft.craft_id), "model_id": String(craft.model_id),
			"pad_id": String(pad.pad_id), "position": pad.position, "footprint": footprint,
			"yaw_degrees": float(projection.yaw_degrees)}
	return _reject("no_free_compatible_station_pad")

static func parked_sequence(craft: Dictionary, admission: Dictionary) -> Dictionary:
	return {"phase": "complete", "units": [], "unit_index": 0, "timer": 0.0,
		"position": admission.position, "lz_position": admission.position,
		"visual_only": false, "craft_id": String(craft.craft_id),
		"display_name": String(craft.get("display_name", craft.craft_id)),
		"model_id": String(craft.model_id), "craft_type": String(craft.get("craft_type", "")),
		"station_pad_id": String(admission.pad_id), "approach_angle": "NW",
		"embarked_unit_ids": {}, "boarded_fireteam_ids": [], "card_feedback_text": "Schiff zur Abholung bereit"}

static func preview_handoff(source: String, target: String, unit_ids: PackedStringArray, pilot_id: String, snapshot: Dictionary) -> Dictionary:
	var crafts: Dictionary = snapshot.get("crafts", {})
	var people: Dictionary = snapshot.get("people", {})
	var membership: Dictionary = snapshot.get("membership", {})
	if source.is_empty() or source == target or not crafts.has(source) or not crafts.has(target): return _reject("unknown_handoff_craft")
	if not bool(crafts[source].get("parked", false)) or not bool(crafts[target].get("parked", false)): return _reject("handoff_craft_not_parked")
	if unit_ids.is_empty() or not unit_ids.has(pilot_id): return _reject("handoff_pilot_missing")
	var unique := {}
	for id in unit_ids:
		if unique.has(id) or not Array(membership.get(source, [])).has(id): return _reject("invalid_source_membership")
		unique[id] = true
		for craft_id: String in membership:
			if craft_id != source and Array(membership[craft_id]).has(id): return _reject("ambiguous_unit_membership")
		var person: Dictionary = people.get(id, {})
		if not bool(person.get("alive", false)) or not bool(person.get("deployed", false)) or bool(person.get("boarding_pending", true)): return _reject("handoff_requires_local_deployed_person")
		# Existing retirement clears team execution. Only whole fireteams move;
		# a pilot with no fireteam may be reassigned individually.
		var team := String(person.get("fireteam_id", ""))
		if not team.is_empty() and id != String(crafts[source].get("pilot_unit_id", "")):
			for member: String in people:
				if member != String(crafts[source].get("pilot_unit_id", "")) and String(Dictionary(people.get(member, {})).get("fireteam_id", "")) == team and not unit_ids.has(member): return _reject("handoff_requires_whole_fireteam")
		for craft_id: String in crafts:
			if craft_id != source and String(crafts[craft_id].get("pilot_unit_id", "")) == id: return _reject("pilot_already_assigned")
	var target_members: Array = Array(membership.get(target, [])).duplicate()
	for id in unit_ids: target_members.append(id)
	if target_members.size() > int(crafts[target].get("capacity", 0)): return _reject("handoff_capacity_exceeded")
	var old_pilot := String(crafts[target].get("pilot_unit_id", ""))
	if not old_pilot.is_empty() and old_pilot != pilot_id: return _reject("target_has_pilot")
	return {"ok": true, "source_craft_id": source, "target_craft_id": target,
		"unit_ids": unit_ids.duplicate(), "pilot_unit_id": pilot_id}

static func _reject(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
