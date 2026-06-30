class_name MissionInteractionVisualState
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_visual_state.v1"


static func build_snapshot(use_state_snapshot: Dictionary, objective_gate_snapshot: Dictionary = {}) -> Dictionary:
	var interactions: Array = Array(use_state_snapshot.get("interactions", []))
	var next_interaction_id: String = String(objective_gate_snapshot.get("next_interaction_id", "")).strip_edges()
	var entries: Array = []
	var tone_counts: Dictionary = {}
	var next_count: int = 0
	for index in range(interactions.size()):
		if typeof(interactions[index]) != TYPE_DICTIONARY:
			continue
		var interaction: Dictionary = Dictionary(interactions[index])
		var entry: Dictionary = _build_entry(interaction, next_interaction_id, entries.size())
		if entry.is_empty():
			continue
		var tone: String = String(entry.get("tone", "unknown")).strip_edges().to_lower()
		tone_counts[tone] = int(tone_counts.get(tone, 0)) + 1
		if bool(entry.get("is_next", false)):
			next_count += 1
		entries.append(entry)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"source_use_state_schema": String(use_state_snapshot.get("schema", "")).strip_edges(),
		"source_objective_gate_schema": String(objective_gate_snapshot.get("schema", "")).strip_edges(),
		"runtime_authority": "SimulationRoot via MissionInteractionRuntimeUseState",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"visual_state_count": entries.size(),
		"entries": entries,
		"tone_counts": tone_counts,
		"next_interaction_id": next_interaction_id,
		"next_visual_state_count": next_count,
		"summary": _build_summary(entries, next_interaction_id),
	}


static func _build_entry(interaction: Dictionary, next_interaction_id: String, index: int) -> Dictionary:
	if typeof(interaction.get("marker_position", null)) != TYPE_VECTOR2:
		return {}
	var interaction_id: String = String(interaction.get("interaction_id", "")).strip_edges()
	if interaction_id.is_empty():
		return {}
	var status: String = String(interaction.get("runtime_use_status", interaction.get("status", "unknown"))).strip_edges().to_lower()
	var progress: float = clampf(float(interaction.get("progress", 0.0)), 0.0, 1.0)
	var duration_seconds: float = maxf(float(interaction.get("duration_seconds", 0.0)), 0.0)
	var hold_seconds: float = maxf(float(interaction.get("hold_seconds", 0.0)), 0.0)
	var token: String = _build_token(interaction)
	var is_next: bool = not next_interaction_id.is_empty() and interaction_id == next_interaction_id
	var state_text: String = _build_state_text(status, progress, hold_seconds, duration_seconds)
	var short_label: String = "%s %s" % [token, state_text]
	if is_next and status != "complete":
		short_label = "NEXT %s" % short_label
	return {
		"id": "interaction_visual_%s" % interaction_id,
		"index": index,
		"interaction_id": interaction_id,
		"interaction_type": String(interaction.get("interaction_type", "")).strip_edges(),
		"step_id": String(interaction.get("step_id", "")).strip_edges(),
		"gate_id": String(interaction.get("gate_id", "")).strip_edges(),
		"marker_id": String(interaction.get("marker_id", "")).strip_edges(),
		"token": token,
		"status": status,
		"tone": _tone_for_status(status, is_next),
		"progress": progress,
		"hold_seconds": hold_seconds,
		"duration_seconds": duration_seconds,
		"world_position": Vector2(interaction.get("marker_position", Vector2.ZERO)),
		"short_label": short_label,
		"label": _build_detail_label(short_label, interaction),
		"is_next": is_next,
		"can_use_now": bool(interaction.get("can_use_now", false)),
		"blocked_by_step_id": String(interaction.get("blocked_by_step_id", "")).strip_edges(),
		"nearest_fireteam_id": String(interaction.get("nearest_fireteam_id", "")).strip_edges(),
		"distance_world": float(interaction.get("distance_world", -1.0)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _build_token(interaction: Dictionary) -> String:
	var haystack: String = "%s %s %s %s" % [
		String(interaction.get("interaction_type", "")),
		String(interaction.get("interaction_id", "")),
		String(interaction.get("objective_type", "")),
		String(interaction.get("display_name", "")),
	]
	haystack = haystack.strip_edges().to_lower()
	if haystack.contains("door") or haystack.contains("breach"):
		return "DOOR"
	if haystack.contains("computer") or haystack.contains("terminal") or haystack.contains("station"):
		return "COM"
	if haystack.contains("air") or haystack.contains("aa"):
		return "AA"
	if haystack.contains("cargo"):
		return "CARGO"
	return "INT"


static func _build_state_text(status: String, progress: float, hold_seconds: float, duration_seconds: float) -> String:
	match status:
		"complete":
			return "OK"
		"in_progress":
			if duration_seconds > 0.0:
				return "%d/%ds" % [roundi(hold_seconds), roundi(duration_seconds)]
			return "%d%%" % roundi(progress * 100.0)
		"usable":
			return "READY"
		"blocked":
			return "BLOCKED"
		"out_of_range":
			return "APPROACH"
		"interrupted":
			return "INTERRUPTED"
		_:
			return "?"


static func _build_detail_label(short_label: String, interaction: Dictionary) -> String:
	var reason: String = String(interaction.get("runtime_use_reason", "")).strip_edges()
	var required_order: String = String(interaction.get("required_order", "")).strip_edges().to_upper()
	if reason.is_empty() and required_order.is_empty():
		return short_label
	var details: PackedStringArray = PackedStringArray([short_label])
	if not required_order.is_empty():
		details.append(required_order)
	if not reason.is_empty():
		details.append(reason)
	return "\n".join(details)


static func _tone_for_status(status: String, is_next: bool) -> String:
	match status:
		"complete":
			return "complete"
		"in_progress":
			return "progress"
		"usable":
			return "ready" if is_next else "available"
		"blocked":
			return "blocked"
		"out_of_range":
			return "approach" if is_next else "muted"
		"interrupted":
			return "warning"
		_:
			return "unknown"


static func _build_summary(entries: Array, next_interaction_id: String) -> String:
	if entries.is_empty():
		return "Interaction visuals unavailable"
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if bool(entry.get("is_next", false)):
			return String(entry.get("short_label", "")).strip_edges()
	if not next_interaction_id.is_empty():
		return "NEXT %s not visible" % next_interaction_id
	return "%d interaction visuals" % entries.size()
