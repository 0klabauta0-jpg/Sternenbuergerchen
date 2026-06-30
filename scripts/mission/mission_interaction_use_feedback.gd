class_name MissionInteractionUseFeedback
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_use_feedback.v1"

const STATUS_IN_PROGRESS: String = "in_progress"
const STATUS_USABLE: String = "usable"
const STATUS_BLOCKED: String = "blocked"
const STATUS_OUT_OF_RANGE: String = "out_of_range"
const STATUS_COMPLETE: String = "complete"
const STATUS_INTERRUPTED: String = "interrupted"
const STATUS_UNKNOWN: String = "unknown"

const STATUS_PRIORITY: Dictionary = {
	STATUS_IN_PROGRESS: 0,
	STATUS_USABLE: 1,
	STATUS_BLOCKED: 2,
	STATUS_INTERRUPTED: 3,
	STATUS_OUT_OF_RANGE: 4,
	STATUS_COMPLETE: 5,
	STATUS_UNKNOWN: 6,
}


static func build_snapshot(use_state_snapshot: Dictionary, feedback_context: Dictionary = {}) -> Dictionary:
	var selected_fireteam_ids: PackedStringArray = _normalize_selected_fireteam_ids(feedback_context.get("selected_fireteam_ids", []))
	var all_entries: Array = _build_feedback_entries(Array(use_state_snapshot.get("interactions", [])), selected_fireteam_ids)
	var relevant_entries: Array = _filter_relevant_entries(all_entries, selected_fireteam_ids)
	var primary: Dictionary = relevant_entries[0].duplicate(true) if not relevant_entries.is_empty() else {}
	return {
		"schema": SNAPSHOT_SCHEMA,
		"source_use_state_schema": String(use_state_snapshot.get("schema", "")).strip_edges(),
		"runtime_authority": "SimulationRoot",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"scenario_id": String(use_state_snapshot.get("scenario_id", "")).strip_edges(),
		"selected_fireteam_ids": Array(selected_fireteam_ids),
		"feedback_entries": all_entries,
		"relevant_feedback_entries": relevant_entries,
		"feedback_count": all_entries.size(),
		"relevant_feedback_count": relevant_entries.size(),
		"primary_feedback": primary,
		"primary_interaction_id": String(primary.get("interaction_id", "")).strip_edges(),
		"primary_status": String(primary.get("status", STATUS_UNKNOWN)).strip_edges(),
		"feedback_line": String(primary.get("feedback_line", "")).strip_edges(),
		"detail_text": String(primary.get("detail_text", "")).strip_edges(),
		"action_label": String(primary.get("action_label", "")).strip_edges(),
		"severity": String(primary.get("severity", "muted")).strip_edges(),
		"can_prompt_use": bool(primary.get("can_prompt_use", false)),
		"has_selected_context": not selected_fireteam_ids.is_empty(),
	}


static func _build_feedback_entries(interactions: Array, selected_fireteam_ids: PackedStringArray) -> Array:
	var entries: Array = []
	for interaction_variant in interactions:
		if typeof(interaction_variant) != TYPE_DICTIONARY:
			continue
		var interaction: Dictionary = Dictionary(interaction_variant)
		var entry: Dictionary = _build_feedback_entry(interaction, selected_fireteam_ids)
		if entry.is_empty():
			continue
		entries.append(entry)
	entries.sort_custom(Callable(MissionInteractionUseFeedback, "_sort_feedback_entries"))
	return entries


