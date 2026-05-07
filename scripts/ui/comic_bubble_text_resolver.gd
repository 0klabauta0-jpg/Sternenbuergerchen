class_name ComicBubbleTextResolver
extends RefCounted

const COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_visual_contract.gd")
const CHARACTER_GAMEPLAY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/character_gameplay_resolver.gd")

const CATALOG_PATH: String = "res://data/comic_bubble_text_catalog.json"
const TEXT_SOURCE_ID: String = "comic_bubble_text_catalog"
const SKILL_TIER_HIGH: String = "high"
const SKILL_TIER_LOW: String = "low"
const SKILL_TIER_NEUTRAL: String = "neutral"
const DEFAULT_MAX_LINES: int = 2
const DEFAULT_MAX_CHARS_PER_LINE: int = 22
const DEFAULT_HIGH_SKILL_THRESHOLD: float = 0.65


static func load_catalog() -> Dictionary:
	var diagnostics: PackedStringArray = PackedStringArray()
	if not FileAccess.file_exists(CATALOG_PATH):
		return {"catalog": {}, "diagnostics": PackedStringArray(["missing_comic_bubble_text_catalog:%s" % CATALOG_PATH])}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {"catalog": {}, "diagnostics": PackedStringArray(["cannot_open_comic_bubble_text_catalog:%s" % CATALOG_PATH])}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"catalog": {}, "diagnostics": PackedStringArray(["invalid_comic_bubble_text_catalog_json:%s" % CATALOG_PATH])}
	var catalog: Dictionary = Dictionary(parsed).duplicate(true)
	for issue in validate_catalog(catalog):
		diagnostics.append(issue)
	return {"catalog": catalog, "diagnostics": diagnostics}


static func get_catalog_snapshot() -> Dictionary:
	var loaded: Dictionary = load_catalog()
	var catalog: Dictionary = Dictionary(loaded.get("catalog", {}))
	var rules: Dictionary = Dictionary(catalog.get("rules", {}))
	return {
		"catalog_path": CATALOG_PATH,
		"text_source": TEXT_SOURCE_ID,
		"catalog_version": int(catalog.get("catalog_version", 0)),
		"runtime_contract": String(rules.get("runtime_contract", "")),
		"text_lines_max": int(rules.get("text_lines_max", DEFAULT_MAX_LINES)),
		"text_chars_per_line_max": int(rules.get("text_chars_per_line_max", DEFAULT_MAX_CHARS_PER_LINE)),
		"selection": String(rules.get("selection", "")),
		"diagnostics": PackedStringArray(loaded.get("diagnostics", PackedStringArray())),
	}


static func validate_catalog(catalog: Dictionary = {}) -> PackedStringArray:
	var source_catalog: Dictionary = catalog
	if source_catalog.is_empty():
		source_catalog = Dictionary(load_catalog().get("catalog", {}))
	var issues: PackedStringArray = PackedStringArray()
	var rules: Dictionary = Dictionary(source_catalog.get("rules", {}))
	var max_lines: int = maxi(int(rules.get("text_lines_max", DEFAULT_MAX_LINES)), 1)
	var max_chars: int = maxi(int(rules.get("text_chars_per_line_max", DEFAULT_MAX_CHARS_PER_LINE)), 4)
	if String(rules.get("runtime_contract", "")).strip_edges() != "visual_only_no_gameplay_truth":
		issues.append("invalid_runtime_contract")
	if not source_catalog.has("ftl"):
		issues.append("missing_ftl_text_section")
	if not source_catalog.has("npc"):
		issues.append("missing_npc_text_section")
	_validate_text_tree(Dictionary(source_catalog.get("ftl", {})), "ftl", max_lines, max_chars, issues)
	_validate_text_tree(Dictionary(source_catalog.get("npc", {})), "npc", max_lines, max_chars, issues)
	return issues


static func resolve_ftl_text(feedback_action: String, feedback_state: String, subject = null, context: Dictionary = {}) -> String:
	return String(resolve_ftl_text_payload(feedback_action, feedback_state, subject, context).get("text", ""))


