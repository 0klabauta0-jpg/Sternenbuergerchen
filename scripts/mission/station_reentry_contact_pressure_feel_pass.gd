class_name StationReentryContactPressureFeelPass
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_contact_pressure_feel_pass.v1"
const VALID_RISK_STATES: Array[String] = ["safe", "risky", "suicidal", "unknown"]


static func build_snapshot(inputs: Dictionary = {}) -> Dictionary:
	var interaction_feel: Dictionary = Dictionary(inputs.get("interaction_feel", {}))
	var contact_report: Dictionary = Dictionary(inputs.get("contact_report", {}))
	var threat_preview: Dictionary = Dictionary(inputs.get("threat_preview", {}))
	var pressure_feedback: Dictionary = Dictionary(inputs.get("pressure_feedback", {}))
	var combat_hud: Dictionary = Dictionary(inputs.get("combat_hud", {}))
	var contact_summary: Dictionary = _contact_summary(contact_report)
	var threat_summary: Dictionary = _threat_summary(threat_preview)
	var pressure_summary: Dictionary = _pressure_summary(pressure_feedback)
	var hud_summary: Dictionary = _hud_summary(combat_hud)
	var gates: Array = [
		_gate("interaction_feel_ready", _interaction_feel_gate_passes(interaction_feel), "TASK_775-Interaction-Feel ist gruen."),
		_gate("contact_report_visible", bool(contact_summary.get("visible", false)), "Kontaktmeldung zeigt Typ/Text, Position, Confidence und Alter."),
		_gate("threat_reason_visible", bool(threat_summary.get("visible", false)), "Risk-/LOS-/Exposure-Grund ist vor oder bei Kontakt sichtbar."),
		_gate("pressure_feedback_visible", bool(pressure_summary.get("visible", false)), "Fire/Wait/No-Fire/Contact-Druck ist knapp erklaert."),
		_gate("combat_hud_compact", bool(hud_summary.get("compact", false)), "HUD-Zeile behaelt Contact/Risk/LOS/Cover kompakt."),
		_gate("read_only_sources", _sources_are_read_only([interaction_feel, contact_report, threat_preview, pressure_feedback, combat_hud]), "Feel-Pass liest nur Snapshots und erzeugt keine Gameplay-Wahrheit."),
	]
	var failed_gate_ids: Array[String] = _failed_gate_ids(gates)
	var status: String = _build_status(failed_gate_ids)
	var ready: bool = status == "ready_for_contact_pressure_playtest"
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_776",
		"source_task_ids": ["TASK_775", "TASK_542", "TASK_543", "TASK_546", "TASK_567"],
		"status": status,
		"summary": _build_summary(status, failed_gate_ids),
		"ready_for_contact_pressure_playtest": ready,
		"interaction_feel_status": String(interaction_feel.get("status", "")),
		"contact_summary": contact_summary,
		"threat_summary": threat_summary,
		"pressure_summary": pressure_summary,
		"hud_summary": hud_summary,
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
	}


static func _interaction_feel_gate_passes(interaction_feel: Dictionary) -> bool:
	return not interaction_feel.is_empty() \
		and String(interaction_feel.get("task_id", "")) == "TASK_775" \
		and String(interaction_feel.get("status", "")) == "ready_for_mission_interaction_playtest" \
		and bool(interaction_feel.get("ready_for_mission_interaction_playtest", false)) \
		and _snapshot_read_only(interaction_feel)


static func _contact_summary(contact_report: Dictionary) -> Dictionary:
	var first_contact: Dictionary = Dictionary(contact_report.get("first_contact", contact_report.get("contact", {}))).duplicate(true)
	var report_text: String = String(contact_report.get("report_text", first_contact.get("report_text", ""))).strip_edges()
	var enemy_type: String = String(contact_report.get("enemy_type", first_contact.get("enemy_type", first_contact.get("unit_type", "")))).strip_edges()
	var confidence: float = float(contact_report.get("confidence", first_contact.get("confidence", first_contact.get("contact_report_quality", -1.0))))
	var age_seconds: float = float(contact_report.get("last_seen_age_seconds", first_contact.get("last_seen_age_seconds", contact_report.get("age_seconds", -1.0))))
	var has_position: bool = _has_position(contact_report) or _has_position(first_contact)
	var gate_passes: bool = String(contact_report.get("gate", "pass")) == "pass" or bool(contact_report.get("visible", false))
	var visible: bool = gate_passes \
		and (not report_text.is_empty() or not enemy_type.is_empty()) \
		and has_position \
		and confidence >= 0.0 \
		and age_seconds >= 0.0
	return {
		"visible": visible,
		"report_text": report_text,
		"enemy_type": enemy_type,
		"has_position": has_position,
		"confidence": confidence,
		"last_seen_age_seconds": age_seconds,
		"selected_contact_count": int(contact_report.get("selected_contact_count", 1 if not first_contact.is_empty() else 0)),
	}


