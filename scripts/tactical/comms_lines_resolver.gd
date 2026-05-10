class_name CommsLinesResolver
extends RefCounted

const CATALOG_PATH: String = "res://data/comms_lines.json"
const TEXT_SOURCE_ID: String = "comms_lines"

const TRIGGER_ENEMY_CONTACT: String = "enemy_contact"
const TRIGGER_SUPPRESSION_START: String = "suppression_start"
const TRIGGER_ORDER_CONFIRMED: String = "order_confirmed"
const TRIGGER_WAYPOINT_REACHED: String = "waypoint_reached"
const TRIGGER_FLANKING_INITIATED: String = "flanking_initiated"
const TRIGGER_OBJECTIVE_CAPTURED: String = "objective_captured"
const TRIGGER_RETURNING_TO_PLAN: String = "returning_to_plan"


static func resolve_feedback_text_payload(feedback_action: String, feedback_state: String, leader = null, context: Dictionary = {}) -> Dictionary:
	var catalog: Dictionary = load_catalog()
	if catalog.is_empty():
		return {"ok": false, "diagnostic": "missing_comms_lines_catalog:%s" % CATALOG_PATH}
	var line_context: Dictionary = _build_line_context(feedback_action, feedback_state, leader, context)
	var trigger: String = _resolve_trigger(feedback_action, feedback_state, line_context)
	var quality_level: int = _resolve_quality_level(leader, line_context)
	var selection: Dictionary = _select_line_variant(catalog, trigger, quality_level, line_context)
	if selection.is_empty():
		return {
			"ok": false,
			"diagnostic": "no_matching_comms_line:%s:q%d" % [trigger, quality_level],
			"text_source": TEXT_SOURCE_ID,
			"trigger": trigger,
			"quality_level": quality_level,
		}
	var entry: Dictionary = Dictionary(selection.get("entry", {}))
	var variant: Dictionary = Dictionary(selection.get("variant", {}))
	var text: String = _format_text(str(variant.get("text", "")), line_context).strip_edges()
	if text.is_empty():
		return {"ok": false, "diagnostic": "empty_matching_comms_line:%s:q%d" % [trigger, quality_level]}
	return {
		"ok": true,
		"text": text,
		"text_source": TEXT_SOURCE_ID,
		"text_key": "comms_lines.%s.q%d.%d" % [trigger, int(entry.get("quality_level", quality_level)), int(selection.get("variant_index", 0))],
		"trigger": trigger,
		"quality_level": int(entry.get("quality_level", quality_level)),
		"requested_quality_level": quality_level,
		"delay_seconds": float(entry.get("delay_seconds", 0.0)),
		"icon": str(entry.get("icon", "")) if entry.get("icon", null) != null else "",
		"trait_override": str(selection.get("trait_override", "")),
	}


static func load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


static func validate_catalog(catalog: Dictionary = {}) -> PackedStringArray:
	var source: Dictionary = catalog if not catalog.is_empty() else load_catalog()
	var issues: PackedStringArray = PackedStringArray()
	if source.is_empty():
		issues.append("missing_or_invalid_comms_lines_catalog")
		return issues
	if not source.has("lines"):
		issues.append("missing_lines")
	var seen_triggers: Dictionary = {}
	for line_variant in Array(source.get("lines", [])):
		if typeof(line_variant) != TYPE_DICTIONARY:
			issues.append("line_not_dictionary")
			continue
		var line: Dictionary = Dictionary(line_variant)
		var trigger: String = String(line.get("trigger", "")).strip_edges()
		if trigger.is_empty():
			issues.append("line_missing_trigger")
		else:
			seen_triggers[trigger] = true
		if int(line.get("quality_level", -1)) < 0 or int(line.get("quality_level", -1)) > 3:
			issues.append("line_invalid_quality:%s" % trigger)
		if Array(line.get("variants", [])).is_empty():
			issues.append("line_missing_variants:%s" % trigger)
		for variant_value in Array(line.get("variants", [])):
			if typeof(variant_value) != TYPE_DICTIONARY:
				issues.append("variant_not_dictionary:%s" % trigger)
				continue
			if String(Dictionary(variant_value).get("text", "")).strip_edges().is_empty():
				issues.append("variant_empty_text:%s" % trigger)
	for required_trigger in [TRIGGER_ENEMY_CONTACT, TRIGGER_ORDER_CONFIRMED, TRIGGER_FLANKING_INITIATED, TRIGGER_OBJECTIVE_CAPTURED]:
		if not seen_triggers.has(required_trigger):
			issues.append("missing_required_trigger:%s" % required_trigger)
	return issues


