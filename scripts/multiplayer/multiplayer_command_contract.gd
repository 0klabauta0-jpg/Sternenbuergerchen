class_name MultiplayerCommandContract
extends RefCounted

const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const AD_HOC_ORDER_SCRIPT: GDScript = preload("res://scripts/command/ad_hoc_order.gd")

const ROLE_HOST: String = "host"
const ROLE_COMMANDER: String = "commander"
const ROLE_FIRETEAM: String = "fireteam"
const ROLE_SPECTATOR: String = "spectator"
const ALLOWED_ROLES: PackedStringArray = [
	ROLE_HOST,
	ROLE_COMMANDER,
	ROLE_FIRETEAM,
	ROLE_SPECTATOR,
]

const CATEGORY_UNIT_COMMAND: String = "unit_command"
const CATEGORY_COMMANDER_COMMAND: String = "commander_command"
const CATEGORY_AREA_ORDER: String = "area_order"
const CATEGORY_AD_HOC_ORDER: String = "ad_hoc_order"
const CATEGORY_DROPSHIP_COMMAND: String = "dropship_command"
const CATEGORY_COMMANDER_INTENT: String = "commander_intent"
const CATEGORY_ROLE_OVERRIDE: String = "role_override"
const CATEGORY_BREAKOUT_RESPONSE: String = "breakout_response"
const CATEGORY_AIR_ASSET_COMMAND: String = "air_asset_command"
const CATEGORY_TACTICAL_RULE: String = "tactical_rule"

const ALLOWED_AREA_ORDER_TYPES: PackedStringArray = [
	"engage",
	"defend",
]
const ALLOWED_DROPSHIP_COMMAND_TYPES: PackedStringArray = [
	"set_lz",
	"clear_lz",
	"call_dropship",
	"set_dropship_approach",
	"return_dropship",
]
const ALLOWED_ROLE_OVERRIDE_COMMAND_TYPES: PackedStringArray = [
	"role_override",
	"set_peer_role",
	"set_peer_fireteams",
]
const ALLOWED_BREAKOUT_RESPONSE_TYPES: PackedStringArray = [
	"breakout_confirm",
	"breakout_abort",
	"breakout_regroup",
	"breakout_override",
]
const ALLOWED_AIR_ASSET_COMMAND_TYPES: PackedStringArray = [
	"air_asset_guard_lz",
	"air_asset_abort_approach",
	"air_asset_hold",
	"air_asset_request_status",
]
const ALLOWED_FIRE_RULES: PackedStringArray = [
	"hold",
	"return",
	"free",
	"suppress",
]
const FORBIDDEN_STATE_KEYS: PackedStringArray = [
	"effect_type",
	"damage",
	"health",
	"integrity",
	"vital_state",
	"bleedout_ticks",
	"position",
	"global_position",
	"objective",
	"objective_state",
	"capture_progress",
	"owning_team_id",
	"runtime_state",
	"runtime_status",
	"visible",
	"has_lz_position",
	"drop_ship_requested",
	"mission_drop_state",
	"mission_drop_progress",
	"mission_drop_cards",
	"committed_plan_state",
	"fireteam_plan_status",
	"breakout_state",
	"communication_events",
	"air_asset_status",
	"air_asset_state",
	"vfx_events",
	"sfx_events",
]
const FORBIDDEN_LZ_SOURCES: PackedStringArray = [
	"scenario",
	"mission_scenario",
	"editor",
	"map_editor",
]


static func is_allowed_role(role_id: String) -> bool:
	return ALLOWED_ROLES.has(role_id.strip_edges().to_lower())


func validate(command_dict: Dictionary, context: Dictionary = {}) -> Dictionary:
	if typeof(command_dict) != TYPE_DICTIONARY:
		return _reject("command_not_dictionary")

	var command: Dictionary = command_dict.duplicate(true)
	var forbidden_key: String = _find_forbidden_state_key(command)
	if not forbidden_key.is_empty():
		return _reject("state_mutation_key:%s" % forbidden_key)

	var category: String = _detect_category(command)
	if category.is_empty():
		return _reject("command_not_whitelisted")

	var validation: Dictionary = _validate_category_payload(category, command)
	if not bool(validation.get("accepted", false)):
		return validation

	var ownership: Dictionary = Dictionary(validation.get("ownership", {}))
	var rights_validation: Dictionary = _validate_peer_rights(ownership, context)
	if not bool(rights_validation.get("accepted", false)):
		return rights_validation

	return {
		"accepted": true,
		"reason": "",
		"category": category,
		"command_type": String(validation.get("command_type", "")),
		"team_id": String(ownership.get("team_id", "")),
		"unit_id": String(ownership.get("unit_id", "")),
		"fireteam_id": String(ownership.get("fireteam_id", "")),
		"command": command,
	}


