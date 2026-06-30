class_name MissionInteractionObjectReaction
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_object_reaction.v1"


static func build_snapshot(visual_state_snapshot: Dictionary) -> Dictionary:
	var visual_entries: Array = Array(visual_state_snapshot.get("entries", []))
	var entries: Array = []
	var kind_counts: Dictionary = {}
	var state_counts: Dictionary = {}
	for visual_variant in visual_entries:
		if typeof(visual_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = _build_entry(Dictionary(visual_variant), entries.size())
		if entry.is_empty():
			continue
		var kind: String = String(entry.get("object_kind", "unknown")).strip_edges().to_lower()
		var reaction_state: String = String(entry.get("reaction_state", "unknown")).strip_edges().to_lower()
		kind_counts[kind] = int(kind_counts.get(kind, 0)) + 1
		state_counts[reaction_state] = int(state_counts.get(reaction_state, 0)) + 1
		entries.append(entry)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"source_visual_state_schema": String(visual_state_snapshot.get("schema", "")).strip_edges(),
		"runtime_authority": "SimulationRoot via MissionInteractionVisualState",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"object_reaction_count": entries.size(),
		"entries": entries,
		"kind_counts": kind_counts,
		"state_counts": state_counts,
		"summary": _build_summary(entries),
	}


static func _build_entry(visual_entry: Dictionary, index: int) -> Dictionary:
	if typeof(visual_entry.get("world_position", null)) != TYPE_VECTOR2:
		return {}
	var interaction_id: String = String(visual_entry.get("interaction_id", "")).strip_edges()
	if interaction_id.is_empty():
		return {}
	var object_kind: String = _resolve_object_kind(visual_entry)
	var status: String = String(visual_entry.get("status", "unknown")).strip_edges().to_lower()
	var reaction_state: String = _resolve_reaction_state(object_kind, status, bool(visual_entry.get("is_next", false)))
	var progress: float = clampf(float(visual_entry.get("progress", 0.0)), 0.0, 1.0)
	if status == "complete":
		progress = 1.0
	var accent: Color = _accent_color_for_reaction(object_kind, reaction_state)
	return {
		"id": "interaction_object_reaction_%s" % interaction_id,
		"index": index,
		"interaction_id": interaction_id,
		"interaction_type": String(visual_entry.get("interaction_type", "")).strip_edges(),
		"step_id": String(visual_entry.get("step_id", "")).strip_edges(),
		"marker_id": String(visual_entry.get("marker_id", "")).strip_edges(),
		"asset_hint": String(visual_entry.get("asset_hint", "")).strip_edges(),
		"display_name": String(visual_entry.get("display_name", "")).strip_edges(),
		"token": String(visual_entry.get("token", "")).strip_edges(),
		"object_kind": object_kind,
		"status": status,
		"reaction_state": reaction_state,
		"world_position": Vector2(visual_entry.get("world_position", Vector2.ZERO)),
		"progress": progress,
		"open_fraction": _open_fraction_for_reaction(object_kind, reaction_state, progress),
		"screen_active": object_kind == "computer" and ["active", "controlled", "ready"].has(reaction_state),
		"beacon_active": ["aa", "cargo"].has(object_kind) and reaction_state != "idle",
		"locked": reaction_state == "locked" or reaction_state == "blocked",
		"is_next": bool(visual_entry.get("is_next", false)),
		"accent_color": accent,
		"accent_color_hex": accent.to_html(false),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _resolve_object_kind(visual_entry: Dictionary) -> String:
	var haystack: String = "%s %s %s %s %s %s" % [
		String(visual_entry.get("token", "")),
		String(visual_entry.get("interaction_type", "")),
		String(visual_entry.get("interaction_id", "")),
		String(visual_entry.get("asset_hint", "")),
		String(visual_entry.get("display_name", "")),
		String(visual_entry.get("step_id", "")),
	]
	haystack = haystack.strip_edges().to_lower()
	if haystack.contains("door") or haystack.contains("breach"):
		return "door"
	if haystack.contains("computer") or haystack.contains("terminal") or haystack.contains("station") or haystack.contains("com"):
		return "computer"
	if haystack.contains("air") or haystack.contains("aa"):
		return "aa"
	if haystack.contains("cargo"):
		return "cargo"
	return "interaction"


static func _resolve_reaction_state(object_kind: String, status: String, is_next: bool) -> String:
	match status:
		"complete":
			match object_kind:
				"door":
					return "open"
				"computer":
					return "controlled"
				"aa":
					return "disabled"
				"cargo":
					return "departed"
				_:
					return "complete"
		"in_progress":
			return "active"
		"usable":
			return "ready" if is_next else "idle"
		"blocked":
			return "locked" if object_kind == "door" else "blocked"
		"out_of_range":
			return "ready" if is_next else "idle"
		"interrupted":
			return "warning"
		_:
			return "unknown"


static func _open_fraction_for_reaction(object_kind: String, reaction_state: String, progress: float) -> float:
	if object_kind != "door":
		return 0.0
	match reaction_state:
		"open":
			return 1.0
		"active":
			return clampf(maxf(progress, 0.35), 0.0, 1.0)
		"ready":
			return 0.12
		_:
			return 0.0


static func _accent_color_for_reaction(object_kind: String, reaction_state: String) -> Color:
	match reaction_state:
		"controlled", "disabled", "departed", "open", "complete":
			return Color(0.46, 0.96, 0.62, 1.0)
		"active":
			return Color(0.32, 0.78, 1.0, 1.0)
		"ready":
			return Color(0.94, 0.98, 1.0, 1.0)
		"blocked", "locked":
			return Color(1.0, 0.38, 0.30, 1.0)
		"warning":
			return Color(1.0, 0.68, 0.30, 1.0)
		_:
			match object_kind:
				"computer":
					return Color(0.46, 0.78, 1.0, 1.0)
				"aa":
					return Color(1.0, 0.48, 0.34, 1.0)
				"cargo":
					return Color(1.0, 0.82, 0.34, 1.0)
				"door":
					return Color(0.82, 0.86, 0.9, 1.0)
				_:
					return Color(0.86, 0.9, 0.94, 1.0)


static func _build_summary(entries: Array) -> String:
	if entries.is_empty():
		return "Interaction object reactions unavailable"
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if bool(entry.get("is_next", false)):
			return "NEXT %s %s" % [
				String(entry.get("object_kind", "interaction")).to_upper(),
				String(entry.get("reaction_state", "unknown")).to_upper(),
			]
	return "%d interaction object reactions" % entries.size()
