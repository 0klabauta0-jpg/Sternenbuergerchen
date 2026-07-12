extends RefCounted

const SCHEMA := "sternenbuergerchen.multiplayer_dropship_bootstrap.v1"
const SOURCE := "multiplayer_lobby"


static func build_initial_planning_state(controller: Node, assignments: Dictionary) -> Dictionary:
	if controller == null or not controller.has_method("get_planning_state") or not controller.has_method("get_fireteam_member_status_row_snapshot"):
		return {}
	var members_by_fireteam := _build_member_ids_by_fireteam(Array(controller.call("get_fireteam_member_status_row_snapshot")))
	var fireteam_ids := _assigned_fireteam_ids(Dictionary(assignments.get("peer_fireteams", {})))
	var cards: Array = []
	var embarked_unit_ids: Array = []
	for fireteam_id in fireteam_ids:
		var member_ids: Array = Array(members_by_fireteam.get(fireteam_id, [])).duplicate()
		if member_ids.is_empty():
			continue
		embarked_unit_ids.append_array(member_ids)
		cards.append(_build_card(fireteam_id, member_ids, cards.size() + 1))
	if cards.is_empty():
		return {}
	var state: Dictionary = Dictionary(controller.call("get_planning_state")).duplicate(true)
	var first_card: Dictionary = Dictionary(cards[0])
	state.merge({
		"schema": SCHEMA,
		"mission_drop_source": SOURCE,
		"mission_drop_craft_id": String(first_card.get("craft_id", "")),
		"mission_drop_display_name": String(first_card.get("display_name", "Dropship")),
		"mission_drop_title_text": String(first_card.get("title_text", "Dropship")),
		"mission_drop_state": "waiting",
		"mission_drop_progress": 0.0,
		"mission_drop_eta_seconds": 0,
		"mission_drop_passenger_count": Array(first_card.get("embarked_unit_ids", [])).size(),
		"mission_drop_cards": cards,
		"embarked_unit_ids": embarked_unit_ids,
		"deployed_unit_ids": [],
		"deployed_unit_positions": {},
		"selected_fireteam": String(first_card.get("boarded_fireteam_ids", [""])[0]),
		"selected_fireteams": Array(first_card.get("boarded_fireteam_ids", [])),
		"has_lz_position": false,
		"drop_ship_requested": false,
		"drop_ship_staged": true,
		"ui_sets_gameplay_truth": false,
	}, true)
	return state


static func _assigned_fireteam_ids(peer_fireteams: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for peer_id in peer_fireteams.keys():
		for fireteam_variant in PackedStringArray(peer_fireteams.get(peer_id, PackedStringArray())):
			var fireteam_id: String = String(fireteam_variant).strip_edges().to_lower()
			if not fireteam_id.is_empty() and not result.has(fireteam_id):
				result.append(fireteam_id)
	result.sort()
	return result


static func _build_member_ids_by_fireteam(rows: Array) -> Dictionary:
	var result: Dictionary = {}
	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(row_variant)
		var fireteam_id: String = String(row.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var member_ids: Array = []
		for member_variant in Array(row.get("members", [])):
			var unit_id: String = String(Dictionary(member_variant).get("unit_id", "")).strip_edges()
			if not unit_id.is_empty():
				member_ids.append(unit_id)
		result[fireteam_id] = member_ids
	return result


static func _build_card(fireteam_id: String, member_ids: Array, order_number: int) -> Dictionary:
	var label: String = fireteam_id.to_upper()
	return {
		"craft_id": "dropship_%s" % fireteam_id,
		"display_name": "Dropship %s" % label,
		"title_text": "#%d Dropship %s" % [order_number, label],
		"state": "waiting",
		"progress": 0.0,
		"eta_seconds": 0,
		"passenger_count": member_ids.size(),
		"embarked_unit_ids": member_ids.duplicate(),
		"boarded_fireteam_ids": [fireteam_id],
		"has_embarked_payload": true,
		"has_lz_position": false,
		"approach_angle": "NW" if order_number % 2 == 1 else "SE",
		"drop_ship_requested": false,
		"drop_ship_staged": true,
		"payload_source": SOURCE,
	}
