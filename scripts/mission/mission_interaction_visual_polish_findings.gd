class_name MissionInteractionVisualPolishFindings
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_visual_polish_findings.v1"
const DEFAULT_VISUAL_BUDGET_LIMIT: int = 32
const DEFAULT_OBJECT_REACTION_VISUAL_LIMIT: int = 16
const DEFAULT_ROUTE_CALLOUT_LIMIT: int = 6


static func build_snapshot(render_snapshot: Dictionary, evidence_manifest: Dictionary = {}, limits: Dictionary = {}) -> Dictionary:
	var visual_budget_limit: int = maxi(1, int(limits.get("visual_budget_limit", DEFAULT_VISUAL_BUDGET_LIMIT)))
	var object_reaction_visual_limit: int = maxi(1, int(limits.get("object_reaction_visual_limit", DEFAULT_OBJECT_REACTION_VISUAL_LIMIT)))
	var route_callout_limit: int = maxi(0, int(limits.get("route_callout_limit", DEFAULT_ROUTE_CALLOUT_LIMIT)))
	var visual_state_count: int = int(render_snapshot.get("mission_interaction_visual_state_count", 0))
	var object_reaction_count: int = int(render_snapshot.get("mission_interaction_object_reaction_count", 0))
	var object_reaction_visual_count: int = int(render_snapshot.get("mission_interaction_object_reaction_visual_count", 0))
	var route_callout_visual_count: int = int(render_snapshot.get("route_callout_visual_count", 0))
	var visual_budget: int = int(evidence_manifest.get("visual_budget", visual_state_count + object_reaction_visual_count + route_callout_visual_count))
	var findings: Array = []
	_add_count_findings(findings, visual_state_count, object_reaction_count, object_reaction_visual_count, route_callout_visual_count, visual_budget, visual_budget_limit, object_reaction_visual_limit, route_callout_limit)
	_add_readonly_findings(findings, Array(render_snapshot.get("mission_interaction_visual_state_entries", [])), Array(render_snapshot.get("mission_interaction_object_reaction_entries", [])))
	var manual_review_open: bool = bool(evidence_manifest.get("manual_fullhd_review_required", true)) and not bool(evidence_manifest.get("manual_fullhd_review_done", false))
	if manual_review_open:
		findings.append(_finding("manual_fullhd_review_open", "manual", "Echter FullHD-Fenster-Sichtentscheid ist noch offen.", "TASK_690 - Mission Interaction Manual Sight Notes"))
	var blocking_count: int = _count_findings_by_severity(findings, "blocker")
	var warning_count: int = _count_findings_by_severity(findings, "warning")
	var manual_count: int = _count_findings_by_severity(findings, "manual")
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "read-only render/evidence snapshot",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"visual_state_count": visual_state_count,
		"object_reaction_count": object_reaction_count,
		"object_reaction_visual_count": object_reaction_visual_count,
		"route_callout_visual_count": route_callout_visual_count,
		"visual_budget": visual_budget,
		"visual_budget_limit": visual_budget_limit,
		"object_reaction_visual_limit": object_reaction_visual_limit,
		"route_callout_limit": route_callout_limit,
		"within_visual_budget": visual_budget > 0 and visual_budget <= visual_budget_limit,
		"manual_review_open": manual_review_open,
		"blocking_issue_count": blocking_count,
		"warning_count": warning_count,
		"manual_note_count": manual_count,
		"findings": findings,
		"status": "blocked" if blocking_count > 0 else ("needs_manual_review" if manual_review_open else ("warning" if warning_count > 0 else "ok")),
		"summary": _build_summary(blocking_count, warning_count, manual_count, visual_budget, visual_budget_limit),
		"recommended_next_task": _recommended_next_task(blocking_count, warning_count, manual_review_open),
	}


static func _add_count_findings(findings: Array, visual_state_count: int, object_reaction_count: int, object_reaction_visual_count: int, route_callout_visual_count: int, visual_budget: int, visual_budget_limit: int, object_reaction_visual_limit: int, route_callout_limit: int) -> void:
	if visual_state_count <= 0:
		findings.append(_finding("missing_visual_states", "blocker", "Keine Mission-Interaction-Visualstate-Eintraege im Render-Snapshot.", "TASK_686 regression"))
	elif visual_state_count < 3:
		findings.append(_finding("low_visual_state_count", "warning", "Weniger als drei Mission-Interaction-Visualstates sichtbar.", "TASK_689 visual polish"))
	if object_reaction_count <= 0:
		findings.append(_finding("missing_object_reactions", "blocker", "Keine Object-Reaction-Eintraege im Render-Snapshot.", "TASK_687 regression"))
	elif object_reaction_visual_count < object_reaction_count:
		findings.append(_finding("object_reaction_visual_under_budget", "blocker", "Weniger Objektreaktions-Visuals als Objektreaktionen.", "TASK_687 regression"))
	if visual_budget <= 0:
		findings.append(_finding("empty_visual_budget", "blocker", "Mission-Interaction-Visualbudget ist leer.", "TASK_688 evidence regression"))
	elif visual_budget > visual_budget_limit:
		findings.append(_finding("visual_budget_too_high", "blocker", "Mission-Interaction-Visualbudget liegt ueber dem Limit.", "TASK_689 visual budget polish"))
	if object_reaction_visual_count > object_reaction_visual_limit:
		findings.append(_finding("object_reaction_visual_count_high", "warning", "Viele Object-Reaction-Proxies koennen die Karte optisch verdichten.", "TASK_689 proxy size polish"))
	if route_callout_visual_count > route_callout_limit:
		findings.append(_finding("route_callout_count_high", "warning", "Viele Route-Callouts koennen mit Interaction-Labels konkurrieren.", "TASK_689 label priority polish"))


static func _add_readonly_findings(findings: Array, visual_entries: Array, object_entries: Array) -> void:
	for entry_variant in visual_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if not bool(entry.get("read_only", false)) or bool(entry.get("ui_sets_gameplay_truth", true)):
			findings.append(_finding("visual_entry_not_readonly", "blocker", "Ein Visualstate-Eintrag verletzt read-only/UI-Truth-Regel.", "TASK_686 regression"))
			break
	for entry_variant in object_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if not bool(entry.get("read_only", false)) or bool(entry.get("ui_sets_gameplay_truth", true)):
			findings.append(_finding("object_reaction_entry_not_readonly", "blocker", "Ein Object-Reaction-Eintrag verletzt read-only/UI-Truth-Regel.", "TASK_687 regression"))
			break


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count


static func _build_summary(blocking_count: int, warning_count: int, manual_count: int, visual_budget: int, visual_budget_limit: int) -> String:
	if blocking_count > 0:
		return "%d blocker, budget %d/%d" % [blocking_count, visual_budget, visual_budget_limit]
	if warning_count > 0:
		return "%d warnings, budget %d/%d" % [warning_count, visual_budget, visual_budget_limit]
	if manual_count > 0:
		return "technisch gruen, manueller Sichtlauf offen, budget %d/%d" % [visual_budget, visual_budget_limit]
	return "technisch gruen, budget %d/%d" % [visual_budget, visual_budget_limit]


static func _recommended_next_task(blocking_count: int, warning_count: int, manual_review_open: bool) -> String:
	if blocking_count > 0:
		return "TASK_690 - Mission Interaction Visual Regression Fix"
	if warning_count > 0:
		return "TASK_690 - Mission Interaction Visual Polish"
	if manual_review_open:
		return "TASK_690 - Mission Interaction Manual Sight Notes"
	return "TASK_691 - Mission Interaction Runtime Visual Assets"
