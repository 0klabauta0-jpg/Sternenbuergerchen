class_name MultiFireteamPlanResolver
extends RefCounted

const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const FIRETEAM_EXECUTION_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_execution_plan.gd")
const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")

const ROLE_LEAD: String = "lead"
const ROLE_SUPPORT: String = "support"
const ROLE_SECURITY: String = "security"
const ROLE_RESERVE: String = "reserve"
const ROLE_RECON: String = "recon"

const STATUS_PREVIEW: String = "preview"
const STATUS_ACTIVE: String = "active"
const STATUS_BLOCKED_PATH: String = "blocked_path"
const STATUS_CONTACT_STABLE: String = "contact_stable"

const DEFAULT_MIN_SPACING: float = 96.0
const DEFAULT_SUPPORT_STANDOFF: float = 128.0

const ROLE_LABELS: Dictionary = {
	ROLE_LEAD: "LEAD",
	ROLE_SUPPORT: "SUP",
	ROLE_SECURITY: "SEC",
	ROLE_RESERVE: "RES",
	ROLE_RECON: "RCN",
}


static func resolve_area_plan(intent_variant: Variant, fireteam_contexts: Array, options: Dictionary = {}) -> Dictionary:
	var intent = _coerce_intent(intent_variant)
	if intent == null:
		return {}
	var intent_dict: Dictionary = Dictionary(intent.call("to_dict"))
	var contexts: Array = _normalize_contexts(fireteam_contexts)
	if contexts.size() < 2:
		return {}
	var target_position: Vector2 = _resolve_target_position(intent_dict, contexts, options)
	var min_spacing: float = maxf(float(options.get("min_spacing", DEFAULT_MIN_SPACING)), 32.0)
	var base_phase: int = maxi(int(options.get("phase", intent_dict.get("phase", 0))), 0)
	var plan_id: String = _build_plan_id(intent_dict, options)
	var roles: PackedStringArray = _build_role_sequence(String(intent_dict.get("verb", "")), contexts.size())
	var assignments: Array = []
	var used_fireteam_ids: Dictionary = {}
	for role in roles:
		var context_index: int = _pick_context_for_role(String(role), contexts, used_fireteam_ids, target_position)
		if context_index < 0:
			continue
		var context: Dictionary = Dictionary(contexts[context_index])
		used_fireteam_ids[String(context.get("fireteam_id", ""))] = true
		assignments.append(_build_assignment(plan_id, intent_dict, context, String(role), assignments.size(), base_phase, target_position, min_spacing, options))
	for context in contexts:
		var fireteam_id: String = String(Dictionary(context).get("fireteam_id", ""))
		if used_fireteam_ids.has(fireteam_id):
			continue
		assignments.append(_build_assignment(plan_id, intent_dict, Dictionary(context), ROLE_SECURITY, assignments.size(), base_phase, target_position, min_spacing, options))
	assignments = _enforce_assignment_spacing(assignments, target_position, min_spacing)
	var plan: Dictionary = {
		"plan_id": plan_id,
		"command_id": String(intent_dict.get("command_id", "")),
		"sync_group_id": String(intent_dict.get("sync_group_id", plan_id)),
		"target_area_id": String(intent_dict.get("target_area_id", "")),
		"target_position": target_position,
		"phase": base_phase,
		"status": _resolve_plan_status(assignments),
		"requires_player_confirmation": true,
		"confirmed": false,
		"minimum_spacing": min_spacing,
		"minimum_spacing_ok": _check_minimum_spacing(assignments, min_spacing),
		"role_assignments": assignments,
		"area_context": Dictionary(options.get("area_context", {})).duplicate(true),
		"uses_existing_runtime_paths": true,
		"runtime_authority": "SimulationRoot",
		"ui_sets_unit_truth": false,
		"warnings": _collect_plan_warnings(assignments),
	}
	return _refresh_plan_feedback(plan)


static func confirm_plan(plan: Dictionary) -> Dictionary:
	var confirmed_plan: Dictionary = plan.duplicate(true)
	confirmed_plan["confirmed"] = true
	confirmed_plan["requires_player_confirmation"] = false
	if String(confirmed_plan.get("status", STATUS_PREVIEW)) == STATUS_PREVIEW:
		confirmed_plan["status"] = STATUS_ACTIVE
	var assignments: Array = []
	for assignment_variant in Array(confirmed_plan.get("role_assignments", [])):
		var assignment: Dictionary = Dictionary(assignment_variant).duplicate(true)
		if String(assignment.get("status", "")) == "ready":
			assignment["status"] = STATUS_ACTIVE
		assignments.append(assignment)
	confirmed_plan["role_assignments"] = assignments
	return _refresh_plan_feedback(confirmed_plan)


