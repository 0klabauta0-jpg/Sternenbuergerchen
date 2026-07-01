class_name StationReentryFirefightTensionFeelPass
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_tension_feel_pass.v1"


static func build_snapshot(inputs: Dictionary = {}) -> Dictionary:
	var contact_pressure: Dictionary = Dictionary(inputs.get("contact_pressure", {}))
	var engagement: Dictionary = Dictionary(inputs.get("engagement", {}))
	var fire_visuals: Dictionary = Dictionary(inputs.get("fire_visuals", {}))
	var combat_metrics: Dictionary = Dictionary(inputs.get("combat_metrics", {}))
	var hud_decision: Dictionary = Dictionary(inputs.get("hud_decision", {}))
	var exchange_summary: Dictionary = _exchange_summary(engagement)
	var visual_summary: Dictionary = _visual_summary(fire_visuals)
	var metrics_summary: Dictionary = _metrics_summary(combat_metrics)
	var tension_summary: Dictionary = _tension_summary(exchange_summary, metrics_summary)
	var next_decision_summary: Dictionary = _next_decision_summary(hud_decision)
	var gates: Array = [
		_gate("contact_pressure_ready", _contact_pressure_gate_passes(contact_pressure), "TASK_776-Contact-Pressure ist gruen."),
		_gate("fire_exchange_visible", bool(exchange_summary.get("visible", false)), "Erster Feuerwechsel nennt Attacker, Target, Weapon und Outcome."),
		_gate("fire_visuals_visible", bool(visual_summary.get("visible", false)), "Trace, Impact/Fokus und Unit-Badge sind sichtbar."),
		_gate("combat_metrics_visible", bool(metrics_summary.get("visible", false)), "Shots, Hits, Wounded, Down und Friendly-Fire-Risiko sind zaehlbar."),
		_gate("tension_state_readable", bool(tension_summary.get("visible", false)), "Treffer/Verfehlen/Verwundung/Down werden als Druckmoment benannt."),
		_gate("next_decision_visible", bool(next_decision_summary.get("visible", false)), "HUD benennt nach dem Feuerwechsel einen naechsten Spielergriff."),
		_gate("read_only_sources", _sources_are_read_only([contact_pressure, engagement, fire_visuals, combat_metrics, hud_decision]), "Feel-Pass liest nur Snapshots und erzeugt keine Gameplay-Wahrheit."),
	]
	var failed_gate_ids: Array[String] = _failed_gate_ids(gates)
	var status: String = _build_status(failed_gate_ids)
	var ready: bool = status == "ready_for_firefight_tension_playtest"
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_777",
		"source_task_ids": ["TASK_776", "TASK_543", "TASK_544", "TASK_546", "TASK_584"],
		"status": status,
		"summary": _build_summary(status, failed_gate_ids),
		"ready_for_firefight_tension_playtest": ready,
		"contact_pressure_status": String(contact_pressure.get("status", "")),
		"exchange_summary": exchange_summary,
		"visual_summary": visual_summary,
		"metrics_summary": metrics_summary,
		"tension_summary": tension_summary,
		"next_decision_summary": next_decision_summary,
		"gates": gates,
		"gate_count": gates.size(),
		"passed_gate_count": gates.size() - failed_gate_ids.size(),
		"failed_gate_ids": failed_gate_ids,
		"recommended_next_task": _recommended_next_task(status, failed_gate_ids),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
	}


static func _contact_pressure_gate_passes(contact_pressure: Dictionary) -> bool:
	return not contact_pressure.is_empty() \
		and String(contact_pressure.get("task_id", "")) == "TASK_776" \
		and String(contact_pressure.get("status", "")) == "ready_for_contact_pressure_playtest" \
		and bool(contact_pressure.get("ready_for_contact_pressure_playtest", false)) \
		and _snapshot_read_only(contact_pressure)


