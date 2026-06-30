class_name MissionInteractionObjectiveGate
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_objective_gate.v1"


static func build_snapshot(binding_snapshot: Dictionary, use_state_snapshot: Dictionary, use_feedback_snapshot: Dictionary, gate_snapshot: Dictionary, cargo_snapshot: Dictionary = {}, intent_snapshot: Dictionary = {}) -> Dictionary:
	var gate_entries: Array = Array(gate_snapshot.get("gates", []))
	var interactions: Array = Array(use_state_snapshot.get("interactions", []))
	var objective_entries: Array = []
	var complete_count: int = 0
	var blocked_count: int = 0
	var active_count: int = 0
	var next_gate: Dictionary = {}
	for index in range(gate_entries.size()):
		var gate: Dictionary = Dictionary(gate_entries[index])
		var interaction: Dictionary = _find_interaction_for_gate(interactions, String(gate.get("step_id", "")))
		var entry: Dictionary = _build_objective_entry(gate, interaction, index)
		var status: String = String(entry.get("gate_status", "")).strip_edges().to_lower()
		if bool(entry.get("complete", false)):
			complete_count += 1
		elif status == "blocked":
			blocked_count += 1
		elif status == "active" or status == "pending":
			active_count += 1
		if next_gate.is_empty() and not bool(entry.get("complete", false)):
			next_gate = entry.duplicate(true)
		objective_entries.append(entry)
	var all_complete: bool = bool(gate_snapshot.get("all_gates_complete", false)) or (not objective_entries.is_empty() and complete_count == objective_entries.size())
	var primary_feedback: Dictionary = Dictionary(use_feedback_snapshot.get("primary_feedback", {}))
	var next_interaction_id: String = String(next_gate.get("interaction_id", "")).strip_edges()
	var next_interaction: Dictionary = _find_interaction_by_id(interactions, next_interaction_id)
	var current_blocker: String = String(next_gate.get("blocked_by_step_id", "")).strip_edges()
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "SimulationRoot via MissionScenarioRuntimeGates",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"source_binding_schema": String(binding_snapshot.get("schema", "")).strip_edges(),
		"source_use_state_schema": String(use_state_snapshot.get("schema", "")).strip_edges(),
		"source_feedback_schema": String(use_feedback_snapshot.get("schema", "")).strip_edges(),
		"scenario_configured": bool(gate_snapshot.get("configured", false)),
		"scenario_id": String(binding_snapshot.get("scenario_id", use_state_snapshot.get("scenario_id", ""))).strip_edges(),
		"objective_gate_count": objective_entries.size(),
		"complete_gate_count": complete_count,
		"blocked_gate_count": blocked_count,
		"active_gate_count": active_count,
		"all_gates_complete": all_complete,
		"objective_gates": objective_entries,
		"next_gate": next_gate,
		"next_step_id": String(next_gate.get("step_id", "")).strip_edges(),
		"next_objective_type": String(next_gate.get("objective_type", "")).strip_edges(),
		"next_interaction": next_interaction,
		"next_interaction_id": next_interaction_id,
		"next_runtime_use_status": String(next_interaction.get("runtime_use_status", next_gate.get("runtime_use_status", ""))).strip_edges(),
		"next_action_label": _build_next_action_label(next_gate, next_interaction, primary_feedback),
		"next_line": _build_next_line(next_gate, next_interaction, all_complete),
		"blocked_by_step_id": current_blocker,
		"cargo_blocked_by_step_id": String(cargo_snapshot.get("blocked_by_step_id", "")).strip_edges(),
		"cargo_state": String(cargo_snapshot.get("cargo_state", cargo_snapshot.get("state", ""))).strip_edges(),
		"last_intent_interaction_id": String(intent_snapshot.get("interaction_id", "")).strip_edges(),
		"last_intent_accepted": bool(intent_snapshot.get("accepted", false)),
	}