static func swap_roles(plan: Dictionary, first_fireteam_id: String, second_fireteam_id: String) -> Dictionary:
	var swapped_plan: Dictionary = plan.duplicate(true)
	var assignments: Array = Array(swapped_plan.get("role_assignments", [])).duplicate(true)
	var first_index: int = _find_assignment_index(assignments, first_fireteam_id)
	var second_index: int = _find_assignment_index(assignments, second_fireteam_id)
	if first_index < 0 or second_index < 0:
		return swapped_plan
	var first_assignment: Dictionary = Dictionary(assignments[first_index]).duplicate(true)
	var second_assignment: Dictionary = Dictionary(assignments[second_index]).duplicate(true)
	var first_role: String = String(first_assignment.get("role", ""))
	first_assignment["role"] = String(second_assignment.get("role", ""))
	second_assignment["role"] = first_role
	_update_assignment_role_fields(first_assignment)
	_update_assignment_role_fields(second_assignment)
	assignments[first_index] = first_assignment
	assignments[second_index] = second_assignment
	swapped_plan["role_assignments"] = assignments
	return _refresh_plan_feedback(swapped_plan)


static func is_valid_plan(plan: Dictionary) -> bool:
	if String(plan.get("plan_id", "")).strip_edges().is_empty():
		return false
	var assignments: Array = Array(plan.get("role_assignments", []))
	if assignments.size() < 2:
		return false
	if bool(plan.get("ui_sets_unit_truth", true)):
		return false
	if String(plan.get("runtime_authority", "")) != "SimulationRoot":
		return false
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		if String(assignment.get("fireteam_id", "")).strip_edges().is_empty():
			return false
		if String(assignment.get("role", "")).strip_edges().is_empty():
			return false
		if typeof(assignment.get("planned_position", null)) != TYPE_VECTOR2:
			return false
	return true


static func _coerce_intent(intent_variant: Variant):
	if intent_variant == null:
		return null
	if intent_variant is RefCounted and intent_variant.has_method("to_dict") and intent_variant.has_method("is_valid"):
		return intent_variant
	if typeof(intent_variant) == TYPE_DICTIONARY:
		return COMMANDER_INTENT_SCRIPT.call("from_dict", Dictionary(intent_variant))
	return null


static func _normalize_contexts(raw_contexts: Array) -> Array:
	var contexts: Array = []
	for context_variant in raw_contexts:
		if typeof(context_variant) != TYPE_DICTIONARY:
			continue
		var context: Dictionary = Dictionary(context_variant)
		var fireteam_id: String = String(context.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var normalized_context: Dictionary = {
			"fireteam_id": fireteam_id,
			"team_id": String(context.get("team_id", fireteam_id)).strip_edges(),
			"display_label": String(context.get("display_label", fireteam_id.to_upper())).strip_edges().to_upper(),
			"position": _coerce_vector2(context.get("position", context.get("anchor_position", Vector2.ZERO)), Vector2.ZERO),
			"leadership": _read_score(context, "leadership", "leader_skill", 0.5),
			"discipline": _read_score(context, "discipline", "fire_discipline", 0.5),
			"cohesion": _read_score(context, "cohesion", "execution_cohesion", 0.5),
			"communication": _read_score(context, "communication", "communication_clarity", 0.5),
			"initiative": _read_score(context, "initiative", "speed", 0.5),
			"speed": _read_score(context, "speed", "mobility", 0.5),
			"accuracy": _read_score(context, "accuracy", "marksmanship", 0.5),
			"awareness": _read_score(context, "awareness", "recognition", 0.5),
			"stealth": _read_score(context, "stealth", "signature_control", 0.5),
			"readiness": _read_score(context, "readiness", "fit_ratio", 1.0),
			"weapon_range": _read_score(context, "weapon_range", "range", 0.5),
			"cover_quality": _read_score(context, "cover_quality", "cover", 0.5),
			"member_count": maxi(int(context.get("member_count", 0)), 0),
			"medic_count": maxi(int(context.get("medic_count", 0)), 0),
			"contact_pressure": _resolve_contact_pressure(context),
			"blocked_path": bool(context.get("blocked_path", context.get("path_blocked", false))) or String(context.get("path_status", "")).strip_edges().to_lower() == "blocked",
		}
		var ftl_snapshot: Dictionary = _resolve_ftl_skill_snapshot(context, normalized_context)
		normalized_context["ftl_skill_snapshot"] = ftl_snapshot
		_apply_ftl_snapshot_to_context(normalized_context, ftl_snapshot)
		contexts.append(normalized_context)
	contexts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("fireteam_id", "")) < String(b.get("fireteam_id", ""))
	)
	return contexts


