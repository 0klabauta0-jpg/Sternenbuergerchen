class_name StationReentryMissionInteractionFeelPass
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_mission_interaction_feel_pass.v1"
const REQUIRED_ROUTE_TOKENS: Array[String] = ["AA", "DOOR", "COM", "CARGO"]
const REQUIRED_COMMANDS: Array[String] = ["move", "take", "breach", "defend", "go"]


static func build_snapshot(inputs: Dictionary = {}) -> Dictionary:
	var acceptance: Dictionary = Dictionary(inputs.get("acceptance", {}))
	var route_readout: Dictionary = Dictionary(inputs.get("route_readout", {}))
	var cues: Array = Array(inputs.get("cues", []))
	var command_affordances: Dictionary = Dictionary(inputs.get("command_affordances", {}))
	var route_tokens: Array[String] = _route_tokens(route_readout)
	var cue_summaries: Array = _cue_summaries(cues)
	var missing_tokens: Array[String] = _missing_tokens(route_tokens)
	var missing_cue_tokens: Array[String] = _missing_cue_tokens(cue_summaries)
	var missing_commands: Array[String] = _missing_commands(command_affordances)
	var gates: Array = [
		_gate("reentry_accepted", _acceptance_gate_passes(acceptance), "TASK_774-Reentry-Slice ist eng akzeptiert."),
		_gate("route_sequence_readable", missing_tokens.is_empty(), "Route liest AA > DOOR > COM > CARGO."),
		_gate("all_interaction_cues_readable", missing_cue_tokens.is_empty() and _all_cues_within_budget(cue_summaries), "AA/Door/Computer/Cargo-Cues sind kurz und handlungsnah."),
		_gate("command_affordances_present", missing_commands.is_empty() and bool(command_affordances.get("preview_before_go", false)), "Move/Take/Breach/Defend/GO sind als naechste Handlung greifbar."),
		_gate("read_only_sources", _sources_are_read_only([acceptance, route_readout, command_affordances], cues), "Feel-Pass liest nur Snapshots und erzeugt keine Gameplay-Wahrheit."),
	]
	var failed_gate_ids: Array[String] = _failed_gate_ids(gates)
	var status: String = _build_status(failed_gate_ids)
	var ready: bool = status == "ready_for_mission_interaction_playtest"
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_775",
		"source_task_id": "TASK_774",
		"source_route_cue_task_id": "TASK_736",
		"status": status,
		"summary": _build_summary(status, failed_gate_ids),
		"ready_for_mission_interaction_playtest": ready,
		"route_tokens": route_tokens,
		"required_route_tokens": REQUIRED_ROUTE_TOKENS,
		"missing_route_tokens": missing_tokens,
		"cue_summaries": cue_summaries,
		"cue_count": cue_summaries.size(),
		"missing_cue_tokens": missing_cue_tokens,
		"command_affordances": command_affordances.duplicate(true),
		"missing_commands": missing_commands,
		"gates": gates,
		"gate_count": gates.size(),
		"passed_gate_count": gates.size() - failed_gate_ids.size(),
		"failed_gate_ids": failed_gate_ids,
		"recommended_next_task": _recommended_next_task(status, failed_gate_ids),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
	}


static func _acceptance_gate_passes(acceptance: Dictionary) -> bool:
	return not acceptance.is_empty() \
		and String(acceptance.get("task_id", "")) == "TASK_774" \
		and bool(acceptance.get("accepted_for_next_playable_slice", false)) \
		and String(acceptance.get("status", "")) == "accepted_for_next_playable_slice" \
		and _snapshot_read_only(acceptance)


static func _route_tokens(route_readout: Dictionary) -> Array[String]:
	var tokens: Array[String] = []
	var raw_tokens: Array = Array(route_readout.get("route_tokens", []))
	if raw_tokens.is_empty():
		for key in ["aa_token", "door_token", "computer_token", "cargo_token"]:
			var token: String = String(route_readout.get(key, "")).strip_edges().split(" ", false, 1)[0].to_upper()
			if not token.is_empty() and token != "-":
				raw_tokens.append(token)
	for token_variant in raw_tokens:
		var token: String = String(token_variant).strip_edges().to_upper()
		if token.is_empty() or tokens.has(token):
			continue
		tokens.append(token)
	return tokens


static func _cue_summaries(cues: Array) -> Array:
	var result: Array = []
	for cue_variant in cues:
		if typeof(cue_variant) != TYPE_DICTIONARY:
			continue
		var cue: Dictionary = Dictionary(cue_variant)
		var token: String = String(cue.get("next_token", "")).strip_edges().to_upper()
		var line: String = String(cue.get("cue_line", "")).strip_edges()
		result.append({
			"token": token,
			"cue_line": line,
			"runtime_status": String(cue.get("runtime_status", "")),
			"action_label": String(cue.get("action_label", "")),
			"active": bool(cue.get("active", false)),
			"line_within_limit": bool(cue.get("line_within_limit", false)),
			"uses_player_action_language": bool(cue.get("uses_player_action_language", false)),
			"read_only": bool(cue.get("read_only", false)),
			"ui_sets_gameplay_truth": bool(cue.get("ui_sets_gameplay_truth", true)),
		})
	return result