static func _build_objective_entry(gate: Dictionary, interaction: Dictionary, index: int) -> Dictionary:
	var status: String = String(gate.get("status", "")).strip_edges().to_lower()
	var step_id: String = String(gate.get("step_id", "")).strip_edges()
	return {
		"index": index,
		"step_id": step_id,
		"objective_type": String(gate.get("objective_type", "")).strip_edges(),
		"gate_status": status,
		"complete": bool(gate.get("complete", false)),
		"progress": clampf(float(gate.get("progress", interaction.get("progress", 0.0))), 0.0, 1.0),
		"hold_elapsed_seconds": maxf(float(gate.get("hold_elapsed_seconds", interaction.get("hold_seconds", 0.0))), 0.0),
		"hold_required_seconds": maxf(float(gate.get("hold_required_seconds", interaction.get("duration_seconds", 0.0))), 0.0),
		"blocked_by_step_id": String(gate.get("blocked_by_step_id", interaction.get("blocked_by_step_id", ""))).strip_edges(),
		"target_marker_id": String(gate.get("target_marker_id", interaction.get("marker_id", ""))).strip_edges(),
		"interaction_id": String(interaction.get("interaction_id", "")).strip_edges(),
		"interaction_type": String(interaction.get("interaction_type", "")).strip_edges(),
		"runtime_use_status": String(interaction.get("runtime_use_status", "")).strip_edges(),
		"can_use_now": bool(interaction.get("can_use_now", false)),
		"required_order": String(interaction.get("required_order", "")).strip_edges(),
		"nearest_fireteam_id": String(interaction.get("nearest_fireteam_id", "")).strip_edges(),
		"distance_world": float(interaction.get("distance_world", -1.0)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _find_interaction_for_gate(interactions: Array, step_id: String) -> Dictionary:
	var normalized_step_id: String = step_id.strip_edges()
	for interaction_variant in interactions:
		if typeof(interaction_variant) != TYPE_DICTIONARY:
			continue
		var interaction: Dictionary = Dictionary(interaction_variant)
		if String(interaction.get("step_id", "")).strip_edges() == normalized_step_id:
			return interaction.duplicate(true)
	return {}


static func _find_interaction_by_id(interactions: Array, interaction_id: String) -> Dictionary:
	var normalized_id: String = interaction_id.strip_edges()
	for interaction_variant in interactions:
		if typeof(interaction_variant) != TYPE_DICTIONARY:
			continue
		var interaction: Dictionary = Dictionary(interaction_variant)
		if String(interaction.get("interaction_id", "")).strip_edges() == normalized_id:
			return interaction.duplicate(true)
	return {}


static func _build_next_action_label(next_gate: Dictionary, next_interaction: Dictionary, primary_feedback: Dictionary) -> String:
	if next_gate.is_empty():
		return "COMPLETE"
	var runtime_status: String = String(next_interaction.get("runtime_use_status", next_gate.get("runtime_use_status", ""))).strip_edges().to_lower()
	if runtime_status == "usable" or runtime_status == "in_progress":
		var action_label: String = String(primary_feedback.get("action_label", "")).strip_edges()
		return action_label if not action_label.is_empty() else String(next_interaction.get("required_order", "USE")).strip_edges().to_upper()
	if runtime_status == "out_of_range":
		return "ANNAEHERN"
	if runtime_status == "blocked":
		return "BLOCKIERT"
	return "PRUEFEN"


static func _build_next_line(next_gate: Dictionary, next_interaction: Dictionary, all_complete: bool) -> String:
	if all_complete:
		return "OBJECTIVES complete"
	if next_gate.is_empty():
		return "OBJECTIVES unklar"
	var token: String = _objective_token(String(next_gate.get("objective_type", "")), String(next_interaction.get("interaction_id", "")))
	var status: String = String(next_interaction.get("runtime_use_status", next_gate.get("gate_status", ""))).strip_edges().to_upper()
	var blocker: String = String(next_gate.get("blocked_by_step_id", "")).strip_edges()
	if not blocker.is_empty():
		return "NEXT %s blockiert durch %s" % [token, blocker]
	if status.is_empty():
		status = "PENDING"
	return "NEXT %s %s" % [token, status]


static func _objective_token(objective_type: String, interaction_id: String) -> String:
	var haystack: String = "%s %s" % [objective_type.strip_edges().to_lower(), interaction_id.strip_edges().to_lower()]
	if haystack.contains("air") or haystack.contains("aa"):
		return "AA"
	if haystack.contains("computer") or haystack.contains("station"):
		return "COM"
	if haystack.contains("cargo"):
		return "CARGO"
	return "OBJ"