static func _read_score(context: Dictionary, primary_key: String, fallback_key: String, default_value: float) -> float:
	return clampf(float(context.get(primary_key, context.get(fallback_key, default_value))), 0.0, 1.0)


static func _resolve_ftl_skill_snapshot(source_context: Dictionary, normalized_context: Dictionary) -> Dictionary:
	var explicit_snapshot: Dictionary = Dictionary(source_context.get("ftl_skill_snapshot", source_context.get("ftl_tactical_snapshot", {}))).duplicate(true)
	if not explicit_snapshot.is_empty():
		if String(explicit_snapshot.get("fireteam_id", "")).strip_edges().is_empty():
			explicit_snapshot["fireteam_id"] = String(normalized_context.get("fireteam_id", ""))
		if explicit_snapshot.has("plan_quality"):
			if String(explicit_snapshot.get("effect_text", "")).strip_edges().is_empty():
				explicit_snapshot["effect_text"] = String(FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_tactical_effect_text", explicit_snapshot))
			return explicit_snapshot
		return FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_leader_tactical_skill_snapshot", explicit_snapshot, normalized_context)
	var leader_profile: Dictionary = Dictionary(source_context.get("leader_profile", source_context.get("leader_data", {}))).duplicate(true)
	if not leader_profile.is_empty():
		if String(leader_profile.get("fireteam_id", "")).strip_edges().is_empty():
			leader_profile["fireteam_id"] = String(normalized_context.get("fireteam_id", ""))
		return FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_leader_tactical_skill_snapshot", leader_profile, normalized_context)
	var synthesized_leader: Dictionary = {
		"unit_id": String(source_context.get("leader_unit_id", "%s_ftl" % String(normalized_context.get("fireteam_id", "")))).strip_edges(),
		"fireteam_id": String(normalized_context.get("fireteam_id", "")),
		"skill_values": {
			"leadership": float(normalized_context.get("leadership", 0.5)),
			"discipline": float(normalized_context.get("discipline", 0.5)),
			"awareness": float(normalized_context.get("awareness", 0.5)),
			"recognition": float(normalized_context.get("awareness", 0.5)),
			"speed": float(normalized_context.get("speed", 0.5)),
		},
		"communication_values": {
			"speech_quality": float(normalized_context.get("communication", 0.5)),
		},
		"behavior_axes": {
			"initiative": float(normalized_context.get("initiative", 0.5)),
			"order_fidelity": float(normalized_context.get("discipline", 0.5)),
			"contact_stability": float(normalized_context.get("awareness", 0.5)),
		},
		"progression": {
			"morale": 0.50,
			"frustration": 0.0,
		},
	}
	return FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_leader_tactical_skill_snapshot", synthesized_leader, normalized_context)


static func _apply_ftl_snapshot_to_context(context: Dictionary, snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		context["plan_quality"] = _fallback_plan_quality(context)
		context["communication_clarity"] = float(context.get("communication", 0.5))
		context["breakout_judgement"] = _fallback_plan_quality(context)
		context["spacing_quality"] = float(context.get("cohesion", 0.5))
		return
	context["plan_quality"] = clampf(float(snapshot.get("plan_quality", _fallback_plan_quality(context))), 0.0, 1.0)
	context["communication_clarity"] = clampf(float(snapshot.get("communication_clarity", context.get("communication", 0.5))), 0.0, 1.0)
	context["breakout_judgement"] = clampf(float(snapshot.get("breakout_judgement", context.get("plan_quality", 0.5))), 0.0, 1.0)
	context["spacing_quality"] = clampf(float(snapshot.get("spacing_quality", context.get("cohesion", 0.5))), 0.0, 1.0)
	context["contact_report_quality"] = clampf(float(snapshot.get("contact_report_quality", context.get("communication", 0.5))), 0.0, 1.0)
	context["reaction_delay_seconds"] = clampf(float(snapshot.get("reaction_delay_seconds", 0.35)), 0.05, 0.85)
	context["tempo_modifier"] = clampf(float(snapshot.get("tempo_modifier", 1.0)), 0.86, 1.14)
	context["tactical_effect_text"] = String(snapshot.get("effect_text", "")).strip_edges()
	context["communication"] = clampf((float(context.get("communication", 0.5)) * 0.55) + (float(context.get("communication_clarity", 0.5)) * 0.45), 0.0, 1.0)
	context["cohesion"] = clampf((float(context.get("cohesion", 0.5)) * 0.68) + (float(context.get("spacing_quality", 0.5)) * 0.32), 0.0, 1.0)


static func _fallback_plan_quality(context: Dictionary) -> float:
	return clampf(
		(float(context.get("leadership", 0.5)) * 0.34)
		+ (float(context.get("discipline", 0.5)) * 0.20)
		+ (float(context.get("cohesion", 0.5)) * 0.18)
		+ (float(context.get("communication", 0.5)) * 0.14)
		+ (float(context.get("initiative", 0.5)) * 0.14),
		0.0,
		1.0
	)


static func _resolve_contact_pressure(context: Dictionary) -> float:
	if context.has("contact_pressure"):
		return clampf(float(context.get("contact_pressure", 0.0)), 0.0, 1.0)
	var contacts: Array = Array(context.get("contacts", []))
	if not contacts.is_empty():
		return clampf(float(contacts.size()) / 4.0, 0.0, 1.0)
	var contact_state: String = String(context.get("contact_state", "")).strip_edges().to_lower()
	match contact_state:
		"confirmed":
			return 1.0
		"spotted":
			return 0.75
		"suspected":
			return 0.45
		_:
			return 0.0


static func _resolve_target_position(intent: Dictionary, contexts: Array, options: Dictionary) -> Vector2:
	var area_context: Dictionary = Dictionary(options.get("area_context", {}))
	var area_center: Variant = area_context.get("center_position", null)
	if typeof(area_center) == TYPE_VECTOR2:
		return Vector2(area_center)
	var target = intent.get("target_position", null)
	if typeof(target) == TYPE_VECTOR2:
		return Vector2(target)
	if typeof(target) == TYPE_VECTOR2I:
		return Vector2(target)
	var sum: Vector2 = Vector2.ZERO
	for context_variant in contexts:
		sum += Vector2(Dictionary(context_variant).get("position", Vector2.ZERO))
	return sum / float(maxi(contexts.size(), 1))


static func _build_plan_id(intent: Dictionary, options: Dictionary) -> String:
	var explicit_plan_id: String = String(options.get("plan_id", "")).strip_edges()
	if not explicit_plan_id.is_empty():
		return explicit_plan_id
	var command_id: String = String(intent.get("command_id", "command")).strip_edges()
	var group_id: String = String(intent.get("sync_group_id", "")).strip_edges()
	if group_id.is_empty():
		group_id = "group"
	return "multi_%s_%s" % [_sanitize_token(group_id), _sanitize_token(command_id)]


static func _build_role_sequence(verb: String, fireteam_count: int) -> PackedStringArray:
	var normalized_verb: String = verb.strip_edges().to_lower()
	var roles: PackedStringArray = PackedStringArray()
	if normalized_verb == COMMANDER_INTENT_SCRIPT.VERB_RECON:
		roles.append(ROLE_RECON)
		roles.append(ROLE_SUPPORT)
		roles.append(ROLE_SECURITY)
		roles.append(ROLE_RESERVE)
	elif normalized_verb == COMMANDER_INTENT_SCRIPT.VERB_DEFEND or normalized_verb == COMMANDER_INTENT_SCRIPT.VERB_SECURE:
		roles.append(ROLE_SECURITY)
		roles.append(ROLE_SUPPORT)
		roles.append(ROLE_RESERVE)
		roles.append(ROLE_LEAD)
	else:
		roles.append(ROLE_LEAD)
		roles.append(ROLE_SUPPORT)
		roles.append(ROLE_RESERVE)
		roles.append(ROLE_SECURITY)
		roles.append(ROLE_RECON)
	while roles.size() > fireteam_count:
		roles.remove_at(roles.size() - 1)
	return roles


static func _pick_context_for_role(role: String, contexts: Array, used_fireteam_ids: Dictionary, target_position: Vector2) -> int:
	var best_index: int = -1
	var best_score: float = -INF
	for index in range(contexts.size()):
		var context: Dictionary = Dictionary(contexts[index])
		var fireteam_id: String = String(context.get("fireteam_id", ""))
		if used_fireteam_ids.has(fireteam_id):
			continue
		var score: float = _score_context_for_role(role, context, target_position)
		if score <= best_score and not (absf(score - best_score) <= 0.0001 and best_index >= 0 and fireteam_id < String(Dictionary(contexts[best_index]).get("fireteam_id", ""))):
			continue
		best_score = score
		best_index = index
	return best_index


static func _score_context_for_role(role: String, context: Dictionary, target_position: Vector2) -> float:
	var distance_score: float = 1.0 - clampf(Vector2(context.get("position", Vector2.ZERO)).distance_to(target_position) / 1200.0, 0.0, 1.0)
	var blocked_penalty: float = 0.35 if bool(context.get("blocked_path", false)) else 0.0
	match role:
		ROLE_LEAD:
			return (float(context.get("plan_quality", 0.5)) * 0.26) + (float(context.get("leadership", 0.5)) * 0.20) + (float(context.get("cohesion", 0.5)) * 0.16) + (float(context.get("speed", 0.5)) * 0.14) + (float(context.get("readiness", 1.0)) * 0.12) + (float(context.get("communication_clarity", 0.5)) * 0.06) + (distance_score * 0.06) - blocked_penalty
		ROLE_SUPPORT:
			return (float(context.get("weapon_range", 0.5)) * 0.27) + (float(context.get("accuracy", 0.5)) * 0.23) + (float(context.get("discipline", 0.5)) * 0.18) + (float(context.get("plan_quality", 0.5)) * 0.12) + (float(context.get("cover_quality", 0.5)) * 0.11) + (float(context.get("readiness", 1.0)) * 0.09)
		ROLE_SECURITY:
			return (float(context.get("awareness", 0.5)) * 0.26) + (float(context.get("discipline", 0.5)) * 0.20) + (float(context.get("breakout_judgement", 0.5)) * 0.18) + (float(context.get("contact_pressure", 0.0)) * 0.18) + (float(context.get("readiness", 1.0)) * 0.18)
		ROLE_RESERVE:
			return (clampf(float(context.get("medic_count", 0)) / 2.0, 0.0, 1.0) * 0.30) + (float(context.get("readiness", 1.0)) * 0.20) + (float(context.get("communication_clarity", 0.5)) * 0.18) + (float(context.get("breakout_judgement", 0.5)) * 0.10) + ((1.0 - float(context.get("contact_pressure", 0.0))) * 0.12) + ((1.0 - distance_score) * 0.10)
		ROLE_RECON:
			return (float(context.get("stealth", 0.5)) * 0.28) + (float(context.get("speed", 0.5)) * 0.22) + (float(context.get("awareness", 0.5)) * 0.20) + (float(context.get("contact_report_quality", 0.5)) * 0.12) + (distance_score * 0.18) - blocked_penalty
		_:
			return 0.0


static func _build_assignment(
	plan_id: String,
	intent: Dictionary,
	context: Dictionary,
	role: String,
	role_index: int,
	base_phase: int,
	target_position: Vector2,
	min_spacing: float,
	options: Dictionary
) -> Dictionary:
	var planned_position: Vector2 = target_position + _role_offset(role, role_index, min_spacing)
	var status: String = "ready"
	if bool(context.get("blocked_path", false)):
		status = STATUS_BLOCKED_PATH
	elif float(context.get("contact_pressure", 0.0)) >= 0.5:
		status = STATUS_CONTACT_STABLE
	var execution_plan = _build_execution_plan_for_assignment(plan_id, intent, context, role, base_phase, planned_position, options)
	var assignment: Dictionary = {
		"plan_id": plan_id,
		"fireteam_id": String(context.get("fireteam_id", "")),
		"team_id": String(context.get("team_id", "")),
		"display_label": String(context.get("display_label", "")),
		"role": role,
		"role_label": _role_label(role),
		"phase": base_phase,
		"plan_phase_index": _role_phase_index(role),
		"step_order": role_index,
		"next_step": _next_step_for_role(role, String(intent.get("verb", ""))),
		"planned_position": planned_position,
		"minimum_spacing": min_spacing,
		"status": status,
		"movement_style": _movement_style_for_role(role, String(intent.get("verb", ""))),
		"security_mode": _security_mode_for_role(role),
		"contact_pressure": float(context.get("contact_pressure", 0.0)),
		"blocked_path": bool(context.get("blocked_path", false)),
		"plan_quality": float(context.get("plan_quality", 0.5)),
		"communication_clarity": float(context.get("communication_clarity", 0.5)),
		"breakout_judgement": float(context.get("breakout_judgement", 0.5)),
		"spacing_quality": float(context.get("spacing_quality", 0.5)),
		"contact_report_quality": float(context.get("contact_report_quality", 0.5)),
		"tactical_effect_text": String(context.get("tactical_effect_text", "")),
		"ftl_public_snapshot": FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_public_leader_tactical_snapshot", Dictionary(context.get("ftl_skill_snapshot", {}))),
		"map_label_text": "",
		"execution_plan": Dictionary(execution_plan.call("to_snapshot")) if execution_plan != null and execution_plan.has_method("to_snapshot") else {},
	}
	_update_assignment_role_fields(assignment, String(intent.get("verb", "")))
	return assignment


static func _build_execution_plan_for_assignment(plan_id: String, intent: Dictionary, context: Dictionary, role: String, base_phase: int, planned_position: Vector2, options: Dictionary):
	var assignment_intent: Dictionary = intent.duplicate(true)
	assignment_intent["fireteam_id"] = String(context.get("fireteam_id", ""))
	assignment_intent["team_id"] = String(context.get("team_id", ""))
	assignment_intent["target_position"] = planned_position
	assignment_intent["phase"] = base_phase
	var metadata: Dictionary = Dictionary(assignment_intent.get("metadata", {})).duplicate(true)
	metadata["multi_fireteam_plan_id"] = plan_id
	metadata["coordination_role"] = role
	assignment_intent["metadata"] = metadata
	var ftl_snapshot: Dictionary = Dictionary(context.get("ftl_skill_snapshot", {}))
	var ftl_skill: Dictionary = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_skill_factors_from_snapshot", ftl_snapshot) if not ftl_snapshot.is_empty() else {
		"leadership": float(context.get("leadership", 0.5)),
		"discipline": float(context.get("discipline", 0.5)),
		"cohesion": float(context.get("cohesion", 0.5)),
		"communication": float(context.get("communication", 0.5)),
		"initiative": float(context.get("initiative", 0.5)),
	}
	var overrides: Dictionary = {
		"coordination_plan_id": plan_id,
		"coordination_role": role,
		"movement_style": _movement_style_for_role(role, String(intent.get("verb", ""))),
		"security_mode": _security_mode_for_role(role),
		"target_position": planned_position,
		"metadata": {
			"multi_fireteam_plan_id": plan_id,
			"coordination_role": role,
			"uses_existing_runtime_paths": true,
			"ftl_effect_label": String(ftl_snapshot.get("effect_label", "")),
		},
	}
	return FIRETEAM_EXECUTION_PLAN_SCRIPT.call("from_intent", COMMANDER_INTENT_SCRIPT.call("from_dict", assignment_intent), ftl_skill, overrides)


static func _role_offset(role: String, role_index: int, min_spacing: float) -> Vector2:
	match role:
		ROLE_LEAD:
			return Vector2.ZERO
		ROLE_SUPPORT:
			return Vector2(-DEFAULT_SUPPORT_STANDOFF, -min_spacing * 0.65)
		ROLE_SECURITY:
			return Vector2(DEFAULT_SUPPORT_STANDOFF, -min_spacing * 0.65)
		ROLE_RESERVE:
			return Vector2(0.0, min_spacing * 1.25)
		ROLE_RECON:
			return Vector2(0.0, -min_spacing * 1.55)
		_:
			var angle: float = TAU * float(role_index) / 5.0
			return Vector2.RIGHT.rotated(angle) * min_spacing


static func _enforce_assignment_spacing(assignments: Array, target_position: Vector2, min_spacing: float) -> Array:
	var result: Array = []
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant).duplicate(true)
		var planned_position: Vector2 = Vector2(assignment.get("planned_position", target_position))
		for previous_variant in result:
			var previous: Dictionary = Dictionary(previous_variant)
			var previous_position: Vector2 = Vector2(previous.get("planned_position", target_position))
			if planned_position.distance_to(previous_position) >= min_spacing:
				continue
			var away: Vector2 = planned_position - previous_position
			if away.length() < 0.001:
				away = Vector2.RIGHT.rotated(float(result.size()) * 1.7)
			planned_position = previous_position + away.normalized() * min_spacing
		assignment["planned_position"] = planned_position
		var execution_plan: Dictionary = Dictionary(assignment.get("execution_plan", {})).duplicate(true)
		if not execution_plan.is_empty():
			execution_plan["target_position"] = planned_position
			assignment["execution_plan"] = execution_plan
		result.append(assignment)
	return result