static func resolve_ftl_text_payload(feedback_action: String, feedback_state: String, subject = null, context: Dictionary = {}) -> Dictionary:
	var loaded: Dictionary = load_catalog()
	var catalog: Dictionary = Dictionary(loaded.get("catalog", {}))
	var rules: Dictionary = Dictionary(catalog.get("rules", {}))
	var action: String = normalize_action(feedback_action)
	var state: String = normalize_state(feedback_state, action)
	var character_context: Dictionary = Dictionary(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("resolve_ftl_context", subject, Array(context.get("fireteam_units", [])), context))
	var skill_tier: String = _coerce_skill_tier(String(context.get("skill_tier", "")))
	if skill_tier.is_empty():
		skill_tier = _coerce_skill_tier(String(character_context.get("skill_tier", "")))
	if skill_tier.is_empty():
		skill_tier = resolve_skill_tier(subject, {"channel": "ftl"})
	var ftl_catalog: Dictionary = Dictionary(catalog.get("ftl", {}))
	var state_catalog: Dictionary = Dictionary(ftl_catalog.get(state, {}))
	var action_catalog: Dictionary = _get_nested_dictionary(state_catalog, action)
	var selected_key: String = "ftl.%s.%s.%s" % [state, action, skill_tier]
	if action_catalog.is_empty():
		action_catalog = _get_nested_dictionary(state_catalog, "default")
		selected_key = "ftl.%s.default.%s" % [state, skill_tier]
	var text: String = _select_tier_text(action_catalog, skill_tier)
	if text.is_empty():
		var fallback_catalog: Dictionary = Dictionary(ftl_catalog.get("fallback", {}))
		text = _select_tier_text(fallback_catalog, skill_tier)
		selected_key = "ftl.fallback.%s" % skill_tier
	var payload: Dictionary = _build_text_payload(
		_sanitize_text(text, rules),
		skill_tier,
		selected_key,
		"ftl",
		PackedStringArray(loaded.get("diagnostics", PackedStringArray()))
	)
	payload.merge(_build_character_payload_metadata(character_context), true)
	return payload


static func resolve_npc_thought_text(unit, context: Dictionary = {}) -> String:
	return String(resolve_npc_thought_text_payload(unit, context).get("text", ""))


static func resolve_npc_thought_text_payload(unit, context: Dictionary = {}) -> Dictionary:
	var loaded: Dictionary = load_catalog()
	var catalog: Dictionary = Dictionary(loaded.get("catalog", {}))
	var rules: Dictionary = Dictionary(catalog.get("rules", {}))
	var role_key: String = resolve_role_key(unit, context)
	var situation: Dictionary = _resolve_npc_situation(unit, context, role_key)
	var character_context: Dictionary = Dictionary(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("resolve_thought_context", unit, context))
	var category: String = String(situation.get("category", "role"))
	var key: String = String(situation.get("key", "default"))
	var skill_tier: String = _coerce_skill_tier(String(context.get("skill_tier", "")))
	if skill_tier.is_empty():
		skill_tier = _coerce_skill_tier(String(character_context.get("skill_tier", "")))
	if skill_tier.is_empty():
		skill_tier = resolve_skill_tier(unit, {"channel": "npc", "role_key": role_key, "situation_key": key})
	var character_text: String = String(character_context.get("thought_text", "")).strip_edges()
	var character_thought_key: String = String(character_context.get("thought_key", "")).strip_edges()
	if category == "role" and not character_text.is_empty() and not character_thought_key.is_empty():
		var character_payload: Dictionary = _build_text_payload(
			_sanitize_text(character_text, rules),
			skill_tier,
			"character.%s" % character_thought_key,
			"character",
			PackedStringArray(loaded.get("diagnostics", PackedStringArray())),
			role_key,
			character_thought_key
		)
		character_payload["text_source"] = CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.SOURCE_ID
		character_payload.merge(_build_character_payload_metadata(character_context), true)
		return character_payload
	var npc_catalog: Dictionary = Dictionary(catalog.get("npc", {}))
	var category_catalog: Dictionary = Dictionary(npc_catalog.get(category, {}))
	var key_catalog: Dictionary = _get_nested_dictionary(category_catalog, key)
	var selected_key: String = "npc.%s.%s.%s" % [category, key, skill_tier]
	if key_catalog.is_empty() and category == "role":
		key_catalog = _get_nested_dictionary(category_catalog, "default")
		selected_key = "npc.role.default.%s" % skill_tier
	if key_catalog.is_empty():
		key_catalog = _get_nested_dictionary(Dictionary(Dictionary(npc_catalog.get("role", {})).get("default", {})), skill_tier)
	var text: String = _select_tier_text(key_catalog, skill_tier)
	if text.is_empty():
		var fallback_catalog: Dictionary = Dictionary(Dictionary(npc_catalog.get("role", {})).get("default", {}))
		text = _select_tier_text(fallback_catalog, skill_tier)
		selected_key = "npc.role.default.%s" % skill_tier
	var payload: Dictionary = _build_text_payload(
		_sanitize_text(text, rules),
		skill_tier,
		selected_key,
		category,
		PackedStringArray(loaded.get("diagnostics", PackedStringArray())),
		role_key,
		key
	)
	payload.merge(_build_character_payload_metadata(character_context), true)
	return payload