func _validate_category_payload(category: String, command: Dictionary) -> Dictionary:
	match category:
		CATEGORY_UNIT_COMMAND:
			return _validate_unit_command(command)
		CATEGORY_COMMANDER_COMMAND:
			return _validate_commander_command(command)
		CATEGORY_AREA_ORDER:
			return _validate_area_order(command)
		CATEGORY_AD_HOC_ORDER:
			return _validate_ad_hoc_order(command)
		CATEGORY_DROPSHIP_COMMAND:
			return _validate_dropship_command(command)
		CATEGORY_COMMANDER_INTENT:
			return _validate_commander_intent(command)
		CATEGORY_ROLE_OVERRIDE:
			return _validate_role_override(command)
		CATEGORY_BREAKOUT_RESPONSE:
			return _validate_breakout_response(command)
		CATEGORY_AIR_ASSET_COMMAND:
			return _validate_air_asset_command(command)
		CATEGORY_TACTICAL_RULE:
			return _validate_tactical_rule(command)
		_:
			return _reject("command_not_whitelisted")


func _validate_unit_command(command: Dictionary) -> Dictionary:
	var unit_command = UNIT_COMMAND_SCRIPT.call("from_dict", command)
	if unit_command == null or not unit_command.has_method("is_valid") or not bool(unit_command.call("is_valid")):
		return _reject("invalid_unit_command")

	var command_type: String = String(command.get("command_type", "")).strip_edges().to_lower()
	var unit_id: String = String(command.get("unit_id", "")).strip_edges()
	var team_id: String = String(command.get("team_id", "")).strip_edges()
	if unit_id.is_empty() or team_id.is_empty():
		return _reject("unit_command_missing_unit_or_team")
	if command_type == UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION and not _has_vector2_or_vector3(command, "target_position"):
		return _reject("move_command_missing_target")
	if command_type == UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA and not (_has_vector2_or_vector3(command, "target_position") or not String(command.get("target_area_id", "")).strip_edges().is_empty()):
		return _reject("engage_area_missing_target")

	return _accept_payload(command_type, unit_id, team_id, String(command.get("fireteam_id", "")).strip_edges().to_lower())


func _validate_commander_command(command: Dictionary) -> Dictionary:
	var commander_command = COMMANDER_COMMAND_SCRIPT.call("from_dict", command)
	if commander_command == null or not commander_command.has_method("is_valid") or not bool(commander_command.call("is_valid")):
		return _reject("invalid_commander_command")

	var command_type: String = _extract_command_type(command)
	var unit_id: String = String(command.get("unit_id", "")).strip_edges()
	var team_id: String = String(command.get("team_id", "")).strip_edges()
	if unit_id.is_empty() or team_id.is_empty():
		return _reject("commander_command_missing_unit_or_team")
	if command_type != COMMANDER_COMMAND_SCRIPT.TYPE_ENGAGE and not _has_vector2_or_vector3(command, "target_position"):
		return _reject("commander_command_missing_target")

	return _accept_payload(command_type, unit_id, team_id, String(command.get("fireteam_id", "")).strip_edges().to_lower())


func _validate_area_order(command: Dictionary) -> Dictionary:
	var area_order = AREA_ORDER_SCRIPT.call("from_dict", command)
	if area_order == null or not area_order.has_method("is_valid") or not bool(area_order.call("is_valid")):
		return _reject("invalid_area_order")

	var command_type: String = String(command.get("command_type", "")).strip_edges().to_lower()
	if not ALLOWED_AREA_ORDER_TYPES.has(command_type):
		return _reject("area_order_not_whitelisted")

	return _accept_payload(
		command_type,
		String(command.get("unit_id", "")).strip_edges(),
		String(command.get("team_id", "")).strip_edges(),
		String(command.get("fireteam_id", "")).strip_edges().to_lower()
	)