static func _build_line_context(feedback_action: String, feedback_state: String, leader, context: Dictionary) -> Dictionary:
	var result: Dictionary = context.duplicate(true)
	var action: String = _normalize_action(feedback_action)
	var state: String = _normalize_state(feedback_state, action)
	result["active_command"] = String(result.get("active_command", action)).strip_edges().to_lower()
	result["feedback_action"] = action
	result["feedback_state"] = state
	var fireteam_id: String = String(result.get("fireteam_id", "")).strip_edges()
	if fireteam_id.is_empty() and leader != null and leader.has_method("get_fireteam_id"):
		fireteam_id = String(leader.call("get_fireteam_id")).strip_edges()
	result["fireteam_id"] = fireteam_id
	result["leader_name"] = String(result.get("leader_name", _resolve_display_name(leader, "Leader"))).strip_edges()
	if not result.has("member_name"):
		result["member_name"] = String(result.get("leader_name", "Member"))
	var traits: PackedStringArray = _resolve_trait_ids(leader, result)
	result["trait_ids"] = traits
	if not traits.is_empty():
		result["trait"] = String(traits[0])
	var character_context: Dictionary = Dictionary(result.get("character_gameplay_context", {}))
	if not character_context.is_empty():
		result["leadership"] = float(result.get("leadership", character_context.get("leadership", result.get("communication_clarity", 0.5))))
		result["communication"] = float(result.get("communication", character_context.get("communication", result.get("leadership", 0.5))))
	if state == "contact" and not result.has("detection_state"):
		result["detection_state"] = "confirmed"
	if state == "contact" and not result.has("enemy_count"):
		result["enemy_count"] = "few"
	if state == "contact" and not result.has("distance"):
		result["distance"] = "40"
	return result


static func _resolve_trigger(feedback_action: String, feedback_state: String, context: Dictionary) -> String:
	for key in ["comms_trigger", "communication_trigger", "trigger"]:
		var explicit: String = String(context.get(key, "")).strip_edges().to_lower()
		if not explicit.is_empty():
			return explicit
	var event_type: String = String(context.get("tactical_event_type", context.get("event_type", ""))).strip_edges().to_lower()
	match event_type:
		"contact_report":
			return TRIGGER_ENEMY_CONTACT
		"breakout_adaptation":
			return TRIGGER_FLANKING_INITIATED
		"cannot_execute", "needs_orders":
			return TRIGGER_SUPPRESSION_START
		"objective_complete":
			return TRIGGER_OBJECTIVE_CAPTURED
		"phase_completed":
			return TRIGGER_WAYPOINT_REACHED
		"phase_started", "plan_role_assigned", "order_received":
			return TRIGGER_ORDER_CONFIRMED
		"objective_progress":
			return TRIGGER_ORDER_CONFIRMED
		"air_asset_threatened", "air_asset_destroyed":
			return TRIGGER_ENEMY_CONTACT
	var action: String = _normalize_action(feedback_action)
	var state: String = _normalize_state(feedback_state, action)
	if state == "contact":
		return TRIGGER_ENEMY_CONTACT
	if state == "blocked":
		return TRIGGER_SUPPRESSION_START
	if action == "flank":
		return TRIGGER_FLANKING_INITIATED
	if action == "take" and state == "done":
		return TRIGGER_OBJECTIVE_CAPTURED
	if state == "done":
		return TRIGGER_WAYPOINT_REACHED
	if state == "running" and action == "go":
		return TRIGGER_RETURNING_TO_PLAN
	return TRIGGER_ORDER_CONFIRMED


static func _resolve_quality_level(leader, context: Dictionary) -> int:
	var score: float = _resolve_quality_score(leader, context)
	if score < 0.30:
		return 0
	if score < 0.60:
		return 1
	if score < 0.80:
		return 2
	return 3