static func resolve_skill_tier(subject, context: Dictionary = {}) -> String:
	var explicit_tier: String = _coerce_skill_tier(String(context.get("skill_tier", "")))
	if not explicit_tier.is_empty():
		return explicit_tier
	if subject == null:
		return SKILL_TIER_NEUTRAL
	var loaded: Dictionary = load_catalog()
	var rules: Dictionary = Dictionary(Dictionary(loaded.get("catalog", {})).get("rules", {}))
	var threshold: float = float(rules.get("high_skill_threshold", DEFAULT_HIGH_SKILL_THRESHOLD))
	var role_key: String = String(context.get("role_key", "")).strip_edges().to_lower()
	var channel: String = String(context.get("channel", "")).strip_edges().to_lower()
	var scores: Array = []
	if channel == "ftl" or role_key == "leader":
		_append_score(scores, subject, "get_leadership_skill", ["skill_leadership"])
		_append_score(scores, subject, "get_discipline", ["discipline"])
		_append_score(scores, subject, "get_awareness", ["awareness"])
		_append_score(scores, subject, "", ["speech_quality"])
	elif role_key == "medic":
		_append_score(scores, subject, "get_toughness_skill", ["skill_toughness"])
		_append_score(scores, subject, "get_discipline", ["discipline"])
		_append_score(scores, subject, "get_awareness", ["awareness"])
	elif role_key == "pilot":
		_append_score(scores, subject, "", ["dropship_piloting", "freighter_piloting", "fighter_piloting"])
		_append_score(scores, subject, "get_discipline", ["discipline"])
	elif role_key == "engineer":
		_append_score(scores, subject, "get_discipline", ["discipline"])
		_append_score(scores, subject, "get_awareness", ["awareness"])
	elif role_key == "heavy":
		_append_score(scores, subject, "get_toughness_skill", ["skill_toughness"])
		_append_score(scores, subject, "get_accuracy_skill", ["skill_accuracy"])
	else:
		_append_score(scores, subject, "get_accuracy_skill", ["skill_accuracy"])
		_append_score(scores, subject, "get_awareness", ["awareness"])
		_append_score(scores, subject, "get_discipline", ["discipline"])
	if scores.is_empty():
		return SKILL_TIER_NEUTRAL
	var score: float = 0.0
	for value_variant in scores:
		score = maxf(score, float(value_variant))
	return SKILL_TIER_HIGH if score >= threshold else SKILL_TIER_LOW


