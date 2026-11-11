extends RefCounted
## One atomic home checkpoint, independent of the editable Skirmish profile.
const DEFAULT_PATH := "user://campaigns/introduction/checkpoint_v1.json"
const MAX_BYTES := 4 * 1024 * 1024
static func validate_payload(payload: Dictionary) -> Dictionary:
	if payload.get("schema_version") != 1 or typeof(payload.get("roster")) != TYPE_ARRAY or payload.roster.size() < 2 or payload.roster.size() > 4 or typeof(payload.get("craft")) != TYPE_DICTIONARY:
		return {"ok":false,"reason":"invalid_checkpoint"}
	var ids: Array = []
	for unit in payload.roster:
		if typeof(unit) != TYPE_DICTIONARY or typeof(unit.get("unit_id")) != TYPE_STRING or String(unit.unit_id).is_empty() or ids.has(unit.unit_id):
			return {"ok":false,"reason":"invalid_campaign_roster"}
		for field in ["skill_values", "communication_values", "platform_values", "behavior_axes", "method_scores", "function_scores", "recovery_state", "progression", "ftl_tactical_progression"]:
			if unit.has(field) and typeof(unit[field]) != TYPE_DICTIONARY:
				return {"ok":false,"reason":"invalid_roster_field"}
		ids.append(unit.unit_id)
	if payload.has("base_personnel"):
		if typeof(payload.craft.get("definition")) != TYPE_DICTIONARY:
			return {"ok":false,"reason":"invalid_campaign_craft"}
		var base: Variant = payload.base_personnel
		if typeof(base) != TYPE_DICTIONARY or base.get("version") != 1 or typeof(base.get("units")) != TYPE_DICTIONARY or base.units.size() != payload.roster.size():
			return {"ok":false,"reason":"invalid_base_personnel"}
		var occupied: Array = []
		for id in base.units:
			if not ids.has(id) or typeof(base.units[id]) != TYPE_DICTIONARY:
				return {"ok":false,"reason":"invalid_base_identity"}
			var unit: Dictionary = base.units[id]
			for field in ["auto_rest_enabled","rest_automatic"]:
				if unit.has(field) and typeof(unit[field])!=TYPE_BOOL: return {"ok":false,"reason":"invalid_auto_rest_setting"}
			if typeof(unit.get("position")) != TYPE_ARRAY or unit.position.size() != 2 or not String(unit.get("status", "")) in ["outside","sleeping","aboard"]:
				return {"ok":false,"reason":"invalid_base_position"}
			for number in unit.position:
				if typeof(number) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(number)):
					return {"ok":false,"reason":"invalid_base_position"}
			if unit.status == "sleeping":
				var bed := String(unit.get("bed_id", ""))
				if bed.is_empty() or occupied.has(bed):
					return {"ok":false,"reason":"invalid_base_bed"}
				occupied.append(bed)
			if unit.status == "aboard":
				var valid_craft := false
				for ship: Dictionary in Array(payload.get("fleet",[{"definition":payload.craft.definition}])):
					valid_craft = valid_craft or String(unit.get("craft_id","")) == String(ship.definition.get("craft_id",""))
				if not valid_craft: return {"ok":false,"reason":"invalid_base_craft"}
	var leader: Dictionary = payload.roster[0]
	var pilot: Dictionary = payload.roster[1]
	if String(leader.get("roster_role_category", "")) != "operator" or String(pilot.get("roster_role_category", "")) != "pilot" or not _positive_number(leader.get("skill_leadership", Dictionary(leader.get("skill_values", {})).get("leadership", 0))) or not _positive_number(pilot.get("dropship_piloting")):
		return {"ok":false,"reason":"invalid_campaign_roles"}
	var craft: Dictionary = payload.craft
	if typeof(craft.get("definition")) != TYPE_DICTIONARY or String(craft.definition.get("craft_id", "")).is_empty() or typeof(craft.get("pilot_id")) != TYPE_STRING or not String(craft.pilot_id) in ([""] + ids) or craft.definition.get("craft_type") != "dropship":
		return {"ok":false,"reason":"invalid_campaign_craft"}
	for field in ["staged_unit_ids", "staged_fireteam_ids", "fireteam_definitions"]:
		if craft.has(field) and typeof(craft[field]) != TYPE_ARRAY:
			return {"ok":false,"reason":"invalid_craft_field"}
	for field in ["member_loadouts", "selected_cargo", "loaded_cargo"]:
		if craft.has(field) and typeof(craft[field]) != TYPE_DICTIONARY:
			return {"ok":false,"reason":"invalid_craft_field"}
	for unit_id in craft.get("staged_unit_ids", []):
		if typeof(unit_id) != TYPE_STRING or not ids.has(unit_id):
			return {"ok":false,"reason":"invalid_staged_unit"}
	for unit_id in craft.get("member_loadouts", {}):
		if not ids.has(unit_id) or typeof(craft.member_loadouts[unit_id]) != TYPE_DICTIONARY:
			return {"ok":false,"reason":"invalid_saved_loadout"}
	var fireteam_ids: Array = []
	for definition in craft.get("fireteam_definitions", []):
		if typeof(definition) != TYPE_DICTIONARY or typeof(definition.get("id")) != TYPE_STRING or String(definition.id).is_empty() or fireteam_ids.has(definition.id) or typeof(definition.get("lead_unit_id")) != TYPE_STRING:
			return {"ok":false,"reason":"invalid_saved_fireteam"}
		var lead_id: String = definition.lead_unit_id
		if not lead_id.is_empty() and (not ids.has(lead_id)):
			return {"ok":false,"reason":"invalid_saved_fireteam_lead"}
		var member_ids: Array = []
		for field in ["member_unit_ids", "members"]:
			if not definition.has(field):
				continue
			if typeof(definition[field]) not in [TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY]:
				return {"ok":false,"reason":"invalid_saved_fireteam_members"}
			var seen: Array = []
			for member in definition[field]:
				var member_id: Variant = member.get("unit_id", member.get("id", "")) if typeof(member) == TYPE_DICTIONARY else member
				if typeof(member_id) != TYPE_STRING or not ids.has(member_id) or seen.has(member_id):
					return {"ok":false,"reason":"invalid_saved_fireteam_member"}
				seen.append(member_id)
				if not member_ids.has(member_id):
					member_ids.append(member_id)
		if typeof(definition.get("member_loadouts", {})) != TYPE_DICTIONARY:
			return {"ok":false,"reason":"invalid_saved_fireteam_loadouts"}
		for member_id in definition.get("member_loadouts", {}):
			if not ids.has(member_id) or typeof(definition.member_loadouts[member_id]) != TYPE_DICTIONARY:
				return {"ok":false,"reason":"invalid_saved_fireteam_loadout"}
			if not member_ids.has(member_id):
				member_ids.append(member_id)
		if lead_id.is_empty() and not member_ids.is_empty():
			return {"ok":false,"reason":"missing_saved_fireteam_lead"}
		fireteam_ids.append(definition.id)
	for fireteam_id in craft.get("staged_fireteam_ids", []):
		if not fireteam_ids.has(fireteam_id):
			return {"ok":false,"reason":"invalid_staged_fireteam"}
	if craft.definition.has("cargo_options") and typeof(craft.definition.cargo_options) != TYPE_ARRAY:
		return {"ok":false,"reason":"invalid_craft_definition"}
	for field in ["campaign", "supply", "onboarding"]:
		if typeof(payload.get(field)) != TYPE_DICTIONARY:
			return {"ok":false,"reason":"missing_owner_state"}
	if payload.campaign.get("enforce_sequence",true) != true: return {"ok":false,"reason":"campaign_sequence_disabled"}
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	var onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
	for pair in [[campaign, payload.campaign], [supply, payload.supply], [onboarding, payload.onboarding]]:
		var result: Dictionary = pair[0].restore_state(pair[1])
		if not result.get("ok", false):
			return result
	if not payload.campaign.departures_by_craft_id.is_empty() or String(payload.campaign.selected_location_id) != "homebase":
		return {"ok":false,"reason":"checkpoint_not_home"}
	for job in payload.campaign.jobs.values():
		if String(job.status) == "active":
			return {"ok":false,"reason":"checkpoint_active_job"}
	var fleet: Variant = payload.get("fleet",[{"definition":craft.definition,"pilot_id":craft.pilot_id,"location":"homebase"}])
	var station: Dictionary = supply.validate_station_receipts(payload.supply.requests)
	if not station.get("ok", false): return station
	if int(station.capacity) > 2 and not bool(payload.campaign.get("progress", {}).get("second_pad_built", false)): return {"ok":false,"reason":"checkpoint_pad_progress_mismatch"}
	if typeof(fleet) != TYPE_ARRAY or fleet.is_empty() or fleet.size() > int(station.capacity): return {"ok":false,"reason":"invalid_campaign_fleet"}
	var fleet_ids: Array = []
	for ship in fleet:
		if typeof(ship) != TYPE_DICTIONARY or typeof(ship.get("definition")) != TYPE_DICTIONARY: return {"ok":false,"reason":"invalid_campaign_fleet"}
		var ship_id := String(ship.definition.get("craft_id",""))
		if ship_id.is_empty() or fleet_ids.has(ship_id) or String(ship.get("pilot_id","")) not in ([""]+ids) or String(ship.get("location","homebase")) not in ["homebase","waiting_pad"]: return {"ok":false,"reason":"invalid_campaign_fleet"}
		if ship_id.begins_with("polisa_"):
			var purchased: Dictionary = station.ships.get(ship_id, {})
			if purchased.is_empty() or String(ship.definition.get("model_id", "")) != String(purchased.model_id) or String(ship.definition.get("craft_type", "")) != String(purchased.craft_type): return {"ok":false,"reason":"checkpoint_unverified_station_ship"}
		fleet_ids.append(ship_id)
	for purchased_id: String in station.ships:
		if not fleet_ids.has(purchased_id): return {"ok":false,"reason":"checkpoint_missing_purchased_ship"}
	if String(fleet[0].definition.get("craft_id","")) != String(craft.definition.craft_id) or JSON.stringify(fleet[0].definition,"",true) != JSON.stringify(craft.definition,"",true) or String(fleet[0].get("pilot_id","")) != String(craft.pilot_id): return {"ok":false,"reason":"checkpoint_primary_craft_mismatch"}
	if payload.has("location_resources"):
		if typeof(payload.location_resources) != TYPE_DICTIONARY: return {"ok":false,"reason":"invalid_resource_checkpoint"}
		var resources: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json"))
		if typeof(resources) != TYPE_DICTIONARY: return {"ok":false,"reason":"invalid_resource_definitions"}
		for location in payload.location_resources:
			var state: Variant = payload.location_resources[location]
			if not payload.campaign.locations.has(location): return {"ok":false,"reason":"invalid_resource_checkpoint"}
			var expected: Variant = resources.get(location,{})
			if typeof(expected) != TYPE_DICTIONARY or typeof(state) != TYPE_DICTIONARY or state.get("version") != 1 or state.get("location_id") != location or typeof(state.get("sites")) != TYPE_DICTIONARY or state.sites.size() != expected.size(): return {"ok":false,"reason":"invalid_resource_checkpoint"}
			var durable: Dictionary = Dictionary(payload.supply.get("location_resources",{}))
			if durable.has(location) and JSON.stringify(durable[location],"",true) != JSON.stringify(state.sites,"",true): return {"ok":false,"reason":"resource_owner_mismatch"}
			for site in expected:
				var entry: Variant = state.sites.get(site)
				if typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("discovered")) != TYPE_BOOL or typeof(entry.get("remaining")) not in [TYPE_INT,TYPE_FLOAT]: return {"ok":false,"reason":"invalid_resource_checkpoint"}
				var remaining := float(entry.remaining)
				if not is_finite(remaining) or remaining < 0 or remaining != floor(remaining) or remaining > float(expected[site].quantity): return {"ok":false,"reason":"invalid_resource_checkpoint"}
	if payload.supply.fuel_by_craft_id.size() != fleet_ids.size(): return {"ok":false,"reason":"checkpoint_craft_mismatch"}
	for ship_id in fleet_ids:
		if not payload.supply.fuel_by_craft_id.has(ship_id): return {"ok":false,"reason":"checkpoint_craft_mismatch"}
	if payload.supply.reward_receipts.size() != payload.campaign.completion_receipts.size():
		return {"ok":false,"reason":"checkpoint_reward_mismatch"}
	for receipt_id in payload.supply.reward_receipts:
		if payload.campaign.completion_receipts.get(receipt_id) != payload.supply.reward_receipts[receipt_id]:
			return {"ok":false,"reason":"checkpoint_receipt_mismatch"}
	var sequence := ["satellite_recovery","outpost_recovery","benit_delivery","outpost_chip_recovery","buccaneer_rescue"]
	for index in range(mini(int(payload.onboarding.stage_index)-1,sequence.size())):
		if not payload.campaign.completion_receipts.has(String(sequence[index])+":completed"): return {"ok":false,"reason":"checkpoint_progress_mismatch"}
	var progress: Dictionary = payload.campaign.get("progress",{})
	if ids.has("campaign_outpost_recruit") != bool(progress.get("recruited_outpost",false)) or ids.has("campaign_rescue_pilot") != bool(progress.get("recruited_pilot",false)): return {"ok":false,"reason":"checkpoint_roster_progress_mismatch"}
	var original_fleet_count := fleet_ids.size() - Dictionary(station.ships).size()
	if original_fleet_count not in [1,2] or bool(progress.get("recruited_pilot",false)) != (original_fleet_count == 2) or (original_fleet_count == 2 and not fleet_ids.has("campaign_buccaneer_01")): return {"ok":false,"reason":"checkpoint_fleet_progress_mismatch"}

	return {"ok":true}