static func _exchange_summary(engagement: Dictionary) -> Dictionary:
	var first_fire_event: Dictionary = Dictionary(engagement.get("first_fire_event", engagement.get("fire_event", {}))).duplicate(true)
	var diagnostics: Dictionary = Dictionary(engagement.get("contact_decision_diagnostics", {})).duplicate(true)
	var attacker_id: String = String(engagement.get("attacker_unit_id", first_fire_event.get("attacker_unit_id", diagnostics.get("attacker_unit_id", "")))).strip_edges()
	var target_id: String = String(engagement.get("target_unit_id", first_fire_event.get("target_unit_id", diagnostics.get("target_unit_id", diagnostics.get("actual_target_id", ""))))).strip_edges()
	var weapon_id: String = String(engagement.get("weapon_id", first_fire_event.get("weapon_id", diagnostics.get("weapon_id", "")))).strip_edges()
	var outcome: String = String(engagement.get("outcome", first_fire_event.get("combat_outcome", diagnostics.get("outcome", diagnostics.get("status", ""))))).strip_edges().to_lower()
	var fire_event_id: String = String(engagement.get("fire_event_id", first_fire_event.get("event_id", diagnostics.get("fire_event_id", "")))).strip_edges()
	var visible: bool = not attacker_id.is_empty() \
		and not target_id.is_empty() \
		and not weapon_id.is_empty() \
		and not outcome.is_empty() \
		and (not fire_event_id.is_empty() or String(engagement.get("gate", "pass")) == "pass")
	return {
		"visible": visible,
		"attacker_unit_id": attacker_id,
		"target_unit_id": target_id,
		"weapon_id": weapon_id,
		"outcome": outcome,
		"fire_event_id": fire_event_id,
	}


static func _visual_summary(fire_visuals: Dictionary) -> Dictionary:
	var primary: Dictionary = Dictionary(fire_visuals.get("primary_3d", fire_visuals.get("primary_snapshot", {}))).duplicate(true)
	var first_visual: Dictionary = Dictionary(fire_visuals.get("first_fire_visual", {})).duplicate(true)
	var trace_visible: bool = bool(fire_visuals.get("trace_visible", false)) \
		or bool(first_visual.get("trace_visible", false)) \
		or int(primary.get("weapon_fire_vfx_visual_count", 0)) > 0
	var impact_visible: bool = bool(fire_visuals.get("impact_visible", false)) \
		or bool(first_visual.get("impact_visible", false)) \
		or bool(first_visual.get("target_focus_visible", false))
	var badge_visible: bool = bool(fire_visuals.get("unit_badge_visible", false)) \
		or int(primary.get("unit_status_badge_visible_count", primary.get("unit_status_badge_count", 0))) > 0 \
		or bool(primary.get("unit_status_badges_readable", false))
	return {
		"visible": trace_visible and impact_visible and badge_visible,
		"trace_visible": trace_visible,
		"impact_visible": impact_visible,
		"unit_badge_visible": badge_visible,
		"weapon_fire_vfx_visual_count": int(primary.get("weapon_fire_vfx_visual_count", 0)),
	}


static func _metrics_summary(combat_metrics: Dictionary) -> Dictionary:
	var metrics: Dictionary = Dictionary(combat_metrics.get("metrics", combat_metrics)).duplicate(true)
	var shots_fired: int = int(metrics.get("shots_fired", combat_metrics.get("shots_fired", 0)))
	var hit_count: int = int(metrics.get("hit_count", combat_metrics.get("hit_count", 0)))
	var wounded_count: int = int(metrics.get("wounded_count", combat_metrics.get("wounded_count", 0)))
	var down_count: int = int(metrics.get("down_count", combat_metrics.get("down_count", 0)))
	var friendly_fire_event_count: int = int(metrics.get("friendly_fire_event_count", combat_metrics.get("friendly_fire_event_count", 0)))
	var friendly_fire_risk_count: int = int(metrics.get("friendly_fire_risk_count", combat_metrics.get("friendly_fire_risk_count", 0)))
	var required_keys_present: bool = metrics.has("shots_fired") \
		and metrics.has("hit_count") \
		and metrics.has("wounded_count") \
		and metrics.has("down_count") \
		and metrics.has("friendly_fire_risk_count")
	return {
		"visible": required_keys_present and shots_fired > 0,
		"shots_fired": shots_fired,
		"hit_count": hit_count,
		"wounded_count": wounded_count,
		"down_count": down_count,
		"friendly_fire_event_count": friendly_fire_event_count,
		"friendly_fire_risk_count": friendly_fire_risk_count,
	}


static func _tension_summary(exchange_summary: Dictionary, metrics_summary: Dictionary) -> Dictionary:
	var outcome: String = String(exchange_summary.get("outcome", "")).strip_edges().to_lower()
	var shots_fired: int = int(metrics_summary.get("shots_fired", 0))
	var hit_count: int = int(metrics_summary.get("hit_count", 0))
	var wounded_count: int = int(metrics_summary.get("wounded_count", 0))
	var down_count: int = int(metrics_summary.get("down_count", 0))
	var label: String = "pressure"
	if down_count > 0:
		label = "casualty_pressure"
	elif wounded_count > 0 or hit_count > 0:
		label = "wounded_pressure"
	elif outcome.find("miss") >= 0 or hit_count == 0:
		label = "suppression_pressure"
	var visible: bool = shots_fired > 0 \
		and not outcome.is_empty() \
		and ["casualty_pressure", "wounded_pressure", "suppression_pressure", "pressure"].has(label)
	return {
		"visible": visible,
		"tension_label": label,
		"outcome": outcome,
		"first_exchange_has_survivable_pressure": down_count == 0 and shots_fired > 0,
		"first_exchange_has_casualty_pressure": down_count > 0,
	}