static func _check_minimum_spacing(assignments: Array, min_spacing: float) -> bool:
	for left_index in range(assignments.size()):
		var left_position: Vector2 = Vector2(Dictionary(assignments[left_index]).get("planned_position", Vector2.ZERO))
		for right_index in range(left_index + 1, assignments.size()):
			var right_position: Vector2 = Vector2(Dictionary(assignments[right_index]).get("planned_position", Vector2.ZERO))
			if left_position.distance_to(right_position) < min_spacing - 0.001:
				return false
	return true


static func _resolve_plan_status(assignments: Array) -> String:
	var has_blocked: bool = false
	var has_contact: bool = false
	for assignment_variant in assignments:
		var status: String = String(Dictionary(assignment_variant).get("status", ""))
		has_blocked = has_blocked or status == STATUS_BLOCKED_PATH
		has_contact = has_contact or status == STATUS_CONTACT_STABLE
	if has_blocked:
		return STATUS_BLOCKED_PATH
	if has_contact:
		return STATUS_CONTACT_STABLE
	return STATUS_PREVIEW


static func _collect_plan_warnings(assignments: Array) -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var fireteam_id: String = String(assignment.get("fireteam_id", ""))
		if bool(assignment.get("blocked_path", false)):
			warnings.append("blocked_path:%s" % fireteam_id)
		if float(assignment.get("contact_pressure", 0.0)) >= 0.5:
			warnings.append("contact_stable:%s" % fireteam_id)
	return warnings