static func _threat_summary(threat_preview: Dictionary) -> Dictionary:
	var risk_state: String = String(threat_preview.get("risk_state", "unknown")).strip_edges().to_lower()
	var risk_text: String = String(threat_preview.get("risk_preview_text", threat_preview.get("preview_text", ""))).strip_edges()
	var line_count: int = int(threat_preview.get("line_of_fire_entry_count", threat_preview.get("render_preview_threat_line_count", threat_preview.get("threat_line_count", 0))))
	var enemy_exposure_count: int = int(threat_preview.get("enemy_exposure_count", threat_preview.get("enemy_line_count", 0)))
	var friendly_fire_risk_count: int = int(threat_preview.get("friendly_fire_risk_count", 0))
	var unknown_explained: bool = risk_state != "unknown" or risk_text.findn("no intel") >= 0 or risk_text.findn("unknown") >= 0 or not String(threat_preview.get("risk_reason", "")).strip_edges().is_empty()
	var reason_visible: bool = not risk_text.is_empty() and VALID_RISK_STATES.has(risk_state) and unknown_explained
	var visible: bool = reason_visible and (line_count > 0 or enemy_exposure_count > 0 or risk_state == "safe" or risk_state == "unknown")
	return {
		"visible": visible,
		"risk_state": risk_state,
		"risk_preview_text": risk_text,
		"line_of_fire_entry_count": line_count,
		"enemy_exposure_count": enemy_exposure_count,
		"friendly_fire_risk_count": friendly_fire_risk_count,
	}


static func _pressure_summary(pressure_feedback: Dictionary) -> Dictionary:
	var status: String = String(pressure_feedback.get("engagement_status", pressure_feedback.get("status", ""))).strip_edges().to_lower()
	var reason: String = String(pressure_feedback.get("engagement_reason", pressure_feedback.get("reason", ""))).strip_edges().to_lower()
	var text: String = String(pressure_feedback.get("contact_decision_text", pressure_feedback.get("pressure_text", ""))).strip_edges()
	var diagnostics: Dictionary = Dictionary(pressure_feedback.get("contact_decision_diagnostics", {})).duplicate(true)
	if status.is_empty():
		status = String(diagnostics.get("status", "")).strip_edges().to_lower()
	if reason.is_empty():
		reason = String(diagnostics.get("reason", "")).strip_edges().to_lower()
	var visible_status: bool = ["fired", "waiting", "blocked", "contact", "no_fire", "no fire"].has(status) or text.findn("fire") >= 0 or text.findn("contact") >= 0 or text.findn("wait") >= 0
	var has_block_or_target: bool = not reason.is_empty() \
		or not String(diagnostics.get("target_unit_id", diagnostics.get("actual_target_id", ""))).strip_edges().is_empty() \
		or not String(diagnostics.get("candidate_reason", "")).strip_edges().is_empty() \
		or int(diagnostics.get("cooldown_ticks_remaining", 0)) > 0
	var visible: bool = visible_status and (has_block_or_target or not text.is_empty())
	return {
		"visible": visible,
		"engagement_status": status,
		"engagement_reason": reason,
		"pressure_text": text,
		"has_block_or_target": has_block_or_target,
	}