func _validate_ad_hoc_order(command: Dictionary) -> Dictionary:
	var ad_hoc_order = AD_HOC_ORDER_SCRIPT.call("from_dict", command)
	if ad_hoc_order == null or not ad_hoc_order.has_method("is_valid") or not bool(ad_hoc_order.call("is_valid")):
		return _reject("invalid_ad_hoc_order")

	return _accept_payload(
		String(command.get("order_type", "")).strip_edges().to_lower(),
		String(command.get("unit_id", "")).strip_edges(),
		String(command.get("team_id", "")).strip_edges(),
		String(command.get("fireteam_id", "")).strip_edges().to_lower()
	)


func _validate_dropship_command(command: Dictionary) -> Dictionary:
	var command_type: String = _extract_command_type(command)
	if not ALLOWED_DROPSHIP_COMMAND_TYPES.has(command_type):
		return _reject("dropship_command_not_whitelisted")
	if _has_forbidden_lz_source(command):
		return _reject("lz_from_forbidden_source")

	var team_id: String = String(command.get("team_id", "")).strip_edges()
	var craft_id: String = String(command.get("craft_id", "")).strip_edges()
	var fireteam_id: String = String(command.get("fireteam_id", "")).strip_edges().to_lower()
	if team_id.is_empty():
		return _reject("dropship_command_missing_team")
	if craft_id.is_empty():
		return _reject("dropship_command_missing_craft")
	if fireteam_id.is_empty():
		return _reject("dropship_command_missing_fireteam")
	if command_type == "set_lz" and not (_has_vector2_or_vector3(command, "target_position") or _has_vector2_or_vector3(command, "lz_position")):
		return _reject("set_lz_missing_position")
	if command_type == "set_dropship_approach":
		var approach_angle: String = String(command.get("approach_angle", "")).strip_edges().to_upper()
		if approach_angle.is_empty():
			return _reject("dropship_approach_missing_angle")
		if not approach_angle in ["NW", "NE", "SW", "SE"]:
			return _reject("dropship_approach_invalid")

	return _accept_payload(command_type, String(command.get("unit_id", "")).strip_edges(), team_id, fireteam_id, {
		"craft_id": craft_id,
		"requires_fireteam_assignment": true,
		"requires_dropship_assignment": true,
	})


