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
	var runtime_visual_state: String = _runtime_visual_state_for_reaction(object_kind, reaction_state, progress)
	var visual_asset_type_id: String = _visual_asset_type_id_for_state(object_kind, runtime_visual_state)
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
		"grid_position": Vector2i(visual_entry.get("grid_position", Vector2i.ZERO)) if typeof(visual_entry.get("grid_position", null)) == TYPE_VECTOR2I or typeof(visual_entry.get("grid_position", null)) == TYPE_VECTOR2 else null,
		"progress": progress,
		"open_fraction": _open_fraction_for_reaction(object_kind, reaction_state, progress),
		"runtime_visual_state": runtime_visual_state,
		"visual_swap_state": _visual_swap_state_for_reaction(object_kind, runtime_visual_state),
		"visual_asset_family": _visual_asset_family_for_kind(object_kind),
		"visual_asset_type_id": visual_asset_type_id,
		"visual_model_path": _visual_model_path_for_type_id(visual_asset_type_id),
		"visual_preview_path": _visual_preview_path_for_type_id(visual_asset_type_id),
		"visual_state_label": _visual_state_label_for_reaction(object_kind, runtime_visual_state),
		"computer_panel_text": _computer_panel_text_for_state(runtime_visual_state) if object_kind == "computer" else "",
		"door_walkability_hint": _door_walkability_hint(runtime_visual_state) if object_kind == "door" else "",
		"door_los_hint": _door_los_hint(runtime_visual_state) if object_kind == "door" else "",
		"door_animation_phase": _door_animation_phase_for_state(runtime_visual_state, progress) if object_kind == "door" else "",
		"door_asset_swap_state": _door_asset_swap_state_for_state(runtime_visual_state) if object_kind == "door" else "",
		"door_leaf_gap_fraction": _door_leaf_gap_fraction_for_state(runtime_visual_state, progress) if object_kind == "door" else 0.0,
		"door_threshold_visible": object_kind == "door" and runtime_visual_state == "open",
		"door_runtime_collision_source": "MissionInteractionDoorRuntimeCollisionLOS" if object_kind == "door" else "",
		"door_visual_sets_gameplay_truth": false,
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


static func _runtime_visual_state_for_reaction(object_kind: String, reaction_state: String, progress: float) -> String:
	match object_kind:
		"door":
			match reaction_state:
				"open":
					return "open"
				"active":
					return "open" if progress >= 0.85 else "half"
				"ready":
					return "closed"
				"locked", "blocked":
					return "closed"
				_:
					return "closed"
		"computer":
			match reaction_state:
				"controlled", "complete":
					return "controlled"
				"active":
					return "active"
				"ready":
					return "idle"
				_:
					return "idle"
		_:
			return reaction_state


static func _visual_asset_family_for_kind(object_kind: String) -> String:
	match object_kind:
		"door":
			return "space_station_single_door_runtime_visual"
		"computer":
			return "space_station_computer_runtime_visual"
		"aa":
			return "mission_aa_reaction_proxy"
		"cargo":
			return "mission_cargo_reaction_proxy"
		_:
			return "mission_interaction_reaction_proxy"


static func _visual_asset_type_id_for_state(object_kind: String, runtime_visual_state: String) -> String:
	match object_kind:
		"door":
			match runtime_visual_state:
				"open":
					return "station_set_door_single"
				"half":
					return "station_set_door_single_half"
				_:
					return "station_set_door_single_closed"
		"computer":
			return "station_computer"
		_:
			return ""


static func _visual_model_path_for_type_id(type_id: String) -> String:
	match type_id:
		"station_set_door_single":
			return "res://Assets/curated/kenney/space_station/models_all/door-single.glb"
		"station_set_door_single_half":
			return "res://Assets/curated/kenney/space_station/models_all/door-single-half.glb"
		"station_set_door_single_closed":
			return "res://Assets/curated/kenney/space_station/models_all/door-single-closed.glb"
		"station_computer":
			return "res://Assets/curated/kenney/space_station/models/computer.glb"
		_:
			return ""


static func _visual_preview_path_for_type_id(type_id: String) -> String:
	match type_id:
		"station_set_door_single":
			return "res://Assets/curated/kenney/space_station/previews_all/door-single.png"
		"station_set_door_single_half":
			return "res://Assets/curated/kenney/space_station/previews_all/door-single-half.png"
		"station_set_door_single_closed":
			return "res://Assets/curated/kenney/space_station/previews_all/door-single-closed.png"
		"station_computer":
			return "res://Assets/curated/kenney/space_station/previews_all/computer.png"
		_:
			return ""


static func _visual_state_label_for_reaction(object_kind: String, runtime_visual_state: String) -> String:
	if object_kind == "door":
		match runtime_visual_state:
			"open":
				return "DOOR OPEN"
			"half":
				return "DOOR OPENING"
			_:
				return "DOOR CLOSED"
	if object_kind == "computer":
		return "COM %s" % runtime_visual_state.to_upper()
	return runtime_visual_state.to_upper()


static func _computer_panel_text_for_state(runtime_visual_state: String) -> String:
	match runtime_visual_state:
		"controlled":
			return "CTRL"
		"active":
			return "LINK"
		_:
			return "IDLE"


static func _door_walkability_hint(runtime_visual_state: String) -> String:
	if runtime_visual_state == "open":
		return "effective_open_via_door_runtime_producer"
	return "effective_blocked_until_door_runtime_producer_opens"


static func _door_los_hint(runtime_visual_state: String) -> String:
	if runtime_visual_state == "open":
		return "effective_clear_via_door_runtime_producer"
	return "effective_blocked_until_door_runtime_producer_opens"


static func _visual_swap_state_for_reaction(object_kind: String, runtime_visual_state: String) -> String:
	if object_kind != "door":
		return runtime_visual_state
	return _door_asset_swap_state_for_state(runtime_visual_state)


static func _door_asset_swap_state_for_state(runtime_visual_state: String) -> String:
	match runtime_visual_state:
		"open":
			return "door_open_asset"
		"half":
			return "door_half_open_asset"
		_:
			return "door_closed_asset"


static func _door_animation_phase_for_state(runtime_visual_state: String, progress: float) -> String:
	match runtime_visual_state:
		"open":
			return "open"
		"half":
			return "opening_%d_percent" % roundi(clampf(progress, 0.0, 1.0) * 100.0)
		_:
			return "closed_idle"


static func _door_leaf_gap_fraction_for_state(runtime_visual_state: String, progress: float) -> float:
	match runtime_visual_state:
		"open":
			return 1.0
		"half":
			return clampf(maxf(progress, 0.35), 0.35, 0.84)
		_:
			return 0.0


static func _open_fraction_for_reaction(object_kind: String, reaction_state: String, progress: float) -> float:
	if object_kind != "door":
		return 0.0
	match reaction_state:
		"open":
			return 1.0
		"active":
			return clampf(maxf(progress, 0.35), 0.0, 1.0)
		"ready":
			return 0.0
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