static func _hud_summary(combat_hud: Dictionary) -> Dictionary:
	var compact_line: String = String(combat_hud.get("compact_line", combat_hud.get("hud_line", ""))).strip_edges()
	var mission_control_line: String = String(combat_hud.get("mission_control_line", "")).strip_edges()
	var selected_fireteam_line: String = String(combat_hud.get("selected_fireteam_line", "")).strip_edges()
	var combined: String = "%s %s %s" % [compact_line, mission_control_line, selected_fireteam_line]
	var has_contact_or_risk: bool = combined.findn("contact") >= 0 or combined.findn("risk") >= 0 or combined.findn("fire") >= 0
	var has_los: bool = bool(combat_hud.get("contains_los_context", false)) or combined.findn("los") >= 0
	var has_cover: bool = bool(combat_hud.get("contains_cover_context", false)) or combined.findn("cover") >= 0
	var within_limit: bool = bool(combat_hud.get("line_within_limit", compact_line.length() <= 96 and not compact_line.is_empty()))
	return {
		"compact": not compact_line.is_empty() and has_contact_or_risk and has_los and has_cover and within_limit,
		"compact_line": compact_line,
		"mission_control_line": mission_control_line,
		"selected_fireteam_line": selected_fireteam_line,
		"has_contact_or_risk": has_contact_or_risk,
		"has_los": has_los,
		"has_cover": has_cover,
		"line_within_limit": within_limit,
	}


static func _has_position(source: Dictionary) -> bool:
	if typeof(source.get("position", null)) == TYPE_VECTOR2 or typeof(source.get("last_known_position", null)) == TYPE_VECTOR2:
		return true
	if typeof(source.get("approximate_position", null)) == TYPE_VECTOR2:
		return true
	if typeof(source.get("position_grid", null)) == TYPE_VECTOR2I or typeof(source.get("last_known_grid", null)) == TYPE_VECTOR2I:
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
		and not bool(snapshot.get("creates_fire_event", false))


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
		return "ready_for_contact_pressure_playtest"
	if failed_gate_ids.has("interaction_feel_ready"):
		return "blocked_until_interaction_feel_ready"
	if failed_gate_ids.has("contact_report_visible"):
		return "needs_contact_report_polish"
	if failed_gate_ids.has("threat_reason_visible"):
		return "needs_threat_reason_polish"
	if failed_gate_ids.has("pressure_feedback_visible"):
		return "needs_pressure_feedback_polish"
	if failed_gate_ids.has("combat_hud_compact"):
		return "needs_combat_hud_polish"
	return "blocked_until_contact_pressure_gates_green"


static func _build_summary(status: String, failed_gate_ids: Array[String]) -> String:
	match status:
		"ready_for_contact_pressure_playtest":
			return "Station-Reentry-Kontakt, Risiko und Druck sind fuer den naechsten Playtest lesbar."
		"blocked_until_interaction_feel_ready":
			return "Contact-Pressure-Pass blockiert, bis TASK_775 gruene Interaktionslesbarkeit liefert."
		"needs_contact_report_polish":
			return "Kontaktmeldung braucht Text, Position, Confidence oder Alterskontext."
		"needs_threat_reason_polish":
			return "Threat-/Risk-Preview braucht sichtbare LOS-/Exposure-Gruende."
		"needs_pressure_feedback_polish":
			return "Fire/Wait/No-Fire-Druck braucht klaren Status oder Blockgrund."
		"needs_combat_hud_polish":
			return "Combat-HUD braucht kompakte Contact/Risk/LOS/Cover-Zeile."
	return "Contact-Pressure-Pass blockiert; fehlende Gates: %s" % ", ".join(failed_gate_ids)


static func _recommended_next_task(status: String, failed_gate_ids: Array[String]) -> String:
	match status:
		"ready_for_contact_pressure_playtest":
			return "TASK_777 - Station Reentry Firefight Tension Feel Pass"
		"blocked_until_interaction_feel_ready":
			return "TASK_775 - complete Mission Interaction Feel gates"
		"needs_contact_report_polish":
			return "TASK_542/TASK_510 - polish Contact Report readability"
		"needs_threat_reason_polish":
			return "TASK_567/TASK_508 - polish Threat Preview reasons"
		"needs_pressure_feedback_polish":
			return "TASK_543 - polish First Engagement feedback"
		"needs_combat_hud_polish":
			return "TASK_546 - polish Combat HUD density"
	return "TASK_776 - complete Contact Pressure gates"