static func _missing_tokens(tokens: Array[String]) -> Array[String]:
	var missing: Array[String] = []
	for token in REQUIRED_ROUTE_TOKENS:
		if not tokens.has(token):
			missing.append(token)
	return missing


static func _missing_cue_tokens(cue_summaries: Array) -> Array[String]:
	var present: Array[String] = []
	for summary_variant in cue_summaries:
		if typeof(summary_variant) != TYPE_DICTIONARY:
			continue
		var summary: Dictionary = Dictionary(summary_variant)
		var token: String = String(summary.get("token", "")).strip_edges().to_upper()
		if bool(summary.get("active", false)) and bool(summary.get("uses_player_action_language", false)) and not String(summary.get("cue_line", "")).strip_edges().is_empty():
			present.append(token)
	var missing: Array[String] = []
	for token in REQUIRED_ROUTE_TOKENS:
		if not present.has(token):
			missing.append(token)
	return missing


static func _all_cues_within_budget(cue_summaries: Array) -> bool:
	if cue_summaries.size() < REQUIRED_ROUTE_TOKENS.size():
		return false
	for summary_variant in cue_summaries:
		if typeof(summary_variant) != TYPE_DICTIONARY:
			return false
		if not bool(Dictionary(summary_variant).get("line_within_limit", false)):
			return false
	return true


static func _missing_commands(command_affordances: Dictionary) -> Array[String]:
	var available: Array = Array(command_affordances.get("available_commands", []))
	var normalized: Array[String] = []
	for command_variant in available:
		var command: String = String(command_variant).strip_edges().to_lower()
		if not command.is_empty() and not normalized.has(command):
			normalized.append(command)
	var missing: Array[String] = []
	for command in REQUIRED_COMMANDS:
		if not normalized.has(command):
			missing.append(command)
	return missing


static func _sources_are_read_only(dict_sources: Array, cue_sources: Array) -> bool:
	for source_variant in dict_sources:
		if typeof(source_variant) != TYPE_DICTIONARY:
			return false
		if not _snapshot_read_only(Dictionary(source_variant)):
			return false
	for cue_variant in cue_sources:
		if typeof(cue_variant) != TYPE_DICTIONARY:
			return false
		if not _snapshot_read_only(Dictionary(cue_variant)):
			return false
	return true


static func _snapshot_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_navigation", false))


static func _gate(id: String, passed: bool, label: String) -> Dictionary:
	return {
		"id": id,
		"passed": passed,
		"label": label,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _failed_gate_ids(gates: Array) -> Array[String]:
	var failed: Array[String] = []
	for gate_variant in gates:
		if typeof(gate_variant) != TYPE_DICTIONARY:
			continue
		var gate: Dictionary = Dictionary(gate_variant)
		if not bool(gate.get("passed", false)):
			failed.append(String(gate.get("id", "")))
	return failed


static func _build_status(failed_gate_ids: Array[String]) -> String:
	if failed_gate_ids.is_empty():
		return "ready_for_mission_interaction_playtest"
	if failed_gate_ids.has("reentry_accepted"):
		return "blocked_until_reentry_accepted"
	if failed_gate_ids.has("all_interaction_cues_readable"):
		return "needs_interaction_cue_polish"
	if failed_gate_ids.has("command_affordances_present"):
		return "needs_command_affordance_polish"
	if failed_gate_ids.has("route_sequence_readable"):
		return "needs_route_sequence_repair"
	return "blocked_until_interaction_feel_gates_green"


static func _build_summary(status: String, failed_gate_ids: Array[String]) -> String:
	match status:
		"ready_for_mission_interaction_playtest":
			return "Station-Reentry-Interaktionen sind als naechster Missionsgriff lesbar."
		"blocked_until_reentry_accepted":
			return "Mission-Interaction-Feel-Pass blockiert, bis TASK_774 akzeptiert ist."
		"needs_interaction_cue_polish":
			return "AA/Door/Computer/Cargo-Cues brauchen noch klare Handlungssprache oder Textbudget."
		"needs_command_affordance_polish":
			return "Command-Affordances fuer Move/Take/Breach/Defend/GO sind nicht vollstaendig sichtbar."
		"needs_route_sequence_repair":
			return "Route-Sequenz AA > DOOR > COM > CARGO ist nicht vollstaendig lesbar."
	return "Interaction-Feel-Pass blockiert; fehlende Gates: %s" % ", ".join(failed_gate_ids)


static func _recommended_next_task(status: String, failed_gate_ids: Array[String]) -> String:
	match status:
		"ready_for_mission_interaction_playtest":
			return "TASK_776 - Station Reentry Contact Pressure Feel Pass"
		"blocked_until_reentry_accepted":
			return "TASK_774 - Station Reentry Next Playable Slice Acceptance"
		"needs_interaction_cue_polish":
			return "TASK_775 - polish Station Reentry interaction cues"
		"needs_command_affordance_polish":
			return "TASK_775 - polish Station Reentry command affordances"
		"needs_route_sequence_repair":
			return "TASK_726/TASK_736 - repair Station route sequence or cue source"
	return "TASK_775 - complete Mission Interaction Feel gates"