static func resolve_role_key(unit, context: Dictionary = {}) -> String:
	var explicit_role: String = String(context.get("role_key", "")).strip_edges().to_lower()
	if not explicit_role.is_empty():
		return _normalize_role_key(explicit_role)
	if unit != null and bool(_get_property(unit, "is_fireteam_lead", false)):
		return "leader"
	var role_id: String = _get_string(unit, "get_role_id", String(context.get("role_id", ""))).strip_edges().to_lower()
	if unit != null and unit.has_method("has_medic_tool") and bool(unit.call("has_medic_tool")):
		return "medic"
	return _normalize_role_key(role_id)


static func normalize_action(feedback_action: String) -> String:
	var action: String = feedback_action.strip_edges().to_lower()
	match action:
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
			return "move" if action.is_empty() else action


static func normalize_state(feedback_state: String, action: String = "") -> String:
	var state: String = feedback_state.strip_edges().to_lower()
	match state:
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


static func _resolve_npc_situation(unit, context: Dictionary, role_key: String) -> Dictionary:
	var vital_state: String = _get_string(unit, "get_vital_state", "fit").strip_edges().to_lower()
	var health_ratio: float = _health_ratio(unit)
	if vital_state == "down" or vital_state == "bleedout":
		return {"category": "health", "key": "downed"}
	if vital_state == "respawning":
		return {"category": "health", "key": "respawning"}
	if vital_state != "fit" or health_ratio < 0.55:
		return {"category": "health", "key": "wounded"}
	if _has_current_command(unit):
		return {"category": "order", "key": "default"}
	return {"category": "role", "key": role_key if not role_key.is_empty() else "default"}


static func _build_text_payload(
	text: String,
	skill_tier: String,
	text_key: String,
	category: String,
	diagnostics: PackedStringArray,
	role_key: String = "",
	situation_key: String = ""
) -> Dictionary:
	return {
		"ok": not text.strip_edges().is_empty(),
		"text": text,
		"text_source": TEXT_SOURCE_ID,
		"text_key": text_key,
		"category": category,
		"role_key": role_key,
		"situation_key": situation_key,
		"skill_tier": skill_tier,
		"diagnostics": diagnostics,
	}


static func _sanitize_text(text: String, rules: Dictionary) -> String:
	var max_lines: int = maxi(int(rules.get("text_lines_max", DEFAULT_MAX_LINES)), 1)
	var max_chars: int = maxi(int(rules.get("text_chars_per_line_max", DEFAULT_MAX_CHARS_PER_LINE)), 4)
	return String(COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT.call("sanitize_text", text, max_lines, max_chars)).strip_edges()


static func _build_character_payload_metadata(character_context: Dictionary) -> Dictionary:
	if character_context.is_empty():
		return {}
	return {
		"character_gameplay_source": String(character_context.get("source", "")),
		"character_morale_state": String(character_context.get("morale_state", "")),
		"character_frustration_state": String(character_context.get("frustration_state", "")),
		"character_teamfit_label": String(character_context.get("teamfit_label", character_context.get("cohesion_label", ""))),
		"character_relationship_hint": String(character_context.get("relationship_hint", "")),
		"character_thought_key": String(character_context.get("thought_key", "")),
		"ftl_clarity_label": String(character_context.get("ftl_clarity_label", "")),
	}


static func _select_tier_text(texts: Dictionary, skill_tier: String) -> String:
	var normalized_tier: String = _coerce_skill_tier(skill_tier)
	if normalized_tier.is_empty():
		normalized_tier = SKILL_TIER_NEUTRAL
	if texts.has(normalized_tier):
		return String(texts.get(normalized_tier, "")).strip_edges()
	if texts.has(SKILL_TIER_NEUTRAL):
		return String(texts.get(SKILL_TIER_NEUTRAL, "")).strip_edges()
	if texts.has(SKILL_TIER_HIGH):
		return String(texts.get(SKILL_TIER_HIGH, "")).strip_edges()
	if texts.has(SKILL_TIER_LOW):
		return String(texts.get(SKILL_TIER_LOW, "")).strip_edges()
	return ""