static func _resolve_quality_score(leader, context: Dictionary) -> float:
	var score: float = -1.0
	for key in ["communication_quality", "communication_clarity", "communication", "leadership"]:
		if context.has(key):
			score = float(context.get(key, 0.5))
			break
	var character_context: Dictionary = Dictionary(context.get("character_gameplay_context", {}))
	if score < 0.0 and not character_context.is_empty():
		score = float(character_context.get("communication", character_context.get("leadership", 0.5)))
	if score < 0.0 and leader != null and leader.has_method("get_leadership_skill"):
		score = float(leader.call("get_leadership_skill"))
	if score < 0.0:
		var tier: String = String(context.get("skill_tier", "")).strip_edges().to_lower()
		match tier:
			"high":
				score = 0.84
			"low":
				score = 0.38
			_:
				score = 0.62
	for trait_id_variant in _resolve_trait_ids(leader, context):
		match String(trait_id_variant).strip_edges().to_lower():
			"calm":
				score += 0.20
			"steady":
				score += 0.10
			"cautious":
				score += 0.05
			"aggressive":
				score -= 0.10
			"reckless":
				score -= 0.30
	return clampf(score, 0.0, 1.0)


static func _select_line_variant(catalog: Dictionary, trigger: String, quality_level: int, context: Dictionary) -> Dictionary:
	for quality in _quality_search_order(quality_level):
		for entry_variant in Array(catalog.get("lines", [])):
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = Dictionary(entry_variant)
			if String(entry.get("trigger", "")).strip_edges().to_lower() != trigger:
				continue
			if int(entry.get("quality_level", -1)) != quality:
				continue
			var trait_selection: Dictionary = _select_trait_variant(entry, context)
			if not trait_selection.is_empty():
				trait_selection["entry"] = entry
				return trait_selection
			var variants: Array = Array(entry.get("variants", []))
			for index in range(variants.size()):
				var variant_value: Variant = variants[index]
				if typeof(variant_value) != TYPE_DICTIONARY:
					continue
				var variant: Dictionary = Dictionary(variant_value)
				if not _conditions_match(Dictionary(variant.get("conditions", {})), context):
					continue
				if not _has_required_placeholders(variant, context):
					continue
				return {
					"entry": entry,
					"variant": variant,
					"variant_index": index,
				}
	return {}


static func _select_trait_variant(entry: Dictionary, context: Dictionary) -> Dictionary:
	var trait_overrides: Dictionary = Dictionary(entry.get("trait_overrides", {}))
	if trait_overrides.is_empty():
		return {}
	var traits: PackedStringArray = PackedStringArray(context.get("trait_ids", PackedStringArray()))
	for trait_variant in traits:
		var trait_id: String = String(trait_variant).strip_edges().to_lower()
		if trait_id.is_empty() or not trait_overrides.has(trait_id):
			continue
		var override: Dictionary = Dictionary(trait_overrides.get(trait_id, {}))
		var variants: Array = Array(override.get("variants", []))
		for index in range(variants.size()):
			var variant_value: Variant = variants[index]
			if typeof(variant_value) != TYPE_DICTIONARY:
				continue
			var variant: Dictionary = Dictionary(variant_value)
			if not _conditions_match(Dictionary(variant.get("conditions", {})), context):
				continue
			if not _has_required_placeholders(variant, context):
				continue
				return {
					"variant": variant,
					"variant_index": index,
					"trait_override": trait_id,
				}
	return {}


static func _conditions_match(conditions: Dictionary, context: Dictionary) -> bool:
	for key_variant in conditions.keys():
		var key: String = String(key_variant).strip_edges()
		var expected: Variant = conditions.get(key_variant)
		if key == "trait":
			if not _expected_contains_any_trait(expected, PackedStringArray(context.get("trait_ids", PackedStringArray()))):
				return false
			continue
		var actual: Variant = context.get(key, null)
		if actual == null:
			return false
		if expected is Array or expected is PackedStringArray:
			if not _array_has_value(expected, actual):
				return false
		elif typeof(expected) == TYPE_BOOL:
			if bool(actual) != bool(expected):
				return false
		else:
			if String(actual).strip_edges().to_lower() != String(expected).strip_edges().to_lower():
				return false
	return true


static func _has_required_placeholders(variant: Dictionary, context: Dictionary) -> bool:
	var text: String = String(variant.get("text", ""))
	for placeholder in ["{direction}", "{distance}", "{enemy_count}", "{member_name}", "{leader_name}", "{new_leader_name}"]:
		if not text.contains(placeholder):
			continue
		if String(_replacement_for_placeholder(placeholder, context)).strip_edges().is_empty():
			return false
	return true