func _validate_commander_intent(command: Dictionary) -> Dictionary:
	var commander_intent = COMMANDER_INTENT_SCRIPT.call("from_dict", command)
	if commander_intent == null or not commander_intent.has_method("is_valid") or not bool(commander_intent.call("is_valid")):
		return _reject("invalid_commander_intent")

	var intent_dict: Dictionary = Dictionary(commander_intent.call("to_dict"))
	var team_id: String = String(intent_dict.get("team_id", command.get("team_id", ""))).strip_edges()
	if team_id.is_empty():
		return _reject("commander_intent_missing_team")
	var fireteam_id: String = String(intent_dict.get("fireteam_id", "")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		var fireteam_ids: PackedStringArray = PackedStringArray(intent_dict.get("coordinated_fireteam_ids", PackedStringArray()))
		if not fireteam_ids.is_empty():
			fireteam_id = String(fireteam_ids[0]).strip_edges().to_lower()
	return _accept_payload("commander_intent", "", team_id, fireteam_id)


func _validate_role_override(command: Dictionary) -> Dictionary:
	var command_type: String = _extract_command_type(command)
	if not ALLOWED_ROLE_OVERRIDE_COMMAND_TYPES.has(command_type):
		return _reject("role_override_not_whitelisted")
	var target_peer_id: int = int(command.get("target_peer_id", command.get("peer_id", 0)))
	if target_peer_id <= 0:
		return _reject("role_override_missing_peer")
	if command.has("role_id") and not is_allowed_role(String(command.get("role_id", "")).strip_edges().to_lower()):
		return _reject("role_override_unknown_role")
	return _accept_payload(command_type, "", String(command.get("team_id", "")).strip_edges(), String(command.get("fireteam_id", "")).strip_edges().to_lower(), {"requires_host": true})


func _validate_breakout_response(command: Dictionary) -> Dictionary:
	var command_type: String = _extract_command_type(command)
	if not ALLOWED_BREAKOUT_RESPONSE_TYPES.has(command_type):
		return _reject("breakout_response_not_whitelisted")
	var breakout_id: String = String(command.get("breakout_id", "")).strip_edges()
	var fireteam_id: String = String(command.get("fireteam_id", "")).strip_edges().to_lower()
	var team_id: String = String(command.get("team_id", "")).strip_edges()
	if breakout_id.is_empty():
		return _reject("breakout_response_missing_breakout_id")
	if fireteam_id.is_empty() or team_id.is_empty():
		return _reject("breakout_response_missing_owner")
	return _accept_payload(command_type, "", team_id, fireteam_id)


func _validate_air_asset_command(command: Dictionary) -> Dictionary:
	var command_type: String = _extract_command_type(command)
	if not ALLOWED_AIR_ASSET_COMMAND_TYPES.has(command_type):
		return _reject("air_asset_command_not_whitelisted")
	if _has_forbidden_lz_source(command):
		return _reject("lz_from_forbidden_source")
	var team_id: String = String(command.get("team_id", "")).strip_edges()
	if team_id.is_empty():
		return _reject("air_asset_command_missing_team")
	if command_type == "air_asset_guard_lz" and not (_has_vector2_or_vector3(command, "target_position") or _has_vector2_or_vector3(command, "lz_position")):
		return _reject("air_asset_guard_lz_missing_position")
	return _accept_payload(command_type, String(command.get("unit_id", "")).strip_edges(), team_id, String(command.get("fireteam_id", "")).strip_edges().to_lower())


func _validate_tactical_rule(command: Dictionary) -> Dictionary:
	var command_type: String = _extract_command_type(command)
	if command_type != "set_fire_rule":
		return _reject("tactical_rule_not_whitelisted")
	var team_id: String = String(command.get("team_id", "")).strip_edges()
	var fireteam_id: String = String(command.get("fireteam_id", "")).strip_edges().to_lower()
	var fire_rule: String = String(command.get("fire_rule", "")).strip_edges().to_lower()
	if team_id.is_empty() or fireteam_id.is_empty():
		return _reject("tactical_rule_missing_owner")
	if not ALLOWED_FIRE_RULES.has(fire_rule):
		return _reject("invalid_fire_rule")
	return _accept_payload(command_type, "", team_id, fireteam_id, {"requires_fireteam_assignment": true})


func _validate_peer_rights(ownership: Dictionary, context: Dictionary) -> Dictionary:
	var role_id: String = String(context.get("peer_role", ROLE_COMMANDER)).strip_edges().to_lower()
	if role_id.is_empty():
		role_id = ROLE_COMMANDER
	if not is_allowed_role(role_id):
		return _reject("peer_role_not_allowed")
	if role_id == ROLE_SPECTATOR:
		return _reject("spectator_cannot_command")
	if bool(ownership.get("requires_host", false)):
		return {"accepted": true} if role_id == ROLE_HOST else _reject("host_required")
	if role_id == ROLE_HOST:
		return {"accepted": true}

	var peer_team_id: String = String(context.get("peer_team_id", "")).strip_edges()
	var command_team_id: String = String(ownership.get("team_id", "")).strip_edges()
	var unit_team_id: String = String(context.get("unit_team_id", "")).strip_edges()
	if peer_team_id.is_empty():
		return _reject("peer_has_no_team")
	if not command_team_id.is_empty() and command_team_id != peer_team_id:
		return _reject("peer_team_mismatch")
	if not unit_team_id.is_empty() and unit_team_id != peer_team_id:
		return _reject("unit_team_mismatch")
	if bool(ownership.get("requires_fireteam_assignment", false)):
		var assigned_fireteam_ids: PackedStringArray = _normalize_string_array(context.get("peer_fireteam_ids", PackedStringArray()))
		var required_fireteam_id: String = String(ownership.get("fireteam_id", "")).strip_edges().to_lower()
		if required_fireteam_id.is_empty():
			return _reject("fireteam_role_missing_fireteam")
		if not assigned_fireteam_ids.has(required_fireteam_id):
			return _reject("fireteam_not_assigned_to_peer")
	if bool(ownership.get("requires_dropship_assignment", false)):
		var required_craft_id: String = String(ownership.get("craft_id", "")).strip_edges()
		var required_fireteam_id: String = String(ownership.get("fireteam_id", "")).strip_edges().to_lower()
		var craft_fireteam_ids: PackedStringArray = _normalize_string_array(context.get("craft_fireteam_ids", PackedStringArray()))
		if required_craft_id.is_empty() or not bool(context.get("craft_exists", false)):
			return _reject("dropship_craft_unknown")
		if required_fireteam_id.is_empty() or not craft_fireteam_ids.has(required_fireteam_id):
			return _reject("dropship_not_assigned_to_fireteam")
	if role_id == ROLE_COMMANDER:
		return {"accepted": true}

	var peer_fireteam_ids: PackedStringArray = _normalize_string_array(context.get("peer_fireteam_ids", PackedStringArray()))
	var command_fireteam_id: String = String(ownership.get("fireteam_id", "")).strip_edges().to_lower()
	var unit_fireteam_id: String = String(context.get("unit_fireteam_id", "")).strip_edges().to_lower()
	var resolved_fireteam_id: String = command_fireteam_id if not command_fireteam_id.is_empty() else unit_fireteam_id
	if role_id == ROLE_FIRETEAM:
		if resolved_fireteam_id.is_empty():
			return _reject("fireteam_role_missing_fireteam")
		if not peer_fireteam_ids.has(resolved_fireteam_id):
			return _reject("fireteam_not_assigned_to_peer")
		return {"accepted": true}

	return _reject("peer_role_not_allowed")


func _detect_category(command: Dictionary) -> String:
	var explicit_category: String = String(command.get("contract_category", command.get("payload_kind", ""))).strip_edges().to_lower()
	if explicit_category in [
		CATEGORY_UNIT_COMMAND,
		CATEGORY_COMMANDER_COMMAND,
		CATEGORY_AREA_ORDER,
		CATEGORY_AD_HOC_ORDER,
		CATEGORY_DROPSHIP_COMMAND,
		CATEGORY_COMMANDER_INTENT,
		CATEGORY_ROLE_OVERRIDE,
		CATEGORY_BREAKOUT_RESPONSE,
		CATEGORY_AIR_ASSET_COMMAND,
		CATEGORY_TACTICAL_RULE,
	]:
		return explicit_category
	if command.has("area_order_id") or command.has("world_polygon") or command.has("tile_positions"):
		return CATEGORY_AREA_ORDER
	if command.has("order_type"):
		return CATEGORY_AD_HOC_ORDER

	var command_type: String = _extract_command_type(command)
	if command.has("verb") and command.has("command_id"):
		return CATEGORY_COMMANDER_INTENT
	if ALLOWED_ROLE_OVERRIDE_COMMAND_TYPES.has(command_type):
		return CATEGORY_ROLE_OVERRIDE
	if ALLOWED_BREAKOUT_RESPONSE_TYPES.has(command_type):
		return CATEGORY_BREAKOUT_RESPONSE
	if ALLOWED_AIR_ASSET_COMMAND_TYPES.has(command_type):
		return CATEGORY_AIR_ASSET_COMMAND
	if UNIT_COMMAND_SCRIPT.ALLOWED_COMMAND_TYPES.has(command_type):
		return CATEGORY_UNIT_COMMAND
	if COMMANDER_COMMAND_SCRIPT.ALLOWED_COMMAND_TYPES.has(command_type):
		return CATEGORY_COMMANDER_COMMAND
	if ALLOWED_DROPSHIP_COMMAND_TYPES.has(command_type):
		return CATEGORY_DROPSHIP_COMMAND
	return ""


func _extract_command_type(command: Dictionary) -> String:
	if command.has("command_type"):
		return String(command.get("command_type", "")).strip_edges().to_lower()
	if command.has("type"):
		return String(command.get("type", "")).strip_edges().to_lower()
	return ""


func _find_forbidden_state_key(command: Dictionary) -> String:
	for key_variant in command.keys():
		var key: String = String(key_variant).strip_edges()
		if key == "target_position" or key == "lz_position":
			continue
		if FORBIDDEN_STATE_KEYS.has(key):
			return key
	return ""


func _has_forbidden_lz_source(command: Dictionary) -> bool:
	var source_context: String = String(command.get("source_context", command.get("source", ""))).strip_edges().to_lower()
	return FORBIDDEN_LZ_SOURCES.has(source_context)


func _has_vector2_or_vector3(command: Dictionary, key: String) -> bool:
	var value: Variant = command.get(key, null)
	var value_type: int = typeof(value)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR3


func _accept_payload(command_type: String, unit_id: String, team_id: String, fireteam_id: String, extra_ownership: Dictionary = {}) -> Dictionary:
	var ownership: Dictionary = {
		"unit_id": unit_id,
		"team_id": team_id,
		"fireteam_id": fireteam_id,
	}
	ownership.merge(extra_ownership, true)
	return {
		"accepted": true,
		"command_type": command_type,
		"ownership": ownership,
	}


func _reject(reason: String) -> Dictionary:
	return {
		"accepted": false,
		"reason": reason,
	}


func _normalize_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for item_variant in Array(value):
		var normalized: String = String(item_variant).strip_edges().to_lower()
		if normalized.is_empty() or result.has(normalized):
			continue
		result.append(normalized)
	return result