static func _refresh_plan_feedback(plan: Dictionary) -> Dictionary:
	var refreshed: Dictionary = plan.duplicate(true)
	var assignments: Array = Array(refreshed.get("role_assignments", []))
	refreshed["selected_fireteam_lines"] = _build_selected_fireteam_lines(assignments)
	refreshed["mission_control_text"] = _build_mission_control_text(refreshed, assignments)
	refreshed["map_role_labels"] = _build_map_role_labels(assignments)
	refreshed["feedback_events"] = _build_feedback_events(refreshed, assignments)
	refreshed["minimum_spacing_ok"] = _check_minimum_spacing(assignments, float(refreshed.get("minimum_spacing", DEFAULT_MIN_SPACING)))
	return refreshed


static func _build_selected_fireteam_lines(assignments: Array) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		lines.append("%s %s P%d | Q%d | %s | %s" % [
			String(assignment.get("display_label", assignment.get("fireteam_id", ""))).to_upper(),
			String(assignment.get("role_label", "")).to_upper(),
			int(assignment.get("plan_phase_index", 0)),
			int(round(float(assignment.get("plan_quality", 0.5)) * 100.0)),
			String(assignment.get("next_step", "")),
			String(assignment.get("status", "")),
		])
	return lines


static func _build_mission_control_text(plan: Dictionary, assignments: Array) -> String:
	var role_parts: PackedStringArray = PackedStringArray()
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		role_parts.append("%s=%s" % [
			String(assignment.get("role_label", "")),
			String(assignment.get("display_label", assignment.get("fireteam_id", ""))).to_upper(),
		])
	return "PLAN %s P%d | %s | %s" % [
		String(plan.get("status", STATUS_PREVIEW)).to_upper(),
		int(plan.get("phase", 0)),
		" ".join(role_parts),
		"CONFIRMED" if bool(plan.get("confirmed", false)) else "PRE-GO",
	]


