class_name StationReentryFirefightCommandSurfacePolish
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_command_surface_polish.v1"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_reentry_firefight_command_surface_polish.json"
const COMMAND_SURFACE_STYLE_ID: String = "task_783_firefight_command_surface_v1"
const SUMMARY_LINE_LIMIT: int = 96

const TASK_783_SCOPE_ISSUES: Array[String] = [
	"interaction_line_missing",
	"primary_action_unclear",
	"quick_actions_hidden",
	"auto_command_commit_confusing",
	"surface_too_dense",
]

const EXTERNAL_ISSUE_NEXT_TASK: Dictionary = {
	"hold_fire_missing": "TASK_570 - Hold-Fire-Discipline-Mission-Bridge",
	"selected_fireteam_panel_mismatch": "TASK_547 - Multi-Fireteam Combat HUD Consistency Smoke",
	"command_matrix_unreachable": "TASK_736 - Station Scenario Command Feedback Polish",
	"host_client_surface_mismatch": "TASK_770 - Station Reentry Host Client Next Order Sync",
	"performance_stutter_visible": "TASK_769 - Station Reentry Performance Feel Pass",
}


static func build_snapshot(inputs: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = Dictionary(inputs.get("command_surface_findings", {}))
	var interaction: Dictionary = Dictionary(inputs.get("interaction_polish", {}))
	var active_issue_ids: Array[String] = _active_issue_ids(findings)
	var external_issue_ids: Array[String] = _external_issue_ids(active_issue_ids)
	var polished_issue_ids: Array[String] = _task_783_issue_ids(active_issue_ids)
	var primary_action: Dictionary = Dictionary(interaction.get("primary_action", {})).duplicate(true)
	var quick_actions: Array = _build_quick_action_rail(Array(interaction.get("quick_actions", [])), primary_action)
	var interaction_line: String = String(interaction.get("interaction_line", findings.get("expected_interaction_line", ""))).strip_edges()
	var guard_line: String = _build_guard_line(findings, interaction)
	var surface_rows: Array = _build_surface_rows(interaction_line, primary_action, quick_actions, guard_line)
	var gates: Array = [
		_gate("command_surface_findings_ready", _findings_ready(findings), "TASK_782-Findings sind sauber oder liefern belegten TASK_783-Polish."),
		_gate("interaction_polish_ready", _interaction_ready(interaction), "TASK_780-Interaction-Polish liefert bestehende Folgezeile und Quick-Actions."),
		_gate("primary_action_visible", not primary_action.is_empty(), "Primaerer Griff ist als eigene Surface-Zeile vorhanden."),
		_gate("quick_action_rail_visible", quick_actions.size() >= 3, "Quick-Action-Rail enthaelt mindestens drei bestehende Griffe."),
		_gate("guard_line_visible", not guard_line.is_empty(), "No-Auto-Command/Existing-Commands-Grenze ist sichtbar."),
		_gate("summary_line_within_limit", _build_summary_line(primary_action, quick_actions).length() <= SUMMARY_LINE_LIMIT, "Summary bleibt im HUD-Zeichenbudget."),
		_gate("read_only_sources", _sources_are_read_only([findings, interaction]), "Polish liest nur Snapshots und erzeugt keine Gameplay-Wahrheit."),
	]
	var failed_gate_ids: Array[String] = _failed_gate_ids(gates)
	var status: String = _build_status(findings, failed_gate_ids, external_issue_ids)
	var recommended_next_task: String = _recommended_next_task(status, external_issue_ids)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_783",
		"source_task_ids": ["TASK_782", "TASK_780", "TASK_570", "TASK_736"],
		"status": status,
		"summary": _build_summary(status, primary_action, quick_actions, external_issue_ids),
		"ready_for_command_surface_polish_review": status == "ready_for_command_surface_polish_review",
		"command_surface_style_id": COMMAND_SURFACE_STYLE_ID,
		"source_findings_status": String(findings.get("status", "")),
		"source_interaction_status": String(interaction.get("status", "")),
		"surface_priority_order": ["interaction_line", "primary_action", "quick_action_rail", "guard_line"],
		"interaction_line": interaction_line,
		"primary_action": primary_action,
		"quick_action_rail": quick_actions,
		"quick_action_count": quick_actions.size(),
		"guard_line": guard_line,
		"summary_line": _build_summary_line(primary_action, quick_actions),
		"summary_line_limit": SUMMARY_LINE_LIMIT,
		"surface_rows": surface_rows,
		"surface_row_count": surface_rows.size(),
		"polished_issue_ids": polished_issue_ids,
		"external_issue_ids": external_issue_ids,
		"active_issue_ids": active_issue_ids,
		"applies_findings": not polished_issue_ids.is_empty(),
		"requires_external_followup": not external_issue_ids.is_empty(),
		"uses_existing_commands_only": bool(interaction.get("uses_existing_commands_only", false)) and bool(findings.get("expected_uses_existing_commands_only", true)),
		"no_auto_command_commit": bool(interaction.get("no_auto_command_commit", false)) and bool(findings.get("expected_no_auto_command_commit", true)),
		"gates": gates,
		"gate_count": gates.size(),
		"passed_gate_count": gates.size() - failed_gate_ids.size(),
		"failed_gate_ids": failed_gate_ids,
		"recommended_next_task": recommended_next_task,
		"manifest_path": String(inputs.get("manifest_path", DEFAULT_MANIFEST_PATH)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
	}


static func _findings_ready(findings: Dictionary) -> bool:
	if findings.is_empty() or String(findings.get("task_id", "")) != "TASK_782" or not _snapshot_read_only(findings):
		return false
	var status: String = String(findings.get("status", ""))
	return ["ready_for_next_station_firefight_iteration", "needs_targeted_command_surface_polish"].has(status)


static func _interaction_ready(interaction: Dictionary) -> bool:
	return not interaction.is_empty() \
		and String(interaction.get("task_id", "")) == "TASK_780" \
		and String(interaction.get("status", "")) == "ready_for_firefight_interaction_playtest" \
		and bool(interaction.get("ready_for_firefight_interaction_playtest", false)) \
		and bool(interaction.get("uses_existing_commands_only", false)) \
		and bool(interaction.get("no_auto_command_commit", false)) \
		and _snapshot_read_only(interaction)


static func _build_quick_action_rail(source_actions: Array, primary_action: Dictionary) -> Array:
	var rail: Array = []
	var primary_id: String = String(primary_action.get("id", ""))
	for action_variant in source_actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = Dictionary(action_variant).duplicate(true)
		var id: String = String(action.get("id", ""))
		if id.is_empty():
			continue
		action["rail_visible"] = true
		action["button_role"] = "primary" if id == primary_id else "secondary"
		action["display_label"] = String(action.get("label", id)).to_upper()
		action["tooltip_hint"] = String(action.get("reason", "Bestehender Befehl, keine Auto-Ausfuehrung."))
		action["read_only"] = true
		action["ui_sets_gameplay_truth"] = false
		action["creates_command"] = false
		rail.append(action)
	return rail


static func _build_guard_line(findings: Dictionary, interaction: Dictionary) -> String:
	var tokens: Array[String] = []
	if bool(interaction.get("no_auto_command_commit", false)) and bool(findings.get("expected_no_auto_command_commit", true)):
		tokens.append("NO AUTO CMD")
	if bool(interaction.get("uses_existing_commands_only", false)) and bool(findings.get("expected_uses_existing_commands_only", true)):
		tokens.append("EXISTING BUTTONS")
	if tokens.is_empty():
		return ""
	return " | ".join(tokens)


static func _build_surface_rows(interaction_line: String, primary_action: Dictionary, quick_actions: Array, guard_line: String) -> Array:
	return [
		_row("interaction_line", "NEXT", interaction_line, "hud_line", true),
		_row("primary_action", "PRIMARY", String(primary_action.get("label", "")), "button_primary", not primary_action.is_empty()),
		_row("quick_action_rail", "QUICK", _quick_labels(quick_actions), "button_rail", quick_actions.size() >= 3),
		_row("guard_line", "GUARD", guard_line, "guard", not guard_line.is_empty()),
	]


static func _row(id: String, label: String, text: String, visual_role: String, visible: bool) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"text": text,
		"visual_role": visual_role,
		"visible": visible,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _quick_labels(quick_actions: Array) -> String:
	var labels: Array[String] = []
	for action_variant in quick_actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var label: String = String(Dictionary(action_variant).get("display_label", "")).strip_edges()
		if label.is_empty():
			continue
		labels.append(label)
	return " / ".join(labels)


static func _build_summary_line(primary_action: Dictionary, quick_actions: Array) -> String:
	var primary_label: String = String(primary_action.get("label", "HOLD")).to_upper()
	var secondary: Array[String] = []
	for action_variant in quick_actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = Dictionary(action_variant)
		var label: String = String(action.get("display_label", action.get("label", ""))).to_upper()
		if label.is_empty() or label == primary_label:
			continue
		secondary.append(label)
		if secondary.size() >= 4:
			break
	var line: String = "NEXT %s" % primary_label
	if not secondary.is_empty():
		line += " | QUICK %s" % " / ".join(secondary)
	return line.left(SUMMARY_LINE_LIMIT)


static func _active_issue_ids(findings: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for flag_variant in Array(findings.get("issue_flags", [])):
		if typeof(flag_variant) != TYPE_DICTIONARY:
			continue
		var flag: Dictionary = Dictionary(flag_variant)
		if bool(flag.get("active", false)):
			ids.append(String(flag.get("id", "")))
	return ids


static func _task_783_issue_ids(active_issue_ids: Array[String]) -> Array[String]:
	var ids: Array[String] = []
	for id in active_issue_ids:
		if TASK_783_SCOPE_ISSUES.has(id):
			ids.append(id)
	return ids


static func _external_issue_ids(active_issue_ids: Array[String]) -> Array[String]:
	var ids: Array[String] = []
	for id in active_issue_ids:
		if not TASK_783_SCOPE_ISSUES.has(id):
			ids.append(id)
	return ids


static func _build_status(findings: Dictionary, failed_gate_ids: Array[String], external_issue_ids: Array[String]) -> String:
	if findings.is_empty() or String(findings.get("task_id", "")) != "TASK_782":
		return "blocked_until_command_surface_findings"
	var findings_status: String = String(findings.get("status", ""))
	if findings_status == "needs_visible_command_surface_review":
		return "blocked_until_visible_command_surface_review"
	if findings_status == "needs_command_surface_review_completion":
		return "blocked_until_command_surface_review_complete"
	if findings_status == "blocked":
		return "blocked_until_command_surface_findings"
	if not external_issue_ids.is_empty():
		return "needs_external_command_surface_followup"
	if not failed_gate_ids.is_empty():
		return "blocked_until_command_surface_polish_gates_green"
	return "ready_for_command_surface_polish_review"


static func _build_summary(status: String, primary_action: Dictionary, quick_actions: Array, external_issue_ids: Array[String]) -> String:
	match status:
		"ready_for_command_surface_polish_review":
			return "Command-Surface-Polish bereit: %s." % _build_summary_line(primary_action, quick_actions)
		"blocked_until_visible_command_surface_review":
			return "Command-Surface-Polish wartet auf den echten sichtbaren TASK_781/TASK_782-Review."
		"blocked_until_command_surface_review_complete":
			return "Command-Surface-Polish wartet auf vollstaendige TASK_782-Pflichtchecks."
		"needs_external_command_surface_followup":
			return "Command-Surface-Findings enthalten externe Follow-ups: %s." % ", ".join(PackedStringArray(external_issue_ids))
		"blocked_until_command_surface_findings":
			return "Command-Surface-Polish wartet auf gueltige TASK_782-Findings."
	return "Command-Surface-Polish blockiert; Gates sind noch nicht gruen."


static func _recommended_next_task(status: String, external_issue_ids: Array[String]) -> String:
	match status:
		"ready_for_command_surface_polish_review":
			return "TASK_784 - Station Reentry Firefight Command Surface Playtest Packet Refresh"
		"blocked_until_visible_command_surface_review":
			return "TASK_781 - run visible Firefight Command Surface Recapture"
		"blocked_until_command_surface_review_complete":
			return "TASK_781 - complete missing visible Command-Surface checks"
		"needs_external_command_surface_followup":
			if not external_issue_ids.is_empty():
				return String(EXTERNAL_ISSUE_NEXT_TASK.get(external_issue_ids[0], "TASK_782 - review command surface findings"))
			return "TASK_782 - review command surface findings"
		"blocked_until_command_surface_findings":
			return "TASK_782 - Station Reentry Firefight Command Surface Findings"
	return "TASK_783 - complete Command Surface Polish gates"


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
