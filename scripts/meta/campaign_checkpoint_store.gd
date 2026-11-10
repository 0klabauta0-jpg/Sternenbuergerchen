extends RefCounted
## One atomic home checkpoint, independent of the editable Skirmish profile.
const DEFAULT_PATH := "user://campaigns/introduction/checkpoint_v1.json"
const MAX_BYTES := 4 * 1024 * 1024
static func validate_payload(payload: Dictionary) -> Dictionary:
	if payload.get("schema_version") != 1 or typeof(payload.get("roster")) != TYPE_ARRAY or payload.roster.size() != 2 or typeof(payload.get("craft")) != TYPE_DICTIONARY:
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
		if typeof(base) != TYPE_DICTIONARY or base.get("version") != 1 or typeof(base.get("units")) != TYPE_DICTIONARY or base.units.size() != 2:
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
			if unit.status == "aboard" and String(unit.get("craft_id", "")) != String(payload.craft.get("definition", {}).get("craft_id", "")):
				return {"ok":false,"reason":"invalid_base_craft"}
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
	if payload.supply.fuel_by_craft_id.size() != 1 or not payload.supply.fuel_by_craft_id.has(craft.definition.craft_id):
		return {"ok":false,"reason":"checkpoint_craft_mismatch"}
	if payload.supply.reward_receipts.size() != payload.campaign.completion_receipts.size():
		return {"ok":false,"reason":"checkpoint_reward_mismatch"}
	for receipt_id in payload.supply.reward_receipts:
		if payload.campaign.completion_receipts.get(receipt_id) != payload.supply.reward_receipts[receipt_id]:
			return {"ok":false,"reason":"checkpoint_receipt_mismatch"}
	if int(payload.onboarding.stage_index) >= 2 and payload.campaign.completion_receipts.is_empty():
		return {"ok":false,"reason":"checkpoint_progress_mismatch"}
	if int(payload.onboarding.stage_index) == 3:
		var bought := false
		var refueled := false
		for request in payload.supply.requests.values():
			var result: Dictionary = request.result
			bought = bought or (result.get("operation") == "buy" and _positive_number(result.get("quantity")))
			refueled = refueled or (result.get("operation") == "refuel" and result.get("craft_id") == craft.definition.craft_id and _positive_number(result.get("amount")))
		if not bought or not refueled:
			return {"ok":false,"reason":"checkpoint_trade_receipts_missing"}
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