static func _valid_path(path: String) -> bool:
	return path.begins_with("user://campaigns/") and not path.contains("..") and path.ends_with(".json")
static func load_checkpoint(path: String = DEFAULT_PATH) -> Dictionary:
	if not _valid_path(path):
		return {"ok":false,"reason":"invalid_checkpoint_path"}
	if not FileAccess.file_exists(path):
		return {"ok":false,"reason":"checkpoint_missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return {"ok":false,"reason":"checkpoint_unreadable"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok":false,"reason":"invalid_checkpoint_json"}
	var result := validate_payload(parsed)
	if result.ok:
		result["payload"] = parsed
	return result
static func save_checkpoint(payload: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
	if not _valid_path(path):
		return {"ok":false,"reason":"invalid_checkpoint_path"}
	var result := validate_payload(payload)
	if not result.ok:
		return result
	var content := JSON.stringify(payload, "\t", true)
	if content.to_utf8_buffer().size() > MAX_BYTES:
		return {"ok":false,"reason":"checkpoint_too_large"}
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		return {"ok":false,"reason":"checkpoint_directory_failed"}
	var temporary := absolute + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return {"ok":false,"reason":"checkpoint_write_failed"}
	file.store_string(content)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return {"ok":false,"reason":"checkpoint_write_failed"}
	# Godot rename replaces the existing file in the same directory atomically.
	if DirAccess.rename_absolute(temporary, absolute) != OK:
		return {"ok":false,"reason":"checkpoint_replace_failed"}
	return {"ok":true,"payload":payload.duplicate(true)}

static func _positive_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) > 0