static func _next_decision_summary(hud_decision: Dictionary) -> Dictionary:
	var compact_line: String = String(hud_decision.get("compact_line", hud_decision.get("hud_line", ""))).strip_edges()
	var next_action: String = String(hud_decision.get("next_action", hud_decision.get("next_decision", ""))).strip_edges().to_lower()
	var combined: String = ("%s %s" % [compact_line, next_action]).to_lower()
	var fire_state_visible: bool = combined.find("fire") >= 0 or combined.find("wait") >= 0 or combined.find("contact") >= 0 or combined.find("no fire") >= 0
	var action_source: String = next_action
	if action_source.is_empty() and compact_line.to_lower().find("next:") >= 0:
		action_source = compact_line.to_lower()
	var action_visible: bool = _contains_any(action_source, ["hold", "push", "cover", "retreat", "flank", "suppress", "breach", "move"])
	var within_limit: bool = bool(hud_decision.get("line_within_limit", compact_line.length() <= 110 and not compact_line.is_empty()))
	return {
		"visible": fire_state_visible and action_visible and within_limit,
		"compact_line": compact_line,
		"next_action": next_action,
		"fire_state_visible": fire_state_visible,
		"action_visible": action_visible,
		"line_within_limit": within_limit,
	}


static func _contains_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.find(needle) >= 0:
			return true
	return false


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
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_navigation", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false))


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
		return "ready_for_firefight_tension_playtest"
	if failed_gate_ids.has("contact_pressure_ready"):
		return "blocked_until_contact_pressure_ready"
	if failed_gate_ids.has("fire_exchange_visible"):
		return "needs_fire_exchange_readability"
	if failed_gate_ids.has("fire_visuals_visible"):
		return "needs_fire_visual_polish"
	if failed_gate_ids.has("combat_metrics_visible"):
		return "needs_combat_metrics_polish"
	if failed_gate_ids.has("tension_state_readable"):
		return "needs_tension_language_polish"
	if failed_gate_ids.has("next_decision_visible"):
		return "needs_next_decision_polish"
	return "blocked_until_firefight_tension_gates_green"


static func _build_summary(status: String, failed_gate_ids: Array[String]) -> String:
	match status:
		"ready_for_firefight_tension_playtest":
			return "Station-Reentry-Feuerwechsel ist als erster Tension-Moment lesbar."
		"blocked_until_contact_pressure_ready":
			return "Firefight-Tension-Pass blockiert, bis TASK_776 gruene Contact-Pressure-Lesbarkeit liefert."
		"needs_fire_exchange_readability":
			return "Erster Feuerwechsel braucht Attacker, Target, Weapon und Outcome."
		"needs_fire_visual_polish":
			return "Fire-Trace, Impact/Fokus oder Unit-Badge sind nicht vollstaendig sichtbar."
		"needs_combat_metrics_polish":
			return "Combat-Metriken brauchen Shots, Hits, Wounded, Down und Friendly-Fire-Risiko."
		"needs_tension_language_polish":
			return "Der erste Feuerwechsel braucht ehrliche Tension-Sprache."
		"needs_next_decision_polish":
			return "HUD braucht nach dem Feuerwechsel einen kompakten naechsten Spielergriff."
	return "Firefight-Tension-Pass blockiert; fehlende Gates: %s" % ", ".join(failed_gate_ids)


static func _recommended_next_task(status: String, failed_gate_ids: Array[String]) -> String:
	match status:
		"ready_for_firefight_tension_playtest":
			return "TASK_778 - Station Reentry Firefight Visual Playtest Packet"
		"blocked_until_contact_pressure_ready":
			return "TASK_776 - complete Contact Pressure gates"
		"needs_fire_exchange_readability":
			return "TASK_543 - polish First Engagement feedback"
		"needs_fire_visual_polish":
			return "TASK_544 - polish Fire/Cover visuals"
		"needs_combat_metrics_polish":
			return "TASK_584 - polish Mini-AAR combat metrics"
		"needs_tension_language_polish":
			return "TASK_777 - polish Firefight Tension language"
		"needs_next_decision_polish":
			return "TASK_777 - polish Firefight next-decision cue"
	return "TASK_777 - complete Firefight Tension gates"
