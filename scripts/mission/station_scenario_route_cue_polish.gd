class_name StationScenarioRouteCuePolish
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_scenario_route_cue_polish.v1"
const TOKEN_LABELS: Dictionary = {
	"AA": "AA sichern",
	"DOOR": "Tuer oeffnen",
	"COM": "Computer halten",
	"CARGO": "Cargo decken",
	"DONE": "Route abgeschlossen",
	"WAIT": "Route pruefen",
}


static func build_snapshot(route_readout: Dictionary, objective_gate: Dictionary, use_feedback: Dictionary = {}, progress_readability: Dictionary = {}) -> Dictionary:
	var next_token: String = String(route_readout.get("next_token", "")).strip_edges().to_upper()
	if next_token.is_empty():
		next_token = _token_from_gate(objective_gate)
	var all_complete: bool = bool(route_readout.get("all_gates_complete", objective_gate.get("all_gates_complete", false))) or next_token == "DONE"
	var next_interaction: Dictionary = Dictionary(objective_gate.get("next_interaction", {}))
	var primary_feedback: Dictionary = Dictionary(use_feedback.get("primary_feedback", {}))
	var runtime_status: String = String(objective_gate.get("next_runtime_use_status", next_interaction.get("runtime_use_status", primary_feedback.get("status", "")))).strip_edges().to_lower()
	if runtime_status.is_empty() and all_complete:
		runtime_status = "complete"
	var action_label: String = String(objective_gate.get("next_action_label", primary_feedback.get("action_label", ""))).strip_edges().to_upper()
	if action_label.is_empty():
		action_label = _default_action_for_token(next_token)
	var distance_world: float = float(next_interaction.get("distance_world", primary_feedback.get("distance_world", -1.0)))
	var fireteam_token: String = _fireteam_token(String(next_interaction.get("nearest_fireteam_id", primary_feedback.get("nearest_fireteam_id", ""))).strip_edges())
	var progress_line: String = String(progress_readability.get("compact_line", progress_readability.get("display_line", ""))).strip_edges()
	var cue_line: String = _build_cue_line(next_token, action_label, runtime_status, fireteam_token, distance_world, progress_line, all_complete)
	var detail_line: String = _build_detail_line(next_token, runtime_status, action_label, fireteam_token, distance_world, objective_gate)
	var line_limit: int = 96
	return {
		"schema": SNAPSHOT_SCHEMA,
		"active": not cue_line.is_empty(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"runtime_authority": "MissionInteractionObjectiveGate + MissionInteractionUseFeedback",
		"source": "station_route_run_readout_objective_gate_use_feedback",
		"route_readout_schema": String(route_readout.get("schema", "")).strip_edges(),
		"objective_gate_schema": String(objective_gate.get("schema", "")).strip_edges(),
		"use_feedback_schema": String(use_feedback.get("schema", "")).strip_edges(),
		"progress_readability_schema": String(progress_readability.get("schema", "")).strip_edges(),
		"next_token": next_token,
		"next_step_id": String(objective_gate.get("next_step_id", route_readout.get("next_step_id", ""))).strip_edges(),
		"next_interaction_id": String(objective_gate.get("next_interaction_id", route_readout.get("next_interaction_id", ""))).strip_edges(),
		"runtime_status": runtime_status,
		"action_label": action_label,
		"fireteam_token": fireteam_token,
		"distance_world": distance_world,
		"cue_line": cue_line,
		"detail_line": detail_line,
		"visible_lines": [cue_line] if not cue_line.is_empty() else [],
		"visible_line_count": 1 if not cue_line.is_empty() else 0,
		"max_visible_line_count": 1,
		"line_char_limit": line_limit,
		"line_length": cue_line.length(),
		"line_within_limit": cue_line.length() <= line_limit,
		"contains_next_token": not next_token.is_empty() and cue_line.contains(next_token),
		"contains_action": not action_label.is_empty() and cue_line.to_upper().contains(action_label),
		"contains_fireteam_token": fireteam_token != "FT?" and cue_line.contains(fireteam_token),
		"all_gates_complete": all_complete,
	}


static func _build_cue_line(next_token: String, action_label: String, runtime_status: String, fireteam_token: String, distance_world: float, progress_line: String, all_complete: bool) -> String:
	if all_complete:
		return "CUE DONE: Extraktion/Debrief pruefen"
	var label: String = String(TOKEN_LABELS.get(next_token, TOKEN_LABELS.get("WAIT", "Route pruefen")))
	match runtime_status:
		"in_progress":
			return "CUE %s: %s" % [next_token, progress_line if not progress_line.is_empty() else "halten"]
		"usable":
			return "CUE %s: %s + GO | %s" % [next_token, action_label, fireteam_token]
		"out_of_range":
			return "CUE %s: %s | %s %.0fm" % [next_token, label, fireteam_token, maxf(distance_world, 0.0)]
		"blocked":
			return "CUE %s: blockiert | vorherigen Schritt loesen" % next_token
		"interrupted":
			return "CUE %s: neu sichern | %s" % [next_token, fireteam_token]
		"complete":
			return "CUE %s: erledigt | naechsten Schritt pruefen" % next_token
		_:
			return "CUE %s: %s" % [next_token if not next_token.is_empty() else "WAIT", label]


static func _build_detail_line(next_token: String, runtime_status: String, action_label: String, fireteam_token: String, distance_world: float, objective_gate: Dictionary) -> String:
	var blocker: String = String(objective_gate.get("blocked_by_step_id", "")).strip_edges()
	if not blocker.is_empty():
		return "Naechstes Ziel %s wartet auf %s." % [next_token, blocker]
	if runtime_status == "usable":
		return "%s ist in Reichweite: %s vorbereiten und mit GO bestaetigen." % [next_token, action_label]
	if runtime_status == "out_of_range":
		return "%s muss naeher an den Marker: %s ist %.0fm entfernt." % [next_token, fireteam_token, maxf(distance_world, 0.0)]
	if runtime_status == "in_progress":
		return "%s laeuft; Fireteam im Radius halten." % next_token
	if runtime_status == "complete":
		return "%s ist erledigt; Route liest den naechsten offenen Gate-Schritt." % next_token
	return "%s aus Objective-Gate-Snapshot lesen; kein UI-State wird gesetzt." % (next_token if not next_token.is_empty() else "Route")


static func _token_from_gate(objective_gate: Dictionary) -> String:
	if bool(objective_gate.get("all_gates_complete", false)):
		return "DONE"
	var step_id: String = String(objective_gate.get("next_step_id", "")).strip_edges().to_lower()
	if step_id.contains("door"):
		return "DOOR"
	if step_id.contains("computer"):
		return "COM"
	if step_id.contains("cargo"):
		return "CARGO"
	if step_id.contains("air") or step_id.contains("aa"):
		return "AA"
	return "WAIT"


static func _default_action_for_token(token: String) -> String:
	match token:
		"DOOR":
			return "BREACH"
		"COM", "AA":
			return "TAKE"
		"CARGO":
			return "DEFEND"
		_:
			return "USE"


static func _fireteam_token(raw_fireteam_id: String) -> String:
	var value: String = raw_fireteam_id.strip_edges().to_upper()
	return value if not value.is_empty() else "FT?"