static func _build_map_role_labels(assignments: Array) -> Array:
	var labels: Array = []
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		labels.append({
			"fireteam_id": String(assignment.get("fireteam_id", "")),
			"role": String(assignment.get("role", "")),
			"role_label": String(assignment.get("role_label", "")),
			"map_label_text": String(assignment.get("map_label_text", "")),
			"planned_position": assignment.get("planned_position", Vector2.ZERO),
			"status": String(assignment.get("status", "")),
		})
	return labels


static func _build_feedback_events(plan: Dictionary, assignments: Array) -> Array:
	var events: Array = []
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		events.append({
			"plan_id": String(plan.get("plan_id", "")),
			"fireteam_id": String(assignment.get("fireteam_id", "")),
			"feedback_action": "coordination_plan",
			"feedback_state": String(assignment.get("status", "")),
			"detail": "%s %s" % [String(assignment.get("role_label", "")), String(assignment.get("next_step", ""))],
		})
	return events


static func _update_assignment_role_fields(assignment: Dictionary, verb: String = "") -> void:
	var role: String = String(assignment.get("role", "")).strip_edges().to_lower()
	assignment["role_label"] = _role_label(role)
	assignment["plan_phase_index"] = _role_phase_index(role)
	assignment["next_step"] = _next_step_for_role(role, verb)
	assignment["movement_style"] = _movement_style_for_role(role, verb)
	assignment["security_mode"] = _security_mode_for_role(role)
	assignment["map_label_text"] = "%s P%d" % [_role_label(role), int(assignment.get("plan_phase_index", 0))]
	var execution_plan: Dictionary = Dictionary(assignment.get("execution_plan", {})).duplicate(true)
	if not execution_plan.is_empty():
		execution_plan["coordination_role"] = role
		execution_plan["coordination_plan_id"] = String(assignment.get("plan_id", ""))
		execution_plan["movement_style"] = assignment["movement_style"]
		execution_plan["security_mode"] = assignment["security_mode"]
		assignment["execution_plan"] = execution_plan