static func _format_text(template: String, context: Dictionary) -> String:
	var result: String = template
	for placeholder in ["{member_name}", "{fireteam_id}", "{direction}", "{distance}", "{enemy_count}", "{leader_name}", "{new_leader_name}"]:
		result = result.replace(placeholder, String(_replacement_for_placeholder(placeholder, context)))
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result.strip_edges()


static func _replacement_for_placeholder(placeholder: String, context: Dictionary) -> String:
	match placeholder:
		"{member_name}":
			return String(context.get("member_name", "")).strip_edges()
		"{fireteam_id}":
			var fireteam_id: String = String(context.get("fireteam_id", "")).strip_edges()
			return "FT" if fireteam_id.is_empty() else fireteam_id.to_upper()
		"{direction}":
			return String(context.get("direction_label", context.get("direction", ""))).strip_edges()
		"{distance}":
			return String(context.get("distance", "")).strip_edges()
		"{enemy_count}":
			return _enemy_count_display(context.get("enemy_count", ""))
		"{leader_name}":
			return String(context.get("leader_name", "")).strip_edges()
		"{new_leader_name}":
			return String(context.get("new_leader_name", "")).strip_edges()
		_:
			return ""


static func _quality_search_order(quality_level: int) -> PackedInt32Array:
	match clampi(quality_level, 0, 3):
		3:
			return PackedInt32Array([3, 2, 1, 0])
		2:
			return PackedInt32Array([2, 1, 0])
		1:
			return PackedInt32Array([1, 0])
		_:
			return PackedInt32Array([0])


static func _normalize_action(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"engage", "attack", "contact":
			return "engage"
		"defend", "cover", "hold":
			return "defend"
		"take", "objective", "capture":
			return "take"
		"go", "execute", "next":
			return "go"
		"heal", "support", "medbay":
			return "support"
		"flank":
			return "flank"
		"move":
			return "move"
		_:
			return "move" if normalized.is_empty() else normalized


static func _normalize_state(value: String, action: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"ok", "ack", "accepted", "accept":
			return "accepted"
		"invalid", "failed", "blocked", "reject", "rejected":
			return "blocked"
		"active", "running", "continue", "continuing":
			return "running"
		"done", "complete", "completed":
			return "done"
		"contact", "danger":
			return "contact"
		"cover", "covered":
			return "cover"
		_:
			if action == "engage":
				return "contact"
			if action == "defend":
				return "cover"
			if action == "take":
				return "running"
			return "accepted"


static func _resolve_display_name(subject, fallback: String) -> String:
	if subject != null and subject.has_method("get_display_name"):
		var display_name: String = String(subject.call("get_display_name")).strip_edges()
		if not display_name.is_empty():
			return display_name
	if subject != null and subject.has_method("get_unit_id"):
		var unit_id: String = String(subject.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			return unit_id
	return fallback


static func _resolve_trait_ids(subject, context: Dictionary) -> PackedStringArray:
	if context.has("trait_ids"):
		return _to_string_array(context.get("trait_ids", PackedStringArray()))
	if subject != null and subject.has_method("get_trait_ids"):
		return _to_string_array(subject.call("get_trait_ids"))
	return PackedStringArray()


static func _to_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var source: Array = []
	if value is PackedStringArray:
		source = Array(value)
	elif value is Array:
		source = Array(value)
	elif value is String:
		source = [String(value)]
	for item in source:
		var text: String = String(item).strip_edges().to_lower()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


static func _array_has_value(expected: Variant, actual: Variant) -> bool:
	var actual_text: String = String(actual).strip_edges().to_lower()
	for expected_value in Array(expected):
		if String(expected_value).strip_edges().to_lower() == actual_text:
			return true
	return false


static func _expected_contains_any_trait(expected: Variant, trait_ids: PackedStringArray) -> bool:
	for trait_id_variant in trait_ids:
		if _array_has_value(expected, String(trait_id_variant)):
			return true
	return false


static func _enemy_count_display(value: Variant) -> String:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return str(int(value))
	var normalized: String = String(value).strip_edges().to_lower()
	match normalized:
		"single":
			return "ein"
		"few":
			return "2-3"
		"many":
			return "mehrere"
		_:
			return normalized
