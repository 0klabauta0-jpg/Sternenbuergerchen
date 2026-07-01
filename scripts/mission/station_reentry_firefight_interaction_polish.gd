class_name StationReentryFirefightInteractionPolish
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_interaction_polish.v1"
const MAX_INTERACTION_LINE_LENGTH: int = 96


static func build_snapshot(inputs: Dictionary = {}) -> Dictionary:
	var visual_findings: Dictionary = Dictionary(inputs.get("visual_findings", {}))
	var firefight_tension: Dictionary = Dictionary(inputs.get("firefight_tension", {}))
	var tension_summary: Dictionary = Dictionary(firefight_tension.get("tension_summary", {}))
	var metrics_summary: Dictionary = Dictionary(firefight_tension.get("metrics_summary", {}))
	var next_decision_summary: Dictionary = Dictionary(firefight_tension.get("next_decision_summary", {}))
	var quick_actions: Array = _build_quick_actions(tension_summary, metrics_summary, next_decision_summary)
	var primary_action: Dictionary = Dictionary(quick_actions[0]) if not quick_actions.is_empty() else {}
	var interaction_line: String = _build_interaction_line(firefight_tension, tension_summary, primary_action, quick_actions)
	var gates: Array = [
		_gate("visual_findings_ready", _visual_findings_ready(visual_findings), "TASK_779-Findings sind bereit oder sauber abgeschlossen."),
		_gate("firefight_tension_ready", _firefight_tension_ready(firefight_tension), "TASK_777-Firefight-Tension ist gruen."),
		_gate("next_decision_source_visible", bool(next_decision_summary.get("visible", false)), "Vorhandener Combat-HUD-Next-Decision-Text ist sichtbar."),
		_gate("quick_actions_visible", quick_actions.size() >= 3, "Mindestens drei Folgegriffe sind sichtbar."),
		_gate("primary_action_visible", not primary_action.is_empty(), "Ein primaerer Folgegriff ist hervorgehoben."),
		_gate("interaction_line_within_limit", interaction_line.length() <= MAX_INTERACTION_LINE_LENGTH, "Firefight-Folgezeile bleibt kompakt."),
		_gate("read_only_sources", _sources_are_read_only([visual_findings, firefight_tension]), "Polish liest nur Snapshots und erzeugt keine Gameplay-Wahrheit."),
	]
	var failed_gate_ids: Array[String] = _failed_gate_ids(gates)
	var status: String = _build_status(failed_gate_ids)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_780",
		"source_task_ids": ["TASK_779", "TASK_777", "TASK_546", "TASK_570"],
		"status": status,
		"summary": _build_summary(status, interaction_line),
		"ready_for_firefight_interaction_playtest": status == "ready_for_firefight_interaction_playtest",
		"visual_findings_status": String(visual_findings.get("status", "")),
		"firefight_tension_status": String(firefight_tension.get("status", "")),
		"interaction_line": interaction_line,
		"interaction_line_char_limit": MAX_INTERACTION_LINE_LENGTH,
		"interaction_line_within_limit": interaction_line.length() <= MAX_INTERACTION_LINE_LENGTH,
		"primary_action": primary_action,
		"quick_actions": quick_actions,
		"quick_action_count": quick_actions.size(),
		"existing_command_surface": "command_matrix_and_combat_hud",
		"uses_existing_commands_only": true,
		"no_auto_command_commit": true,
		"tension_summary": tension_summary.duplicate(true),
		"metrics_summary": metrics_summary.duplicate(true),
		"next_decision_summary": next_decision_summary.duplicate(true),
		"gates": gates,
		"gate_count": gates.size(),
		"passed_gate_count": gates.size() - failed_gate_ids.size(),
		"failed_gate_ids": failed_gate_ids,
		"recommended_next_task": _recommended_next_task(status),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
	}


static func _visual_findings_ready(visual_findings: Dictionary) -> bool:
	return not visual_findings.is_empty() \
		and String(visual_findings.get("task_id", "")) == "TASK_779" \
		and ["ready_for_next_station_firefight_iteration", "needs_targeted_firefight_visual_polish"].has(String(visual_findings.get("status", ""))) \
		and _snapshot_read_only(visual_findings)


static func _firefight_tension_ready(firefight_tension: Dictionary) -> bool:
	return not firefight_tension.is_empty() \
		and String(firefight_tension.get("task_id", "")) == "TASK_777" \
		and String(firefight_tension.get("status", "")) == "ready_for_firefight_tension_playtest" \
		and bool(firefight_tension.get("ready_for_firefight_tension_playtest", false)) \
		and _snapshot_read_only(firefight_tension)