static func _role_label(role: String) -> String:
	return String(ROLE_LABELS.get(role, role.substr(0, mini(role.length(), 3)).to_upper()))


static func _role_phase_index(role: String) -> int:
	match role:
		ROLE_SUPPORT, ROLE_SECURITY, ROLE_RECON:
			return 0
		ROLE_LEAD:
			return 1
		ROLE_RESERVE:
			return 2
		_:
			return 1


static func _next_step_for_role(role: String, verb: String) -> String:
	match role:
		ROLE_SUPPORT:
			return "cover_lead"
		ROLE_SECURITY:
			return "watch_sector"
		ROLE_RESERVE:
			return "hold_recover"
		ROLE_RECON:
			return "probe_area"
		_:
			var normalized_verb: String = verb.strip_edges().to_lower()
			if normalized_verb == COMMANDER_INTENT_SCRIPT.VERB_TAKE:
				return "take_area"
			if normalized_verb == COMMANDER_INTENT_SCRIPT.VERB_ENGAGE:
				return "engage_area"
			return "move_to_area"


static func _movement_style_for_role(role: String, verb: String) -> String:
	match role:
		ROLE_SUPPORT, ROLE_SECURITY, ROLE_RESERVE:
			return FIRETEAM_EXECUTION_PLAN_SCRIPT.MOVEMENT_STYLE_HOLD
		ROLE_RECON:
			return FIRETEAM_EXECUTION_PLAN_SCRIPT.MOVEMENT_STYLE_PROBE
		_:
			return FIRETEAM_EXECUTION_PLAN_SCRIPT.MOVEMENT_STYLE_BOUNDING if verb.strip_edges().to_lower() != COMMANDER_INTENT_SCRIPT.VERB_MOVE else FIRETEAM_EXECUTION_PLAN_SCRIPT.MOVEMENT_STYLE_RUSH