static func _build_feedback_entry(interaction: Dictionary, selected_fireteam_ids: PackedStringArray) -> Dictionary:
	var interaction_id: String = String(interaction.get("interaction_id", "")).strip_edges()
	if interaction_id.is_empty():
		return {}
	var status: String = String(interaction.get("runtime_use_status", STATUS_UNKNOWN)).strip_edges().to_lower()
	if status.is_empty():
		status = STATUS_UNKNOWN
	var display_token: String = _build_display_token(interaction)
	var required_order: String = String(interaction.get("required_order", "")).strip_edges().to_upper()
	var nearest_fireteam_id: String = String(interaction.get("nearest_fireteam_id", "")).strip_edges().to_lower()
	var selected_relevance: bool = selected_fireteam_ids.is_empty() or selected_fireteam_ids.has(nearest_fireteam_id)
	var distance_world: float = float(interaction.get("distance_world", -1.0))
	var radius_world: float = maxf(float(interaction.get("radius_world", 0.0)), 0.0)
	var progress: float = clampf(float(interaction.get("progress", 0.0)), 0.0, 1.0)
	var hold_seconds: float = maxf(float(interaction.get("hold_seconds", 0.0)), 0.0)
	var duration_seconds: float = maxf(float(interaction.get("duration_seconds", 0.0)), 0.0)
	var line: String = _build_feedback_line(status, display_token, required_order, nearest_fireteam_id, distance_world, radius_world, progress, hold_seconds, duration_seconds, interaction)
	return {
		"interaction_id": interaction_id,
		"display_token": display_token,
		"display_name": String(interaction.get("display_name", interaction_id)).strip_edges(),
		"status": status,
		"feedback_line": line,
		"detail_text": _build_detail_text(status, interaction, distance_world, radius_world, hold_seconds, duration_seconds),
		"action_label": _build_action_label(status, required_order),
		"severity": _severity_for_status(status),
		"priority": int(STATUS_PRIORITY.get(status, STATUS_PRIORITY.get(STATUS_UNKNOWN, 99))),
		"can_prompt_use": status == STATUS_USABLE or status == STATUS_IN_PROGRESS,
		"selected_relevance": selected_relevance,
		"nearest_fireteam_id": nearest_fireteam_id,
		"distance_world": distance_world,
		"radius_world": radius_world,
		"progress": progress,
		"hold_seconds": hold_seconds,
		"duration_seconds": duration_seconds,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _build_feedback_line(status: String, display_token: String, required_order: String, nearest_fireteam_id: String, distance_world: float, radius_world: float, progress: float, hold_seconds: float, duration_seconds: float, interaction: Dictionary) -> String:
	var fireteam_token: String = nearest_fireteam_id.to_upper() if not nearest_fireteam_id.is_empty() else "FT?"
	match status:
		STATUS_IN_PROGRESS:
			if duration_seconds > 0.0:
				return "%s laeuft %d%% | %.0f/%.0fs | %s" % [display_token, int(round(progress * 100.0)), hold_seconds, duration_seconds, fireteam_token]
			return "%s laeuft %d%% | %s" % [display_token, int(round(progress * 100.0)), fireteam_token]
		STATUS_USABLE:
			return "%s bereit | %s | %s %.0fm" % [display_token, required_order if not required_order.is_empty() else "USE", fireteam_token, maxf(distance_world, 0.0)]
		STATUS_BLOCKED:
			var blocked_by_step_id: String = String(interaction.get("blocked_by_step_id", "")).strip_edges()
			return "%s blockiert | zuerst %s" % [display_token, blocked_by_step_id] if not blocked_by_step_id.is_empty() else "%s blockiert" % display_token
		STATUS_INTERRUPTED:
			return "%s unterbrochen | neu sichern" % display_token
		STATUS_OUT_OF_RANGE:
			return "%s ausser Reichweite | %s %.0fm > %.0fm" % [display_token, fireteam_token, maxf(distance_world, 0.0), radius_world]
		STATUS_COMPLETE:
			return "%s fertig" % display_token
		_:
			return "%s unklar" % display_token


static func _build_detail_text(status: String, interaction: Dictionary, distance_world: float, radius_world: float, hold_seconds: float, duration_seconds: float) -> String:
	var reason: String = String(interaction.get("runtime_use_reason", "")).strip_edges()
	match status:
		STATUS_USABLE:
			return "In Reichweite. Befehl %s kann vorbereitet werden." % String(interaction.get("required_order", "use")).strip_edges().to_upper()
		STATUS_IN_PROGRESS:
			return "Runtime meldet Fortschritt %.0f/%.0fs." % [hold_seconds, duration_seconds] if duration_seconds > 0.0 else "Runtime meldet laufende Bedienung."
		STATUS_BLOCKED:
			return "Blockiert durch %s." % reason if not reason.is_empty() else "Noch nicht freigeschaltet."
		STATUS_OUT_OF_RANGE:
			return "Naechstes Fireteam %.0fm entfernt, Radius %.0fm." % [maxf(distance_world, 0.0), radius_world]
		STATUS_COMPLETE:
			return "Interaction ist abgeschlossen."
		STATUS_INTERRUPTED:
			return "Interaction wurde unterbrochen und braucht neuen Runtime-Fortschritt."
		_:
			return "Zu wenig Runtime-Kontext fuer eine sichere Empfehlung."


static func _build_action_label(status: String, required_order: String) -> String:
	match status:
		STATUS_USABLE:
			return required_order if not required_order.is_empty() else "USE"
		STATUS_IN_PROGRESS:
			return "HALTEN"
		STATUS_BLOCKED:
			return "BLOCKIERT"
		STATUS_OUT_OF_RANGE:
			return "ANNAEHERN"
		STATUS_COMPLETE:
			return "FERTIG"
		STATUS_INTERRUPTED:
			return "NEU STARTEN"
		_:
			return "UNKLAR"


static func _severity_for_status(status: String) -> String:
	match status:
		STATUS_USABLE:
			return "good"
		STATUS_IN_PROGRESS:
			return "progress"
		STATUS_BLOCKED, STATUS_INTERRUPTED:
			return "warn"
		STATUS_OUT_OF_RANGE:
			return "muted"
		STATUS_COMPLETE:
			return "done"
		_:
			return "unknown"


static func _build_display_token(interaction: Dictionary) -> String:
	var interaction_id: String = String(interaction.get("interaction_id", "")).strip_edges().to_lower()
	var display_name: String = String(interaction.get("display_name", interaction_id)).strip_edges().to_lower()
	if interaction_id.contains("cargo") or display_name.contains("cargo"):
		return "CARGO"
	if interaction_id.contains("computer") or display_name.contains("computer") or display_name.contains("station"):
		return "COM"
	if interaction_id.contains("aa") or display_name.contains("aa") or display_name.contains("air"):
		return "AA"
	var interaction_type: String = String(interaction.get("interaction_type", "")).strip_edges().to_upper()
	return interaction_type if not interaction_type.is_empty() else "INTERACTION"


static func _filter_relevant_entries(entries: Array, selected_fireteam_ids: PackedStringArray) -> Array:
	if selected_fireteam_ids.is_empty():
		return entries.duplicate(true)
	var relevant: Array = []
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if bool(entry.get("selected_relevance", false)) or String(entry.get("nearest_fireteam_id", "")).strip_edges().is_empty():
			relevant.append(entry)
	return relevant if not relevant.is_empty() else entries.duplicate(true)


static func _sort_feedback_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_priority: int = int(a.get("priority", 99))
	var b_priority: int = int(b.get("priority", 99))
	if a_priority != b_priority:
		return a_priority < b_priority
	var a_distance: float = float(a.get("distance_world", INF))
	var b_distance: float = float(b.get("distance_world", INF))
	if a_distance != b_distance:
		return a_distance < b_distance
	return String(a.get("interaction_id", "")) < String(b.get("interaction_id", ""))


static func _normalize_selected_fireteam_ids(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()
	var raw: Array = []
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		raw = Array(PackedStringArray(value))
	elif typeof(value) == TYPE_ARRAY:
		raw = Array(value)
	for fireteam_id_variant in raw:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or result.has(fireteam_id):
			continue
		result.append(fireteam_id)
	return result