static func _build_quick_actions(tension_summary: Dictionary, metrics_summary: Dictionary, next_decision_summary: Dictionary) -> Array:
	var actions: Array = []
	var tension_label: String = String(tension_summary.get("tension_label", "pressure")).to_lower()
	var down_count: int = int(metrics_summary.get("down_count", 0))
	var wounded_count: int = int(metrics_summary.get("wounded_count", 0))
	var friendly_fire_risk_count: int = int(metrics_summary.get("friendly_fire_risk_count", 0))
	if down_count > 0 or tension_label == "casualty_pressure":
		actions.append(_quick_action("retreat", "RETREAT", "retreat", "Casualty pressure: pull back or reset the angle.", "danger", true))
		actions.append(_quick_action("hold_cover", "HOLD", "defend", "Hold cover while wounded/down state is readable.", "warning", false))
	elif wounded_count > 0 or tension_label == "wounded_pressure":
		actions.append(_quick_action("hold_cover", "HOLD", "defend", "Keep the team in cover after a hit.", "warning", true))
		actions.append(_quick_action("flank", "FLANK", "flank", "Shift angle if the enemy is fixed.", "accent", false))
	else:
		actions.append(_quick_action("hold_cover", "HOLD", "defend", "Hold cover and read the next exchange.", "good", true))
		actions.append(_quick_action("flank", "FLANK", "flank", "Create a cleaner line before pushing.", "accent", false))
	if friendly_fire_risk_count > 0:
		actions.append(_quick_action("hold_fire", "HOLD FIRE", "hold_fire", "Friendly-fire risk is present; tighten fire discipline.", "danger", false))
	actions.append(_quick_action("suppress", "SUP", "suppress", "Use suppression intent to pin without changing this slice's damage model.", "warning", false))
	actions.append(_quick_action("move_cover", "MOVE", "move", "Move to better cover if the preview is safer.", "accent", false))
	var source_next: String = String(next_decision_summary.get("next_action", "")).strip_edges()
	if not source_next.is_empty():
		for index in actions.size():
			var action: Dictionary = Dictionary(actions[index])
			if source_next.to_lower().find(String(action.get("label", "")).to_lower()) >= 0 \
					or source_next.to_lower().find(String(action.get("command_type", "")).to_lower()) >= 0:
				action["source_next_action_match"] = true
				actions[index] = action
				break
	return _dedupe_actions(actions)


static func _quick_action(id: String, label: String, command_type: String, reason: String, severity: String, primary: bool) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"command_type": command_type,
		"reason": reason,
		"severity": severity,
		"primary": primary,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
	}


static func _dedupe_actions(actions: Array) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = Dictionary(action_variant)
		var id: String = String(action.get("id", ""))
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		result.append(action)
	return result


static func _build_interaction_line(firefight_tension: Dictionary, tension_summary: Dictionary, primary_action: Dictionary, quick_actions: Array) -> String:
	var metrics_summary: Dictionary = Dictionary(firefight_tension.get("metrics_summary", {}))
	var outcome: String = String(tension_summary.get("outcome", "")).strip_edges().to_upper()
	var label: String = String(tension_summary.get("tension_label", "pressure")).strip_edges().to_upper()
	var shots: int = int(metrics_summary.get("shots_fired", 0))
	var hits: int = int(metrics_summary.get("hit_count", 0))
	var ff_risk: int = int(metrics_summary.get("friendly_fire_risk_count", 0))
	var primary_label: String = String(primary_action.get("label", "HOLD")).strip_edges().to_upper()
	var secondary_labels: Array[String] = []
	for action_variant in quick_actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = Dictionary(action_variant)
		var label_text: String = String(action.get("label", "")).strip_edges().to_upper()
		if label_text.is_empty() or label_text == primary_label:
			continue
		secondary_labels.append(label_text)
		if secondary_labels.size() >= 3:
			break
	var line: String = "FF %s | %s | S%d/H%d/FF%d | NEXT %s" % [outcome if not outcome.is_empty() else "CONTACT", label, shots, hits, ff_risk, primary_label]
	if not secondary_labels.is_empty():
		line += " / %s" % " / ".join(secondary_labels)
	if line.length() > MAX_INTERACTION_LINE_LENGTH:
		line = "FF %s | NEXT %s / %s" % [outcome if not outcome.is_empty() else "CONTACT", primary_label, " / ".join(secondary_labels.slice(0, 2))]
	return line.left(MAX_INTERACTION_LINE_LENGTH)


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
		return "ready_for_firefight_interaction_playtest"
	if failed_gate_ids.has("visual_findings_ready"):
		return "blocked_until_visual_findings_ready"
	if failed_gate_ids.has("firefight_tension_ready"):
		return "blocked_until_firefight_tension_ready"
	if failed_gate_ids.has("next_decision_source_visible"):
		return "needs_next_decision_source"
	if failed_gate_ids.has("interaction_line_within_limit"):
		return "needs_interaction_line_density_polish"
	return "blocked_until_firefight_interaction_gates_green"


static func _build_summary(status: String, interaction_line: String) -> String:
	match status:
		"ready_for_firefight_interaction_playtest":
			return "Firefight-Folgegriff ist kompakt lesbar: %s" % interaction_line
		"blocked_until_visual_findings_ready":
			return "Firefight-Interaction-Polish wartet auf TASK_779-Findings."
		"blocked_until_firefight_tension_ready":
			return "Firefight-Interaction-Polish wartet auf gruene TASK_777-Tension."
		"needs_next_decision_source":
			return "Combat-HUD braucht einen sichtbaren Next-Decision-Quelltext."
		"needs_interaction_line_density_polish":
			return "Firefight-Folgezeile ist zu lang oder zu dicht."
	return "Firefight-Interaction-Polish blockiert; Gates sind noch nicht gruen."


static func _recommended_next_task(status: String) -> String:
	match status:
		"ready_for_firefight_interaction_playtest":
			return "TASK_781 - Station Reentry Firefight Command Surface Recapture"
		"blocked_until_visual_findings_ready":
			return "TASK_779 - Station Reentry Firefight Visual Findings"
		"blocked_until_firefight_tension_ready":
			return "TASK_777 - Station Reentry Firefight Tension Feel Pass"
		"needs_next_decision_source":
			return "TASK_546 - Mission Combat Feedback HUD Density Polish"
		"needs_interaction_line_density_polish":
			return "TASK_780 - polish Firefight interaction line density"
	return "TASK_780 - complete Firefight Interaction gates"


static func _sources_are_read_only(sources: Array) -> bool:
	for source_variant in sources:
		if typeof(source_variant) != TYPE_DICTIONARY:
			return false
		if not _snapshot_read_only(Dictionary(source_variant)):
			return false
	return true


static func _snapshot_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true))