static func _coerce_skill_tier(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	match normalized_value:
		SKILL_TIER_HIGH, SKILL_TIER_LOW, SKILL_TIER_NEUTRAL:
			return normalized_value
		_:
			return ""


static func _normalize_role_key(role_id: String) -> String:
	var normalized_role: String = role_id.strip_edges().to_lower()
	match normalized_role:
		"leader", "fireteam_lead", "ftl":
			return "leader"
		"medic", "combat_medic", "field_medic":
			return "medic"
		"pilot", "dropship_pilot", "freighter_pilot", "fighter_pilot":
			return "pilot"
		"engineer", "tech", "technician":
			return "engineer"
		"heavy", "support", "specialist", "gunner":
			return "heavy"
		"shooter", "rifleman", "security_guard", "scout", "marksman":
			return "shooter"
		_:
			return "default" if normalized_role.is_empty() else "default"


static func _append_score(scores: Array, subject, method_name: String, property_names: Array) -> void:
	var probe: Dictionary = _probe_float(subject, method_name, property_names)
	if bool(probe.get("found", false)):
		var value: float = clampf(float(probe.get("value", 0.0)), 0.0, 1.0)
		scores.append(value)


static func _probe_float(subject, method_name: String, property_names: Array) -> Dictionary:
	if subject == null:
		return {"found": false, "value": 0.0}
	if not method_name.is_empty() and subject.has_method(method_name):
		return {"found": true, "value": float(subject.call(method_name))}
	for property_name_variant in property_names:
		var property_name: String = String(property_name_variant)
		var value: Variant = _get_property(subject, property_name, null)
		if value == null:
			continue
		return {"found": true, "value": float(value)}
	return {"found": false, "value": 0.0}


static func _get_nested_dictionary(source: Dictionary, key: String) -> Dictionary:
	var normalized_key: String = key.strip_edges()
	if normalized_key.is_empty() or not source.has(normalized_key):
		return {}
	var value: Variant = source.get(normalized_key, {})
	return Dictionary(value) if typeof(value) == TYPE_DICTIONARY else {}


static func _get_property(subject, property_name: String, fallback: Variant) -> Variant:
	if subject == null or property_name.is_empty():
		return fallback
	if subject.has_method("get"):
		var value: Variant = subject.call("get", property_name)
		if value != null:
			return value
	return fallback


static func _get_string(unit, method_name: String, fallback: String) -> String:
	if unit != null and unit.has_method(method_name):
		return String(unit.call(method_name))
	return fallback


static func _health_ratio(unit) -> float:
	if unit == null or not unit.has_method("get_health") or not unit.has_method("get_max_health_points"):
		return 1.0
	var max_health: int = maxi(int(unit.call("get_max_health_points")), 1)
	return clampf(float(unit.call("get_health")) / float(max_health), 0.0, 1.0)


static func _has_current_command(unit) -> bool:
	if unit == null or not unit.has_method("get_current_unit_command"):
		return false
	return unit.call("get_current_unit_command") != null


static func _validate_text_tree(value: Variant, path: String, max_lines: int, max_chars: int, issues: PackedStringArray) -> void:
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary: Dictionary = Dictionary(value)
		for key_variant in dictionary.keys():
			var child_key: String = String(key_variant).strip_edges()
			_validate_text_tree(dictionary.get(key_variant), "%s.%s" % [path, child_key], max_lines, max_chars, issues)
		return
	if typeof(value) != TYPE_STRING:
		issues.append("non_string_text:%s" % path)
		return
	var text: String = String(value)
	if text.strip_edges().is_empty():
		issues.append("empty_text:%s" % path)
	var lines: PackedStringArray = text.split("\n", false)
	if lines.size() > max_lines:
		issues.append("text_too_many_lines:%s" % path)
	for line_variant in lines:
		var line: String = String(line_variant)
		if line.length() > max_chars:
			issues.append("text_line_too_long:%s" % path)