static func _security_mode_for_role(role: String) -> String:
	match role:
		ROLE_SUPPORT, ROLE_SECURITY:
			return FIRETEAM_EXECUTION_PLAN_SCRIPT.SECURITY_SECTOR
		ROLE_RESERVE:
			return FIRETEAM_EXECUTION_PLAN_SCRIPT.SECURITY_ALL_ROUND
		ROLE_RECON:
			return FIRETEAM_EXECUTION_PLAN_SCRIPT.SECURITY_FACING
		_:
			return FIRETEAM_EXECUTION_PLAN_SCRIPT.SECURITY_FACING


static func _find_assignment_index(assignments: Array, fireteam_id: String) -> int:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	for index in range(assignments.size()):
		if String(Dictionary(assignments[index]).get("fireteam_id", "")).strip_edges().to_lower() == normalized_fireteam_id:
			return index
	return -1


static func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return Vector2(value)
	if typeof(value) == TYPE_VECTOR2I:
		return Vector2(value)
	if typeof(value) == TYPE_DICTIONARY:
		var data: Dictionary = Dictionary(value)
		return Vector2(float(data.get("x", fallback.x)), float(data.get("y", fallback.y)))
	return fallback


static func _sanitize_token(value: String) -> String:
	var result: String = value.strip_edges().to_lower()
	for token in [" ", "/", "\\", ":", ".", "-"]:
		result = result.replace(token, "_")
	while result.contains("__"):
		result = result.replace("__", "_")
	return "none" if result.is_empty() else result
