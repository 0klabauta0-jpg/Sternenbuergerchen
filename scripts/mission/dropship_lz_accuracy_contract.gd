class_name DropshipLZAccuracyContract
extends RefCounted

const MAX_V1_DEVIATION_RADIUS: float = 96.0
const MIN_V1_DEVIATION_RADIUS: float = 12.0


static func resolve_lz_command(requested_lz_position: Vector2, seed: String, pilot_skill: float = 0.5, team_skill: float = 0.5, server_authoritative: bool = true) -> Dictionary:
	var skill: float = clampf((pilot_skill * 0.72) + (team_skill * 0.28), 0.0, 1.0)
	var radius: float = lerpf(MAX_V1_DEVIATION_RADIUS, MIN_V1_DEVIATION_RADIUS, skill)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_to_int("%s:%.2f:%.2f:lz" % [seed.strip_edges(), pilot_skill, team_skill])
	var angle: float = rng.randf_range(0.0, TAU)
	var distance: float = rng.randf_range(0.0, radius)
	var offset := Vector2(cos(angle), sin(angle)) * distance
	var resolved_lz_position: Vector2 = requested_lz_position + offset
	return {
		"requested_lz_position": requested_lz_position,
		"target_lz_position": requested_lz_position,
		"resolved_lz_position": resolved_lz_position,
		"actual_landing_position": resolved_lz_position,
		"landing_deviation": distance,
		"lz_accuracy_radius": radius,
		"pilot_skill": clampf(pilot_skill, 0.0, 1.0),
		"team_skill": clampf(team_skill, 0.0, 1.0),
		"server_authoritative": server_authoritative,
		"multiplayer_authority": "server_resolved_lz",
	}


static func build_command_matrix_state(context: Dictionary) -> Dictionary:
	var has_lz: bool = bool(context.get("has_lz", context.get("has_lz_position", false)))
	var has_team: bool = bool(context.get("has_boarded_team", false))
	var has_pilot: bool = bool(context.get("has_pilot", false))
	var has_dropship: bool = bool(context.get("has_dropship", true))
	var disabled_reasons: PackedStringArray = PackedStringArray()
	if not has_lz:
		disabled_reasons.append("no_lz")
	if not has_pilot:
		disabled_reasons.append("no_pilot")
	if not has_team:
		disabled_reasons.append("no_team_boarded")
	if not has_dropship:
		disabled_reasons.append("no_dropship")
	return {
		"go_button_panel_role": "#16",
		"go_button_group": "command_matrix",
		"legacy_window_17_go_removed": true,
		"lz_pick_group": "target_selection_left",
		"approach_style_options": PackedStringArray(["vorsichtig", "normal", "aggressiv"]),
		"go_enabled": disabled_reasons.is_empty(),
		"disabled_reasons": disabled_reasons,
	}


static func build_arrival_feedback_state(context: Dictionary) -> Dictionary:
	var matrix: Dictionary = build_command_matrix_state(context)
	var phase: String = String(context.get("phase", "")).strip_edges().to_lower()
	if phase.is_empty():
		if not bool(matrix.get("go_enabled", false)):
			phase = "blocked"
		else:
			phase = "ready"
	var reason: String = ""
	var reasons: PackedStringArray = PackedStringArray(matrix.get("disabled_reasons", PackedStringArray()))
	if not reasons.is_empty():
		reason = String(reasons[0])
	return {
		"phase": phase,
		"visible_reason": reason,
		"command_matrix_feedback": matrix,
		"shows_requested_lz": bool(context.get("has_lz", context.get("has_lz_position", false))),
		"shows_resolved_lz": context.has("resolved_lz_position") or context.has("actual_landing_position"),
		"no_silent_failure": true,
		"status_chain": PackedStringArray(["no_lz", "no_pilot", "no_team_boarded", "ready", "go_accepted", "in_transit", "arriving", "landed", "blocked"]),
	}


static func _seed_to_int(value: String) -> int:
	var hash_value: int = 216613626
	for index in range(value.length()):
		hash_value = int((hash_value ^ value.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(hash_value, 1)
